# Sci-Math Hub — Complete Project Documentation

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Technology Stack](#2-technology-stack)
3. [Project Structure](#3-project-structure)
4. [Setup & Installation](#4-setup--installation)
5. [Architecture](#5-architecture)
6. [Database Collections](#6-database-collections)
7. [API Reference](#7-api-reference)
8. [Authentication System](#8-authentication-system)
9. [Gamification Engine](#9-gamification-engine)
10. [Data Flow Diagrams](#10-data-flow-diagrams)
11. [Flutter Integration Guide](#11-flutter-integration-guide)
12. [Testing Guide](#12-testing-guide)
13. [Deployment](#13-deployment)
14. [Environment Variables](#14-environment-variables)

---

## 1. Project Overview

**Sci-Math Hub** is a gamified e-learning platform for students of Classes 8, 9, and 10 (Maharashtra Board), focused on Science and Mathematics.

### Core Goals

- Structured academic learning via chapters, topics, and notes
- YouTube-embedded video resources organized by topic
- Interactive quizzes with instant feedback
- Gamification: points, badges, and daily streaks
- Progress tracking per chapter
- Leaderboard competition by class
- Study scheduling with session management
- Soft authentication: users can browse content before logging in

### User Roles

| Role | Description |
|------|-------------|
| Guest | Browse classes, subjects, chapters, videos, notes. Cannot attempt quizzes or track progress. |
| Student | Full access: quizzes, progress, leaderboard, schedule, badges. |
| Admin | All student access + content management (create/edit/delete classes, subjects, chapters, quizzes, badges). |

---

## 2. Technology Stack

### Frontend (Flutter)

| Package | Purpose |
|---------|---------|
| `flutter` (Dart) | Cross-platform mobile UI framework |
| `provider` | State management |
| `http` | REST API communication |
| `flutter_secure_storage` | Secure JWT token storage |
| `shared_preferences` | Local settings (theme, language) |

### Backend (Python / Flask)

| Package | Purpose |
|---------|---------|
| `Flask 3.0.3` | Web framework (App Factory pattern) |
| `Flask-JWT-Extended 4.6.0` | JWT authentication and token management |
| `Flask-PyMongo 2.3.0` | MongoDB ORM wrapper |
| `Flask-CORS 4.0.1` | Cross-Origin Resource Sharing for Flutter |
| `Werkzeug 3.0.3` | Password hashing (PBKDF2) |
| `python-dotenv 1.0.1` | Environment variable management |
| `gunicorn 22.0.0` | Production WSGI server |

### Database

| Technology | Purpose |
|-----------|---------|
| MongoDB | Document-based NoSQL database |
| PyMongo indexes | Performance optimization and uniqueness constraints |

---

## 3. Project Structure

```
backend/
├── .env                        # Environment variables (do not commit to git)
├── requirements.txt            # Python dependencies
├── run.py                      # App entry point
│
└── app/
    ├── __init__.py             # App factory — creates Flask app, registers blueprints, indexes
    ├── config.py               # Config classes (Development, Production)
    ├── database.py             # MongoDB connection + collection helpers
    ├── utils.py                # Shared helpers: serialize, ok(), err(), now()
    │
    ├── routes/
    │   ├── __init__.py
    │   ├── auth_routes.py      # /api/auth/* — register, login, logout, me
    │   ├── user_routes.py      # /api/user/* — profile, password, preferences, stats
    │   ├── academic_routes.py  # /api/classes, subjects, chapters, topics, videos, progress, search
    │   ├── quiz_routes.py      # /api/quizzes/* — fetch, submit, attempts, create
    │   ├── badge_routes.py     # /api/badges/* — list, create, my badges
    │   ├── leaderboard_routes.py # /api/leaderboard/* — live, global, snapshots
    │   ├── notification_routes.py # /api/notifications/* — list, mark read, delete
    │   └── study_routes.py     # /api/study/* — schedules, sessions, today
    │
    ├── middleware/
    │   └── __init__.py         # (Reserved for future middleware like rate limiting)
    │
    ├── services/
    │   └── __init__.py         # (Reserved for business logic services)
    │
    └── scripts/
        └── seed.py             # Database seed script with sample data
```

---

## 4. Setup & Installation

### Prerequisites

- Python 3.10+
- MongoDB 6.0+ (running locally or MongoDB Atlas URI)
- pip

### Step 1 — Clone and navigate

```bash
cd backend/
```

### Step 2 — Create virtual environment

```bash
python -m venv venv
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate
```

### Step 3 — Install dependencies

```bash
pip install -r requirements.txt
```

### Step 4 — Configure environment

Edit `.env` with your values:

```env
FLASK_ENV=development
SECRET_KEY=your-strong-secret-key
JWT_SECRET_KEY=your-strong-jwt-key
MONGO_URI=mongodb://localhost:27017/sci_math_hub
JWT_ACCESS_TOKEN_EXPIRES=86400
```

### Step 5 — Seed the database (optional but recommended)

```bash
python -m app.scripts.seed
```

This creates:
- 3 classes (8, 9, 10)
- 2 subjects for Class 10 (Science, Mathematics)
- 3 science chapters with topics and videos
- 1 sample quiz with 5 questions
- 9 badges across quiz count, points, and streak criteria
- Admin user: `admin@scimathub.com` / `admin123`

### Step 6 — Run the server

```bash
python run.py
```

Server starts on: `http://0.0.0.0:5000`

Health check: `GET http://localhost:5000/api/health`

---

## 5. Architecture

```
Flutter App (Mobile)
       │
       │  HTTP REST API (JSON)
       ▼
Flask Backend (Python)
       │
       │  PyMongo Driver
       ▼
MongoDB Database
```

### App Factory Pattern

The Flask app uses the **App Factory** pattern in `app/__init__.py`. This allows:
- Multiple app instances (testing, development, production)
- Clean blueprint registration
- Environment-specific configuration

### Blueprint Registration

Each feature domain has its own Blueprint:

```
auth_bp       → /api/auth/*
user_bp       → /api/user/*
academic_bp   → /api/*  (classes, subjects, chapters, topics, videos, progress, search)
quiz_bp       → /api/quizzes/*  and  /api/chapters/<id>/quizzes
badge_bp      → /api/badges/*
leaderboard_bp → /api/leaderboard/*
notification_bp → /api/notifications/*
study_bp      → /api/study/*
```

### Request/Response Format

All responses follow a consistent JSON format:

**Success:**
```json
{
  "message": "Optional message",
  "data_key": { ... }
}
```

**Error:**
```json
{
  "error": "Error description"
}
```

---

## 6. Database Collections

### `users`

Stores all user accounts (students and admins).

| Field | Type | Description |
|-------|------|-------------|
| `_id` | ObjectId | Auto-generated primary key |
| `full_name` | String | User's full name |
| `email` | String | Unique email address |
| `phone` | String | 10-digit unique phone number |
| `password_hash` | String | Werkzeug PBKDF2 hashed password |
| `role` | String | `"student"` or `"admin"` |
| `class_id` | String | Reference to class (stored as string for flexibility) |
| `profile_image` | String | URL or base64 image |
| `total_points` | Integer | Cumulative XP points |
| `streak_count` | Integer | Current daily streak |
| `last_activity_date` | DateTime | Last login for streak calculation |
| `failed_attempts` | Integer | Brute-force protection counter (max 5) |
| `is_active` | Boolean | Account active status |
| `created_at` | DateTime | Registration timestamp |
| `updated_at` | DateTime | Last profile update |

**Indexes:** `email` (unique), `phone` (unique sparse), `class_id`

---

### `user_preferences`

Stores per-user settings and app preferences.

| Field | Type | Description |
|-------|------|-------------|
| `user_id` | String | Reference to users `_id` |
| `dark_mode` | Boolean | Dark theme enabled |
| `language` | String | `"en"` or `"hi"` |
| `notifications_enabled` | Boolean | Master notification toggle |
| `study_reminder_enabled` | Boolean | Daily study reminder |
| `badge_alert_enabled` | Boolean | Badge unlock alerts |
| `quiz_reminder_enabled` | Boolean | Quiz reminder alerts |
| `show_on_leaderboard` | Boolean | Visibility on leaderboard |
| `show_streak_publicly` | Boolean | Public streak visibility |
| `difficulty_level` | String | `"easy"`, `"medium"`, or `"hard"` |
| `preferred_subject` | String | Preferred subject ID |
| `font_size` | String | `"small"`, `"medium"`, or `"large"` |
| `wifi_only_download` | Boolean | Download restriction |

**Index:** `user_id` (unique)

---

### `classes`

| Field | Type | Description |
|-------|------|-------------|
| `_id` | ObjectId | Primary key |
| `class_name` | String | e.g., `"Class 10"` |
| `board` | String | e.g., `"Maharashtra Board"` |
| `created_at` | DateTime | Creation timestamp |

---

### `subjects`

| Field | Type | Description |
|-------|------|-------------|
| `_id` | ObjectId | Primary key |
| `class_id` | String | Parent class reference |
| `subject_name` | String | e.g., `"Science"`, `"Mathematics"` |
| `icon` | String | Icon identifier |
| `created_at` | DateTime | Creation timestamp |

---

### `chapters`

| Field | Type | Description |
|-------|------|-------------|
| `_id` | ObjectId | Primary key |
| `subject_id` | String | Parent subject reference |
| `chapter_number` | Integer | Chapter number |
| `chapter_name` | String | Chapter title |
| `description` | String | Summary description |
| `pdf_url` | String | Optional notes PDF URL |
| `order_index` | Integer | Display order |
| `created_at` | DateTime | Creation timestamp |

**Index:** `subject_id`

---

### `topics`

| Field | Type | Description |
|-------|------|-------------|
| `_id` | ObjectId | Primary key |
| `chapter_id` | String | Parent chapter reference |
| `topic_name` | String | Topic title |
| `content` | String | Rich text / markdown notes |
| `order_index` | Integer | Display order |

**Index:** `chapter_id`

---

### `videos`

| Field | Type | Description |
|-------|------|-------------|
| `_id` | ObjectId | Primary key |
| `chapter_id` | String | Parent chapter reference |
| `topic_id` | String | Optional topic reference |
| `youtube_video_id` | String | YouTube video ID |
| `youtube_url` | String | Full YouTube URL |
| `embed_url` | String | YouTube embed URL |
| `title` | String | Video title |
| `duration` | String | Duration string e.g., `"12:34"` |
| `created_at` | DateTime | Creation timestamp |

**Index:** `chapter_id`

---

### `quizzes`

| Field | Type | Description |
|-------|------|-------------|
| `_id` | ObjectId | Primary key |
| `chapter_id` | String | Parent chapter reference |
| `title` | String | Quiz title |
| `description` | String | Quiz description |
| `questions` | Array | Embedded question documents |
| `created_at` | DateTime | Creation timestamp |

**Question subdocument:**

| Field | Type | Description |
|-------|------|-------------|
| `question_id` | String | Unique ID within quiz (e.g., `"q1"`) |
| `question_text` | String | The question |
| `option_a` | String | Option A |
| `option_b` | String | Option B |
| `option_c` | String | Option C |
| `option_d` | String | Option D |
| `correct_option` | String | `"A"`, `"B"`, `"C"`, or `"D"` |
| `explanation` | String | Answer explanation |

---

### `quiz_attempts`

| Field | Type | Description |
|-------|------|-------------|
| `_id` | ObjectId | Primary key |
| `user_id` | ObjectId | User reference |
| `quiz_id` | ObjectId | Quiz reference |
| `score` | Integer | Correct answers count |
| `total_questions` | Integer | Total questions |
| `percentage` | Float | Score percentage |
| `points_earned` | Integer | Points from this attempt |
| `attempted_at` | DateTime | Attempt timestamp |

**Index:** `(user_id, quiz_id)` compound

---

### `progress`

Tracks chapter-level completion per user.

| Field | Type | Description |
|-------|------|-------------|
| `user_id` | String | User reference |
| `chapter_id` | String | Chapter reference |
| `completion_percentage` | Float | 0.0 to 100.0 |
| `last_accessed` | DateTime | Last access time |

**Index:** `(user_id, chapter_id)` unique compound

---

### `badges`

Badge definitions (criteria for earning).

| Field | Type | Description |
|-------|------|-------------|
| `_id` | ObjectId | Primary key |
| `badge_name` | String | Badge title |
| `description` | String | Badge description |
| `icon_url` | String | Icon URL or emoji |
| `criteria_type` | String | `"quiz_count"`, `"points"`, or `"streak"` |
| `criteria_value` | Integer | Threshold value |
| `created_at` | DateTime | Creation timestamp |

---

### `user_badges`

Awarded badges per user.

| Field | Type | Description |
|-------|------|-------------|
| `_id` | ObjectId | Primary key |
| `user_id` | String | User reference |
| `badge_id` | ObjectId | Badge reference |
| `earned_at` | DateTime | When badge was earned |

---

### `notifications`

| Field | Type | Description |
|-------|------|-------------|
| `_id` | ObjectId | Primary key |
| `user_id` | String / ObjectId | Recipient user |
| `title` | String | Notification title |
| `message` | String | Notification body |
| `type` | String | `"quiz_result"`, `"badge"`, `"system"` |
| `is_read` | Boolean | Read status |
| `created_at` | DateTime | Creation timestamp |

**Index:** `(user_id, is_read)` compound

---

### `study_schedules`

| Field | Type | Description |
|-------|------|-------------|
| `_id` | ObjectId | Primary key |
| `user_id` | String | Owner user |
| `title` | String | Schedule name |
| `start_date` | String | ISO date `"YYYY-MM-DD"` |
| `end_date` | String | ISO date `"YYYY-MM-DD"` |
| `created_at` | DateTime | Creation timestamp |

**Index:** `user_id`

---

### `study_sessions`

| Field | Type | Description |
|-------|------|-------------|
| `_id` | ObjectId | Primary key |
| `schedule_id` | String | Parent schedule |
| `chapter_id` | String | Chapter to study |
| `planned_date` | String | ISO date `"YYYY-MM-DD"` |
| `scheduled_time` | String | Optional time `"HH:MM"` |
| `duration_minutes` | Integer | Planned duration |
| `notes` | String | Session notes |
| `completed` | Boolean | Completion status |
| `completed_at` | DateTime | Completion timestamp |
| `reminder_sent` | Boolean | Reminder flag |

**Index:** `(schedule_id, planned_date)` compound

---

### `leaderboard_snapshots`

Monthly frozen leaderboard records.

| Field | Type | Description |
|-------|------|-------------|
| `_id` | ObjectId | Primary key |
| `class_id` | String | Class reference |
| `month` | String | `"YYYY-MM"` format |
| `rankings` | Array | Ordered list of student rankings |
| `generated_at` | DateTime | Snapshot timestamp |

---

## 7. API Reference

**Base URL:** `http://localhost:5000`

**Authentication:** JWT Bearer token in `Authorization` header:
```
Authorization: Bearer <your_jwt_token>
```

---

### Authentication Endpoints (`/api/auth`)

#### POST `/api/auth/register`

Register a new student account.

**Request Body:**
```json
{
  "full_name": "Armaan Khan",
  "email": "armaan@example.com",
  "phone": "9876543210",
  "password": "mypassword",
  "class_id": "optional_class_id"
}
```

**Response 201:**
```json
{
  "message": "Registration successful",
  "token": "eyJ...",
  "user": {
    "_id": "...",
    "full_name": "Armaan Khan",
    "email": "armaan@example.com",
    "total_points": 0,
    "streak_count": 0
  }
}
```

**Validation Rules:**
- All 4 fields required
- Email must be valid format
- Phone must be exactly 10 digits
- Password minimum 6 characters
- Email and phone must be unique

---

#### POST `/api/auth/login`

Login with email or phone number.

**Request Body:**
```json
{
  "email_or_phone": "armaan@example.com",
  "password": "mypassword"
}
```

**Response 200:**
```json
{
  "message": "Login successful",
  "token": "eyJ...",
  "user": { ... }
}
```

**Notes:**
- Account locked after 5 failed attempts (HTTP 403)
- Streak auto-increments if login is on consecutive day
- Streak resets to 1 if gap > 1 day

---

#### GET `/api/auth/me` 🔒

Get current logged-in user's profile with preferences.

**Response 200:**
```json
{
  "user": {
    "_id": "...",
    "full_name": "Armaan Khan",
    "total_points": 150,
    "streak_count": 3,
    "preferences": {
      "dark_mode": false,
      "language": "en",
      "show_on_leaderboard": true
    }
  }
}
```

---

#### POST `/api/auth/logout` 🔒

Logs out the user (client must discard the JWT token).

**Response 200:**
```json
{ "message": "Logged out successfully" }
```

---

### User Endpoints (`/api/user`)

All endpoints require JWT authentication.

#### PUT `/api/user/profile` 🔒

Update name or profile image.

**Request Body:**
```json
{
  "full_name": "Armaan Ahmed Khan",
  "profile_image": "https://example.com/avatar.jpg"
}
```

---

#### PUT `/api/user/change-email` 🔒

Change email with password verification.

**Request Body:**
```json
{
  "new_email": "newemail@example.com",
  "password": "currentpassword"
}
```

---

#### PUT `/api/user/change-phone` 🔒

Change phone number with password verification.

**Request Body:**
```json
{
  "new_phone": "9123456789",
  "password": "currentpassword"
}
```

---

#### PUT `/api/user/change-password` 🔒

Change password with current password verification.

**Request Body:**
```json
{
  "current_password": "oldpassword",
  "new_password": "newpassword"
}
```

---

#### PUT `/api/user/change-class` 🔒

Update the student's class.

**Request Body:**
```json
{
  "class_id": "class_object_id"
}
```

---

#### GET `/api/user/preferences` 🔒

Get all user preferences/settings.

**Response 200:**
```json
{
  "preferences": {
    "dark_mode": false,
    "language": "en",
    "notifications_enabled": true,
    "study_reminder_enabled": true,
    "badge_alert_enabled": true,
    "quiz_reminder_enabled": true,
    "show_on_leaderboard": true,
    "show_streak_publicly": true,
    "difficulty_level": "medium",
    "font_size": "medium",
    "wifi_only_download": false
  }
}
```

---

#### PUT `/api/user/preferences` 🔒

Update any combination of preference fields.

**Request Body (any subset):**
```json
{
  "dark_mode": true,
  "language": "hi",
  "notifications_enabled": true,
  "study_reminder_enabled": false,
  "badge_alert_enabled": true,
  "quiz_reminder_enabled": true,
  "show_on_leaderboard": true,
  "show_streak_publicly": true,
  "difficulty_level": "hard",
  "font_size": "large",
  "wifi_only_download": true
}
```

---

#### GET `/api/user/stats` 🔒

Get aggregated statistics for the current user.

**Response 200:**
```json
{
  "stats": {
    "total_points": 350,
    "streak_count": 5,
    "total_quizzes_attempted": 12,
    "average_score": 74.58,
    "best_score": 100.0,
    "badges_earned": 3
  }
}
```

---

### Academic Endpoints (`/api`)

#### GET `/api/classes`

List all classes (public, no auth required).

**Response 200:**
```json
{
  "classes": [
    { "_id": "...", "class_name": "Class 10", "board": "Maharashtra Board" }
  ]
}
```

---

#### POST `/api/classes` 🔒 (Admin)

Create a new class.

**Request Body:**
```json
{
  "class_name": "Class 10",
  "board": "Maharashtra Board"
}
```

---

#### GET `/api/classes/<class_id>/subjects`

List subjects for a class (public).

**Response 200:**
```json
{
  "subjects": [
    { "_id": "...", "class_id": "...", "subject_name": "Science" }
  ]
}
```

---

#### POST `/api/subjects` 🔒 (Admin)

Create a new subject.

**Request Body:**
```json
{
  "class_id": "class_object_id",
  "subject_name": "Science",
  "icon": "science"
}
```

---

#### GET `/api/subjects/<subject_id>/chapters`

List chapters for a subject (public).

**Response 200:**
```json
{
  "chapters": [
    {
      "_id": "...",
      "chapter_number": 1,
      "chapter_name": "Chemical Reactions and Equations",
      "order_index": 1
    }
  ]
}
```

---

#### GET `/api/chapters/<chapter_id>` 🔒

Get full chapter details including topics and videos. Also updates progress `last_accessed`.

**Response 200:**
```json
{
  "chapter": {
    "_id": "...",
    "chapter_name": "Chemical Reactions and Equations",
    "topics": [ { "topic_name": "Types of Chemical Reactions", "content": "..." } ],
    "videos": [ { "title": "...", "embed_url": "...", "youtube_url": "..." } ]
  }
}
```

---

#### POST `/api/chapters` 🔒 (Admin)

Create a new chapter.

**Request Body:**
```json
{
  "subject_id": "...",
  "chapter_number": 1,
  "chapter_name": "Chemical Reactions and Equations",
  "description": "Study of chemical changes.",
  "pdf_url": "https://example.com/notes.pdf",
  "order_index": 1
}
```

---

#### PUT `/api/chapters/<chapter_id>` 🔒 (Admin)

Update chapter details.

---

#### DELETE `/api/chapters/<chapter_id>` 🔒 (Admin)

Delete chapter and all its topics and videos.

---

#### GET `/api/chapters/<chapter_id>/topics`

List topics for a chapter (public).

---

#### POST `/api/topics` 🔒 (Admin)

Create a new topic.

**Request Body:**
```json
{
  "chapter_id": "...",
  "topic_name": "Types of Chemical Reactions",
  "content": "Markdown or plain text notes...",
  "order_index": 1
}
```

---

#### GET `/api/chapters/<chapter_id>/videos`

List videos for a chapter (public).

---

#### POST `/api/videos` 🔒 (Admin)

Add a YouTube video to a chapter.

**Request Body:**
```json
{
  "chapter_id": "...",
  "youtube_video_id": "N3kfOCz-WrQ",
  "title": "Chemical Reactions - Class 10",
  "duration": "12:34",
  "topic_id": "optional_topic_id"
}
```

---

#### GET `/api/progress` 🔒

Get all chapter progress records for the current user.

---

#### PUT `/api/progress/<chapter_id>` 🔒

Update chapter completion percentage.

**Request Body:**
```json
{
  "completion_percentage": 75.0
}
```

---

#### GET `/api/search?q=<query>`

Search chapters, topics, and videos (public).

**Query param:** `q` — minimum 2 characters

**Response 200:**
```json
{
  "query": "chemical",
  "results": {
    "chapters": [ ... ],
    "topics": [ ... ],
    "videos": [ ... ]
  }
}
```

---

### Quiz Endpoints (`/api`)

#### GET `/api/quizzes/<quiz_id>` 🔒

Fetch quiz for the student — **correct answers and explanations are stripped**.

**Response 200:**
```json
{
  "quiz": {
    "_id": "...",
    "title": "Chemical Reactions Quiz",
    "questions": [
      {
        "question_id": "q1",
        "question_text": "Which is a combination reaction?",
        "option_a": "...",
        "option_b": "...",
        "option_c": "...",
        "option_d": "..."
      }
    ],
    "attempts_used": 0,
    "attempts_remaining": 5
  }
}
```

---

#### POST `/api/quizzes/<quiz_id>/submit` 🔒

Submit quiz answers and get results.

**Request Body:**
```json
{
  "answers": {
    "q1": "B",
    "q2": "C",
    "q3": "C",
    "q4": "D",
    "q5": "B"
  }
}
```

**Response 200:**
```json
{
  "score": 4,
  "total_questions": 5,
  "percentage": 80.0,
  "points_earned": 40,
  "results": [
    {
      "question_id": "q1",
      "selected": "B",
      "correct": "B",
      "is_correct": true,
      "explanation": "Combination reactions..."
    }
  ],
  "new_badges": [
    { "badge_name": "First Quiz", "description": "Complete your first quiz" }
  ]
}
```

**Points Formula:** `score × 10`
**Max Attempts:** 5 per quiz

---

#### GET `/api/quizzes/<quiz_id>/attempts` 🔒

Get current user's attempts for a specific quiz.

---

#### GET `/api/attempts/my` 🔒

Get all quiz attempts by the current user.

---

#### GET `/api/chapters/<chapter_id>/quizzes` 🔒

List quizzes available for a chapter (without questions).

---

#### POST `/api/quizzes` 🔒 (Admin)

Create a new quiz with embedded questions.

**Request Body:**
```json
{
  "chapter_id": "...",
  "title": "Chemical Reactions Quiz",
  "description": "Test your knowledge",
  "questions": [
    {
      "question_id": "q1",
      "question_text": "Which is a combination reaction?",
      "option_a": "CaCO3 → CaO + CO2",
      "option_b": "2H2 + O2 → 2H2O",
      "option_c": "Fe + CuSO4 → FeSO4 + Cu",
      "option_d": "NaOH + HCl → NaCl + H2O",
      "correct_option": "B",
      "explanation": "Combination reactions involve..."
    }
  ]
}
```

---

### Badge Endpoints (`/api/badges`)

#### GET `/api/badges/`

List all badge definitions (public).

---

#### POST `/api/badges/` 🔒 (Admin)

Create a badge.

**Request Body:**
```json
{
  "badge_name": "Quiz Master",
  "description": "Complete 20 quizzes",
  "icon_url": "🏆",
  "criteria_type": "quiz_count",
  "criteria_value": 20
}
```

**`criteria_type` values:** `quiz_count`, `streak`, `points`

---

#### GET `/api/badges/my` 🔒

Get all badges earned by the current user.

**Response 200:**
```json
{
  "badges": [
    {
      "earned_at": "2025-01-15T10:30:00",
      "badge": {
        "badge_name": "First Quiz",
        "description": "Complete your first quiz",
        "icon_url": "🎯"
      }
    }
  ],
  "total": 1
}
```

---

#### DELETE `/api/badges/<badge_id>` 🔒 (Admin)

Delete a badge definition and remove it from all users.

---

### Leaderboard Endpoints (`/api/leaderboard`)

#### GET `/api/leaderboard/live/<class_id>` 🔒

Real-time leaderboard for a specific class. Users with `show_on_leaderboard: false` are excluded.

**Response 200:**
```json
{
  "leaderboard": [
    {
      "rank": 1,
      "user_id": "...",
      "full_name": "Armaan Khan",
      "total_points": 350,
      "streak_count": 5,
      "quizzes_attempted": 12,
      "average_score": 74.58
    }
  ],
  "total": 15
}
```

---

#### GET `/api/leaderboard/live` 🔒

Global leaderboard (all classes, top 100).

---

#### GET `/api/leaderboard/my-rank/<class_id>` 🔒

Get the current user's rank in their class.

---

#### POST `/api/leaderboard/snapshot/<class_id>` 🔒 (Admin)

Save a monthly leaderboard snapshot.

---

#### GET `/api/leaderboard/snapshots/<class_id>` 🔒

Retrieve historical snapshots for a class.

---

### Notification Endpoints (`/api/notifications`)

#### GET `/api/notifications/` 🔒

Get paginated notifications.

**Query Params:** `page` (default 1), `per_page` (default 20)

**Response 200:**
```json
{
  "notifications": [
    {
      "_id": "...",
      "title": "Quiz Completed!",
      "message": "You scored 4/5 and earned 40 points.",
      "type": "quiz_result",
      "is_read": false,
      "created_at": "..."
    }
  ],
  "total": 8,
  "page": 1,
  "per_page": 20
}
```

---

#### GET `/api/notifications/unread-count` 🔒

Get count of unread notifications.

**Response 200:**
```json
{ "unread_count": 3 }
```

---

#### PUT `/api/notifications/<notif_id>/read` 🔒

Mark a single notification as read.

---

#### PUT `/api/notifications/read-all` 🔒

Mark all notifications as read.

---

#### DELETE `/api/notifications/<notif_id>` 🔒

Delete a notification.

---

### Study Endpoints (`/api/study`)

#### GET `/api/study/schedules` 🔒

Get all study schedules with their sessions.

---

#### POST `/api/study/schedules` 🔒

Create a new study schedule with sessions.

**Request Body:**
```json
{
  "title": "Class 10 Science Revision",
  "start_date": "2025-02-01",
  "end_date": "2025-02-28",
  "sessions": [
    {
      "chapter_id": "...",
      "planned_date": "2025-02-01",
      "scheduled_time": "18:00",
      "duration_minutes": 60,
      "notes": "Focus on balancing equations"
    }
  ]
}
```

---

#### GET `/api/study/schedules/<schedule_id>` 🔒

Get a specific schedule with all sessions.

---

#### DELETE `/api/study/schedules/<schedule_id>` 🔒

Delete a schedule and all its sessions.

---

#### PUT `/api/study/sessions/<session_id>/complete` 🔒

Mark a study session as completed.

---

#### GET `/api/study/today` 🔒

Get today's planned study sessions.

**Response 200:**
```json
{
  "today": "2025-02-22",
  "sessions": [ ... ],
  "count": 2
}
```

---

### Utility Endpoint

#### GET `/api/health`

Health check (no auth).

**Response 200:**
```json
{ "status": "ok", "message": "Sci-Math Hub API is running" }
```

---

## 8. Authentication System

### JWT Flow

```
Client → POST /api/auth/login → Server
                              ← JWT token (valid 24 hours)

Client → GET /api/auth/me
         Header: Authorization: Bearer <token>
       → Server validates token → Returns user data
```

### Token Storage (Flutter)

```dart
// Store token securely
await FlutterSecureStorage().write(key: 'jwt_token', value: token);

// Read token
final token = await FlutterSecureStorage().read(key: 'jwt_token');

// Delete on logout
await FlutterSecureStorage().delete(key: 'jwt_token');
```

### Brute-Force Protection

- After 5 failed login attempts, the account is temporarily locked
- Returns HTTP 403 with message `"Too many failed attempts. Please try again later."`
- Counter resets on successful login

### Streak Logic

Streak is calculated on every login:
- If last login was **yesterday** → `streak + 1`
- If last login was **today** → no change
- If gap is **more than 1 day** → reset to `1`

---

## 9. Gamification Engine

### Points System

| Action | Points |
|--------|--------|
| Each correct answer in a quiz | +10 points |
| Badge milestone (special types can be added) | Configured per badge |

Points are stored cumulatively in `users.total_points`.

### Badge Auto-Award System

After every quiz submission, `_evaluate_and_award_badges(uid)` runs:

1. Fetch user's current stats (`total_points`, `streak_count`)
2. Count total quiz attempts
3. Load all badge definitions
4. Compare each badge's `criteria_type` and `criteria_value` against user's stats
5. If criteria met and badge not already earned → insert into `user_badges`, create notification
6. Return list of newly awarded badges to the response

**Criteria types:**

| Type | Checks |
|------|--------|
| `quiz_count` | `total_attempts >= criteria_value` |
| `points` | `total_points >= criteria_value` |
| `streak` | `streak_count >= criteria_value` |

### Leaderboard Ranking

Rankings are computed dynamically (no denormalized rank stored):
1. Fetch all active students in the class
2. For each student, compute `total_points` and `average_score`
3. Skip students with `show_on_leaderboard: false`
4. Sort by `total_points` descending, then `average_score` as tiebreaker
5. Assign `rank` (1-based)

---

## 10. Data Flow Diagrams

### Quiz Submission Flow

```
Student submits answers
        │
        ▼
JWT verified → user identity extracted
        │
        ▼
Quiz fetched from DB (with correct answers)
        │
        ▼
Answers compared → score, percentage, points calculated
        │
        ▼
Attempt saved to quiz_attempts
        │
        ▼
users.total_points incremented
        │
        ▼
_evaluate_and_award_badges() runs
    ├── Check quiz_count badges
    ├── Check points badges
    └── Check streak badges
              │
              ▼
       New badges → saved to user_badges
                 → notifications created
        │
        ▼
Quiz result notification created
        │
        ▼
Response: score, results, new_badges
```

### Login & Streak Flow

```
POST /api/auth/login
        │
        ▼
Find user by email or phone
        │
        ▼
Check failed_attempts < 5
        │
        ▼
Verify password hash
        │
        ▼
Calculate streak:
    last_activity = today → no change
    last_activity = yesterday → streak + 1
    last_activity = 2+ days ago → reset to 1
        │
        ▼
Update user doc (streak, last_activity_date, failed_attempts = 0)
        │
        ▼
Generate JWT → return token + user
```

---

## 11. Flutter Integration Guide

### API Service Example

```dart
class ApiService {
  static const String baseUrl = 'http://your-server-ip:5000';

  Future<Map<String, dynamic>> login(String identifier, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email_or_phone': identifier, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getMe(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> submitQuiz(
    String quizId, Map<String, String> answers, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/quizzes/$quizId/submit'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'answers': answers}),
    );
    return jsonDecode(response.body);
  }
}
```

### Auth Flow in Flutter

```
App Launch
    │
    ▼
Read JWT from FlutterSecureStorage
    │
    ├── Token found → GET /api/auth/me
    │       ├── 200 OK → Home (Logged-In Mode)
    │       └── 401 → Clear token → Home (Guest Mode)
    │
    └── No token → Home (Guest Mode)
```

### Guest Mode Restrictions

Features that require login should check for token presence:
- Attempting a quiz
- Viewing progress
- Accessing leaderboard
- Managing study schedule

Show a "Login Required" bottom sheet when guest users tap restricted features.

---

## 12. Testing Guide

### Quick Tests with curl

```bash
# Health check
curl http://localhost:5000/api/health

# Register
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"full_name":"Test User","email":"test@example.com","phone":"9876543210","password":"test123"}'

# Login (save the token)
TOKEN=$(curl -s -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email_or_phone":"test@example.com","password":"test123"}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")

# Get profile
curl -H "Authorization: Bearer $TOKEN" http://localhost:5000/api/auth/me

# Get classes
curl http://localhost:5000/api/classes

# Update preferences (dark mode on)
curl -X PUT http://localhost:5000/api/user/preferences \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"dark_mode": true}'

# Get notifications
curl -H "Authorization: Bearer $TOKEN" http://localhost:5000/api/notifications/

# Get today's study sessions
curl -H "Authorization: Bearer $TOKEN" http://localhost:5000/api/study/today
```

### Common HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 400 | Bad request / validation error |
| 401 | Unauthorized / invalid credentials |
| 403 | Forbidden (account locked or wrong role) |
| 404 | Resource not found |
| 409 | Conflict (duplicate email/phone) |
| 500 | Internal server error |

---

## 13. Deployment

### Development

```bash
python run.py
```

### Production with Gunicorn

```bash
gunicorn -w 4 -b 0.0.0.0:5000 "app:create_app('production')"
```

### Production with Nginx (recommended)

1. Run Gunicorn on `127.0.0.1:5000` (internal only)
2. Configure Nginx to proxy pass to Gunicorn
3. Use HTTPS with Let's Encrypt

### MongoDB Atlas (Cloud)

Replace `MONGO_URI` in `.env`:
```
MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/sci_math_hub
```

### Important Production Checklist

- [ ] Change `SECRET_KEY` to a strong random value
- [ ] Change `JWT_SECRET_KEY` to a strong random value
- [ ] Set `FLASK_ENV=production`
- [ ] Use HTTPS (SSL certificate)
- [ ] Enable MongoDB authentication
- [ ] Add rate limiting (flask-limiter)
- [ ] Set up log monitoring
- [ ] Back up MongoDB regularly

---

## 14. Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `FLASK_ENV` | No | `development` | `development` or `production` |
| `SECRET_KEY` | Yes | — | Flask secret for session signing |
| `JWT_SECRET_KEY` | Yes | — | JWT token signing key |
| `MONGO_URI` | Yes | — | MongoDB connection string |
| `JWT_ACCESS_TOKEN_EXPIRES` | No | `86400` | JWT lifetime in seconds (default: 24 hours) |

---

*Documentation version: 1.0 — Sci-Math Hub Backend*
