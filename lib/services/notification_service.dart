import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/medication.dart';

/// 通知服务 - 处理本地通知的发送和管理
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// 导航回调 - 用于通知点击后导航到首页
  static void Function()? onNotificationTap;

  /// 初始化通知服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 初始化时区
    tz_data.initializeTimeZones();

    // Android设置 - 使用应用图标（mipmap资源）
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS设置
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 创建通知渠道（Android）
    await _createNotificationChannel();

    _isInitialized = true;
  }

  /// 创建通知渠道（Android 8.0+）
  Future<void> _createNotificationChannel() async {
    // 先删除旧渠道
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.deleteNotificationChannel('medication_reminder');

    const channel = AndroidNotificationChannel(
      'medication_reminder',
      '用药提醒',
      description: '药品和保健品服用提醒通知',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// 通知点击回调
  void _onNotificationTapped(NotificationResponse response) {
    // 处理通知点击事件
    // 可以通过payload传递药品ID或合并提醒ID
    final payload = response.payload;
    if (payload != null) {
      // 调用导航回调，跳转到首页
      onNotificationTap?.call();
    }
  }

  /// 发送单个药品提醒通知
  Future<void> showMedicationReminder({
    required int notificationId,
    required Medication medication,
    required DateTime scheduledTime,
  }) async {
    final title = '服药提醒';
    final body = '请服用${medication.name}，${medication.dosage}';

    await _showNotification(
      id: notificationId,
      title: title,
      body: body,
      payload: medication.id,
      scheduledTime: scheduledTime,
    );
  }

  /// 发送合并提醒通知（多个药品同一时间）
  Future<void> showMergedReminder({
    required int notificationId,
    required List<Medication> medications,
    required DateTime scheduledTime,
  }) async {
    final title = '服药提醒';
    // 合并药品名称
    final names = medications.map((m) => '${m.name}${m.dosage}').join('、');
    final body = '请服用$names';

    await _showNotification(
      id: notificationId,
      title: title,
      body: body,
      payload: 'merged_${medications.first.id}',
      scheduledTime: scheduledTime,
    );
  }

  /// 显示即时通知
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    DateTime? scheduledTime,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'medication_reminder',
      '用药提醒',
      channelDescription: '药品和保健品服用提醒通知',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.alarm,
      styleInformation: BigTextStyleInformation(body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    if (scheduledTime != null && scheduledTime.isAfter(DateTime.now())) {
      // 定时通知
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } else {
      // 即时通知
      await _notifications.show(id, title, body, details, payload: payload);
    }
  }

  /// 安排重复提醒
  Future<void> scheduleRepeatingReminder({
    required int notificationId,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'medication_reminder',
      '用药提醒',
      channelDescription: '药品和保健品服用提醒通知',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.alarm,
      styleInformation: BigTextStyleInformation(body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      notificationId,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// 取消特定通知
  Future<void> cancelNotification(int notificationId) async {
    await _notifications.cancel(notificationId);
  }

  /// 取消特定药品的所有通知
  /// 由于通知ID是基于药品ID和时间生成的，我们无法直接获取所有通知ID
  /// 这里提供一个占位方法，实际使用中通过数据库查询已调度的提醒来取消
  Future<void> cancelByMedicationId(String medicationId) async {
    // 注意：由于flutter_local_notifications的限制，无法直接根据药品ID取消通知
    // 实际的取消逻辑需要在SchedulerService中实现，遍历该药品的所有提醒时间并取消
    // 这里留空，由调用者负责取消具体通知
  }

  /// 取消所有通知
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// 获取通知权限状态（iOS）
  Future<bool> requestPermissions() async {
    final ios = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    bool? granted;
    if (ios != null) {
      granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    } else if (android != null) {
      granted = await android.requestNotificationsPermission();
    }

    return granted ?? false;
  }

  /// 检查通知权限是否已授权
  Future<bool> checkPermissions() async {
    final ios = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    bool granted = false;
    if (ios != null) {
      // iOS使用checkPermissions
      final result = await ios.checkPermissions();
      granted = result?.isEnabled ?? false;
    } else if (android != null) {
      // Android检查是否启用了通知
      final result = await android.areNotificationsEnabled();
      granted = result ?? false;
    }

    return granted;
  }

  /// 跳转到系统应用通知设置页面
  /// 由于没有合适的跨平台包，这里返回false让用户手动去系统设置
  Future<bool> openNotificationSettings() async {
    // 返回false表示无法自动打开，需要用户手动设置
    return false;
  }

  /// 生成通知ID（基于药品ID和时间戳）
  static int generateNotificationId(String medicationId, DateTime time) {
    // 使用药品ID的hashCode和时间组合生成唯一ID
    final combined = '${medicationId}_${time.millisecondsSinceEpoch}';
    return combined.hashCode.abs() % 2147483647;
  }

  /// 生成合并提醒ID（基于时间）
  static int generateMergedNotificationId(DateTime time) {
    final timeStr =
        '${time.year}_${time.month}_${time.day}_${time.hour}_${time.minute}';
    return timeStr.hashCode.abs() % 2147483647;
  }
}
