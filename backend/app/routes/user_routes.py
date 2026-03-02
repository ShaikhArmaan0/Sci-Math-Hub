import re
from flask import Blueprint, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from werkzeug.security import generate_password_hash, check_password_hash
from app.database import users_col, user_prefs_col, attempts_col, user_badges_col
from app.utils import serialize, now, to_object_id, ok, err

user_bp = Blueprint("user", __name__, url_prefix="/api/user")

EMAIL_REGEX = r"^[\w\.-]+@[\w\.-]+\.\w+$"
PHONE_REGEX = r"^\d{10}$"


def _safe_user(user):
    user = serialize(user)
    user.pop("password_hash", None)
    user.pop("failed_attempts", None)
    return user


# ───────────────── UPDATE PROFILE ─────────────────

@user_bp.route("/profile", methods=["PUT"])
@jwt_required()
def update_profile():
    uid = to_object_id(get_jwt_identity())
    data = request.get_json() or {}

    allowed = ["full_name", "profile_image"]
    updates = {k: v for k, v in data.items() if k in allowed and v is not None}

    if not updates:
        return err("No valid fields to update")

    if "full_name" in updates:
        updates["full_name"] = updates["full_name"].strip()
        if not updates["full_name"]:
            return err("full_name cannot be empty")

    updates["updated_at"] = now()
    users_col().update_one({"_id": uid}, {"$set": updates})
    user = users_col().find_one({"_id": uid})
    return ok({"user": _safe_user(user)}, "Profile updated")


# ───────────────── CHANGE EMAIL ─────────────────

@user_bp.route("/change-email", methods=["PUT"])
@jwt_required()
def change_email():
    uid = to_object_id(get_jwt_identity())
    data = request.get_json() or {}

    new_email = data.get("new_email", "").lower().strip()
    password = data.get("password", "")

    if not new_email or not password:
        return err("new_email and password are required")

    if not re.match(EMAIL_REGEX, new_email):
        return err("Invalid email format")

    user = users_col().find_one({"_id": uid})
    if not check_password_hash(user["password_hash"], password):
        return err("Incorrect password", 401)

    if users_col().find_one({"email": new_email, "_id": {"$ne": uid}}):
        return err("Email already in use", 409)

    users_col().update_one({"_id": uid}, {"$set": {"email": new_email, "updated_at": now()}})
    return ok(message="Email updated successfully")


# ───────────────── CHANGE PHONE ─────────────────

@user_bp.route("/change-phone", methods=["PUT"])
@jwt_required()
def change_phone():
    uid = to_object_id(get_jwt_identity())
    data = request.get_json() or {}

    new_phone = data.get("new_phone", "").strip()
    password = data.get("password", "")

    if not new_phone or not password:
        return err("new_phone and password are required")

    if not re.match(PHONE_REGEX, new_phone):
        return err("Phone must be exactly 10 digits")

    user = users_col().find_one({"_id": uid})
    if not check_password_hash(user["password_hash"], password):
        return err("Incorrect password", 401)

    if users_col().find_one({"phone": new_phone, "_id": {"$ne": uid}}):
        return err("Phone already in use", 409)

    users_col().update_one({"_id": uid}, {"$set": {"phone": new_phone, "updated_at": now()}})
    return ok(message="Phone number updated successfully")


# ───────────────── CHANGE PASSWORD ─────────────────

@user_bp.route("/change-password", methods=["PUT"])
@jwt_required()
def change_password():
    uid = to_object_id(get_jwt_identity())
    data = request.get_json() or {}

    current_password = data.get("current_password", "")
    new_password = data.get("new_password", "")

    if not current_password or not new_password:
        return err("current_password and new_password are required")

    if len(new_password) < 6:
        return err("New password must be at least 6 characters")

    user = users_col().find_one({"_id": uid})
    if not check_password_hash(user["password_hash"], current_password):
        return err("Incorrect current password", 401)

    users_col().update_one(
        {"_id": uid},
        {"$set": {"password_hash": generate_password_hash(new_password), "updated_at": now()}}
    )
    return ok(message="Password changed successfully")


# ───────────────── CHANGE CLASS ─────────────────

@user_bp.route("/change-class", methods=["PUT"])
@jwt_required()
def change_class():
    uid = to_object_id(get_jwt_identity())
    data = request.get_json() or {}

    class_id = data.get("class_id")
    if not class_id:
        return err("class_id is required")

    users_col().update_one({"_id": uid}, {"$set": {"class_id": class_id, "updated_at": now()}})
    user = users_col().find_one({"_id": uid})
    return ok({"user": _safe_user(user)}, "Class updated")


# ───────────────── GET PREFERENCES ─────────────────

@user_bp.route("/preferences", methods=["GET"])
@jwt_required()
def get_preferences():
    uid_str = get_jwt_identity()
    prefs = user_prefs_col().find_one({"user_id": uid_str})
    if not prefs:
        # Auto-create defaults if missing
        prefs = {
            "user_id": uid_str,
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
        user_prefs_col().insert_one(prefs)
    return ok({"preferences": serialize(prefs)})


# ───────────────── UPDATE PREFERENCES ─────────────────

@user_bp.route("/preferences", methods=["PUT"])
@jwt_required()
def update_preferences():
    uid_str = get_jwt_identity()
    data = request.get_json() or {}

    allowed = [
        "dark_mode", "language", "notifications_enabled", "study_reminder_enabled",
        "badge_alert_enabled", "quiz_reminder_enabled", "show_on_leaderboard",
        "show_streak_publicly", "difficulty_level", "preferred_subject",
        "font_size", "wifi_only_download"
    ]
    updates = {k: v for k, v in data.items() if k in allowed}

    if not updates:
        return err("No valid preference fields provided")

    updates["updated_at"] = now()
    user_prefs_col().update_one(
        {"user_id": uid_str},
        {"$set": updates},
        upsert=True
    )
    prefs = user_prefs_col().find_one({"user_id": uid_str})
    return ok({"preferences": serialize(prefs)}, "Preferences updated")


# ───────────────── USER STATS ─────────────────

@user_bp.route("/stats", methods=["GET"])
@jwt_required()
def get_user_stats():
    uid_str = get_jwt_identity()
    uid = to_object_id(uid_str)

    user = users_col().find_one({"_id": uid})
    if not user:
        return err("User not found", 404)

    # Quiz stats
    all_attempts = list(attempts_col().find({"user_id": uid}))
    total_quizzes = len(all_attempts)
    avg_score = round(
        sum(a.get("percentage", 0) for a in all_attempts) / total_quizzes, 2
    ) if total_quizzes else 0.0
    best_score = max((a.get("percentage", 0) for a in all_attempts), default=0)

    # Badge count
    badge_count = user_badges_col().count_documents({"user_id": uid_str})

    return ok({
        "stats": {
            "total_points": user.get("total_points", 0),
            "streak_count": user.get("streak_count", 0),
            "total_quizzes_attempted": total_quizzes,
            "average_score": avg_score,
            "best_score": best_score,
            "badges_earned": badge_count,
        }
    })
