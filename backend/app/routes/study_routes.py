from flask import Blueprint, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.database import schedules_col, sessions_col
from app.utils import serialize, now, to_object_id, ok, err
from datetime import date

study_bp = Blueprint("study", __name__, url_prefix="/api/study")


@study_bp.route("/schedules", methods=["GET"])
@jwt_required()
def get_schedules():
    uid = get_jwt_identity()
    schedules = list(schedules_col().find({"user_id": uid}).sort("created_at", -1))
    result = []
    for s in schedules:
        sd = serialize(s)
        schedule_id = str(s["_id"])
        existing = list(sessions_col().find({"schedule_id": schedule_id}))

        # Backfill sessions for old schedules that have none but have time info
        if not existing and sd.get("start_date") and sd.get("end_date"):
            from datetime import datetime, timedelta
            day_map = {"Mon": 0, "Tue": 1, "Wed": 2, "Thu": 3, "Fri": 4, "Sat": 5, "Sun": 6}
            repeat_days = sd.get("repeat_days", ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"])
            repeat_day_nums = [day_map[d] for d in repeat_days if d in day_map]
            if not repeat_day_nums:
                repeat_day_nums = list(range(7))
            start_time = sd.get("start_time", "09:00")
            duration = sd.get("duration_minutes", 60)
            try:
                start_dt = datetime.strptime(sd["start_date"], "%Y-%m-%d")
                end_dt   = datetime.strptime(sd["end_date"],   "%Y-%m-%d")
                current  = start_dt
                while current <= end_dt:
                    if current.weekday() in repeat_day_nums:
                        session_doc = {
                            "schedule_id": schedule_id,
                            "user_id": uid,
                            "planned_date": current.strftime("%Y-%m-%d"),
                            "scheduled_time": start_time if start_time else None,
                            "duration_minutes": duration,
                            "completed": False,
                            "reminder_sent": False,
                        }
                        sessions_col().insert_one(session_doc)
                        existing.append(session_doc)
                    current += timedelta(days=1)
            except Exception:
                pass

        sd["sessions"] = serialize(existing)
        result.append(sd)
    return ok({"schedules": result})


@study_bp.route("/schedules", methods=["POST"])
@jwt_required()
def create_schedule():
    uid = get_jwt_identity()
    data = request.get_json() or {}
    for f in ["title", "start_date", "end_date"]:
        if not data.get(f):
            return err(f"'{f}' is required")

    from datetime import datetime, timedelta

    # Parse repeat days
    day_map = {"Mon": 0, "Tue": 1, "Wed": 2, "Thu": 3, "Fri": 4, "Sat": 5, "Sun": 6}
    repeat_days = data.get("repeat_days", ["Mon","Tue","Wed","Thu","Fri"])
    repeat_day_nums = [day_map[d] for d in repeat_days if d in day_map]
    if not repeat_day_nums:
        repeat_day_nums = [0, 1, 2, 3, 4]  # Mon-Fri default

    start_time = data.get("start_time", "09:00")
    duration = data.get("duration_minutes", 60)
    subject = data.get("subject", "")

    schedule_doc = {
        "user_id":          uid,
        "title":            data["title"],
        "subject":          subject,
        "start_date":       data["start_date"],
        "end_date":         data["end_date"],
        "start_time":       start_time,
        "end_time":         data.get("end_time", ""),
        "duration_minutes": duration,
        "repeat_days":      repeat_days,
        "created_at":       now(),
    }
    result = schedules_col().insert_one(schedule_doc)
    schedule_id = str(result.inserted_id)

    # Auto-generate sessions for each matching day in the date range
    sessions = []
    try:
        start_dt = datetime.strptime(data["start_date"], "%Y-%m-%d")
        end_dt   = datetime.strptime(data["end_date"],   "%Y-%m-%d")
        current  = start_dt
        while current <= end_dt:
            if current.weekday() in repeat_day_nums:
                session_doc = {
                    "schedule_id":     schedule_id,
                    "user_id":         uid,
                    "planned_date":    current.strftime("%Y-%m-%d"),
                    "scheduled_time":  start_time,
                    "duration_minutes": duration,
                    "completed":       False,
                    "reminder_sent":   False,
                }
                sessions_col().insert_one(session_doc)
                sessions.append(serialize(session_doc))
            current += timedelta(days=1)
    except Exception as e:
        pass  # If date parsing fails, create schedule without sessions

    schedule_doc["_id"] = result.inserted_id
    resp = serialize(schedule_doc)
    resp["sessions"] = sessions
    return ok({"schedule": resp}, "Schedule created", 201)


@study_bp.route("/schedules/<schedule_id>", methods=["GET"])
@jwt_required()
def get_schedule(schedule_id):
    uid = get_jwt_identity()
    oid = to_object_id(schedule_id)
    if not oid:
        return err("Invalid ID", 400)
    schedule = schedules_col().find_one({"_id": oid, "user_id": uid})
    if not schedule:
        return err("Schedule not found", 404)
    sd = serialize(schedule)
    sd["sessions"] = serialize(list(sessions_col().find({"schedule_id": schedule_id})))
    return ok({"schedule": sd})


@study_bp.route("/schedules/<schedule_id>", methods=["DELETE"])
@jwt_required()
def delete_schedule(schedule_id):
    uid = get_jwt_identity()
    oid = to_object_id(schedule_id)
    if not oid:
        return err("Invalid ID", 400)
    result = schedules_col().delete_one({"_id": oid, "user_id": uid})
    if result.deleted_count == 0:
        return err("Schedule not found or unauthorized", 404)
    sessions_col().delete_many({"schedule_id": schedule_id})
    return ok(message="Schedule deleted")


@study_bp.route("/sessions/<session_id>/complete", methods=["PUT"])
@jwt_required()
def mark_session_complete(session_id):
    uid = get_jwt_identity()
    oid = to_object_id(session_id)
    if not oid:
        return err("Invalid ID", 400)

    session = sessions_col().find_one({"_id": oid})
    if not session:
        return err("Session not found", 404)

    schedule = schedules_col().find_one({
        "_id": to_object_id(session["schedule_id"]),
        "user_id": uid
    })
    if not schedule:
        return err("Unauthorized", 403)

    sessions_col().update_one(
        {"_id": oid},
        {"$set": {"completed": True, "completed_at": now()}}
    )
    return ok(message="Session marked complete")


@study_bp.route("/today", methods=["GET"])
@jwt_required()
def get_today_sessions():
    uid = get_jwt_identity()
    today = date.today().isoformat()
    schedule_ids = [str(s["_id"]) for s in schedules_col().find({"user_id": uid})]
    sessions = list(sessions_col().find({
        "schedule_id": {"$in": schedule_ids},
        "planned_date": today,
    }))
    return ok({"today": today, "sessions": serialize(sessions), "count": len(sessions)})