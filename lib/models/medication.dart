/// 药品类别枚举
enum MedicationCategory {
  medicine, // 药品
  supplement, // 保健品
}

/// 药品数据模型
class Medication {
  final String id;
  final String name;
  final MedicationCategory category;
  final String dosage;
  final String? usage;
  final Schedule schedule;
  final bool isActive;
  final DateTime? stoppedAt;
  final String? planGroupId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Medication({
    required this.id,
    required this.name,
    required this.category,
    required this.dosage,
    this.usage,
    required this.schedule,
    required this.isActive,
    this.stoppedAt,
    this.planGroupId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从数据库Map创建Medication对象
  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] == 'medicine'
          ? MedicationCategory.medicine
          : MedicationCategory.supplement,
      dosage: map['dosage'] as String,
      usage: map['usage'] as String?,
      schedule: Schedule.fromJson(map['schedule'] as String),
      isActive: map['is_active'] == 1,
      stoppedAt: map['stopped_at'] != null
          ? DateTime.parse(map['stopped_at'] as String)
          : null,
      planGroupId: map['plan_group_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category == MedicationCategory.medicine
          ? 'medicine'
          : 'supplement',
      'dosage': dosage,
      'usage': usage,
      'schedule': schedule.toJson(),
      'is_active': isActive ? 1 : 0,
      'stopped_at': stoppedAt?.toIso8601String(),
      'plan_group_id': planGroupId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 复制并修改
  Medication copyWith({
    String? id,
    String? name,
    MedicationCategory? category,
    String? dosage,
    String? usage,
    Schedule? schedule,
    bool? isActive,
    DateTime? stoppedAt,
    String? planGroupId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      dosage: dosage ?? this.dosage,
      usage: usage ?? this.usage,
      schedule: schedule ?? this.schedule,
      isActive: isActive ?? this.isActive,
      stoppedAt: stoppedAt ?? this.stoppedAt,
      planGroupId: planGroupId ?? this.planGroupId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 提醒规则类型
enum ScheduleType {
  daily, // 每日固定时间
  interval, // 间隔周期
  weekly, // 每周特定几天
  monthly, // 每月特定日期
  multiday, // 多天计划
}

/// 提醒规则模型
class Schedule {
  final ScheduleType type;
  final List<String> times; // 时间列表 ["08:00", "20:00"]
  final int? hours; // 间隔周期（小时）
  final List<int>? days; // 每周几 [1,3,5] 周一三五
  final List<int>? dates; // 每月几号 [1,15]
  final DateTime? startDate; // 多天计划开始日期
  final int? daysCount; // 多天计划持续天数
  final List<String>? dosages; // 多天计划每天剂量

  const Schedule({
    required this.type,
    required this.times,
    this.hours,
    this.days,
    this.dates,
    this.startDate,
    this.daysCount,
    this.dosages,
  });

  /// 从JSON字符串创建Schedule对象
  factory Schedule.fromJson(String json) {
    final map = _parseJson(json);
    return Schedule(
      type: _parseType(map['type'] as String),
      times: List<String>.from(map['times'] ?? []),
      hours: map['hours'] as int?,
      days: map['days'] != null ? List<int>.from(map['days']) : null,
      dates: map['dates'] != null ? List<int>.from(map['dates']) : null,
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'] as String)
          : null,
      daysCount: map['days'] is int ? map['days'] as int : null,
      dosages:
          map['dosages'] != null ? List<String>.from(map['dosages']) : null,
    );
  }

  /// 解析JSON字符串
  static Map<String, dynamic> _parseJson(String json) {
    // 简单解析JSON
    final result = <String, dynamic>{};
    final content = json.trim();
    if (content.startsWith('{') && content.endsWith('}')) {
      final pairs = content.substring(1, content.length - 1).split(',');
      for (var pair in pairs) {
        final keyValue = pair.split(':');
        if (keyValue.length == 2) {
          final key = keyValue[0].trim().replaceAll('"', '');
          final value = keyValue[1].trim();
          if (value.startsWith('"') && value.endsWith('"')) {
            result[key] = value.substring(1, value.length - 1);
          } else if (value == 'null') {
            result[key] = null;
          } else if (value == 'true') {
            result[key] = true;
          } else if (value == 'false') {
            result[key] = false;
          } else {
            final intVal = int.tryParse(value);
            if (intVal != null) {
              result[key] = intVal;
            } else {
              result[key] = value;
            }
          }
        }
      }
    }
    return result;
  }

  /// 解析类型字符串
  static ScheduleType _parseType(String type) {
    switch (type) {
      case 'daily':
        return ScheduleType.daily;
      case 'interval':
        return ScheduleType.interval;
      case 'weekly':
        return ScheduleType.weekly;
      case 'monthly':
        return ScheduleType.monthly;
      case 'multiday':
        return ScheduleType.multiday;
      default:
        return ScheduleType.daily;
    }
  }

  /// 转换为JSON字符串
  String toJson() {
    final buffer = StringBuffer('{');
    buffer.write('"type":"${_typeToString(type)}"');
    buffer.write(',"times":${_listToJson(times)}');

    if (hours != null) {
      buffer.write(',"hours":$hours');
    }
    if (days != null) {
      buffer.write(',"days":${_listToJsonInt(days!)}');
    }
    if (dates != null) {
      buffer.write(',"dates":${_listToJsonInt(dates!)}');
    }
    if (startDate != null) {
      buffer.write(',"startDate":"${startDate!.toIso8601String().split('T')[0]}"');
    }
    if (daysCount != null) {
      buffer.write(',"days":$daysCount');
    }
    if (dosages != null) {
      buffer.write(',"dosages":${_listToJson(dosages!)}');
    }

    buffer.write('}');
    return buffer.toString();
  }

  /// 类型转字符串
  String _typeToString(ScheduleType type) {
    switch (type) {
      case ScheduleType.daily:
        return 'daily';
      case ScheduleType.interval:
        return 'interval';
      case ScheduleType.weekly:
        return 'weekly';
      case ScheduleType.monthly:
        return 'monthly';
      case ScheduleType.multiday:
        return 'multiday';
    }
  }

  /// 列表转JSON数组
  String _listToJson(List<String> list) {
    return '[${list.map((e) => '"$e"').join(',')}]';
  }

  String _listToJsonInt(List<int> list) {
    return '[${list.join(',')}]';
  }

  /// 创建每日提醒规则
  factory Schedule.daily(List<String> times) {
    return Schedule(type: ScheduleType.daily, times: times);
  }

  /// 创建间隔提醒规则
  factory Schedule.interval(int hours, String time) {
    return Schedule(type: ScheduleType.interval, hours: hours, times: [time]);
  }

  /// 创建每周提醒规则
  factory Schedule.weekly(List<int> days, List<String> times) {
    return Schedule(type: ScheduleType.weekly, days: days, times: times);
  }

  /// 创建每月提醒规则
  factory Schedule.monthly(List<int> dates, List<String> times) {
    return Schedule(type: ScheduleType.monthly, dates: dates, times: times);
  }

  /// 创建多天计划提醒规则
  factory Schedule.multiday(
    DateTime startDate,
    int daysCount,
    List<String> times, {
    List<String>? dosages,
  }) {
    return Schedule(
      type: ScheduleType.multiday,
      startDate: startDate,
      daysCount: daysCount,
      times: times,
      dosages: dosages,
    );
  }

  /// 获取今日提醒时间列表
  List<DateTime> getTodayScheduledTimes() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (type) {
      case ScheduleType.daily:
        return times.map((t) => _parseTime(t, today)).toList();

      case ScheduleType.interval:
        // 间隔周期需要计算
        if (hours == null || times.isEmpty) return [];
        return _calculateIntervalTimes(hours!, times.first, today);

      case ScheduleType.weekly:
        if (days == null || days!.isEmpty || times.isEmpty) return [];
        // 判断今天是否在设置的星期几内 (1=周一, 7=周日)
        final weekday = now.weekday;
        if (days!.contains(weekday)) {
          return times.map((t) => _parseTime(t, today)).toList();
        }
        return [];

      case ScheduleType.monthly:
        if (dates == null || dates!.isEmpty || times.isEmpty) return [];
        if (dates!.contains(now.day)) {
          return times.map((t) => _parseTime(t, today)).toList();
        }
        return [];

      case ScheduleType.multiday:
        if (startDate == null || daysCount == null || times.isEmpty) return [];
        final start = DateTime(
            startDate!.year, startDate!.month, startDate!.day);
        final end = start.add(Duration(days: daysCount! - 1));
        if (today.isAfter(end) || today.isBefore(start)) return [];
        return times.map((t) => _parseTime(t, today)).toList();
    }
  }

  /// 解析时间字符串
  DateTime _parseTime(String timeStr, DateTime baseDate) {
    final parts = timeStr.split(':');
    return DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  /// 计算间隔提醒时间
  List<DateTime> _calculateIntervalTimes(
      int hours, String startTime, DateTime baseDate) {
    final times = <DateTime>[];
    final firstTime = _parseTime(startTime, baseDate);
    final now = DateTime.now();

    // 从今天第一个提醒时间开始，检查是否已过
    var currentTime = firstTime;

    // 如果第一个时间已过，从现在开始计算
    if (currentTime.isBefore(now)) {
      // 计算从第一个提醒时间到现在经过了几次
      final diff = now.difference(currentTime).inMinutes;
      final intervals = diff ~/ (hours * 60);
      currentTime = currentTime.add(Duration(hours: hours * (intervals + 1)));
    }

    // 生成今天的提醒时间（最多5个）
    var count = 0;
    while (currentTime.hour < 23 && count < 5) {
      times.add(currentTime);
      currentTime = currentTime.add(Duration(hours: hours));
      count++;
    }

    return times;
  }
}

/// 记录状态
enum RecordStatus {
  pending, // 待服
  taken, // 已服
  skipped, // 跳过
  missed, // 错过
}

/// 服药记录模型
class Record {
  final String id;
  final String medicationId;
  final DateTime scheduledTime;
  final DateTime? actualTime;
  final RecordStatus status;
  final String? skipReason;
  final DateTime createdAt;

  const Record({
    required this.id,
    required this.medicationId,
    required this.scheduledTime,
    this.actualTime,
    required this.status,
    this.skipReason,
    required this.createdAt,
  });

  /// 从数据库Map创建Record对象
  factory Record.fromMap(Map<String, dynamic> map) {
    return Record(
      id: map['id'] as String,
      medicationId: map['medication_id'] as String,
      scheduledTime: DateTime.parse(map['scheduled_time'] as String),
      actualTime: map['actual_time'] != null
          ? DateTime.parse(map['actual_time'] as String)
          : null,
      status: _parseStatus(map['status'] as String),
      skipReason: map['skip_reason'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// 解析状态字符串
  static RecordStatus _parseStatus(String status) {
    switch (status) {
      case 'taken':
        return RecordStatus.taken;
      case 'skipped':
        return RecordStatus.skipped;
      case 'missed':
        return RecordStatus.missed;
      default:
        return RecordStatus.pending;
    }
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medication_id': medicationId,
      'scheduled_time': scheduledTime.toIso8601String(),
      'actual_time': actualTime?.toIso8601String(),
      'status': _statusToString(status),
      'skip_reason': skipReason,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 状态转字符串
  String _statusToString(RecordStatus status) {
    switch (status) {
      case RecordStatus.taken:
        return 'taken';
      case RecordStatus.skipped:
        return 'skipped';
      case RecordStatus.missed:
        return 'missed';
      case RecordStatus.pending:
        return 'pending';
    }
  }

  /// 复制并修改
  Record copyWith({
    String? id,
    String? medicationId,
    DateTime? scheduledTime,
    DateTime? actualTime,
    RecordStatus? status,
    String? skipReason,
    DateTime? createdAt,
  }) {
    return Record(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      actualTime: actualTime ?? this.actualTime,
      status: status ?? this.status,
      skipReason: skipReason ?? this.skipReason,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
