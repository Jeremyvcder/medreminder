import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';

/// 语音播报服务 - 使用TTS引擎播报服药提醒
class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  /// 定时任务存储的数据（alarmId -> data）
  static final Map<int, Map<String, dynamic>> _scheduledData = {};

  /// 存储定时任务数据
  static void setScheduledData(int alarmId, Map<String, dynamic> data) {
    _scheduledData[alarmId] = data;
  }

  /// 定时播报回调（供android_alarm_manager调用）
  static Future<void> scheduledCallback(int alarmId) async {
    print('定时语音回调触发: alarmId=$alarmId');
    try {
      final data = _scheduledData[alarmId];
      if (data == null) {
        print('未找到定时任务数据: $alarmId');
        return;
      }

      // 清理数据
      _scheduledData.remove(alarmId);

      final type = data['type'] as String;

      final voiceService = VoiceService();

      // 确保TTS已初始化
      await voiceService.initialize();

      if (type == 'single') {
        final medData = data['data'] as Map<String, dynamic>;
        await voiceService.speakMedicationReminder(
          medicationName: medData['name'] as String,
          dosage: medData['dosage'] as String,
          isMedicine: medData['isMedicine'] == 'true',
        );
      } else if (type == 'merged') {
        final medsData = data['data'] as List<dynamic>;
        final medications = medsData.map((m) => {
          'name': (m as Map<String, dynamic>)['name'] as String,
          'dosage': m['dosage'] as String,
          'isMedicine': m['isMedicine'] as String,
        }).toList();
        await voiceService.speakMergedReminder(medications: medications);
      }
    } catch (e) {
      print('定时语音回调执行失败: $e');
    }
  }

  // 语音设置
  bool _voiceEnabled = true;
  bool _medicineVoiceEnabled = true;
  bool _supplementVoiceEnabled = true;

  /// 初始化TTS引擎
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 设置引擎启动回调
      _tts.setStartHandler(() {
        print('TTS引擎已启动');
      });

      // 尝试设置语言（可能失败因为引擎未绑定，但不影响后续使用）
      try {
        var isAvailable = await _tts.isLanguageAvailable('zh-CN');
        print('TTS中文支持状态: $isAvailable');
        if (isAvailable == 1 || isAvailable == 0) {
          await _tts.setLanguage('zh-CN');
        } else {
          print('使用系统默认语言');
        }
      } catch (e) {
        print('TTS语言设置失败: $e');
      }

      // 设置语音参数
      try {
        await _tts.setSpeechRate(0.5);
        await _tts.setVolume(1.0);
        await _tts.setPitch(1.0);
      } catch (e) {
        print('TTS参数设置失败: $e');
      }

      // 播报完成回调
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        print('TTS播报完成');
      });

      // 错误回调
      _tts.setErrorHandler((message) {
        print('TTS错误: $message');
        _isSpeaking = false;
      });

      _isInitialized = true;
      print('TTS初始化成功');
    } catch (e) {
      // TTS初始化失败不影响App运行
      print('TTS初始化失败: $e');
    }
  }

  /// 更新语音设置
  void updateSettings({
    bool? voiceEnabled,
    bool? medicineVoiceEnabled,
    bool? supplementVoiceEnabled,
  }) {
    if (voiceEnabled != null) _voiceEnabled = voiceEnabled;
    if (medicineVoiceEnabled != null) {
      _medicineVoiceEnabled = medicineVoiceEnabled;
    }
    if (supplementVoiceEnabled != null) {
      _supplementVoiceEnabled = supplementVoiceEnabled;
    }
  }

  /// 检查是否在免打扰时段（24:00 - 08:00）
  bool isInQuietHours() {
    final now = DateTime.now();
    final hour = now.hour;
    // 0-8点为免打扰时段
    return hour >= 0 && hour < 8;
  }

  /// 播报服药提醒
  Future<void> speakMedicationReminder({
    required String medicationName,
    required String dosage,
    required bool isMedicine, // true=药品, false=保健品
  }) async {
    // 检查语音开关
    if (!_voiceEnabled) return;

    // 检查品类开关
    if (isMedicine && !_medicineVoiceEnabled) return;
    if (!isMedicine && !_supplementVoiceEnabled) return;

    // 检查免打扰时段
    if (isInQuietHours()) return;

    // 确保TTS已初始化
    if (!_isInitialized) {
      await initialize();
    }

    // 停止当前播报
    await stop();

    // 播报内容
    final text = '请服用$medicationName，$dosage';
    await _speak(text);
  }

  /// 播报合并提醒（多个药品）
  Future<void> speakMergedReminder({
    required List<Map<String, String>> medications, // [{name, dosage, isMedicine}]
  }) async {
    // 检查语音开关
    if (!_voiceEnabled) return;

    // 检查是否有需要播报的药品
    bool hasMedicineToSpeak = false;
    for (var med in medications) {
      final isMedicine = med['isMedicine'] == 'true';
      if (isMedicine && _medicineVoiceEnabled) hasMedicineToSpeak = true;
      if (!isMedicine && _supplementVoiceEnabled) hasMedicineToSpeak = true;
    }

    if (!hasMedicineToSpeak) return;

    // 检查免打扰时段
    if (isInQuietHours()) return;

    // 确保TTS已初始化
    if (!_isInitialized) {
      await initialize();
    }

    // 停止当前播报
    await stop();

    // 构建播报内容
    final buffer = StringBuffer('请服用');
    for (var i = 0; i < medications.length; i++) {
      final med = medications[i];
      if (i > 0) {
        buffer.write('、');
      }
      buffer.write('${med['name']}${med['dosage']}');
    }
    await _speak(buffer.toString());
  }

  /// 执行实际播报
  Future<void> _speak(String text) async {
    print('语音播报开始: $text, voiceEnabled=$_voiceEnabled, isInitialized=$_isInitialized');
    try {
      if (_isSpeaking) {
        await _tts.stop();
      }

      // 确保等待上一次的播报完成
      await _tts.awaitSpeakCompletion(true);

      _isSpeaking = true;
      var result = await _tts.speak(text);
      print('TTS speak返回: $result');

      if (result == 1) {
        print('语音播报成功');
      } else {
        print('语音播报失败，返回码: $result');
      }
    } catch (e) {
      // 打印错误日志便于调试
      print('语音播报错误: $e');
      _isSpeaking = false;
    }
  }

  /// 停止播报
  Future<void> stop() async {
    if (_isSpeaking) {
      await _tts.stop();
      _isSpeaking = false;
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    await _tts.stop();
    _isInitialized = false;
  }
}
