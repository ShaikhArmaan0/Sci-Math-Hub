from flask import Blueprint, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.database import notifs_col
from app.utils import serialize, now, to_object_id, ok, err

notification_bp = Blueprint("notification", __name__, url_prefix="/api/notifications")


@notification_bp.route("/", methods=["GET"])
@jwt_required()
def get_notifications():
    uid = get_jwt_identity()
    page = int(request.args.get("page", 1))
    per_page = int(request.args.get("per_page", 20))
    skip = (page - 1) * per_page

    notifs = list(
        notifs_col()
        .find({"user_id": uid})
        .sort("created_at", -1)
        .skip(skip)
        .limit(per_page)
    )
    total = notifs_col().count_documents({"user_id": uid})
    return ok({
        "notifications": serialize(notifs),
        "total": total,
        "page": page,
        "per_page": per_page
    })


@notification_bp.route("/unread-count", methods=["GET"])
@jwt_required()
def unread_count():
    uid = get_jwt_identity()
    count = notifs_col().count_documents({"user_id": uid, "is_read": False})
    return ok({"unread_count": count})


@notification_bp.route("/<notif_id>/read", methods=["PUT"])
@jwt_required()
def mark_read(notif_id):
    uid = get_jwt_identity()
    oid = to_object_id(notif_id)
    if not oid:
        return err("Invalid notification ID", 400)
    result = notifs_col().update_one({"_id": oid, "user_id": uid}, {"$set": {"is_read": True}})
    if result.matched_count == 0:
        return err("Notification not found", 404)
    return ok(message="Marked as read")


@notification_bp.route("/read-all", methods=["PUT"])
@jwt_required()
def mark_all_read():
    uid = get_jwt_identity()
    notifs_col().update_many({"user_id": uid, "is_read": False}, {"$set": {"is_read": True}})
    return ok(message="All notifications marked as read")


@notification_bp.route("/<notif_id>", methods=["DELETE"])
@jwt_required()
def delete_notification(notif_id):
    uid = get_jwt_identity()
    oid = to_object_id(notif_id)
    if not oid:
        return err("Invalid notification ID", 400)
    result = notifs_col().delete_one({"_id": oid, "user_id": uid})
    if result.deleted_count == 0:
        return err("Notification not found", 404)
    return ok(message="Notification deleted")
