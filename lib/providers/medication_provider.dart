import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../db/database_helper.dart';
import '../models/medication.dart';
import '../services/scheduler_service.dart';

/// 药品状态管理Provider
class MedicationProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final Uuid _uuid = const Uuid();

  List<Medication> _activeMedications = [];
  List<Medication> _inactiveMedications = [];
  bool _isLoading = false;
  String? _error;

  List<Medication> get activeMedications => _activeMedications;
  List<Medication> get inactiveMedications => _inactiveMedications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 加载所有药品
  Future<void> loadMedications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final activeMaps = await _db.getMedications(isActive: true);
      final inactiveMaps = await _db.getMedications(isActive: false);

      _activeMedications = activeMaps.map((m) => Medication.fromMap(m)).toList();
      _inactiveMedications =
          inactiveMaps.map((m) => Medication.fromMap(m)).toList();
    } catch (e) {
      _error = '加载药品失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 搜索药品
  Future<List<Medication>> searchMedications(String query) async {
    if (query.isEmpty) {
      return [..._activeMedications, ..._inactiveMedications];
    }

    final maps = await _db.getMedications(searchQuery: query);
    return maps.map((m) => Medication.fromMap(m)).toList();
  }

  /// 添加药品
  Future<Medication?> addMedication({
    required String name,
    required MedicationCategory category,
    required String dosage,
    String? usage,
    required Schedule schedule,
    String? planGroupId,
  }) async {
    try {
      final now = DateTime.now();
      final medication = Medication(
        id: _uuid.v4(),
        name: name,
        category: category,
        dosage: dosage,
        usage: usage,
        schedule: schedule,
        isActive: true,
        createdAt: now,
        updatedAt: now,
        planGroupId: planGroupId,
      );

      await _db.insertMedication(medication.toMap());
      await loadMedications();

      // 等待数据库操作完成后再生成提醒
      await Future.delayed(const Duration(milliseconds: 300));
      // 生成今日提醒记录
      await SchedulerService().scheduleTodayReminders();

      return medication;
    } catch (e) {
      _error = '添加药品失败: $e';
      notifyListeners();
      return null;
    }
  }

  /// 更新药品
  Future<bool> updateMedication(Medication medication) async {
    try {
      final updated = medication.copyWith(updatedAt: DateTime.now());
      await _db.updateMedication(updated.id, updated.toMap());
      await loadMedications();

      // 等待数据库操作完成后再生成提醒
      await Future.delayed(const Duration(milliseconds: 300));
      // 重新生成今日提醒
      await SchedulerService().scheduleTodayReminders();

      return true;
    } catch (e) {
      _error = '更新药品失败: $e';
      notifyListeners();
      return false;
    }
  }

  /// 停用药品
  Future<bool> deactivateMedication(String id) async {
    try {
      final medications = await _db.getMedications();
      final medMap = medications.firstWhere((m) => m['id'] == id);
      final medication = Medication.fromMap(medMap);

      final updated = medication.copyWith(
        isActive: false,
        stoppedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _db.updateMedication(id, updated.toMap());
      await loadMedications();
      return true;
    } catch (e) {
      _error = '停用药品失败: $e';
      notifyListeners();
      return false;
    }
  }

  /// 恢复药品
  Future<bool> reactivateMedication(String id) async {
    try {
      final medications = await _db.getMedications();
      final medMap = medications.firstWhere((m) => m['id'] == id);
      final medication = Medication.fromMap(medMap);

      final updated = medication.copyWith(
        isActive: true,
        stoppedAt: null,
        updatedAt: DateTime.now(),
      );

      await _db.updateMedication(id, updated.toMap());
      await loadMedications();
      return true;
    } catch (e) {
      _error = '恢复药品失败: $e';
      notifyListeners();
      return false;
    }
  }

  /// 删除药品（永久删除）
  Future<bool> deleteMedication(String id) async {
    try {
      await _db.deleteMedication(id);
      await loadMedications();
      return true;
    } catch (e) {
      _error = '删除药品失败: $e';
      notifyListeners();
      return false;
    }
  }

  /// 根据ID获取药品
  Medication? getMedicationById(String id) {
    try {
      return [..._activeMedications, ..._inactiveMedications]
          .firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 创建多天计划
  Future<List<Medication>> createMultiDayPlan({
    required String name,
    required MedicationCategory category,
    required String dosage,
    String? usage,
    required DateTime startDate,
    required int daysCount,
    required List<String> times,
    List<String>? dosages,
  }) async {
    final planGroupId = _uuid.v4();
    final medications = <Medication>[];

    for (var i = 0; i < daysCount; i++) {
      final dayDate = startDate.add(Duration(days: i));
      final dayDosage = dosages != null && i < dosages.length
          ? dosages[i]
          : dosage;

      final schedule = Schedule.multiday(
        dayDate,
        1, // 每天作为单独的一条记录
        times,
        dosages: [dayDosage],
      );

      final medication = await addMedication(
        name: name,
        category: category,
        dosage: dayDosage,
        usage: usage,
        schedule: schedule,
        planGroupId: planGroupId,
      );

      if (medication != null) {
        medications.add(medication);
      }
    }

    // 等待数据库操作完成后再生成提醒
    await Future.delayed(const Duration(milliseconds: 300));
    // 统一生成今日提醒（避免多次调用）
    await SchedulerService().scheduleTodayReminders();

    return medications;
  }
}
