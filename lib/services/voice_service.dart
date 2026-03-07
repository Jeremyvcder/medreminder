import 'package:flutter_tts/flutter_tts.dart';

/// 语音播报服务 - 使用TTS引擎播报服药提醒
class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  // 语音设置
  bool _voiceEnabled = true;
  bool _medicineVoiceEnabled = true;
  bool _supplementVoiceEnabled = true;

  /// 初始化TTS引擎
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _tts.setLanguage('zh-CN');
    await _tts.setSpeechRate(0.5); // 语速适中
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    // 播报完成回调
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
    });

    _isInitialized = true;
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
    if (_isSpeaking) {
      await _tts.stop();
    }
    _isSpeaking = true;
    await _tts.speak(text);
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
