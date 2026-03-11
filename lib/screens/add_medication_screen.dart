import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/medication.dart';
import '../providers/medication_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/template_provider.dart';
import '../data/medication_library.dart';
import 'daily_dose_screen.dart';

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
  List<int> _selectedWeekdays = [1, 3, 5]; // 默认周一、三、五
  List<int> _selectedDates = [1, 15]; // 默认1号和15号
  List<TimeOfDay> _reminderTimes = [const TimeOfDay(hour: 8, minute: 0)];
  bool _isMultiDay = false;
  int _multiDayDays = 3;
  DateTime _startDate = DateTime.now();
  bool _useUniformDosage = true; // 统一剂量 vs 逐天设置
  List<String> _dailyDosages = []; // 逐天剂量列表

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
      _scheduleType = med.schedule.type;
      if (_scheduleType == ScheduleType.weekly && med.schedule.days != null) {
        _selectedWeekdays = List.from(med.schedule.days!);
      }
      if (_scheduleType == ScheduleType.monthly && med.schedule.dates != null) {
        _selectedDates = List.from(med.schedule.dates!);
      }
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
    // 隐藏输入法键盘
    FocusScope.of(context).unfocus();

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
    // 先关闭输入法键盘
    FocusScope.of(context).unfocus();
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    );
    if (time != null) {
      setState(() {
        _reminderTimes.add(time);
      });
      // 使用延迟确保在 picker 关闭后焦点被正确移除
      await Future.delayed(Duration.zero);
      FocusScope.of(context).unfocus();
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
    // 先关闭输入法键盘
    FocusScope.of(context).unfocus();
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTimes[index],
    );
    if (time != null) {
      setState(() {
        _reminderTimes[index] = time;
      });
      // 使用延迟确保在 picker 关闭后焦点被正确移除
      await Future.delayed(Duration.zero);
      FocusScope.of(context).unfocus();
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
      // 关闭输入法键盘
      FocusScope.of(context).unfocus();
    }
  }

  /// 打开逐天剂量设置页面
  Future<void> _openDailyDoseScreen() async {
    final result = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (context) => DailyDoseScreen(
          daysCount: _multiDayDays,
          defaultDosage: _dosageController.text.isNotEmpty ? _dosageController.text : '1片',
          initialDosages: _dailyDosages,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _dailyDosages = result;
      });
    }
  }

  /// 打开模板选择弹窗
  Future<void> _showTemplateDialog() async {
    final templateProvider = context.read<TemplateProvider>();
    await templateProvider.loadTemplates();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Consumer<TemplateProvider>(
        builder: (context, provider, child) {
          // 加载中显示加载指示器
          if (provider.isLoading) {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (provider.templates.isEmpty) {
            return const SizedBox(
              height: 200,
              child: Center(child: Text('暂无模板')),
            );
          }
          return ListView.builder(
            shrinkWrap: true,
            itemCount: provider.templates.length,
            itemBuilder: (context, index) {
              final template = provider.templates[index];
              return ListTile(
                title: Text(template.name),
                subtitle: Text('${template.daysCount}天'),
                onTap: () {
                  setState(() {
                    _isMultiDay = true;
                    _multiDayDays = template.daysCount;
                    _dailyDosages = List.from(template.dosages);
                    _useUniformDosage = false;
                  });
                  Navigator.of(context).pop();
                },
              );
            },
          );
        },
      ),
    );
  }

  /// 保存当前设置为模板
  Future<void> _saveAsTemplate() async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('保存为模板'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '模板名称',
            hintText: '如：我的28天计划',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(nameController.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      final templateProvider = context.read<TemplateProvider>();
      final template = await templateProvider.addTemplate(
        name: result,
        daysCount: _multiDayDays,
        dosages: _useUniformDosage
            ? List.generate(_multiDayDays, (_) => _dosageController.text)
            : _dailyDosages,
      );
      if (mounted) {
        if (template != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('模板保存成功')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(templateProvider.error ?? '模板保存失败')),
          );
        }
      }
    }
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<MedicationProvider>();

    // 处理剂量为空的情况，使用默认值
    String dosage = _dosageController.text.trim();
    if (dosage.isEmpty) {
      dosage = '1片'; // 默认剂量
    }

    final times = _reminderTimes
        .map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
        .toList();

    try {
      if (_isEditing) {
        // 编辑模式
        final updated = widget.medication!.copyWith(
          name: _nameController.text,
          category: _category,
          dosage: dosage,
          usage: _usageController.text.isEmpty ? null : _usageController.text,
          schedule: Schedule.daily(times),
        );
        await provider.updateMedication(updated);
      } else if (_isMultiDay) {
        // 创建多天计划
        final dosages = _useUniformDosage || _dailyDosages.isEmpty
            ? List.generate(_multiDayDays, (_) => dosage)
            : _dailyDosages;
        await provider.createMultiDayPlan(
          name: _nameController.text,
          category: _category,
          dosage: dosage,
          usage: _usageController.text.isEmpty ? null : _usageController.text,
          startDate: _startDate,
          daysCount: _multiDayDays,
          times: times,
          dosages: dosages,
        );
      } else {
      // 创建普通提醒
      Schedule schedule;
      switch (_scheduleType) {
        case ScheduleType.daily:
          schedule = Schedule.daily(times);
          break;
        case ScheduleType.weekly:
          schedule = Schedule.weekly(_selectedWeekdays, times);
          break;
        case ScheduleType.monthly:
          schedule = Schedule.monthly(_selectedDates, times);
          break;
        default:
          schedule = Schedule.daily(times);
      }

      await provider.addMedication(
        name: _nameController.text,
        category: _category,
        dosage: dosage,
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
          Navigator.of(context).pop(true);
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
                hintText: '如：1片、2粒（不填时默认为1片）',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                // 剂量可以为空，使用默认值
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
                          ? () => setState(() {
                              _multiDayDays--;
                              // 清除逐天剂量，保持一致
                              _dailyDosages.clear();
                            })
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _multiDayDays < 7
                          ? () => setState(() {
                              _multiDayDays++;
                              _dailyDosages.clear();
                            })
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // 剂量模式选择
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('统一剂量'),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('逐天设置'),
                  ),
                ],
                selected: {_useUniformDosage},
                onSelectionChanged: (selection) {
                  setState(() {
                    _useUniformDosage = selection.first;
                  });
                },
              ),
              const SizedBox(height: 8),
              // 逐天剂量设置按钮
              if (!_useUniformDosage)
                ListTile(
                  title: const Text('每日剂量'),
                  subtitle: Text(
                    _dailyDosages.isEmpty
                        ? '点击设置每天的剂量'
                        : _dailyDosages.join('、'),
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: _openDailyDoseScreen,
                ),
              const SizedBox(height: 8),
              // 模板按钮
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showTemplateDialog,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('使用模板'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saveAsTemplate,
                      icon: const Icon(Icons.save),
                      label: const Text('保存模板'),
                    ),
                  ),
                ],
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
            const SizedBox(height: 16),

            // 重复类型选择（仅在非多天计划时显示）
            if (!_isMultiDay) ...[
              const Text(
                '重复类型',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<ScheduleType>(
                segments: const [
                  ButtonSegment(
                    value: ScheduleType.daily,
                    label: Text('每日'),
                    icon: Icon(Icons.today),
                  ),
                  ButtonSegment(
                    value: ScheduleType.weekly,
                    label: Text('每周'),
                    icon: Icon(Icons.calendar_view_week),
                  ),
                  ButtonSegment(
                    value: ScheduleType.monthly,
                    label: Text('每月'),
                    icon: Icon(Icons.calendar_month),
                  ),
                ],
                selected: {_scheduleType},
                onSelectionChanged: (value) {
                  setState(() {
                    _scheduleType = value.first;
                  });
                },
              ),
              const SizedBox(height: 16),

              // 每周选择（选择星期几）
              if (_scheduleType == ScheduleType.weekly) ...[
                const Text(
                  '选择星期',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (int i = 1; i <= 7; i++)
                      FilterChip(
                        label: Text(['周一', '周二', '周三', '周四', '周五', '周六', '周日'][i - 1]),
                        selected: _selectedWeekdays.contains(i),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedWeekdays.add(i);
                            } else if (_selectedWeekdays.length > 1) {
                              _selectedWeekdays.remove(i);
                            }
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // 每月选择（选择日期）
              if (_scheduleType == ScheduleType.monthly) ...[
                const Text(
                  '选择日期',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 150,
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (int i = 1; i <= 31; i++)
                          FilterChip(
                            label: Text('$i'),
                            selected: _selectedDates.contains(i),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedDates.add(i);
                                  _selectedDates.sort();
                                } else if (_selectedDates.length > 1) {
                                  _selectedDates.remove(i);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],

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
