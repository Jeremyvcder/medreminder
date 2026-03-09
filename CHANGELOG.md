# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- 首页不显示提醒的问题：将 `_createPendingRecord` 移到通知发送之前，确保通知权限异常时记录仍能创建
- 保存药品无反应的问题：修复 medicine_box_screen.dart 和 medication_provider.dart 在 build 期间调用 setState 的问题
- 优化添加药品后的数据刷新逻辑，先刷新数据再返回首页

### Added
- 添加药品页面：提醒时间支持点击直接编辑

## [1.1.0] - 2026-03-07

### Added (阶段2: 核心提醒功能)
- 数据模型：Medication、Schedule（支持5种提醒规则）、Record
- 服务层：NotificationService、VoiceService、SchedulerService
- 状态管理：MedicationProvider、ReminderProvider、SettingsProvider
- 内置药品库：200种常用药品和保健品
- 首页：今日待服清单、合并提醒、已完成折叠区
- 药箱：活跃/停用项目管理、搜索、删除
- 添加药品：内置药品库搜索、剂量用法、多天计划
- 药品详情：编辑/停用/恢复/删除

### Dependencies
- flutter_tts: ^4.0.2

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