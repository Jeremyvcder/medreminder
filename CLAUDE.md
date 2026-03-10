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

## 版本记录规范

### 存档（当我说"存档"或"提交"时）
1. 运行 git diff 检查本次改动
2. 执行 git add . 和 git commit（根据改动自动生成备注）
3. 在 CHANGELOG.md 顶部添加记录，格式：
   ## YYYY-MM-DD HH:mm
   - 改动内容

### 回退（当我说"回退"或"撤销"时）
1. 先告诉我会回退到哪个版本（显示上一次的提交信息）
2. 等我确认后再执行回退
3. 回退后在 CHANGELOG.md 顶部记录：
   ## YYYY-MM-DD HH:mm
   - 回退：撤销了 xxx 改动

### 查看历史（当我说"历史"或"记录"时）
显示最近 5 次提交的简要信息

## 其他开发规范
1. 在编写任何代码前，请先描述你的方案并等待批准。如果需求不明确，在编写任何代码之前务必提出澄清问题
2. 如果任何一项任务需要修改超过3个文件，请先停下来，将其分解成更小的任务
3. 编写代码后，列出可能出现的问题，并建议相应的测试用例来覆盖这些问题
4. 当发现bug时，首先要编写一个能够重现该bug的测试，然后不断修复它，直到测试通过为止
5. 每次我纠正你之后，就在CLAUDE.md文件中添加一条新规则，以防止再发生这样的情况
6. 进行产品模块功能等内容的增删改时，若修改的内容与产品需求文档存在出入，需要同步更新产品需求文档，保证产品呈现与需求文档的一致性