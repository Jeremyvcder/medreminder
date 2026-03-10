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
  /// [scheduleReminder] 是否立即生成提醒，批量添加时设为false以提高性能
  Future<Medication?> addMedication({
    required String name,
    required MedicationCategory category,
    required String dosage,
    String? usage,
    required Schedule schedule,
    String? planGroupId,
    bool scheduleReminder = true,
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

      // 批量添加时跳过单独的提醒生成，由调用方统一处理
      if (scheduleReminder) {
        // 等待数据库操作完成后再生成提醒
        await Future.delayed(const Duration(milliseconds: 300));
        // 生成今日提醒记录
        await SchedulerService().scheduleTodayReminders();
      }

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

      // 删除该药品的所有pending记录，避免重复
      await _db.deletePendingRecordsByMedicationId(medication.id);

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
  /// 如果是多天计划（planGroupId不为空），则停用整个计划组
  Future<bool> deactivateMedication(String id) async {
    try {
      final medications = await _db.getMedications();
      final medMap = medications.firstWhere((m) => m['id'] == id);
      final medication = Medication.fromMap(medMap);

      // 检查是否是的多天计划
      final isMultiDay = medication.planGroupId != null;
      List<Medication> medsToDeactivate = [medication];

      if (isMultiDay) {
        // 多天计划，停用整个计划组
        medsToDeactivate = medications
            .where((m) => m['plan_group_id'] == medication.planGroupId)
            .map((m) => Medication.fromMap(m))
            .toList();
      }

      // 创建SchedulerService实例并取消每个药品的未来通知
      final schedulerService = SchedulerService();
      for (var med in medsToDeactivate) {
        await schedulerService.cancelMedicationReminders(med.id);
      }

      // 更新每个药品的停用历史
      final now = DateTime.now();
      for (var med in medsToDeactivate) {
        // 获取当前历史记录
        final history = med.stoppedHistory ?? [];

        // 添加新的停用记录
        final newHistory = [
          ...history,
          StoppedHistoryItem(time: now, action: 'deactivate'),
        ];

        final updated = med.copyWith(
          isActive: false,
          stoppedHistory: newHistory,
          updatedAt: now,
        );

        await _db.updateMedication(med.id, updated.toMap());
      }

      await loadMedications();
      return true;
    } catch (e) {
      _error = '停用药品失败: $e';
      notifyListeners();
      return false;
    }
  }

  /// 恢复药品
  /// 如果是多天计划（planGroupId不为空），则恢复整个计划组
  Future<bool> reactivateMedication(String id) async {
    try {
      final medications = await _db.getMedications();
      final medMap = medications.firstWhere((m) => m['id'] == id);
      final medication = Medication.fromMap(medMap);

      // 检查是否是的多天计划
      final isMultiDay = medication.planGroupId != null;
      List<Medication> medsToReactivate = [medication];

      if (isMultiDay) {
        // 多天计划，恢复整个计划组
        medsToReactivate = medications
            .where((m) => m['plan_group_id'] == medication.planGroupId)
            .map((m) => Medication.fromMap(m))
            .toList();
      }

      // 创建SchedulerService实例
      final schedulerService = SchedulerService();

      // 更新每个药品的恢复历史
      final now = DateTime.now();
      for (var med in medsToReactivate) {
        // 获取当前历史记录
        final history = med.stoppedHistory ?? [];

        // 添加新的恢复记录
        final newHistory = [
          ...history,
          StoppedHistoryItem(time: now, action: 'reactivate'),
        ];

        final updated = med.copyWith(
          isActive: true,
          stoppedHistory: newHistory,
          updatedAt: now,
        );

        await _db.updateMedication(med.id, updated.toMap());

        // 恢复后重新调度提醒（当天触发逻辑在SchedulerService中处理）
        await schedulerService.scheduleReminderForMedication(med.id);
      }

      await loadMedications();
      return true;
    } catch (e) {
      _error = '恢复药品失败: $e';
      notifyListeners();
      return false;
    }
  }

  /// 删除药品（永久删除）
  /// 如果是多天计划，会删除整个计划组的所有药品
  Future<bool> deleteMedication(String id) async {
    try {
      // 先获取药品信息，检查是否是的多天计划
      final medication = getMedicationById(id);
      if (medication != null && medication.planGroupId != null) {
        // 多天计划，删除整个计划组
        await _db.deleteMedicationsByPlanGroupId(medication.planGroupId!);
      } else {
        // 普通药品，只删除单个
        await _db.deleteMedication(id);
      }
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
        daysCount, // 计划的总天数
        times,
        dosages: [dayDosage],
      );

      // 批量添加时不单独生成提醒
      final medication = await addMedication(
        name: name,
        category: category,
        dosage: dayDosage,
        usage: usage,
        schedule: schedule,
        planGroupId: planGroupId,
        scheduleReminder: false,
      );

      if (medication != null) {
        medications.add(medication);
      }
    }

    // 统一生成今日提醒（只调用一次）
    await Future.delayed(const Duration(milliseconds: 100));
    await SchedulerService().scheduleTodayReminders();

    return medications;
  }
}
