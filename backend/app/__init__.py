import os
from flask import Flask, jsonify
from flask_jwt_extended import JWTManager
from flask_cors import CORS
from app.config import config
from app.database import mongo

jwt = JWTManager()


def create_app(config_name=None):
    if config_name is None:
        config_name = os.getenv("FLASK_ENV", "development")

    app = Flask(__name__)
    app.config.from_object(config.get(config_name, config["default"]))
    # app.config["MONGO_URI"] = app.config.get("MONGO_URI", "mongodb://localhost:27017/sci_math_hub")
    app.config["MONGO_URI"] = os.getenv("MONGO_URI")

    # Init extensions
    mongo.init_app(app)
    jwt.init_app(app)
    CORS(app, resources={r"/api/*": {"origins": "*"}})

    # Create MongoDB indexes on startup
    with app.app_context():
        _create_indexes()

    # Register blueprints
    from app.routes.auth_routes        import auth_bp
    from app.routes.user_routes        import user_bp
    from app.routes.academic_routes    import academic_bp
    from app.routes.quiz_routes        import quiz_bp
    from app.routes.leaderboard_routes import leaderboard_bp
    from app.routes.badge_routes       import badge_bp
    from app.routes.notification_routes import notification_bp
    from app.routes.study_routes       import study_bp
    from app.routes.doubts_routes      import doubts_bp

    for bp in [auth_bp, user_bp, academic_bp, quiz_bp,
               leaderboard_bp, badge_bp, notification_bp, study_bp, doubts_bp]:
        app.register_blueprint(bp)

    # Health check
    @app.route("/api/health")
    def health():
        return jsonify({"status": "ok", "message": "Sci-Math Hub API is running"}), 200

    # Error handlers
    @app.errorhandler(404)
    def not_found(e):
        return jsonify({"error": "Resource not found"}), 404

    @app.errorhandler(500)
    def server_error(e):
        return jsonify({"error": "Internal server error"}), 500

    @jwt.expired_token_loader
    def expired_token(jwt_header, jwt_data):
        return jsonify({"error": "Token has expired. Please login again."}), 401

    @jwt.invalid_token_loader
    def invalid_token(reason):
        return jsonify({"error": "Invalid token"}), 401

    @jwt.unauthorized_loader
    def missing_token(reason):
        return jsonify({"error": "Authorization token is missing"}), 401

    return app


def _create_indexes():
    """Create MongoDB indexes for performance and uniqueness."""
    from app.database import (
        users_col, chapters_col, topics_col, videos_col,
        attempts_col, progress_col, notifs_col, schedules_col,
        sessions_col, user_prefs_col
    )
    try:
        users_col().create_index("email", unique=True)
        users_col().create_index("phone", unique=True, sparse=True)
        users_col().create_index("class_id")
        chapters_col().create_index("subject_id")
        topics_col().create_index("chapter_id")
        videos_col().create_index("chapter_id")
        attempts_col().create_index([("user_id", 1), ("quiz_id", 1)])
        progress_col().create_index([("user_id", 1), ("chapter_id", 1)], unique=True)
        notifs_col().create_index([("user_id", 1), ("is_read", 1)])
        schedules_col().create_index("user_id")
        sessions_col().create_index([("schedule_id", 1), ("planned_date", 1)])
        user_prefs_col().create_index("user_id", unique=True)
    except Exception:
        pass