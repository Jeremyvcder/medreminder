# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added (阶段5: 停用机制)
- 停用/恢复历史记录：使用JSON数组存储多次停用/恢复的时间戳
- 数据库迁移：v2版本升级到v3，添加stopped_history字段并迁移原有数据
- 停用时取消通知：停用药品时自动取消该药品的所有未来提醒通知
- 恢复后当天触发逻辑：恢复药品时，如果有任一提醒时间未过则当天触发，否则从次日开始
- 多天计划批量停用：停用多天计划时同时停用整个计划组的所有药品
- UI提示优化：详情页停用/恢复确认框中增加多天计划提示

### Fixed
- 选择药品后自动隐藏输入法键盘
- 停用/恢复/删除药品后首页自动刷新
- 记录详情弹窗UI优化：增加宽度解决内容溢出，时间信息垂直排列区分层级
- 首页确认/跳过服药后日历和依从性统计同步更新
- 首页空状态时支持下拉刷新

## [1.2.0] - 2026-03-10

### Fixed
- 首页不显示提醒的问题：修复已过去时间点不创建记录的问题，现在添加稍晚的提醒也能正常显示
- 添加稍晚提醒后不自动返回的问题：优化通知和语音发送为异步执行
- 多天计划无法保存的问题：修复 Schedule.toJson 中 daysCount 的 key 名称错误（days -> daysCount）
- 多天计划显示为1天的问题：修复 daysCount 参数错误（1 -> daysCount）
- 添加药品页面的 try-catch-finally 异常处理

### Added
- 批量添加药品优化：多天计划使用统一提醒生成，提高性能
- 药箱界面多天计划合并显示：显示为"X天计划"标记

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