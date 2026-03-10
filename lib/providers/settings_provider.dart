import 'package:flutter/foundation.dart';
import '../db/database_helper.dart';
import '../services/voice_service.dart';

/// 设置状态管理Provider
class SettingsProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final VoiceService _voiceService = VoiceService();

  bool _voiceEnabled = false;
  bool _medicineVoiceEnabled = false;
  bool _supplementVoiceEnabled = false;
  bool _largeTextMode = false;
  bool _hasAgreedPrivacy = false;
  String? _deviceUuid;
  bool _isLoading = false;

  // Getters
  bool get voiceEnabled => _voiceEnabled;
  bool get medicineVoiceEnabled => _medicineVoiceEnabled;
  bool get supplementVoiceEnabled => _supplementVoiceEnabled;
  bool get largeTextMode => _largeTextMode;
  bool get hasAgreedPrivacy => _hasAgreedPrivacy;
  String? get deviceUuid => _deviceUuid;
  bool get isLoading => _isLoading;

  /// 加载设置
  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      _voiceEnabled = await _getBoolSetting('voice_enabled');
      _medicineVoiceEnabled = await _getBoolSetting('voice_medicine_enabled');
      _supplementVoiceEnabled = await _getBoolSetting('voice_supplement_enabled');
      _largeTextMode = await _getBoolSetting('large_text_mode');
      _hasAgreedPrivacy = await _getBoolSetting('has_agreed_privacy');
      _deviceUuid = await _db.getSetting('device_uuid');

      // 更新语音服务设置
      _voiceService.updateSettings(
        voiceEnabled: _voiceEnabled,
        medicineVoiceEnabled: _medicineVoiceEnabled,
        supplementVoiceEnabled: _supplementVoiceEnabled,
      );
    } catch (e) {
      // 使用默认值
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 获取布尔值设置
  Future<bool> _getBoolSetting(String key) async {
    final value = await _db.getSetting(key);
    return value == 'true';
  }

  /// 设置语音总开关
  Future<void> setVoiceEnabled(bool value) async {
    _voiceEnabled = value;
    await _db.setSetting('voice_enabled', value.toString());
    _voiceService.updateSettings(voiceEnabled: value);
    notifyListeners();
  }

  /// 设置药品语音开关
  Future<void> setMedicineVoiceEnabled(bool value) async {
    _medicineVoiceEnabled = value;
    await _db.setSetting('voice_medicine_enabled', value.toString());
    _voiceService.updateSettings(medicineVoiceEnabled: value);
    notifyListeners();
  }

  /// 设置保健品语音开关
  Future<void> setSupplementVoiceEnabled(bool value) async {
    _supplementVoiceEnabled = value;
    await _db.setSetting('voice_supplement_enabled', value.toString());
    _voiceService.updateSettings(supplementVoiceEnabled: value);
    notifyListeners();
  }

  /// 设置大字模式
  Future<void> setLargeTextMode(bool value) async {
    _largeTextMode = value;
    await _db.setSetting('large_text_mode', value.toString());
    notifyListeners();
  }

  /// 同意隐私政策
  Future<void> agreePrivacy() async {
    _hasAgreedPrivacy = true;
    await _db.setSetting('has_agreed_privacy', 'true');
    notifyListeners();
  }

  /// 检查是否已同意隐私政策
  bool get hasAgreedPrivacyPolicy => _hasAgreedPrivacy;

  /// 获取字体缩放比例
  double get textScaleFactor => _largeTextMode ? 1.5 : 1.0;
}
