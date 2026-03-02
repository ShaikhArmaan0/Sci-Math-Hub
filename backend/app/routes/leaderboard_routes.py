from flask import Blueprint, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.database import users_col, attempts_col, leaderboard_col, user_prefs_col
from app.utils import serialize, now, to_object_id, ok, err
from datetime import datetime, timezone

leaderboard_bp = Blueprint("leaderboard", __name__, url_prefix="/api/leaderboard")


def _build_board(students):
    """Build ranked board from a list of student user docs."""
    board = []
    for s in students:
        uid_str = str(s["_id"])
        student_attempts = list(attempts_col().find({"user_id": to_object_id(uid_str)}))
        avg = round(
            sum(a.get("percentage", 0) for a in student_attempts) / len(student_attempts), 2
        ) if student_attempts else 0.0

        # Check leaderboard visibility preference
        prefs = user_prefs_col().find_one({"user_id": uid_str})
        if prefs and not prefs.get("show_on_leaderboard", True):
            continue

        board.append({
            "user_id":            uid_str,
            "full_name":          s["full_name"],
            "profile_image":      s.get("profile_image", ""),
            "total_points":       s.get("total_points", 0),
            "streak_count":       s.get("streak_count", 0),
            "quizzes_attempted":  len(student_attempts),
            "average_score":      avg,
        })

    board.sort(key=lambda x: (-x["total_points"], -x["average_score"]))
    for i, entry in enumerate(board):
        entry["rank"] = i + 1
    return board


@leaderboard_bp.route("/live/<class_id>", methods=["GET"])
@jwt_required()
def get_live_leaderboard(class_id):
    """Real-time leaderboard for a specific class."""
    students = list(users_col().find({
        "class_id": class_id,
        "role": "student",
        "is_active": True
    }))
    board = _build_board(students)
    return ok({"leaderboard": board, "total": len(board)})


@leaderboard_bp.route("/live", methods=["GET"])
@jwt_required()
def get_global_leaderboard():
    """Global leaderboard across all classes (top 100)."""
    students = list(users_col().find({"role": "student", "is_active": True}))
    board = _build_board(students)
    return ok({"leaderboard": board[:100], "total": len(board)})


@leaderboard_bp.route("/my-rank/<class_id>", methods=["GET"])
@jwt_required()
def get_my_rank(class_id):
    """Get the current user's rank in their class."""
    uid_str = get_jwt_identity()
    students = list(users_col().find({
        "class_id": class_id,
        "role": "student",
        "is_active": True
    }))
    board = _build_board(students)
    my_entry = next((e for e in board if e["user_id"] == uid_str), None)
    return ok({"rank": my_entry, "total_students": len(board)})


@leaderboard_bp.route("/snapshot/<class_id>", methods=["POST"])
@jwt_required()
def generate_snapshot(class_id):
    """Admin: freeze current leaderboard as a monthly snapshot."""
    uid = to_object_id(get_jwt_identity())
    user = users_col().find_one({"_id": uid})
    if not user or user.get("role") != "admin":
        return err("Admin access required", 403)

    month = datetime.now(timezone.utc).strftime("%Y-%m")
    students = list(users_col().find({
        "class_id": class_id,
        "role": "student",
        "is_active": True
    }))
    board = _build_board(students)

    snapshot = {
        "class_id":     class_id,
        "month":        month,
        "rankings":     board,
        "generated_at": now()
    }
    result = leaderboard_col().insert_one(snapshot)
    return ok(
        {"snapshot_id": str(result.inserted_id), "month": month, "rankings": board},
        f"Snapshot generated for {month}",
        201
    )


@leaderboard_bp.route("/snapshots/<class_id>", methods=["GET"])
@jwt_required()
def get_snapshots(class_id):
    """Get historical leaderboard snapshots for a class."""
    snaps = list(leaderboard_col().find({"class_id": class_id}).sort("generated_at", -1))
    return ok({"snapshots": serialize(snaps)})
