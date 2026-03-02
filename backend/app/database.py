"""
Central MongoDB connection using PyMongo (flask-pymongo).
All routes import collection helpers from here.
"""
from flask_pymongo import PyMongo

mongo = PyMongo()


def get_db():
    return mongo.db


# ── Collection helpers ────────────────────────────────────────────────────────
def users_col():          return mongo.db.users
def user_prefs_col():     return mongo.db.user_preferences
def classes_col():        return mongo.db.classes
def subjects_col():       return mongo.db.subjects
def chapters_col():       return mongo.db.chapters
def topics_col():         return mongo.db.topics
def videos_col():         return mongo.db.videos
def quizzes_col():        return mongo.db.quizzes
def attempts_col():       return mongo.db.quiz_attempts
def progress_col():       return mongo.db.progress
def badges_col():         return mongo.db.badges
def user_badges_col():    return mongo.db.user_badges
def notifs_col():         return mongo.db.notifications
def schedules_col():      return mongo.db.study_schedules
def sessions_col():       return mongo.db.study_sessions
def leaderboard_col():    return mongo.db.leaderboard_snapshots
def doubts_col():         return mongo.db.doubts
def doubt_answers_col():  return mongo.db.doubt_answers
def activity_col():       return mongo.db.user_activity