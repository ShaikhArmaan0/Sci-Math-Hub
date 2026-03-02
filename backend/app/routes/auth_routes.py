import re
import random
import time
from datetime import datetime, timezone
from flask import Blueprint, request
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from werkzeug.security import generate_password_hash, check_password_hash
from bson import ObjectId
from app.database import users_col, user_prefs_col
from app.utils import serialize, now, to_object_id, ok, err

auth_bp = Blueprint("auth", __name__, url_prefix="/api/auth")

EMAIL_REGEX = r"^[\w\.-]+@[\w\.-]+\.\w+$"
PHONE_REGEX = r"^\d{10}$"

_otp_store = {}


def _safe_user(user):
    user = serialize(user)
    user.pop("password_hash", None)
    user.pop("failed_attempts", None)
    return user


def _default_prefs(user_id):
    return {
        "user_id": user_id,
        "dark_mode": False,
        "language": "en",
        "notifications_enabled": True,
        "study_reminder_enabled": True,
        "badge_alert_enabled": True,
        "quiz_reminder_enabled": True,
        "show_on_leaderboard": True,
        "show_streak_publicly": True,
        "difficulty_level": "medium",
        "preferred_subject": None,
        "font_size": "medium",
        "wifi_only_download": False,
        "created_at": now(),
        "updated_at": now(),
    }


# ── Register ──────────────────────────────────────────────────────────────────

@auth_bp.route("/register", methods=["POST"])
def register():
    data = request.get_json() or {}

    for field in ["full_name", "email", "phone", "password"]:
        if not data.get(field):
            return err(f"'{field}' is required")

    email = data["email"].lower().strip()
    phone = data["phone"].strip()

    if not re.match(EMAIL_REGEX, email):
        return err("Invalid email format")
    if not re.match(PHONE_REGEX, phone):
        return err("Phone must be exactly 10 digits")
    if len(data["password"]) < 6:
        return err("Password must be at least 6 characters")
    if users_col().find_one({"email": email}):
        return err("Email already registered", 409)
    if users_col().find_one({"phone": phone}):
        return err("Phone already registered", 409)

    doc = {
        "full_name": data["full_name"].strip(),
        "email": email,
        "phone": phone,
        "password_hash": generate_password_hash(data["password"]),
        "role": "student",
        "class_id": data.get("class_id"),
        "profile_image": "",
        "total_points": 0,
        "streak_count": 0,
        "failed_attempts": 0,
        "last_activity_date": None,
        "is_active": True,
        "created_at": now(),
        "updated_at": now(),
    }

    result = users_col().insert_one(doc)
    user_id = str(result.inserted_id)
    token = create_access_token(identity=user_id)

    prefs = _default_prefs(user_id)
    user_prefs_col().insert_one(prefs)

    doc["_id"] = result.inserted_id
    return ok({"token": token, "user": _safe_user(doc)}, "Registration successful", 201)


# ── Login ─────────────────────────────────────────────────────────────────────

@auth_bp.route("/login", methods=["POST"])
def login():
    data = request.get_json() or {}
    identifier = data.get("email_or_phone", "").strip()
    password = data.get("password", "")

    if not identifier or not password:
        return err("Email/Phone and password are required")

    query = {"$or": [{"email": identifier.lower()}, {"phone": identifier}]}
    user = users_col().find_one(query)
    if not user:
        return err("Invalid credentials", 401)

    if not user.get("is_active", True):
        return err("Account is deactivated. Contact support.", 403)

    if user.get("failed_attempts", 0) >= 5:
        return err("Too many failed attempts. Please try again later.", 403)

    if not check_password_hash(user["password_hash"], password):
        users_col().update_one({"_id": user["_id"]}, {"$inc": {"failed_attempts": 1}})
        return err("Invalid credentials", 401)

    users_col().update_one({"_id": user["_id"]}, {"$set": {"failed_attempts": 0}})

    today = datetime.now(timezone.utc).date()
    last_activity = user.get("last_activity_date")
    streak_update = {"last_activity_date": now()}

    if last_activity:
        if isinstance(last_activity, datetime):
            last_date = last_activity.replace(tzinfo=timezone.utc).date()
        else:
            last_date = last_activity.date() if hasattr(last_activity, 'date') else today
        diff = (today - last_date).days
        if diff == 1:
            streak_update["streak_count"] = user.get("streak_count", 0) + 1
        elif diff > 1:
            streak_update["streak_count"] = 1
    else:
        streak_update["streak_count"] = 1

    users_col().update_one({"_id": user["_id"]}, {"$set": streak_update})
    updated_user = users_col().find_one({"_id": user["_id"]})
    token = create_access_token(identity=str(user["_id"]))

    return ok({"token": token, "user": _safe_user(updated_user)}, "Login successful")


# ── Get Me ────────────────────────────────────────────────────────────────────

@auth_bp.route("/me", methods=["GET"])
@jwt_required()
def get_me():
    uid = to_object_id(get_jwt_identity())
    user = users_col().find_one({"_id": uid})
    if not user:
        return err("User not found", 404)

    prefs = user_prefs_col().find_one({"user_id": str(uid)})
    user_data = _safe_user(user)
    user_data["preferences"] = serialize(prefs) if prefs else {}

    return ok({"user": user_data})


# ── Logout ────────────────────────────────────────────────────────────────────

@auth_bp.route("/logout", methods=["POST"])
@jwt_required()
def logout():
    return ok(message="Logged out successfully")


# ── Forgot Password / OTP ─────────────────────────────────────────────────────

@auth_bp.route('/forgot-password', methods=['POST'])
def forgot_password():
    data = request.get_json() or {}
    contact = data.get('contact', '').strip()
    if not contact:
        return err('Email or phone is required', 400)

    user = users_col().find_one({
        '$or': [{'email': contact}, {'phone': contact}]
    })
    if not user:
        return ok('OTP sent if account exists')

    otp = str(random.randint(100000, 999999))
    _otp_store[contact] = {
        'otp': otp,
        'user_id': str(user['_id']),
        'expires_at': time.time() + 600
    }

    print(f"\n{'='*40}")
    print(f"OTP for {contact}: {otp}")
    print(f"{'='*40}\n")

    return ok('OTP sent successfully')


@auth_bp.route('/verify-otp', methods=['POST'])
def verify_otp():
    data = request.get_json() or {}
    contact = data.get('contact', '').strip()
    otp = data.get('otp', '').strip()

    if not contact or not otp:
        return err('Contact and OTP are required', 400)

    record = _otp_store.get(contact)
    if not record:
        return err('OTP not found. Please request again.', 400)
    if time.time() > record['expires_at']:
        del _otp_store[contact]
        return err('OTP expired. Please request again.', 400)
    if record['otp'] != otp:
        return err('Invalid OTP', 400)

    return ok('OTP verified successfully')


@auth_bp.route('/reset-password', methods=['POST'])
def reset_password():
    data = request.get_json() or {}
    contact = data.get('contact', '').strip()
    otp = data.get('otp', '').strip()
    new_password = data.get('new_password', '')

    if not contact or not otp or not new_password:
        return err('All fields are required', 400)
    if len(new_password) < 6:
        return err('Password must be at least 6 characters', 400)

    record = _otp_store.get(contact)
    if not record:
        return err('OTP not found. Please request again.', 400)
    if time.time() > record['expires_at']:
        del _otp_store[contact]
        return err('OTP expired. Please request again.', 400)
    if record['otp'] != otp:
        return err('Invalid OTP', 400)

    users_col().update_one(
        {'_id': ObjectId(record['user_id'])},
        {'$set': {'password_hash': generate_password_hash(new_password)}}
    )

    del _otp_store[contact]
    return ok('Password reset successfully')