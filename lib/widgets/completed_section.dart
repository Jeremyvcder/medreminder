import 'package:flutter/material.dart';
import '../models/medication.dart';

/// 已完成区域组件 - 显示折叠的已完成提醒
class CompletedSection extends StatelessWidget {
  final List<Map<String, dynamic>> completedItems;
  final VoidCallback? onItemTap;

  const CompletedSection({
    super.key,
    required this.completedItems,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (completedItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return ExpansionTile(
      leading: Icon(
        Icons.check_circle,
        color: theme.colorScheme.primary,
      ),
      title: Text(
        '已完成 (${completedItems.length})',
        style: theme.textTheme.titleMedium,
      ),
      children: completedItems.map((item) {
        final record = Record.fromMap(item['record']);
        final medication = Medication.fromMap(item['medication']);

        IconData icon;
        Color iconColor;
        String statusText;

        switch (record.status) {
          case RecordStatus.taken:
            icon = Icons.check_circle;
            iconColor = Colors.green;
            statusText = '已服';
            break;
          case RecordStatus.skipped:
            icon = Icons.cancel;
            iconColor = Colors.orange;
            statusText = '已跳过';
            break;
          case RecordStatus.missed:
            icon = Icons.error;
            iconColor = Colors.red;
            statusText = '错过';
            break;
          default:
            icon = Icons.help;
            iconColor = Colors.grey;
            statusText = '未知';
        }

        return ListTile(
          leading: Icon(icon, color: iconColor),
          title: Text(medication.name),
          subtitle: Text(
            '${medication.dosage} • ${_formatTime(record.scheduledTime)}',
            style: theme.textTheme.bodySmall,
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusText,
              style: theme.textTheme.labelSmall?.copyWith(
                color: iconColor,
              ),
            ),
          ),
          onTap: onItemTap,
        );
      }).toList(),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
