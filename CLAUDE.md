# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**medreminder (服药宝)** - A Flutter-based medication reminder app for Android and iOS. The app helps users track their medication schedules with reminders, multi-day plans, and compliance tracking.

## Common Commands

```bash
# Get dependencies
flutter pub get

# Analyze code for issues
flutter analyze

# Build debug APK
flutter build apk --debug

# Build iOS (requires macOS)
flutter build ios

# Run on connected device
flutter run
```

## Architecture

This is a **Flutter mobile app** using the following stack:

- **Framework**: Flutter 3.x with Dart
- **State Management**: Provider
- **Database**: SQLite with SQLCipher encryption (`sqflite_sqlcipher`)
- **Secure Storage**: flutter_secure_storage (Android Keychain / iOS Keychain)
- **Notifications**: flutter_local_notifications
- **Key Packages**:
  - `sqflite_sqlcipher` - Encrypted SQLite database
  - `flutter_secure_storage` - Secure key storage
  - `flutter_local_notifications` - Local push notifications
  - `provider` - State management
  - `uuid` - Unique ID generation
  - `intl` - Internationalization/date formatting
  - `timezone` - Timezone support

## Project Structure

```
lib/
├── main.dart              # App entry point, MaterialApp setup
├── db/
│   └── database_helper.dart    # SQLCipher database with CRUD operations
├── models/                # Data models (planned)
├── providers/             # Provider state management (planned)
├── screens/               # UI screens (planned)
├── services/              # Business logic services (planned)
├── widgets/               # Reusable widgets (planned)
└── data/                  # Static data like medication library (planned)
```

## Database Schema

Three main tables:
- **medications** - Drug/supplement items with schedule rules
- **records** - Medication intake records (taken/skipped/missed)
- **settings** - App configuration

Encryption key is stored securely in device Keychain via flutter_secure_storage.

## Development Notes

- This is an MVP project (v2.7) following a PRD document
- Development follows a staged approach: each module is built and tested before moving to the next
- The app uses a bottom navigation with 4 tabs: Home (首页), Medicine Box (药箱), Records (记录), Settings (设置)
- Key features include: medication reminders, multi-day plans, medication library, large text mode, voice notifications
- **Code comments should be in Chinese (中文)**
