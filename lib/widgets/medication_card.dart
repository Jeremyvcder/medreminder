import 'package:flutter/material.dart';
import '../models/medication.dart';

/// 药品卡片组件 - 显示单个药品信息
class MedicationCard extends StatelessWidget {
  final Medication medication;
  final DateTime? scheduledTime;
  final VoidCallback? onTap;
  final VoidCallback? onConfirm;
  final VoidCallback? onSkip;
  final VoidCallback? onSnooze;

  const MedicationCard({
    super.key,
    required this.medication,
    this.scheduledTime,
    this.onTap,
    this.onConfirm,
    this.onSkip,
    this.onSnooze,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMedicine = medication.category == MedicationCategory.medicine;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部：时间和品类标签
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (scheduledTime != null)
                    Text(
                      _formatTime(scheduledTime!),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isMedicine
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isMedicine ? '药品' : '保健品',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isMedicine
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 药品名称和剂量
              Text(
                medication.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                medication.dosage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (medication.usage != null) ...[
                const SizedBox(height: 2),
                Text(
                  medication.usage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],

              // 操作按钮
              if (onConfirm != null || onSkip != null || onSnooze != null) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onSnooze != null)
                      TextButton(
                        onPressed: onSnooze,
                        child: const Text('稍后'),
                      ),
                    if (onSkip != null)
                      TextButton(
                        onPressed: onSkip,
                        child: const Text('跳过'),
                      ),
                    if (onConfirm != null)
                      FilledButton(
                        onPressed: onConfirm,
                        child: const Text('已服'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
