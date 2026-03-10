import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/medication.dart';
import '../providers/medication_provider.dart';
import '../providers/reminder_provider.dart';
import 'add_medication_screen.dart';
import 'medication_detail_screen.dart';

/// 药品分组（多天计划合并显示）
class _MedicationGroup {
  final List<Medication> medications;
  final String? subtitle;

  _MedicationGroup({
    required this.medications,
    this.subtitle,
  });
}

/// 药箱页面 - 药品列表管理
class MedicineBoxScreen extends StatefulWidget {
  const MedicineBoxScreen({super.key});

  @override
  State<MedicineBoxScreen> createState() => _MedicineBoxScreenState();
}

class _MedicineBoxScreenState extends State<MedicineBoxScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    await context.read<MedicationProvider>().loadMedications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('药箱'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAdd(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索药品名称',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // 药品列表
          Expanded(
            child: Consumer<MedicationProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final activeMeds = provider.activeMedications;
                final inactiveMeds = provider.inactiveMedications;

                // 过滤搜索结果
                List<Medication> filteredActive = activeMeds;
                List<Medication> filteredInactive = inactiveMeds;

                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.toLowerCase();
                  filteredActive = activeMeds
                      .where((m) => m.name.toLowerCase().contains(query))
                      .toList();
                  filteredInactive = inactiveMeds
                      .where((m) => m.name.toLowerCase().contains(query))
                      .toList();
                }

                if (filteredActive.isEmpty && filteredInactive.isEmpty) {
                  return _EmptyState(
                    onAddPressed: () => _navigateToAdd(),
                  );
                }

                // 按 planGroupId 分组（多天计划合并显示）
                final groupedActive = _groupMedications(filteredActive);
                final groupedInactive = _groupMedications(filteredInactive);

                return RefreshIndicator(
                  onRefresh: _loadMedications,
                  child: ListView(
                    children: [
                      // 活跃项目
                      if (groupedActive.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            '活跃项目 (${groupedActive.length})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ...groupedActive.map((item) => _MedicationListTile(
                              medication: item.medications.first,
                              subtitle: item.subtitle,
                              onTap: () => _navigateToDetail(item.medications.first.id),
                              onDelete: () => _deleteMedication(item.medications.first.id),
                            )),
                      ],

                      // 已停用项目
                      if (groupedInactive.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ExpansionTile(
                          title: Text(
                            '已停用项目 (${groupedInactive.length})',
                            style: theme.textTheme.titleMedium,
                          ),
                          children: groupedInactive.map((item) => _MedicationListTile(
                                medication: item.medications.first,
                                subtitle: item.subtitle,
                                isInactive: true,
                                onTap: () => _navigateToDetail(item.medications.first.id),
                                onDelete: () => _deleteMedication(item.medications.first.id),
                                onRestore: () => _restoreMedication(item.medications.first.id),
                              )).toList(),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAdd() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddMedicationScreen(),
      ),
    );
  }

  void _navigateToDetail(String medicationId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MedicationDetailScreen(medicationId: medicationId),
      ),
    );
  }

  /// 药品分组（多天计划合并显示）
  List<_MedicationGroup> _groupMedications(List<Medication> medications) {
    final Map<String, _MedicationGroup> groups = {};

    for (var med in medications) {
      final key = med.planGroupId ?? med.id;
      if (groups.containsKey(key)) {
        groups[key]!.medications.add(med);
      } else {
        // 计算副标题（显示计划天数）
        String? subtitle;
        if (med.planGroupId != null) {
          subtitle = '${med.schedule.daysCount ?? 1}天计划';
        }
        groups[key] = _MedicationGroup(
          medications: [med],
          subtitle: subtitle,
        );
      }
    }

    return groups.values.toList();
  }

  Future<void> _deleteMedication(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text(
          '此操作将永久删除该项目及其所有历史记录，无法恢复。是否确认？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final medicationProvider = context.read<MedicationProvider>();
      final reminderProvider = context.read<ReminderProvider>();
      await medicationProvider.deleteMedication(id);
      // 刷新首页提醒
      await reminderProvider.loadTodayReminders();
      await reminderProvider.loadCompletedReminders();
    }
  }

  Future<void> _restoreMedication(String id) async {
    final medicationProvider = context.read<MedicationProvider>();
    final reminderProvider = context.read<ReminderProvider>();
    await medicationProvider.reactivateMedication(id);
    // 刷新数据以确保UI更新
    await medicationProvider.loadMedications();
    // 刷新首页提醒
    await reminderProvider.loadTodayReminders();
    await reminderProvider.loadCompletedReminders();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已恢复')),
      );
    }
  }
}

/// 药品列表项组件
class _MedicationListTile extends StatelessWidget {
  final Medication medication;
  final String? subtitle;
  final bool isInactive;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;

  const _MedicationListTile({
    required this.medication,
    this.subtitle,
    this.isInactive = false,
    this.onTap,
    this.onDelete,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMedicine = medication.category == MedicationCategory.medicine;

    return Dismissible(
      key: Key(medication.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认删除'),
            content: const Text(
              '此操作将永久删除该项目及其所有历史记录，无法恢复。是否确认？',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('删除'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isMedicine
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isMedicine ? Icons.medication : Icons.egg_alt,
            color: isMedicine
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSecondaryContainer,
          ),
        ),
        title: Text(
          medication.name,
          style: TextStyle(
            color: isInactive ? theme.colorScheme.outline : null,
          ),
        ),
        subtitle: Text(
          subtitle ?? medication.dosage,
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: isInactive
            ? TextButton(
                onPressed: onRestore,
                child: const Text('恢复'),
              )
            : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

/// 空状态组件
class _EmptyState extends StatelessWidget {
  final VoidCallback? onAddPressed;

  const _EmptyState({this.onAddPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 80,
            color: theme.colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无药品',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '添加您的第一个药品',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAddPressed,
            icon: const Icon(Icons.add),
            label: const Text('添加药品'),
          ),
        ],
      ),
    );
  }
}
