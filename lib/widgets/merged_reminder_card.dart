import 'package:flutter/material.dart';
import '../models/medication.dart';

/// 合并提醒卡片 - 显示同一时间的多个药品
class MergedReminderCard extends StatelessWidget {
  final DateTime scheduledTime;
  final List<Medication> medications;
  final VoidCallback? onItemTap;
  final VoidCallback? onConfirmAll;
  final VoidCallback? onConfirmOne;
  final VoidCallback? onSkip;
  final VoidCallback? onSnooze;

  const MergedReminderCard({
    super.key,
    required this.scheduledTime,
    required this.medications,
    this.onItemTap,
    this.onConfirmAll,
    this.onConfirmOne,
    this.onSkip,
    this.onSnooze,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部：时间
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTime(scheduledTime),
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
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${medications.length}项',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 药品列表
            ...medications.map((med) {
              final isMedicine = med.category == MedicationCategory.medicine;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: onItemTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isMedicine
                              ? Icons.medication
                              : Icons.egg_alt,
                          size: 20,
                          color: isMedicine
                              ? theme.colorScheme.primary
                              : theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                med.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                med.dosage,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // 操作按钮
            if (onConfirmAll != null ||
                onSkip != null ||
                onSnooze != null) ...[
              const SizedBox(height: 8),
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
                      child: const Text('跳过全部'),
                    ),
                  if (onConfirmAll != null)
                    FilledButton(
                      onPressed: onConfirmAll,
                      child: const Text('全部已服'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
