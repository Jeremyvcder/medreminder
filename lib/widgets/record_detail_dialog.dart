import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/records_provider.dart';
import '../models/medication.dart';

/// 记录详情弹窗
class RecordDetailDialog extends StatelessWidget {
  final DateTime date;

  const RecordDetailDialog({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final dateFormat = DateFormat('M月d日 EEEE', 'zh_CN');
    final timeFormat = DateFormat('HH:mm');

    return Consumer<RecordsProvider>(
      builder: (context, provider, _) {
        final recordsWithNames = provider.getRecordsWithMedicationNames(date);

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: screenWidth * 0.92,
            constraints: const BoxConstraints(maxHeight: 500),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Row(
                  children: [
                    Icon(
                      Icons.event_note,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dateFormat.format(date),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // 记录列表
                if (recordsWithNames.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: theme.colorScheme.outlineVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '无服药记录',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: recordsWithNames.length,
                      itemBuilder: (context, index) {
                        final data = recordsWithNames[index];
                        final record = data['record'] as Record;
                        final medicationName = data['medicationName'] as String;

                        return _buildRecordItem(
                          context,
                          medicationName,
                          record,
                          timeFormat,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建记录项
  Widget _buildRecordItem(
    BuildContext context,
    String medicationName,
    Record record,
    DateFormat timeFormat,
  ) {
    final theme = Theme.of(context);

    // 根据状态获取颜色和图标
    final statusInfo = _getStatusInfo(record.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 状态图标
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusInfo.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              statusInfo.icon,
              color: statusInfo.color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // 药品信息和时间
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicationName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '计划: ${timeFormat.format(record.scheduledTime)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (record.actualTime != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '实际: ${timeFormat.format(record.actualTime!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],

                // 跳过原因
                if (record.status == RecordStatus.skipped &&
                    record.skipReason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '原因: ${record.skipReason}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 状态标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusInfo.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusInfo.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: statusInfo.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 获取状态信息
  _StatusInfo _getStatusInfo(RecordStatus status) {
    switch (status) {
      case RecordStatus.taken:
        return _StatusInfo(
          label: '已服',
          color: const Color(0xFF3D8A5A), // 主题绿色
          icon: Icons.check_circle,
        );
      case RecordStatus.skipped:
        return _StatusInfo(
          label: '跳过',
          color: Colors.orange,
          icon: Icons.skip_next,
        );
      case RecordStatus.missed:
        return _StatusInfo(
          label: '错过',
          color: Colors.red,
          icon: Icons.cancel,
        );
      case RecordStatus.pending:
        return _StatusInfo(
          label: '待服',
          color: Colors.grey,
          icon: Icons.schedule,
        );
    }
  }
}

/// 状态信息
class _StatusInfo {
  final String label;
  final Color color;
  final IconData icon;

  _StatusInfo({
    required this.label,
    required this.color,
    required this.icon,
  });
}
