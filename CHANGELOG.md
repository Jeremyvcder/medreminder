# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-03-07

### Added
- 项目初始化
- Flutter 基础框架搭建
- 底部导航栏（首页、药箱、记录、设置）
- SQLCipher 加密数据库实现
- 数据库表结构：medications, records, settings
- Provider 状态管理集成
- flutter_local_notifications 通知功能

### Dependencies
- sqflite_sqlcipher: ^3.1.0+1
- flutter_secure_storage: ^9.0.0
- flutter_local_notifications: ^17.0.0
- provider: ^6.1.1
- uuid: ^4.2.1
- intl: ^0.19.0
- timezone: ^0.9.2