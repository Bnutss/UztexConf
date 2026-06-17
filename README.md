# UztexConf

Corporate video conferencing mobile app built with Flutter and LiveKit.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![LiveKit](https://img.shields.io/badge/LiveKit-WebRTC-FF6600)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-lightgrey)

## Overview

UztexConf is an internal video conferencing platform for the company. It provides real-time multi-user video and audio calls with a clean, modern UI.

### Features

- **Video conferencing** — multi-participant rooms with real-time video/audio via LiveKit
- **Adaptive grid layout** — participants displayed in responsive grid (1-col, 2-col, 3-col based on count)
- **Tap-to-expand** — tap any participant to view fullscreen, swipe to navigate between participants
- **Speaking indicators** — green glow border and icon when a participant is speaking
- **Mic/camera status** — real-time indicators for muted mic or disabled camera
- **Camera controls** — toggle mic, camera, speaker, switch front/back camera
- **Room management** — create, join, and delete conference rooms
- **JWT authentication** — login with auto token refresh on expiry
- **Multi-language** — Russian, English, Uzbek with in-app language switching
- **Onboarding** — first-launch setup with language selection and permission requests

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.x / Dart |
| Video/Audio | LiveKit Client SDK |
| Backend | Django + Django REST Framework |
| Auth | JWT (SimpleJWT) with auto-refresh |
| WebRTC | LiveKit Server |
| State | StatefulWidget + EventsListener |

## Project Structure

```
lib/
  config.dart            # Server URL configuration
  main.dart              # App entry point
  models/
    room.dart            # Room and RoomToken models
  screens/
    home_screen.dart     # Room list with search and create
    login_screen.dart    # JWT authentication
    onboarding_screen.dart # First-launch language + permissions
    room_screen.dart     # Video conferencing room (LiveKit)
    settings_screen.dart # Language, profile, about
  services/
    api_service.dart     # REST API client with auto token refresh
    locale_service.dart  # Multi-language support
assets/
  images/
    logo.png             # App logo
```

## Setup

### Prerequisites

- Flutter SDK 3.12+
- Xcode (for iOS) / Android Studio (for Android)
- Running backend server ([UztexConference](https://github.com/Bnutss/UztexConference))
- LiveKit server instance

### Configuration

Edit `lib/config.dart` with your server URL:

```dart
class Config {
  static const String baseUrl = 'https://your-server.com';
}
```

### Run

```bash
# Install dependencies
flutter pub get

# Run on connected device
flutter run

# Build for iOS
flutter build ios

# Build for Android
flutter build apk
```

## Backend API

The app connects to a Django backend that provides:

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/auth/login/` | JWT login |
| `POST` | `/api/auth/refresh/` | Token refresh |
| `GET` | `/api/rooms/` | List rooms |
| `POST` | `/api/rooms/` | Create room |
| `GET` | `/api/rooms/<id>/token/` | Get LiveKit token |
| `DELETE` | `/api/rooms/<id>/` | Delete room |

## License

Proprietary. Internal use only.
