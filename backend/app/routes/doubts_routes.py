import base64, os
from flask import Blueprint, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.database import doubts_col, doubt_answers_col, users_col, activity_col
from app.utils import serialize, now, to_object_id, ok, err

doubts_bp = Blueprint("doubts", __name__, url_prefix="/api/doubts")


def _username(uid_str):
    u = users_col().find_one({"_id": to_object_id(uid_str)})
    return u["full_name"] if u else "Unknown"


# ── GET all doubts (paginated) ────────────────────────────────────────────────
@doubts_bp.route("", methods=["GET"])
def get_doubts():
    page  = int(request.args.get("page", 1))
    limit = int(request.args.get("limit", 20))
    skip  = (page - 1) * limit
    subject = request.args.get("subject")
    query = {}
    if subject:
        query["subject"] = subject
    total  = doubts_col().count_documents(query)
    doubts = list(doubts_col().find(query).sort("created_at", -1).skip(skip).limit(limit))
    for d in doubts:
        d["answer_count"] = doubt_answers_col().count_documents({"doubt_id": str(d["_id"])})
    return ok({"doubts": serialize(doubts), "total": total, "page": page})


# ── POST a new doubt ──────────────────────────────────────────────────────────
@doubts_bp.route("", methods=["POST"])
@jwt_required()
def post_doubt():
    uid  = get_jwt_identity()
    data = request.get_json() or {}
    text = data.get("text", "").strip()
    if not text and not data.get("image_base64"):
        return err("Doubt text or image is required")
    doc = {
        "user_id":      uid,
        "user_name":    _username(uid),
        "text":         text,
        "subject":      data.get("subject", "General"),
        "image_base64": data.get("image_base64", ""),
        "upvotes":      0,
        "is_resolved":  False,
        "created_at":   now(),
    }
    result = doubts_col().insert_one(doc)
    doc["_id"] = result.inserted_id
    # Log activity
    activity_col().insert_one({"user_id": uid, "type": "doubt_posted",
        "ref_id": str(result.inserted_id), "title": text[:60] or "Photo doubt",
        "created_at": now()})
    return ok({"doubt": serialize(doc)}, "Doubt posted", 201)


# ── GET single doubt with answers ─────────────────────────────────────────────
@doubts_bp.route("/<doubt_id>", methods=["GET"])
def get_doubt(doubt_id):
    oid = to_object_id(doubt_id)
    if not oid: return err("Invalid ID", 400)
    doubt = doubts_col().find_one({"_id": oid})
    if not doubt: return err("Doubt not found", 404)
    answers = list(doubt_answers_col().find({"doubt_id": doubt_id}).sort("upvotes", -1))
    data = serialize(doubt)
    data["answers"] = serialize(answers)
    return ok({"doubt": data})


# ── DELETE a doubt ────────────────────────────────────────────────────────────
@doubts_bp.route("/<doubt_id>", methods=["DELETE"])
@jwt_required()
def delete_doubt(doubt_id):
    uid = get_jwt_identity()
    oid = to_object_id(doubt_id)
    doubt = doubts_col().find_one({"_id": oid})
    if not doubt: return err("Not found", 404)
    if doubt["user_id"] != uid: return err("Forbidden", 403)
    doubts_col().delete_one({"_id": oid})
    doubt_answers_col().delete_many({"doubt_id": doubt_id})
    return ok(message="Deleted")


# ── POST an answer ────────────────────────────────────────────────────────────
@doubts_bp.route("/<doubt_id>/answers", methods=["POST"])
@jwt_required()
def post_answer(doubt_id):
    uid  = get_jwt_identity()
    data = request.get_json() or {}
    text = data.get("text", "").strip()
    if not text: return err("Answer text is required")
    oid = to_object_id(doubt_id)
    if not doubts_col().find_one({"_id": oid}):
        return err("Doubt not found", 404)
    doc = {
        "doubt_id":     doubt_id,
        "user_id":      uid,
        "user_name":    _username(uid),
        "text":         text,
        "upvotes":      0,
        "upvoted_by":   [],
        "created_at":   now(),
    }
    result = doubt_answers_col().insert_one(doc)
    doc["_id"] = result.inserted_id
    # Mark doubt answered
    doubts_col().update_one({"_id": oid}, {"$set": {"is_resolved": True}})
    activity_col().insert_one({"user_id": uid, "type": "doubt_answered",
        "ref_id": doubt_id, "title": text[:60], "created_at": now()})
    return ok({"answer": serialize(doc)}, "Answer posted", 201)


# ── Upvote an answer ──────────────────────────────────────────────────────────
@doubts_bp.route("/answers/<answer_id>/upvote", methods=["POST"])
@jwt_required()
def upvote_answer(answer_id):
    uid = get_jwt_identity()
    oid = to_object_id(answer_id)
    ans = doubt_answers_col().find_one({"_id": oid})
    if not ans: return err("Answer not found", 404)
    upvoted_by = ans.get("upvoted_by", [])
    if uid in upvoted_by:
        # Un-upvote
        doubt_answers_col().update_one({"_id": oid}, {
            "$inc": {"upvotes": -1}, "$pull": {"upvoted_by": uid}})
        return ok(message="Upvote removed")
    doubt_answers_col().update_one({"_id": oid}, {
        "$inc": {"upvotes": 1}, "$push": {"upvoted_by": uid}})
    return ok(message="Upvoted")


# ── Get user activity ─────────────────────────────────────────────────────────
@doubts_bp.route("/activity/me", methods=["GET"])
@jwt_required()
def get_my_activity():
    uid = get_jwt_identity()
    activities = list(activity_col().find({"user_id": uid}).sort("created_at", -1).limit(20))
    return ok({"activities": serialize(activities)})


# ── Mark doubt as resolved ────────────────────────────────────────────────────
@doubts_bp.route("/<doubt_id>/resolve", methods=["PUT"])
@jwt_required()
def resolve_doubt(doubt_id):
    uid = get_jwt_identity()
    oid = to_object_id(doubt_id)
    doubt = doubts_col().find_one({"_id": oid})
    if not doubt:
        return err("Doubt not found", 404)
    if doubt.get("user_id") != uid:
        return err("Only the doubt author can mark it as resolved", 403)
    doubts_col().update_one({"_id": oid}, {"$set": {"is_resolved": True}})
    return ok(message="Marked as resolved")