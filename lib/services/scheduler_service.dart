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
  final VoiceService _voiceService = VoiceService(); // 使用单例
  final Uuid _uuid = const Uuid();

  Timer? _dailyTimer;
  Timer? _checkTimer;

  // 存储每个药品的语音提醒Timer（medicationId -> List<Timer>）
  final Map<String, List<Timer>> _voiceTimers = {};

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

    // 按时间分组的提醒（未来的）
    final Map<String, List<Medication>> futureTimeGrouped = {};
    // 已过去时间点的提醒（仍需创建记录，但不发送通知）
    final Map<String, List<Medication>> pastTimeGrouped = {};

    for (var medMap in medications) {
      final medication = Medication.fromMap(medMap);
      final scheduledTimes = medication.schedule.getTodayScheduledTimes();

      for (var time in scheduledTimes) {
        final timeKey =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

        // 根据是否已过去分别处理
        if (time.isBefore(now)) {
          // 已过去的时间：仍需创建记录，但不发送通知
          if (!pastTimeGrouped.containsKey(timeKey)) {
            pastTimeGrouped[timeKey] = [];
          }
          pastTimeGrouped[timeKey]!.add(medication);
        } else {
          // 未来的时间：创建记录并发送通知
          if (!futureTimeGrouped.containsKey(timeKey)) {
            futureTimeGrouped[timeKey] = [];
          }
          futureTimeGrouped[timeKey]!.add(medication);
        }
      }
    }

    // 先处理已过去的提醒（只创建记录，不发通知）
    for (var entry in pastTimeGrouped.entries) {
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
        // 单个药品 - 只创建记录
        await _createPendingRecord(meds.first, scheduledTime);
      } else {
        // 多个药品 - 为每个创建记录
        for (var med in meds) {
          await _createPendingRecord(med, scheduledTime);
        }
      }
    }

    // 再处理未来的提醒（创建记录并发送通知）
    for (var entry in futureTimeGrouped.entries) {
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
    Medication medication,
    DateTime scheduledTime,
  ) async {
    // 创建待服记录
    final isNewRecord = await _createPendingRecord(medication, scheduledTime);

    // 只有新记录才发送通知和语音
    if (!isNewRecord) return;

    final notificationId = NotificationService.generateNotificationId(
      medication.id,
      scheduledTime,
    );

    // 发送通知（通知会在准确时间触发）
    try {
      await _notificationService.showMedicationReminder(
        notificationId: notificationId,
        medication: medication,
        scheduledTime: scheduledTime,
      );
    } catch (e) {
      // 通知失败不影响记录创建
    }

    // 定时语音提醒（使用Timer在准确时间触发）
    _scheduleVoiceReminder(
      medicationId: medication.id,
      scheduledTime: scheduledTime,
      medicationName: medication.name,
      dosage: medication.dosage,
      isMedicine: medication.category == MedicationCategory.medicine,
    );

    // 安排重复提醒（第2、3、4次）
    final records = await _db.getRecords(
      medicationId: medication.id,
      startDate: scheduledTime.subtract(const Duration(minutes: 1)),
      endDate: scheduledTime.add(const Duration(minutes: 1)),
    );
    if (records.isNotEmpty) {
      final recordId = records.first['id'] as String;
      for (int i = 1; i <= maxRepeatCount; i++) {
        await scheduleRepeatReminder(recordId, i);
      }
    }
  }

  /// 定时语音提醒
  void _scheduleVoiceReminder({
    required String medicationId,
    required DateTime scheduledTime,
    required String medicationName,
    required String dosage,
    required bool isMedicine,
  }) {
    // 计算延迟时间
    final delay = scheduledTime.difference(DateTime.now());
    if (delay.isNegative || delay.inMilliseconds <= 0) {
      print('定时语音提醒: 时间已过，立即触发');
      // 时间已过，直接播放语音
      _voiceService.speakMedicationReminder(
        medicationName: medicationName,
        dosage: dosage,
        isMedicine: isMedicine,
      );
      return;
    }

    // 使用Timer延迟执行
    final timer = Timer(delay, () {
      _voiceService.speakMedicationReminder(
        medicationName: medicationName,
        dosage: dosage,
        isMedicine: isMedicine,
      );
    });

    // 存储Timer引用，以便后续可以取消
    _voiceTimers.putIfAbsent(medicationId, () => []);
    _voiceTimers[medicationId]!.add(timer);

    print('已定时语音提醒: ${scheduledTime.toString()}，延迟 ${delay.inMilliseconds}ms');
  }

  /// 调度合并提醒
  Future<void> _scheduleMergedReminder(
    List<Medication> medications,
    DateTime scheduledTime,
  ) async {
    // 为每个药品创建待服记录，检查是否有新记录
    bool hasNewRecord = false;
    for (var medication in medications) {
      final isNew = await _createPendingRecord(medication, scheduledTime);
      if (isNew) hasNewRecord = true;
    }

    // 只有新记录才发送通知和语音
    if (!hasNewRecord) return;

    final notificationId = NotificationService.generateMergedNotificationId(
      scheduledTime,
    );

    // 发送合并通知
    try {
      await _notificationService.showMergedReminder(
        notificationId: notificationId,
        medications: medications,
        scheduledTime: scheduledTime,
      );
    } catch (e) {
      // 通知失败不影响记录创建
    }

    // 定时语音提醒（使用Timer在准确时间触发）
    // 为每个药品都存储Timer引用，以便删除任一药品时可以取消
    final medsData = medications
        .map(
          (m) => {
            'name': m.name,
            'dosage': m.dosage,
            'isMedicine': m.category == MedicationCategory.medicine
                ? 'true'
                : 'false',
            'id': m.id,
          },
        )
        .toList();
    _scheduleMergedVoiceReminder(
      medicationIds: medications.map((m) => m.id).toList(),
      scheduledTime: scheduledTime,
      medications: medsData,
    );
  }

  /// 定时合并语音提醒
  void _scheduleMergedVoiceReminder({
    required List<String> medicationIds,
    required DateTime scheduledTime,
    required List<Map<String, String>> medications,
  }) {
    // 计算延迟时间
    final delay = scheduledTime.difference(DateTime.now());
    if (delay.isNegative || delay.inMilliseconds <= 0) {
      print('定时语音提醒: 时间已过，立即触发');
      // 时间已过，直接播放语音
      _voiceService.speakMergedReminder(
        medications: medications
            .map((m) => {
                  'name': m['name']!,
                  'dosage': m['dosage']!,
                  'isMedicine': m['isMedicine']!,
                })
            .toList(),
      );
      return;
    }

    // 使用Timer延迟执行
    final timer = Timer(delay, () {
      _voiceService.speakMergedReminder(
        medications: medications
            .map((m) => {
                  'name': m['name']!,
                  'dosage': m['dosage']!,
                  'isMedicine': m['isMedicine']!,
                })
            .toList(),
      );
    });

    // 为每个涉及的药品都存储Timer引用
    for (var medicationId in medicationIds) {
      _voiceTimers.putIfAbsent(medicationId, () => []);
      _voiceTimers[medicationId]!.add(timer);
    }

    print('已定时语音提醒: ${scheduledTime.toString()}，延迟 ${delay.inMilliseconds}ms');
  }


  /// 创建待服记录
  /// 返回是否创建了新记录（true=新记录，false=已存在）
  Future<bool> _createPendingRecord(
    Medication medication,
    DateTime scheduledTime,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // 检查该药品今天是否已有任何状态的记录
    final todayRecords = await _db.getRecords(
      medicationId: medication.id,
      startDate: today,
      endDate: tomorrow,
    );

    // 如果计划时间已过，且今天该药品已有记录，不创建新记录
    // 这避免了在用户点击"稍后"→"已服"后，定时器重新创建原时间记录的问题
    if (scheduledTime.isBefore(now) && todayRecords.isNotEmpty) {
      return false; // 计划时间已过且已有记录
    }

    // 如果今天已有pending记录，不创建新记录（避免重复创建）
    final hasPendingRecord = todayRecords.any((r) => r['status'] == 'pending');
    if (hasPendingRecord) {
      return false; // 已有待服记录
    }

    // 检查是否已存在该时间点的记录（±1分钟内）- 作为额外检查
    final existingRecords = await _db.getRecords(
      medicationId: medication.id,
      startDate: scheduledTime.subtract(const Duration(minutes: 1)),
      endDate: scheduledTime.add(const Duration(minutes: 1)),
    );

    if (existingRecords.isNotEmpty) {
      return false; // 同一时间点已有记录
    }

    final record = {
      'id': _uuid.v4(),
      'medication_id': medication.id,
      'scheduled_time': scheduledTime.toIso8601String(),
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    };

    await _db.insertRecord(record);
    return true; // 创建了新记录
  }

  /// 检查错过的提醒
  Future<void> _checkForMissedReminders() async {
    final now = DateTime.now();
    final records = await _db.getRecords();

    for (var recordMap in records) {
      final record = Record.fromMap(recordMap);
      if (record.status == RecordStatus.pending) {
        final scheduledTime = record.scheduledTime;
        // 如果提醒时间已过60分钟，标记为错过
        if (now.difference(scheduledTime).inMinutes >= 60) {
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
    final medicationId = recordMap['medication_id'] as String;

    // 更新记录状态，并将 scheduled_time 更新为实际时间（避免定时器重新创建记录）
    final now = DateTime.now();
    await _db.updateRecord(recordId, {
      ...recordMap,
      'status': 'taken',
      'scheduled_time': now.toIso8601String(),
      'actual_time': now.toIso8601String(),
    });

    // 取消该药品的后续重复提醒
    final notificationId = NotificationService.generateNotificationId(
      medicationId,
      DateTime.parse(recordMap['scheduled_time']),
    );
    await _notificationService.cancelNotification(notificationId);

    // 取消所有重复提醒（第1、2、3次）- 使用与安排时相同的 repeatTime
    final scheduledTime = DateTime.parse(recordMap['scheduled_time']);
    for (int i = 1; i <= maxRepeatCount; i++) {
      final repeatTime = scheduledTime.add(
        Duration(minutes: repeatIntervalMinutes * i),
      );
      final repeatNotificationId = NotificationService.generateNotificationId(
        '$medicationId\_repeat$i',
        repeatTime,
      );
      await _notificationService.cancelNotification(repeatNotificationId);
    }

    // 取消该药品的语音提醒Timer
    _cancelVoiceTimers(medicationId);
  }

  /// 处理跳过
  Future<void> skipMedication(String recordId, {String? reason}) async {
    final records = await _db.getRecords();
    final recordMap = records.firstWhere((r) => r['id'] == recordId);
    final medicationId = recordMap['medication_id'] as String;

    // 更新记录状态，并将 scheduled_time 更新为实际时间（避免定时器重新创建记录）
    final now = DateTime.now();
    await _db.updateRecord(recordId, {
      ...recordMap,
      'status': 'skipped',
      'scheduled_time': now.toIso8601String(),
      'skip_reason': reason,
      'actual_time': now.toIso8601String(),
    });

    // 取消该药品的后续重复提醒
    final notificationId = NotificationService.generateNotificationId(
      medicationId,
      DateTime.parse(recordMap['scheduled_time']),
    );
    await _notificationService.cancelNotification(notificationId);

    // 取消所有重复提醒（第1、2、3次）- 使用与安排时相同的 repeatTime
    final scheduledTime = DateTime.parse(recordMap['scheduled_time']);
    for (int i = 1; i <= maxRepeatCount; i++) {
      final repeatTime = scheduledTime.add(
        Duration(minutes: repeatIntervalMinutes * i),
      );
      final repeatNotificationId = NotificationService.generateNotificationId(
        '$medicationId\_repeat$i',
        repeatTime,
      );
      await _notificationService.cancelNotification(repeatNotificationId);
    }

    // 取消该药品的语音提醒Timer
    _cancelVoiceTimers(medicationId);
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

    // 取消原有重复提醒（第1、2、3次）- 使用与安排时相同的 repeatTime
    for (int i = 1; i <= maxRepeatCount; i++) {
      final repeatTime = scheduledTime.add(
        Duration(minutes: repeatIntervalMinutes * i),
      );
      final repeatNotificationId = NotificationService.generateNotificationId(
        '$medicationId\_repeat$i',
        repeatTime,
      );
      await _notificationService.cancelNotification(repeatNotificationId);
    }

    // 取消原语音提醒Timer
    _cancelVoiceTimers(medicationId);

    // 发送新的提醒
    final medications = await _db.getMedications();
    final medicationMap = medications.firstWhere(
      (m) => m['id'] == medicationId,
    );
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

    // 为新时间调度语音提醒
    _scheduleVoiceReminder(
      medicationId: medicationId,
      scheduledTime: newTime,
      medicationName: medication.name,
      dosage: medication.dosage,
      isMedicine: medication.category == MedicationCategory.medicine,
    );

    // 为新时间安排重复提醒（第1、2、3次）
    for (int i = 1; i <= maxRepeatCount; i++) {
      await scheduleRepeatReminder(recordId, i);
    }
  }

  /// 安排重复提醒
  Future<void> scheduleRepeatReminder(String recordId, int repeatCount) async {
    if (repeatCount > maxRepeatCount) return;

    final records = await _db.getRecords();
    final recordMap = records.firstWhere((r) => r['id'] == recordId);
    final recordStatus = recordMap['status'] as String;

    // 只有 pending 状态才安排重复提醒（已服/已跳过/已错过不安排）
    if (recordStatus != 'pending') {
      return;
    }

    final medicationId = recordMap['medication_id'];
    final scheduledTime = DateTime.parse(recordMap['scheduled_time']);

    // 计算重复提醒时间（累计：15分钟后、30分钟后、45分钟后）
    final repeatTime = scheduledTime.add(
      Duration(minutes: repeatIntervalMinutes * repeatCount),
    );

    // 获取药品信息
    final medications = await _db.getMedications();
    final medicationMap = medications.firstWhere(
      (m) => m['id'] == medicationId,
    );
    final medication = Medication.fromMap(medicationMap);

    // 安排重复提醒（通知）
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

    // 安排重复提醒（语音）
    _scheduleVoiceReminder(
      medicationId: medicationId,
      scheduledTime: repeatTime,
      medicationName: medication.name,
      dosage: medication.dosage,
      isMedicine: medication.category == MedicationCategory.medicine,
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

    final records = await _db.getRecords(startDate: today, endDate: tomorrow);

    // 过滤出待服的记录
    final pendingRecords = records
        .where((r) => r['status'] == 'pending')
        .toList();

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

        // 过滤已停用的药品
        if (medication['is_active'] != 1) continue;

        result.add({'record': record, 'medication': medication});
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

    final records = await _db.getRecords(startDate: today, endDate: tomorrow);

    // 过滤出已完成的记录（taken/skipped/missed）
    final completedRecords = records
        .where(
          (r) =>
              r['status'] == 'taken' ||
              r['status'] == 'skipped' ||
              r['status'] == 'missed',
        )
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

        result.add({'record': record, 'medication': medication});
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

  /// 取消特定药品的所有未来提醒
  Future<void> cancelMedicationReminders(String medicationId) async {
    final medications = await _db.getMedications(isActive: true);
    final medMap = medications.where((m) => m['id'] == medicationId).toList();

    if (medMap.isEmpty) return;

    final medication = Medication.fromMap(medMap.first);
    final scheduledTimes = medication.schedule.getTodayScheduledTimes();
    final now = DateTime.now();

    // 取消今天和明天的提醒
    for (var time in scheduledTimes) {
      if (time.isAfter(now)) {
        final notificationId = NotificationService.generateNotificationId(
          medicationId,
          time,
        );
        await _notificationService.cancelNotification(notificationId);
      }
    }

    // 对于多天计划，也取消明天的提醒
    if (medication.schedule.type == ScheduleType.multiday) {
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      for (var time in scheduledTimes) {
        final tomorrowTime = DateTime(
          tomorrow.year,
          tomorrow.month,
          tomorrow.day,
          time.hour,
          time.minute,
        );
        if (tomorrowTime.isAfter(now)) {
          final notificationId = NotificationService.generateNotificationId(
            medicationId,
            tomorrowTime,
          );
          await _notificationService.cancelNotification(notificationId);
        }
      }
    }

    // 取消语音提醒Timer
    _cancelVoiceTimers(medicationId);
  }

  /// 取消指定药品的语音提醒Timer
  void _cancelVoiceTimers(String medicationId) {
    final timers = _voiceTimers[medicationId] ?? [];
    for (var timer in timers) {
      timer.cancel();
    }
    _voiceTimers.remove(medicationId);
    print('已取消药品 $medicationId 的 ${timers.length} 个语音提醒Timer');
  }

  /// 为特定药品调度提醒
  /// 用于恢复药品后重新调度提醒
  /// 包含当天触发逻辑：如果有任一提醒时间未过，则当天触发
  Future<void> scheduleReminderForMedication(String medicationId) async {
    final medications = await _db.getMedications(isActive: true);
    final medMap = medications.where((m) => m['id'] == medicationId).toList();

    if (medMap.isEmpty) return;

    final medication = Medication.fromMap(medMap.first);
    final now = DateTime.now();

    // 获取该药品今天的提醒时间
    final scheduledTimes = medication.schedule.getTodayScheduledTimes();

    // 检查是否有未来的提醒时间（未过的时间）
    final futureTimes = scheduledTimes.where((t) => t.isAfter(now)).toList();

    if (futureTimes.isNotEmpty) {
      // 有未来时间，今天正常触发 - 为每个未来时间发送通知
      for (var time in futureTimes) {
        final notificationId = NotificationService.generateNotificationId(
          medication.id,
          time,
        );

        await _notificationService.showMedicationReminder(
          notificationId: notificationId,
          medication: medication,
          scheduledTime: time,
        );
      }
    }
    // 如果没有未来时间，则当天不触发，从次日开始正常调度
  }
}
