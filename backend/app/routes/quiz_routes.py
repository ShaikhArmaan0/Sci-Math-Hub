from flask import Blueprint, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.database import users_col, quizzes_col, attempts_col, notifs_col, badges_col, user_badges_col
from app.utils import serialize, now, to_object_id, ok, err

quiz_bp = Blueprint("quiz", __name__, url_prefix="/api")

POINTS_PER_CORRECT = 10
MAX_ATTEMPTS_PER_QUIZ = 5


# ── GET QUIZ (strips correct answers) ────────────────────────────────────────

@quiz_bp.route("/quizzes/<quiz_id>", methods=["GET"])
@jwt_required()
def get_quiz(quiz_id):
    oid = to_object_id(quiz_id)
    if not oid:
        return err("Invalid quiz ID", 400)

    quiz = quizzes_col().find_one({"_id": oid})
    if not quiz:
        return err("Quiz not found", 404)

    uid = to_object_id(get_jwt_identity())
    attempt_count = attempts_col().count_documents({"user_id": uid, "quiz_id": oid})

    safe = serialize(quiz)
    for q in safe.get("questions", []):
        q.pop("correct_option", None)
        q.pop("explanation", None)

    safe["attempts_used"] = attempt_count
    safe["attempts_remaining"] = max(0, MAX_ATTEMPTS_PER_QUIZ - attempt_count)

    return ok({"quiz": safe})


# ── SUBMIT QUIZ ───────────────────────────────────────────────────────────────

@quiz_bp.route("/quizzes/<quiz_id>/submit", methods=["POST"])
@jwt_required()
def submit_quiz(quiz_id):
    uid = to_object_id(get_jwt_identity())
    quiz_oid = to_object_id(quiz_id)

    if not quiz_oid:
        return err("Invalid quiz ID", 400)

    quiz = quizzes_col().find_one({"_id": quiz_oid})
    if not quiz:
        return err("Quiz not found", 404)

    attempt_count = attempts_col().count_documents({"user_id": uid, "quiz_id": quiz_oid})
    if attempt_count >= MAX_ATTEMPTS_PER_QUIZ:
        return err("Maximum attempts reached for this quiz", 403)

    data = request.get_json() or {}
    answers = data.get("answers", {})

    score = 0
    results = []

    for q in quiz.get("questions", []):
        selected = answers.get(q["question_id"], "").upper()
        correct = q["correct_option"].upper()
        is_correct = selected == correct
        if is_correct:
            score += 1

        results.append({
            "question_id": q["question_id"],
            "selected": selected,
            "correct": correct,
            "is_correct": is_correct,
            "explanation": q.get("explanation", "")
        })

    total = len(quiz.get("questions", []))
    percentage = round((score / total) * 100, 2) if total else 0.0
    points = score * POINTS_PER_CORRECT

    attempts_col().insert_one({
        "user_id": uid,
        "quiz_id": quiz_oid,
        "score": score,
        "total_questions": total,
        "percentage": percentage,
        "points_earned": points,
        "attempted_at": now()
    })

    users_col().update_one({"_id": uid}, {"$inc": {"total_points": points}})

    # Auto badge evaluation
    new_badges = _evaluate_and_award_badges(uid)

    # Quiz result notification
    notifs_col().insert_one({
        "user_id": uid,
        "title": "Quiz Completed!",
        "message": f"You scored {score}/{total} and earned {points} points.",
        "type": "quiz_result",
        "is_read": False,
        "created_at": now()
    })

    return ok({
        "score": score,
        "total_questions": total,
        "percentage": percentage,
        "points_earned": points,
        "results": results,
        "new_badges": new_badges
    })


# ── MY ATTEMPTS ───────────────────────────────────────────────────────────────

@quiz_bp.route("/quizzes/<quiz_id>/attempts", methods=["GET"])
@jwt_required()
def get_my_attempts(quiz_id):
    uid = to_object_id(get_jwt_identity())
    quiz_oid = to_object_id(quiz_id)
    if not quiz_oid:
        return err("Invalid quiz ID", 400)

    attempts = list(attempts_col().find(
        {"user_id": uid, "quiz_id": quiz_oid},
        sort=[("attempted_at", -1)]
    ))
    return ok({"attempts": serialize(attempts)})


@quiz_bp.route("/attempts/my", methods=["GET"])
@jwt_required()
def get_all_my_attempts():
    uid = to_object_id(get_jwt_identity())
    attempts = list(attempts_col().find({"user_id": uid}).sort("attempted_at", -1))
    return ok({"attempts": serialize(attempts)})


# ── CREATE QUIZ (Admin) ───────────────────────────────────────────────────────

@quiz_bp.route("/quizzes", methods=["POST"])
@jwt_required()
def create_quiz():
    from app.database import users_col as uc
    uid = to_object_id(get_jwt_identity())
    user = uc().find_one({"_id": uid})
    if not user or user.get("role") != "admin":
        return err("Admin access required", 403)

    data = request.get_json() or {}
    for f in ["chapter_id", "title", "questions"]:
        if not data.get(f):
            return err(f"'{f}' is required")

    if not isinstance(data["questions"], list) or len(data["questions"]) == 0:
        return err("questions must be a non-empty list")

    for i, q in enumerate(data["questions"]):
        for field in ["question_id", "question_text", "option_a", "option_b", "option_c", "option_d", "correct_option"]:
            if not q.get(field):
                return err(f"Question {i+1} missing '{field}'")
        if q["correct_option"].upper() not in ["A", "B", "C", "D"]:
            return err(f"Question {i+1}: correct_option must be A, B, C, or D")

    doc = {
        "chapter_id":  data["chapter_id"],
        "title":       data["title"],
        "description": data.get("description", ""),
        "questions":   data["questions"],
        "created_at":  now(),
    }
    result = quizzes_col().insert_one(doc)
    doc["_id"] = result.inserted_id
    return ok({"quiz": serialize(doc)}, "Quiz created", 201)


# ── GET QUIZZES BY CHAPTER ────────────────────────────────────────────────────

@quiz_bp.route("/chapters/<chapter_id>/quizzes", methods=["GET"])
@jwt_required()
def get_quizzes_by_chapter(chapter_id):
    quizzes = list(quizzes_col().find({"chapter_id": chapter_id}))
    safe = []
    for quiz in quizzes:
        q = serialize(quiz)
        q["question_count"] = len(q.get("questions", []))
        q.pop("questions", None)  # Don't send full questions in list view
        safe.append(q)
    return ok({"quizzes": safe})


# ── INTERNAL: Badge Evaluation ────────────────────────────────────────────────

def _evaluate_and_award_badges(uid):
    """Evaluate and auto-award badges after quiz submission."""
    user = users_col().find_one({"_id": uid})
    if not user:
        return []

    uid_str = str(uid)
    attempt_count = attempts_col().count_documents({"user_id": uid})
    earned = {str(ub["badge_id"]) for ub in user_badges_col().find({"user_id": uid_str})}

    new_badges = []

    for badge in badges_col().find():
        badge_id_str = str(badge["_id"])
        if badge_id_str in earned:
            continue

        ct = badge.get("criteria_type")
        cv = badge.get("criteria_value", 0)
        awarded = False

        if ct == "quiz_count" and attempt_count >= cv:
            awarded = True
        elif ct == "points" and user.get("total_points", 0) >= cv:
            awarded = True
        elif ct == "streak" and user.get("streak_count", 0) >= cv:
            awarded = True

        if awarded:
            user_badges_col().insert_one({
                "user_id": uid_str,
                "badge_id": badge["_id"],
                "earned_at": now()
            })
            notifs_col().insert_one({
                "user_id": uid,
                "title": "🏅 Badge Earned!",
                "message": f"You earned the '{badge['badge_name']}' badge!",
                "type": "badge",
                "is_read": False,
                "created_at": now()
            })
            new_badges.append(serialize(badge))

    return new_badges
