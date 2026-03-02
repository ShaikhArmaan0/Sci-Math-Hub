# Sci-Math Hub — Complete Full Stack Project

A gamified e-learning mobile app for Classes 8, 9, and 10 (Maharashtra Board) — Science & Mathematics.

---

## Project Structure

```
Sci-Math-Hub/
├── backend/           ← Flask + MongoDB REST API
│   ├── app/
│   │   ├── routes/   ← All API endpoints
│   │   ├── scripts/  ← Seed database
│   │   ├── config.py
│   │   ├── database.py
│   │   └── utils.py
│   ├── .env          ← Environment variables
│   ├── requirements.txt
│   └── run.py
│
├── frontend/          ← Flutter mobile app
│   ├── lib/
│   │   ├── constants/ ← Colors, theme, constants
│   │   ├── models/    ← Data models
│   │   ├── providers/ ← State management
│   │   ├── screens/   ← All UI screens
│   │   ├── services/  ← API service layer
│   │   ├── widgets/   ← Reusable components
│   │   └── main.dart  ← App entry point
│   └── pubspec.yaml
│
└── docs/
    └── DOCUMENTATION.md  ← Full API & architecture docs
```

---

## Quick Start

### Step 1: Start MongoDB
```bash
mongosh
```

### Step 2: Start Backend
```bash
cd backend
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
python -m app.scripts.seed   # Populate sample data
python run.py
```
API available at: `http://localhost:5000`
Admin: `admin@scimathub.com` / `admin123`

### Step 3: Run Flutter App
```bash
cd frontend
flutter pub get
flutter run
```

> **Note:** If running on a physical device, update `baseUrl` in `lib/constants/app_constants.dart` to your machine's local IP.
>
> For Android emulator: `http://10.0.2.2:5000` (default)
> For iOS simulator: `http://localhost:5000`
> For physical device: `http://YOUR_IP:5000`

---

## Features

### Guest (No login required)
- Browse Classes, Subjects, Chapters
- Read topic notes
- Watch YouTube videos

### Student (After login)
- Attempt quizzes (max 5 per quiz)
- Earn XP points (10 per correct answer)
- Daily streak tracking
- Auto badge awards
- Leaderboard ranking
- Study schedule & sessions
- Notifications
- Progress tracking

### Admin
- Manage classes, subjects, chapters, topics
- Add YouTube videos
- Create quizzes with questions
- Create badges
- Generate monthly leaderboard snapshots

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart), Provider |
| Backend | Python, Flask, Flask-JWT-Extended |
| Database | MongoDB (via PyMongo) |
| Auth | JWT Bearer tokens |
| Storage | flutter_secure_storage (JWT), SharedPreferences |

---

## API Base URL
Default: `http://localhost:5000`

See `docs/DOCUMENTATION.md` for full API reference.
