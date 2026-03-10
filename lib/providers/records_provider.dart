import 'package:flutter/foundation.dart';
import '../db/database_helper.dart';
import '../models/medication.dart';

/// 记录模块状态管理Provider
class RecordsProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<Record> _records = [];
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = false;
  String? _error;

  // 缓存：药品ID到药品名称的映射
  Map<String, String> _medicationNames = {};

  List<Record> get records => _records;
  DateTime get selectedMonth => _selectedMonth;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 获取有记录的日期集合
  Set<DateTime> get datesWithRecords {
    final dates = <DateTime>{};
    for (var record in _records) {
      final date = DateTime(
        record.scheduledTime.year,
        record.scheduledTime.month,
        record.scheduledTime.day,
      );
      dates.add(date);
    }
    return dates;
  }

  /// 加载指定月份的记录
  Future<void> loadRecordsForMonth(DateTime month) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedMonth = DateTime(month.year, month.month, 1);

      // 获取月份的开始和结束日期
      final startDate = DateTime(month.year, month.month, 1);
      final endDate = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      // 查询记录（包括已停用的药品）
      final maps = await _db.getRecords(
        startDate: startDate,
        endDate: endDate,
      );

      _records = maps.map((m) => Record.fromMap(m)).toList();

      // 加载药品名称映射
      await _loadMedicationNames();
    } catch (e) {
      _error = '加载记录失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 加载药品名称映射
  Future<void> _loadMedicationNames() async {
    final medications = await _db.getMedications();
    _medicationNames = {
      for (var m in medications) m['id'] as String: m['name'] as String
    };
  }

  /// 获取指定日期的记录
  List<Record> getRecordsForDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    return _records.where((record) {
      final recordDate = DateTime(
        record.scheduledTime.year,
        record.scheduledTime.month,
        record.scheduledTime.day,
      );
      return recordDate == targetDate;
    }).toList();
  }

  /// 获取指定日期的记录（带药品名称）
  List<Map<String, dynamic>> getRecordsWithMedicationNames(DateTime date) {
    return getRecordsForDate(date).map((record) {
      return {
        'record': record,
        'medicationName': _medicationNames[record.medicationId] ?? '未知药品',
      };
    }).toList();
  }

  /// 获取指定月份的依从性统计
  Future<Map<String, int>> getComplianceStats({DateTime? startDate, DateTime? endDate}) async {
    try {
      final start = startDate ?? DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final end = endDate ?? DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);

      final maps = await _db.getRecords(
        startDate: start,
        endDate: end,
      );

      final records = maps.map((m) => Record.fromMap(m)).toList();

      int total = records.length;
      int taken = records.where((r) => r.status == RecordStatus.taken).length;
      int skipped = records.where((r) => r.status == RecordStatus.skipped).length;
      int missed = records.where((r) => r.status == RecordStatus.missed).length;
      int pending = records.where((r) => r.status == RecordStatus.pending).length;

      return {
        'total': total,
        'taken': taken,
        'skipped': skipped,
        'missed': missed,
        'pending': pending,
      };
    } catch (e) {
      return {'total': 0, 'taken': 0, 'skipped': 0, 'missed': 0, 'pending': 0};
    }
  }

  /// 计算依从率（已服/总数）
  double getComplianceRate(Map<String, int> stats) {
    final total = stats['total'] ?? 0;
    if (total == 0) return 0.0;
    final taken = stats['taken'] ?? 0;
    return (taken / total) * 100;
  }

  /// 切换到上个月
  void goToPreviousMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    loadRecordsForMonth(_selectedMonth);
  }

  /// 切换到下个月
  void goToNextMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    loadRecordsForMonth(_selectedMonth);
  }

  /// 切换到今天
  void goToToday() {
    _selectedMonth = DateTime.now();
    loadRecordsForMonth(_selectedMonth);
  }

  /// 刷新当前月份数据
  Future<void> refresh() async {
    await loadRecordsForMonth(_selectedMonth);
  }
}
