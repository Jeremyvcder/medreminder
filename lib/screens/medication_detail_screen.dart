import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/medication.dart';
import '../providers/medication_provider.dart';
import '../providers/reminder_provider.dart';
import 'add_medication_screen.dart';

/// 药品详情页面
class MedicationDetailScreen extends StatefulWidget {
  final String medicationId;

  const MedicationDetailScreen({
    super.key,
    required this.medicationId,
  });

  @override
  State<MedicationDetailScreen> createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends State<MedicationDetailScreen> {
  Medication? _medication;

  @override
  void initState() {
    super.initState();
    _loadMedication();
  }

  void _loadMedication() {
    final provider = context.read<MedicationProvider>();
    setState(() {
      _medication = provider.getMedicationById(widget.medicationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_medication == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('药品不存在'),
        ),
      );
    }

    final medication = _medication!;
    final isMedicine = medication.category == MedicationCategory.medicine;

    return Scaffold(
      appBar: AppBar(
        title: Text(medication.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEdit(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 药品信息卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 品类标签
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isMedicine
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isMedicine ? '药品' : '保健品',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isMedicine
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 名称
                  Text(
                    medication.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 剂量
                  _InfoRow(
                    icon: Icons.straighten,
                    label: '剂量',
                    value: medication.dosage,
                  ),

                  // 用法
                  if (medication.usage != null) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.info_outline,
                      label: '用法',
                      value: medication.usage!,
                    ),
                  ],

                  // 提醒时间
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.access_time,
                    label: '提醒时间',
                    value: medication.schedule.times.join('、'),
                  ),

                  // 状态
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: medication.isActive
                        ? Icons.check_circle
                        : Icons.pause_circle,
                    label: '状态',
                    value: medication.isActive ? '活跃' : '已停用',
                    valueColor:
                        medication.isActive ? Colors.green : Colors.orange,
                  ),

                  // 停用日期
                  if (medication.lastStoppedAt != null) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.calendar_today,
                      label: '停用日期',
                      value: _formatDate(medication.lastStoppedAt!),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 操作按钮
          if (medication.isActive)
            OutlinedButton(
              onPressed: () => _deactivateMedication(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text('停用'),
              ),
            )
          else
            FilledButton(
              onPressed: () => _reactivateMedication(),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text('恢复'),
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _deleteMedication(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text('永久删除'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  void _navigateToEdit() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddMedicationScreen(medication: _medication),
      ),
    );
  }

  Future<void> _deactivateMedication() async {
    // 检查是否是的多天计划
    final isMultiDay = _medication?.planGroupId != null;

    String contentText;
    if (isMultiDay) {
      contentText = '这是多天用药计划，停用将同时停用所有相关药品。停用后将不再提醒，但历史记录会保留。您可在药箱底部的"已停用项目"中恢复。是否确认停用？';
    } else {
      contentText = '停用后将不再提醒，但历史记录会保留。您可在药箱底部的"已停用项目"中恢复。是否确认停用？';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认停用'),
        content: Text(contentText),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认停用'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final medicationProvider = context.read<MedicationProvider>();
      final reminderProvider = context.read<ReminderProvider>();
      await medicationProvider.deactivateMedication(widget.medicationId);
      // 刷新数据后再获取最新状态
      await medicationProvider.loadMedications();
      // 刷新首页提醒
      await reminderProvider.loadTodayReminders();
      await reminderProvider.loadCompletedReminders();
      _medication = medicationProvider.getMedicationById(widget.medicationId);
      if (mounted) setState(() {});
    }
  }

  Future<void> _reactivateMedication() async {
    // 检查是否是的多天计划
    final isMultiDay = _medication?.planGroupId != null;

    String contentText;
    if (isMultiDay) {
      contentText = '这是多天用药计划，恢复将同时恢复所有相关药品。恢复后将重新开始提醒。是否确认恢复？';
    } else {
      contentText = '恢复后将重新开始提醒。是否确认恢复？';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认恢复'),
        content: Text(contentText),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认恢复'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final medicationProvider = context.read<MedicationProvider>();
      final reminderProvider = context.read<ReminderProvider>();
      await medicationProvider.reactivateMedication(widget.medicationId);
      // 刷新数据后再获取最新状态
      await medicationProvider.loadMedications();
      // 刷新首页提醒
      await reminderProvider.loadTodayReminders();
      await reminderProvider.loadCompletedReminders();
      _medication = medicationProvider.getMedicationById(widget.medicationId);
      if (mounted) setState(() {});
    }
  }

  Future<void> _deleteMedication() async {
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
      await medicationProvider.deleteMedication(widget.medicationId);
      // 刷新首页提醒
      await reminderProvider.loadTodayReminders();
      await reminderProvider.loadCompletedReminders();
      Navigator.of(context).pop();
    }
  }
}

/// 信息行组件
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
