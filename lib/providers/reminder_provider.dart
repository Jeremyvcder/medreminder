import 'package:flutter/foundation.dart';
import '../models/medication.dart';
import '../services/notification_service.dart';
import '../services/scheduler_service.dart';

/// 提醒项目（用于UI展示）
class ReminderItem {
  final Record record;
  final Medication medication;
  final bool isMerged;
  final List<ReminderItem>? mergedItems;

  ReminderItem({
    required this.record,
    required this.medication,
    this.isMerged = false,
    this.mergedItems,
  });
}

/// 提醒状态管理Provider
class ReminderProvider extends ChangeNotifier {
  final SchedulerService _schedulerService = SchedulerService();

  List<ReminderItem> _pendingReminders = [];
  List<ReminderItem> _completedReminders = [];
  bool _isLoading = false;
  String? _error;

  // 合并提醒分组
  final Map<int, List<ReminderItem>> _mergedReminders = {};

  List<ReminderItem> get pendingReminders => _pendingReminders;
  List<ReminderItem> get completedReminders => _completedReminders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<int, List<ReminderItem>> get mergedReminders => _mergedReminders;

  /// 获取今日待服清单（已合并）
  Future<void> loadTodayReminders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final rawReminders = await _schedulerService.getTodayReminders();
      _pendingReminders = rawReminders.map((data) {
        return ReminderItem(
          record: Record.fromMap(data['record']),
          medication: Medication.fromMap(data['medication']),
        );
      }).toList();

      // 合并同一时间的提醒
      _mergeRemindersByTime();
    } catch (e) {
      _error = '加载提醒失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 按时间合并提醒
  void _mergeRemindersByTime() {
    _mergedReminders.clear();

    final Map<String, List<ReminderItem>> timeGrouped = {};

    for (var item in _pendingReminders) {
      final timeKey = _formatTime(item.record.scheduledTime);
      if (!timeGrouped.containsKey(timeKey)) {
        timeGrouped[timeKey] = [];
      }
      timeGrouped[timeKey]!.add(item);
    }

    // 转换为通知ID分组
    for (var entry in timeGrouped.entries) {
      final items = entry.value;
      if (items.length > 1) {
        // 多个药品同一时间，生成合并通知ID
        final notificationId = NotificationService.generateMergedNotificationId(
          items.first.record.scheduledTime,
        );
        _mergedReminders[notificationId] = items;
      } else {
        // 单个药品
        final notificationId = NotificationService.generateNotificationId(
          items.first.medication.id,
          items.first.record.scheduledTime,
        );
        _mergedReminders[notificationId] = items;
      }
    }
  }

  /// 格式化时间
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// 获取已完成项目
  Future<void> loadCompletedReminders() async {
    try {
      final rawReminders = await _schedulerService.getCompletedReminders();
      _completedReminders = rawReminders.map((data) {
        return ReminderItem(
          record: Record.fromMap(data['record']),
          medication: Medication.fromMap(data['medication']),
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      _error = '加载已完成记录失败: $e';
      notifyListeners();
    }
  }

  /// 确认服药
  Future<bool> confirmMedication(String recordId) async {
    try {
      await _schedulerService.confirmMedication(recordId);
      await loadTodayReminders();
      await loadCompletedReminders();
      return true;
    } catch (e) {
      _error = '确认失败: $e';
      notifyListeners();
      return false;
    }
  }

  /// 确认多个药品（合并提醒）
  Future<bool> confirmMultipleMedications(List<String> recordIds) async {
    try {
      for (var id in recordIds) {
        await _schedulerService.confirmMedication(id);
      }
      await loadTodayReminders();
      await loadCompletedReminders();
      return true;
    } catch (e) {
      _error = '确认失败: $e';
      notifyListeners();
      return false;
    }
  }

  /// 跳过
  Future<bool> skipMedication(String recordId, {String? reason}) async {
    try {
      await _schedulerService.skipMedication(recordId, reason: reason);
      await loadTodayReminders();
      await loadCompletedReminders();
      return true;
    } catch (e) {
      _error = '跳过失败: $e';
      notifyListeners();
      return false;
    }
  }

  /// 稍后提醒
  Future<bool> snoozeReminder(String recordId) async {
    try {
      await _schedulerService.snoozeReminder(recordId);
      await loadTodayReminders();
      return true;
    } catch (e) {
      _error = '稍后提醒失败: $e';
      notifyListeners();
      return false;
    }
  }

  /// 获取待服数量
  int get pendingCount => _pendingReminders.length;

  /// 获取已完成数量
  int get completedCount => _completedReminders.length;

  /// 获取今日统计
  Map<String, int> getTodayStats() {
    return {
      'total': _pendingReminders.length + _completedReminders.length,
      'pending': _pendingReminders.length,
      'completed': _completedReminders.length,
      'taken': _completedReminders.where((r) => r.record.status == RecordStatus.taken).length,
      'skipped': _completedReminders.where((r) => r.record.status == RecordStatus.skipped).length,
      'missed': _completedReminders.where((r) => r.record.status == RecordStatus.missed).length,
    };
  }
}
