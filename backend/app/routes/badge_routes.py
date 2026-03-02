from flask import Blueprint, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.database import users_col, badges_col, user_badges_col
from app.utils import serialize, now, to_object_id, ok, err

badge_bp = Blueprint("badge", __name__, url_prefix="/api/badges")


@badge_bp.route("/", methods=["GET"])
def get_all_badges():
    """List all available badges (public)."""
    return ok({"badges": serialize(list(badges_col().find()))})


@badge_bp.route("/", methods=["POST"])
@jwt_required()
def create_badge():
    """Admin: create a new badge definition."""
    uid = to_object_id(get_jwt_identity())
    user = users_col().find_one({"_id": uid})
    if not user or user.get("role") != "admin":
        return err("Admin access required", 403)

    data = request.get_json() or {}
    if not data.get("badge_name"):
        return err("badge_name is required")
    if data.get("criteria_type") not in ["quiz_count", "streak", "points"]:
        return err("criteria_type must be quiz_count, streak, or points")
    if not isinstance(data.get("criteria_value"), (int, float)):
        return err("criteria_value must be a number")

    doc = {
        "badge_name":     data["badge_name"],
        "description":    data.get("description", ""),
        "icon_url":       data.get("icon_url", ""),
        "criteria_type":  data["criteria_type"],
        "criteria_value": int(data["criteria_value"]),
        "created_at":     now(),
    }
    result = badges_col().insert_one(doc)
    doc["_id"] = result.inserted_id
    return ok({"badge": serialize(doc)}, "Badge created", 201)


@badge_bp.route("/my", methods=["GET"])
@jwt_required()
def get_my_badges():
    """Get all badges earned by the logged-in user."""
    uid_str = get_jwt_identity()
    user_badges = list(user_badges_col().find({"user_id": uid_str}))
    result = []
    for ub in user_badges:
        badge_oid = to_object_id(str(ub["badge_id"]))
        badge = badges_col().find_one({"_id": badge_oid}) if badge_oid else None
        entry = serialize(ub)
        entry["badge"] = serialize(badge) if badge else None
        result.append(entry)
    return ok({"badges": result, "total": len(result)})


@badge_bp.route("/<badge_id>", methods=["DELETE"])
@jwt_required()
def delete_badge(badge_id):
    """Admin: delete a badge definition."""
    uid = to_object_id(get_jwt_identity())
    user = users_col().find_one({"_id": uid})
    if not user or user.get("role") != "admin":
        return err("Admin access required", 403)
    oid = to_object_id(badge_id)
    if not oid:
        return err("Invalid ID", 400)
    badges_col().delete_one({"_id": oid})
    user_badges_col().delete_many({"badge_id": oid})
    return ok(message="Badge deleted")
