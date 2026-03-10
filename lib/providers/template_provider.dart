import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../db/database_helper.dart';

/// 模板数据模型
class Template {
  final String id;
  final String name;
  final int daysCount;
  final List<String> dosages;
  final DateTime createdAt;

  const Template({
    required this.id,
    required this.name,
    required this.daysCount,
    required this.dosages,
    required this.createdAt,
  });

  factory Template.fromMap(Map<String, dynamic> map) {
    return Template(
      id: map['id'] as String,
      name: map['name'] as String,
      daysCount: map['days_count'] as int,
      dosages: List<String>.from(jsonDecode(map['dosages'] as String)),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'days_count': daysCount,
      'dosages': jsonEncode(dosages),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// 模板状态管理Provider
class TemplateProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final Uuid _uuid = const Uuid();

  List<Template> _templates = [];
  bool _isLoading = false;
  String? _error;

  List<Template> get templates => _templates;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 加载所有模板
  Future<void> loadTemplates() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final maps = await _db.getTemplates();
      _templates = maps.map((m) => Template.fromMap(m)).toList();
    } catch (e) {
      _error = '加载模板失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 添加模板
  Future<Template?> addTemplate({
    required String name,
    required int daysCount,
    required List<String> dosages,
  }) async {
    try {
      final template = Template(
        id: _uuid.v4(),
        name: name,
        daysCount: daysCount,
        dosages: dosages,
        createdAt: DateTime.now(),
      );

      await _db.insertTemplate(template.toMap());
      await loadTemplates();

      return template;
    } catch (e) {
      _error = '保存模板失败: $e';
      notifyListeners();
      return null;
    }
  }

  /// 删除模板
  Future<bool> deleteTemplate(String id) async {
    try {
      await _db.deleteTemplate(id);
      await loadTemplates();
      return true;
    } catch (e) {
      _error = '删除模板失败: $e';
      notifyListeners();
      return false;
    }
  }

  /// 根据ID获取模板
  Template? getTemplateById(String id) {
    try {
      return _templates.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
