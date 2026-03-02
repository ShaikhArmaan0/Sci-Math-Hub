"""
Shared utility helpers used across all routes.
"""
from bson import ObjectId
from datetime import datetime, timezone
from flask import jsonify


def serialize(doc):
    """Deep-serialize a MongoDB document (handles ObjectId & datetime)."""
    if doc is None:
        return None
    if isinstance(doc, list):
        return [serialize(d) for d in doc]
    if isinstance(doc, dict):
        return {k: serialize(v) for k, v in doc.items()}
    if isinstance(doc, ObjectId):
        return str(doc)
    if isinstance(doc, datetime):
        return doc.isoformat()
    return doc


def now():
    return datetime.now(timezone.utc)


def to_object_id(id_str):
    """Safely convert string to ObjectId; return None if invalid."""
    try:
        return ObjectId(id_str)
    except Exception:
        return None


def ok(data=None, message=None, status=200):
    payload = {}
    if message:
        payload["message"] = message
    if data:
        payload.update(data)
    return jsonify(payload), status


def err(message, status=400):
    return jsonify({"error": message}), status
