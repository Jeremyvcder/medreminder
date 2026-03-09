import 'dart:async';
import 'package:uuid/uuid.dart';
import '../db/database_helper.dart';
import '../models/medication.dart';
import 'notification_service.dart';
import 'voice_service.dart';

/// 提醒调度服务 - 负责管理和调度所有药品提醒
class SchedulerService {
  static final SchedulerService _instance = SchedulerService._internal();
  factory SchedulerService() => _instance;
  SchedulerService._internal();

  final DatabaseHelper _db = DatabaseHelper();
  final NotificationService _notificationService = NotificationService();
  final VoiceService _voiceService = VoiceService();
  final Uuid _uuid = const Uuid();

  Timer? _dailyTimer;
  Timer? _checkTimer;

  // 重复提醒配置
  static const int repeatIntervalMinutes = 15;
  static const int maxRepeatCount = 3;
  static const int snoozeMinutes = 10;
  static const int maxSnoozeCount = 3;

  /// 初始化调度服务
  Future<void> initialize() async {
    await _notificationService.initialize();
    await _voiceService.initialize();

    // 启动每日检查定时器（每分钟检查一次）
    _startDailyTimer();

    // 立即检查并调度今日提醒
    await scheduleTodayReminders();
  }

  /// 启动每日定时器
  void _startDailyTimer() {
    // 每分钟检查一次
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      scheduleTodayReminders();
      _checkForMissedReminders();
    });
  }

  /// 调度今日所有提醒
  Future<void> scheduleTodayReminders() async {
    final medications = await _db.getMedications(isActive: true);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 按时间分组的提醒
    final Map<String, List<Medication>> timeGrouped = {};

    for (var medMap in medications) {
      final medication = Medication.fromMap(medMap);
      final scheduledTimes = medication.schedule.getTodayScheduledTimes();

      for (var time in scheduledTimes) {
        // 跳过已过时间的提醒
        if (time.isBefore(now)) {
          continue;
        }

        final timeKey =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

        if (!timeGrouped.containsKey(timeKey)) {
          timeGrouped[timeKey] = [];
        }
        timeGrouped[timeKey]!.add(medication);
      }
    }

    // 为每个时间点发送通知
    for (var entry in timeGrouped.entries) {
      final timeParts = entry.key.split(':');
      final scheduledTime = DateTime(
        today.year,
        today.month,
        today.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      final meds = entry.value;

      if (meds.length == 1) {
        // 单个药品
        await _scheduleSingleReminder(meds.first, scheduledTime);
      } else {
        // 多个药品合并提醒
        await _scheduleMergedReminder(meds, scheduledTime);
      }
    }
  }

  /// 调度单个药品提醒
  Future<void> _scheduleSingleReminder(
      Medication medication, DateTime scheduledTime) async {
    // 先创建待服记录，确保记录一定被创建
    await _createPendingRecord(medication, scheduledTime);

    final notificationId = NotificationService.generateNotificationId(
      medication.id,
      scheduledTime,
    );

    // 发送通知（失败不影响记录创建）
    try {
      await _notificationService.showMedicationReminder(
        notificationId: notificationId,
        medication: medication,
        scheduledTime: scheduledTime,
      );
    } catch (e) {
      // 通知失败不影响记录创建
    }

    // 发送语音提醒（失败不影响记录创建）
    try {
      await _voiceService.speakMedicationReminder(
        medicationName: medication.name,
        dosage: medication.dosage,
        isMedicine: medication.category == MedicationCategory.medicine,
      );
    } catch (e) {
      // 语音失败不影响记录创建
    }
  }

  /// 调度合并提醒
  Future<void> _scheduleMergedReminder(
      List<Medication> medications, DateTime scheduledTime) async {
    // 先为每个药品创建待服记录，确保记录一定被创建
    for (var medication in medications) {
      await _createPendingRecord(medication, scheduledTime);
    }

    final notificationId = NotificationService.generateMergedNotificationId(
      scheduledTime,
    );

    // 发送合并通知（失败不影响记录创建）
    try {
      await _notificationService.showMergedReminder(
        notificationId: notificationId,
        medications: medications,
        scheduledTime: scheduledTime,
      );
    } catch (e) {
      // 通知失败不影响记录创建
    }

    // 发送合并语音提醒（失败不影响记录创建）
    try {
      await _voiceService.speakMergedReminder(
        medications: medications
            .map((m) => {
                  'name': m.name,
                  'dosage': m.dosage,
                  'isMedicine': m.category == MedicationCategory.medicine
                      ? 'true'
                      : 'false',
                })
            .toList(),
      );
    } catch (e) {
      // 语音失败不影响记录创建
    }
  }

  /// 创建待服记录
  Future<void> _createPendingRecord(
      Medication medication, DateTime scheduledTime) async {
    // 检查是否已存在该时间点的记录
    final existingRecords = await _db.getRecords(
      medicationId: medication.id,
      startDate: scheduledTime,
      endDate: scheduledTime.add(const Duration(minutes: 1)),
    );

    if (existingRecords.isNotEmpty) {
      return;
    }

    final record = {
      'id': _uuid.v4(),
      'medication_id': medication.id,
      'scheduled_time': scheduledTime.toIso8601String(),
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    };

    await _db.insertRecord(record);
  }

  /// 检查错过的提醒
  Future<void> _checkForMissedReminders() async {
    final now = DateTime.now();
    final records = await _db.getRecords();

    for (var recordMap in records) {
      final record = Record.fromMap(recordMap);
      if (record.status == RecordStatus.pending) {
        final scheduledTime = record.scheduledTime;
        // 如果提醒时间已过15分钟，标记为错过
        if (now.difference(scheduledTime).inMinutes >= 15) {
          await _db.updateRecord(record.id, {
            ...record.toMap(),
            'status': 'missed',
          });
        }
      }
    }
  }

  /// 处理确认服药
  Future<void> confirmMedication(String recordId) async {
    final records = await _db.getRecords();
    final recordMap = records.firstWhere((r) => r['id'] == recordId);

    await _db.updateRecord(recordId, {
      ...recordMap,
      'status': 'taken',
      'actual_time': DateTime.now().toIso8601String(),
    });

    // 取消该药品的后续重复提醒
    final notificationId = NotificationService.generateNotificationId(
      recordMap['medication_id'],
      DateTime.parse(recordMap['scheduled_time']),
    );
    await _notificationService.cancelNotification(notificationId);
  }

  /// 处理跳过
  Future<void> skipMedication(String recordId, {String? reason}) async {
    final records = await _db.getRecords();
    final recordMap = records.firstWhere((r) => r['id'] == recordId);

    await _db.updateRecord(recordId, {
      ...recordMap,
      'status': 'skipped',
      'skip_reason': reason,
      'actual_time': DateTime.now().toIso8601String(),
    });

    // 取消该药品的后续重复提醒
    final notificationId = NotificationService.generateNotificationId(
      recordMap['medication_id'],
      DateTime.parse(recordMap['scheduled_time']),
    );
    await _notificationService.cancelNotification(notificationId);
  }

  /// 处理稍后提醒
  Future<void> snoozeReminder(String recordId) async {
    final records = await _db.getRecords();
    final recordMap = records.firstWhere((r) => r['id'] == recordId);
    final scheduledTime = DateTime.parse(recordMap['scheduled_time']);
    final medicationId = recordMap['medication_id'];

    // 计算新的提醒时间（10分钟后）
    final newTime = DateTime.now().add(const Duration(minutes: snoozeMinutes));

    // 更新记录
    await _db.updateRecord(recordId, {
      ...recordMap,
      'scheduled_time': newTime.toIso8601String(),
    });

    // 取消原提醒
    final oldNotificationId = NotificationService.generateNotificationId(
      medicationId,
      scheduledTime,
    );
    await _notificationService.cancelNotification(oldNotificationId);

    // 发送新的提醒
    final medications = await _db.getMedications();
    final medicationMap =
        medications.firstWhere((m) => m['id'] == medicationId);
    final medication = Medication.fromMap(medicationMap);

    final newNotificationId = NotificationService.generateNotificationId(
      medicationId,
      newTime,
    );

    await _notificationService.showMedicationReminder(
      notificationId: newNotificationId,
      medication: medication,
      scheduledTime: newTime,
    );
  }

  /// 安排重复提醒
  Future<void> scheduleRepeatReminder(
      String recordId, int repeatCount) async {
    if (repeatCount >= maxRepeatCount) return;

    final records = await _db.getRecords();
    final recordMap = records.firstWhere((r) => r['id'] == recordId);
    final medicationId = recordMap['medication_id'];
    final scheduledTime = DateTime.parse(recordMap['scheduled_time']);

    // 计算重复提醒时间（15分钟后）
    final repeatTime =
        scheduledTime.add(Duration(minutes: repeatIntervalMinutes));

    // 获取药品信息
    final medications = await _db.getMedications();
    final medicationMap =
        medications.firstWhere((m) => m['id'] == medicationId);
    final medication = Medication.fromMap(medicationMap);

    // 安排重复提醒
    final notificationId = NotificationService.generateNotificationId(
      '$medicationId\_repeat$repeatCount',
      repeatTime,
    );

    await _notificationService.scheduleRepeatingReminder(
      notificationId: notificationId,
      title: '服药提醒',
      body: '请服用${medication.name}，${medication.dosage}',
      scheduledTime: repeatTime,
      payload: recordId,
    );
  }

  /// 取消所有提醒
  Future<void> cancelAllReminders() async {
    await _notificationService.cancelAllNotifications();
    _checkTimer?.cancel();
    _dailyTimer?.cancel();
  }

  /// 获取今日待服清单
  Future<List<Map<String, dynamic>>> getTodayReminders() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final records = await _db.getRecords(
      startDate: today,
      endDate: tomorrow,
    );

    // 过滤出待服的记录
    final pendingRecords =
        records.where((r) => r['status'] == 'pending').toList();

    // 获取关联的药品信息
    final medications = await _db.getMedications();
    final result = <Map<String, dynamic>>[];

    for (var record in pendingRecords) {
      final medId = record['medication_id'];
      // 防止药品列表为空或找不到对应药品时崩溃
      try {
        final medication = medications.firstWhere(
          (m) => m['id'] == medId,
          orElse: () => <String, dynamic>{},
        );
        if (medication.isEmpty) continue; // 跳过找不到的药品

        result.add({
          'record': record,
          'medication': medication,
        });
      } catch (e) {
        // 跳过出错的记录
        continue;
      }
    }

    // 按时间排序
    result.sort((a, b) {
      final timeA = DateTime.parse(a['record']['scheduled_time']);
      final timeB = DateTime.parse(b['record']['scheduled_time']);
      return timeA.compareTo(timeB);
    });

    return result;
  }

  /// 获取已完成的项目
  Future<List<Map<String, dynamic>>> getCompletedReminders() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final records = await _db.getRecords(
      startDate: today,
      endDate: tomorrow,
    );

    // 过滤出已完成的记录（taken/skipped/missed）
    final completedRecords = records
        .where((r) =>
            r['status'] == 'taken' ||
            r['status'] == 'skipped' ||
            r['status'] == 'missed')
        .toList();

    // 获取关联的药品信息
    final medications = await _db.getMedications();
    final result = <Map<String, dynamic>>[];

    for (var record in completedRecords) {
      final medId = record['medication_id'];
      // 防止药品列表为空或找不到对应药品时崩溃
      try {
        final medication = medications.firstWhere(
          (m) => m['id'] == medId,
          orElse: () => <String, dynamic>{},
        );
        if (medication.isEmpty) continue; // 跳过找不到的药品

        result.add({
          'record': record,
          'medication': medication,
        });
      } catch (e) {
        // 跳过出错的记录
        continue;
      }
    }

    // 按时间排序
    result.sort((a, b) {
      final timeA = DateTime.parse(a['record']['scheduled_time']);
      final timeB = DateTime.parse(b['record']['scheduled_time']);
      return timeB.compareTo(timeA); // 倒序
    });

    return result;
  }
}
