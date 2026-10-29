# 🏍️ RidingMoto — Co-Traveler Tracker

Real-time group location tracking for riders, hikers, and travelers.  
No login required. Just create a trip, share the code, and ride together.

---

## Features

- ✅ Create a trip with a shareable 6-letter code
- ✅ Join a trip by entering the code
- ✅ Live map showing all group members in real time
- ✅ Custom avatar & color per rider
- ✅ No account needed — fully anonymous
- ✅ Google AdMob banner + interstitial ads
- ✅ iOS & Android support

---

## Project Structure

```
riding-track/
├── backend/          # Django REST + WebSocket backend
│   ├── config/       # Settings, ASGI, URLs
│   ├── trips/        # Models, views, consumer, routing
│   └── requirements.txt
├── mobile/           # Flutter app (iOS + Android)
│   ├── lib/
│   │   ├── core/     # Theme, routes, services, constants
│   │   ├── features/ # Screens (home, create, join, map)
│   │   └── shared/   # Models, widgets
│   └── pubspec.yaml
└── docker-compose.yml
```

---

## Local Development Setup

### Backend

**Option A — Direct Python (SQLite, no Redis, no Docker)**
```bash
cd backend
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

**Option B — Docker Compose (PostgreSQL + Redis)**
```bash
docker-compose up --build
```

Backend runs at: `http://localhost:8000`

---

### Flutter App

**1. Get packages**
```bash
cd mobile
flutter pub get
```

**2. Add your Google Maps API key**

- Android: Edit `android/app/src/main/AndroidManifest.xml`  
  Replace `YOUR_GOOGLE_MAPS_API_KEY` with your key.

- iOS: Edit `ios/Runner/Info.plist`  
  Replace `YOUR_GOOGLE_MAPS_API_KEY` with your key.

**3. Run the app**
```bash
# Android emulator (uses 10.0.2.2 to reach localhost)
flutter run

# iOS simulator — first update lib/core/constants.dart to use localhost URLs
flutter run
```

---

## Getting a Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable: **Maps SDK for Android** and **Maps SDK for iOS**
4. Create an API key under Credentials
5. (Optional) Restrict key to your app's bundle ID / SHA-1

---

## Getting AdMob IDs

1. Go to [Google AdMob](https://admob.google.com/)
2. Create an app for Android and one for iOS
3. Replace the test IDs in:
   - `lib/core/constants.dart` — Ad Unit IDs
   - `android/app/src/main/AndroidManifest.xml` — App ID
   - `ios/Runner/Info.plist` — App ID

---

## API Endpoints

| Method | URL | Description |
|--------|-----|-------------|
| POST | `/api/trips/` | Create a trip |
| POST | `/api/trips/{code}/join/` | Join a trip |
| GET | `/api/trips/{code}/members/` | List active members |
| POST | `/api/trips/{code}/leave/` | Leave a trip |
| GET | `/api/trips/{code}/` | Trip detail |

## WebSocket

```
ws://host/ws/trip/{CODE}/{MEMBER_UUID}/
```

Messages:
- **Send**: `{"type": "location_update", "lat": 12.34, "lng": 56.78}`
- **Receive**: `{"type": "member_update", ...}`, `{"type": "member_joined", ...}`, `{"type": "member_left", ...}`

---

## Tech Stack

| Layer | Tech |
|-------|------|
| Mobile | Flutter 3.x |
| Maps | Google Maps Flutter |
| Real-time | Django Channels (WebSocket) |
| REST API | Django REST Framework |
| Database | SQLite (dev) / PostgreSQL (prod) |
| Cache/WS | Redis (prod) / InMemory (dev) |
| Ads | Google AdMob |
