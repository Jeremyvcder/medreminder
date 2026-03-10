import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/medication.dart';
import '../providers/medication_provider.dart';
import '../providers/reminder_provider.dart';
import '../data/medication_library.dart';

/// 添加药品页面
class AddMedicationScreen extends StatefulWidget {
  final Medication? medication; // 编辑模式时传入

  const AddMedicationScreen({super.key, this.medication});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _usageController = TextEditingController();

  MedicationCategory _category = MedicationCategory.medicine;
  ScheduleType _scheduleType = ScheduleType.daily;
  List<TimeOfDay> _reminderTimes = [const TimeOfDay(hour: 8, minute: 0)];
  bool _isMultiDay = false;
  int _multiDayDays = 3;
  DateTime _startDate = DateTime.now();

  List<MedicationInfo> _searchResults = [];
  bool _isSearching = false;
  bool get _isEditing => widget.medication != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final med = widget.medication!;
      _nameController.text = med.name;
      _dosageController.text = med.dosage;
      _usageController.text = med.usage ?? '';
      _category = med.category;
      _isMultiDay = med.schedule.type == ScheduleType.multiday;
      if (_isMultiDay) {
        _startDate = med.schedule.startDate ?? DateTime.now();
        _multiDayDays = med.schedule.daysCount ?? 1;
      }
      // 解析提醒时间
      _reminderTimes = med.schedule.times.map((t) {
        final parts = t.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }).toList();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _usageController.dispose();
    super.dispose();
  }

  void _searchMedications(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (_isSearching) {
        _searchResults = MedicationLibrary.search(query);
      }
    });
  }

  void _selectMedication(MedicationInfo info) {
    setState(() {
      _nameController.text = info.name;
      _dosageController.text = info.defaultDosage;
      _usageController.text = info.defaultUsage;
      _category = info.category == MedicationLibrary.categoryMedicine
          ? MedicationCategory.medicine
          : MedicationCategory.supplement;
      _isSearching = false;
    });
  }

  Future<void> _addReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    );
    if (time != null) {
      setState(() {
        _reminderTimes.add(time);
      });
    }
  }

  void _removeReminderTime(int index) {
    if (_reminderTimes.length > 1) {
      setState(() {
        _reminderTimes.removeAt(index);
      });
    }
  }

  /// 编辑提醒时间
  Future<void> _editReminderTime(int index) async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTimes[index],
    );
    if (time != null) {
      setState(() {
        _reminderTimes[index] = time;
      });
    }
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<MedicationProvider>();

    final times = _reminderTimes
        .map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
        .toList();

    try {
      if (_isEditing) {
        // 编辑模式
        final updated = widget.medication!.copyWith(
          name: _nameController.text,
          category: _category,
          dosage: _dosageController.text,
          usage: _usageController.text.isEmpty ? null : _usageController.text,
          schedule: Schedule.daily(times),
        );
        await provider.updateMedication(updated);
      } else if (_isMultiDay) {
        // 创建多天计划
        await provider.createMultiDayPlan(
          name: _nameController.text,
          category: _category,
          dosage: _dosageController.text,
          usage: _usageController.text.isEmpty ? null : _usageController.text,
          startDate: _startDate,
          daysCount: _multiDayDays,
          times: times,
        );
      } else {
      // 创建普通提醒
      Schedule schedule;
      switch (_scheduleType) {
        case ScheduleType.daily:
          schedule = Schedule.daily(times);
          break;
        case ScheduleType.weekly:
          schedule = Schedule.weekly([1, 3, 5], times); // 默认周一三五
          break;
        case ScheduleType.monthly:
          schedule = Schedule.monthly([1, 15], times); // 默认1号和15号
          break;
        default:
          schedule = Schedule.daily(times);
      }

      await provider.addMedication(
        name: _nameController.text,
        category: _category,
        dosage: _dosageController.text,
        usage: _usageController.text.isEmpty ? null : _usageController.text,
        schedule: schedule,
      );
    }
    } catch (e) {
      // 保存失败时显示错误
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
      return;
    } finally {
      // 刷新首页数据，确保提醒加载完成后再返回
      if (mounted) {
        await context.read<ReminderProvider>().loadTodayReminders();
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isEditing ? '保存成功' : '添加成功')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑药品' : '添加药品'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 搜索框（内置药品库）
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '药品名称',
                hintText: '搜索或输入药品名称',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _searchMedications,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入药品名称';
                }
                return null;
              },
            ),

            // 搜索结果
            if (_isSearching && _searchResults.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final item = _searchResults[index];
                    return ListTile(
                      title: Text(item.name),
                      subtitle: Text('${item.defaultDosage} • ${item.defaultUsage}'),
                      trailing: Icon(
                        item.category == MedicationLibrary.categoryMedicine
                            ? Icons.medication
                            : Icons.egg_alt,
                      ),
                      onTap: () => _selectMedication(item),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),

            // 品类选择
            Text(
              '品类',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SegmentedButton<MedicationCategory>(
              segments: const [
                ButtonSegment(
                  value: MedicationCategory.medicine,
                  label: Text('药品'),
                  icon: Icon(Icons.medication),
                ),
                ButtonSegment(
                  value: MedicationCategory.supplement,
                  label: Text('保健品'),
                  icon: Icon(Icons.egg_alt),
                ),
              ],
              selected: {_category},
              onSelectionChanged: (selection) {
                setState(() {
                  _category = selection.first;
                });
              },
            ),
            const SizedBox(height: 16),

            // 剂量
            TextFormField(
              controller: _dosageController,
              decoration: InputDecoration(
                labelText: '剂量',
                hintText: '如：1片、2粒',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入剂量';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 用法
            TextFormField(
              controller: _usageController,
              decoration: InputDecoration(
                labelText: '用法（可选）',
                hintText: '如：餐后、睡前、空腹',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 多天计划开关
            SwitchListTile(
              title: const Text('多天用药计划'),
              subtitle: const Text('创建连续多天的提醒'),
              value: _isMultiDay,
              onChanged: (value) {
                setState(() {
                  _isMultiDay = value;
                });
              },
            ),

            if (_isMultiDay) ...[
              const SizedBox(height: 16),
              // 起始日期
              ListTile(
                title: const Text('起始日期'),
                subtitle: Text(
                  '${_startDate.year}年${_startDate.month}月${_startDate.day}日',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectStartDate,
              ),
              const SizedBox(height: 8),
              // 持续天数
              ListTile(
                title: const Text('持续天数'),
                subtitle: Text('$_multiDayDays 天'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: _multiDayDays > 1
                          ? () => setState(() => _multiDayDays--)
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _multiDayDays < 7
                          ? () => setState(() => _multiDayDays++)
                          : null,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // 提醒时间
            Text(
              '提醒时间',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ..._reminderTimes.asMap().entries.map((entry) {
              final index = entry.key;
              final time = entry.value;
              return ListTile(
                leading: const Icon(Icons.access_time),
                title: Text('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editReminderTime(index),
                    ),
                    if (_reminderTimes.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeReminderTime(index),
                      ),
                  ],
                ),
                onTap: () => _editReminderTime(index),
              );
            }),
            TextButton.icon(
              onPressed: _addReminderTime,
              icon: const Icon(Icons.add),
              label: const Text('添加提醒时间'),
            ),
            const SizedBox(height: 24),

            // 保存按钮
            FilledButton(
              onPressed: _saveMedication,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
