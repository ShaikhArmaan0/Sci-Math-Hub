from flask import Blueprint, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.database import (
    users_col, classes_col, subjects_col, chapters_col,
    topics_col, videos_col, progress_col
)
from app.utils import serialize, now, to_object_id, ok, err

academic_bp = Blueprint("academic", __name__, url_prefix="/api")


def is_admin():
    uid = to_object_id(get_jwt_identity())
    user = users_col().find_one({"_id": uid})
    return user and user.get("role") == "admin"


# ── CLASSES ──────────────────────────────────────────────────────────────────

@academic_bp.route("/classes", methods=["GET"])
def get_classes():
    classes = list(classes_col().find())
    return ok({"classes": serialize(classes)})


@academic_bp.route("/classes", methods=["POST"])
@jwt_required()
def create_class():
    if not is_admin():
        return err("Admin access required", 403)
    data = request.get_json() or {}
    if not data.get("class_name") or not data.get("board"):
        return err("class_name and board are required")
    doc = {"class_name": data["class_name"], "board": data["board"], "created_at": now()}
    result = classes_col().insert_one(doc)
    doc["_id"] = result.inserted_id
    return ok({"class": serialize(doc)}, "Class created", 201)


@academic_bp.route("/classes/<class_id>", methods=["DELETE"])
@jwt_required()
def delete_class(class_id):
    if not is_admin():
        return err("Admin access required", 403)
    oid = to_object_id(class_id)
    if not oid:
        return err("Invalid ID", 400)
    classes_col().delete_one({"_id": oid})
    return ok(message="Class deleted")


# ── SUBJECTS ─────────────────────────────────────────────────────────────────

@academic_bp.route("/classes/<class_id>/subjects", methods=["GET"])
def get_subjects(class_id):
    subjects = list(subjects_col().find({"class_id": class_id}))
    return ok({"subjects": serialize(subjects)})


@academic_bp.route("/subjects", methods=["POST"])
@jwt_required()
def create_subject():
    if not is_admin():
        return err("Admin access required", 403)
    data = request.get_json() or {}
    if not data.get("class_id") or not data.get("subject_name"):
        return err("class_id and subject_name are required")
    doc = {
        "class_id": data["class_id"],
        "subject_name": data["subject_name"],
        "icon": data.get("icon", ""),
        "created_at": now()
    }
    result = subjects_col().insert_one(doc)
    doc["_id"] = result.inserted_id
    return ok({"subject": serialize(doc)}, "Subject created", 201)


# ── CHAPTERS ─────────────────────────────────────────────────────────────────

@academic_bp.route("/subjects/<subject_id>/chapters", methods=["GET"])
def get_chapters(subject_id):
    chapters = list(chapters_col().find({"subject_id": subject_id}).sort("order_index", 1))
    return ok({"chapters": serialize(chapters)})


@academic_bp.route("/chapters/<chapter_id>", methods=["GET"])
def get_chapter(chapter_id):
    oid = to_object_id(chapter_id)
    if not oid:
        return err("Invalid ID", 400)
    chapter = chapters_col().find_one({"_id": oid})
    if not chapter:
        return err("Chapter not found", 404)

    data = serialize(chapter)
    data["topics"] = serialize(list(topics_col().find({"chapter_id": chapter_id}).sort("order_index", 1)))
    data["videos"] = serialize(list(videos_col().find({"chapter_id": chapter_id})))

    # Track progress only if user is logged in
    try:
        from flask_jwt_extended import verify_jwt_in_request, get_jwt_identity as _get_uid
        verify_jwt_in_request(optional=True)
        uid = _get_uid()
        if uid:
            progress_col().update_one(
                {"user_id": uid, "chapter_id": chapter_id},
                {
                    "$set": {"last_accessed": now()},
                    "$setOnInsert": {"completion_percentage": 0.0, "user_id": uid, "chapter_id": chapter_id}
                },
                upsert=True
            )
    except Exception:
        pass

    return ok({"chapter": data})


@academic_bp.route("/chapters", methods=["POST"])
@jwt_required()
def create_chapter():
    if not is_admin():
        return err("Admin access required", 403)
    data = request.get_json() or {}
    for f in ["subject_id", "chapter_number", "chapter_name"]:
        if not data.get(f):
            return err(f"'{f}' is required")
    doc = {
        "subject_id":     data["subject_id"],
        "chapter_number": data["chapter_number"],
        "chapter_name":   data["chapter_name"],
        "description":    data.get("description", ""),
        "pdf_url":        data.get("pdf_url", ""),
        "order_index":    data.get("order_index", 0),
        "created_at":     now(),
    }
    result = chapters_col().insert_one(doc)
    doc["_id"] = result.inserted_id
    return ok({"chapter": serialize(doc)}, "Chapter created", 201)


@academic_bp.route("/chapters/<chapter_id>", methods=["PUT"])
@jwt_required()
def update_chapter(chapter_id):
    if not is_admin():
        return err("Admin access required", 403)
    oid = to_object_id(chapter_id)
    if not oid:
        return err("Invalid ID", 400)
    data = request.get_json() or {}
    updates = {k: data[k] for k in ["chapter_name", "description", "pdf_url", "order_index"] if k in data}
    if "pdf_urls" in data:
            updates["pdf_urls"] = data["pdf_urls"]
    chapters_col().update_one({"_id": oid}, {"$set": updates})
    return ok({"chapter": serialize(chapters_col().find_one({"_id": oid}))}, "Chapter updated")


@academic_bp.route("/chapters/<chapter_id>", methods=["DELETE"])
@jwt_required()
def delete_chapter(chapter_id):
    if not is_admin():
        return err("Admin access required", 403)
    oid = to_object_id(chapter_id)
    if not oid:
        return err("Invalid ID", 400)
    chapters_col().delete_one({"_id": oid})
    topics_col().delete_many({"chapter_id": chapter_id})
    videos_col().delete_many({"chapter_id": chapter_id})
    return ok(message="Chapter and its topics/videos deleted")


# ── TOPICS ───────────────────────────────────────────────────────────────────

@academic_bp.route("/chapters/<chapter_id>/topics", methods=["GET"])
def get_topics(chapter_id):
    topics = list(topics_col().find({"chapter_id": chapter_id}).sort("order_index", 1))
    return ok({"topics": serialize(topics)})


@academic_bp.route("/topics", methods=["POST"])
@jwt_required()
def create_topic():
    if not is_admin():
        return err("Admin access required", 403)
    data = request.get_json() or {}
    for f in ["chapter_id", "topic_name"]:
        if not data.get(f):
            return err(f"'{f}' is required")
    doc = {
        "chapter_id":  data["chapter_id"],
        "topic_name":  data["topic_name"],
        "content":     data.get("content", ""),
        "order_index": data.get("order_index", 0),
    }
    result = topics_col().insert_one(doc)
    doc["_id"] = result.inserted_id
    return ok({"topic": serialize(doc)}, "Topic created", 201)


@academic_bp.route("/topics/<topic_id>", methods=["PUT"])
@jwt_required()
def update_topic(topic_id):
    if not is_admin():
        return err("Admin access required", 403)
    oid = to_object_id(topic_id)
    if not oid:
        return err("Invalid ID", 400)
    data = request.get_json() or {}
    updates = {k: data[k] for k in ["topic_name", "content", "order_index"] if k in data}
    topics_col().update_one({"_id": oid}, {"$set": updates})
    return ok({"topic": serialize(topics_col().find_one({"_id": oid}))}, "Topic updated")


# ── VIDEOS ───────────────────────────────────────────────────────────────────

@academic_bp.route("/chapters/<chapter_id>/videos", methods=["GET"])
def get_videos(chapter_id):
    videos = list(videos_col().find({"chapter_id": chapter_id}))
    return ok({"videos": serialize(videos)})


@academic_bp.route("/videos", methods=["POST"])
@jwt_required()
def create_video():
    if not is_admin():
        return err("Admin access required", 403)
    data = request.get_json() or {}
    for f in ["chapter_id", "youtube_video_id", "title"]:
        if not data.get(f):
            return err(f"'{f}' is required")
    vid = data["youtube_video_id"]
    doc = {
        "chapter_id":       data["chapter_id"],
        "topic_id":         data.get("topic_id"),
        "youtube_video_id": vid,
        "youtube_url":      f"https://www.youtube.com/watch?v={vid}",
        "embed_url":        f"https://www.youtube.com/embed/{vid}",
        "title":            data["title"],
        "duration":         data.get("duration", ""),
        "created_at":       now(),
    }
    result = videos_col().insert_one(doc)
    doc["_id"] = result.inserted_id
    return ok({"video": serialize(doc)}, "Video added", 201)


@academic_bp.route("/videos/<video_id>", methods=["DELETE"])
@jwt_required()
def delete_video(video_id):
    if not is_admin():
        return err("Admin access required", 403)
    oid = to_object_id(video_id)
    if not oid:
        return err("Invalid ID", 400)
    videos_col().delete_one({"_id": oid})
    return ok(message="Video deleted")


# ── PROGRESS ─────────────────────────────────────────────────────────────────

@academic_bp.route("/progress", methods=["GET"])
@jwt_required()
def get_my_progress():
    uid = get_jwt_identity()
    progs = list(progress_col().find({"user_id": uid}))
    return ok({"progress": serialize(progs)})


@academic_bp.route("/progress/<chapter_id>", methods=["PUT"])
@jwt_required()
def update_progress(chapter_id):
    uid = get_jwt_identity()
    data = request.get_json() or {}
    pct = min(100.0, float(data.get("completion_percentage", 0)))
    progress_col().update_one(
        {"user_id": uid, "chapter_id": chapter_id},
        {
            "$set": {"completion_percentage": pct, "last_accessed": now()},
            "$setOnInsert": {"user_id": uid, "chapter_id": chapter_id}
        },
        upsert=True
    )
    prog = progress_col().find_one({"user_id": uid, "chapter_id": chapter_id})
    return ok({"progress": serialize(prog)}, "Progress updated")


# ── SEARCH ───────────────────────────────────────────────────────────────────

@academic_bp.route("/search", methods=["GET"])
def search():
    q = request.args.get("q", "").strip()
    if not q or len(q) < 2:
        return err("Query must be at least 2 characters")
    regex = {"$regex": q, "$options": "i"}
    chapters = serialize(list(chapters_col().find({"chapter_name": regex}).limit(10)))
    topics   = serialize(list(topics_col().find({"topic_name": regex}).limit(10)))
    videos   = serialize(list(videos_col().find({"title": regex}).limit(10)))
    return ok({"query": q, "results": {"chapters": chapters, "topics": topics, "videos": videos}})