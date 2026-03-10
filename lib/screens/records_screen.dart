import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/records_provider.dart';
import '../widgets/record_detail_dialog.dart';

/// 记录模块主页面
class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  @override
  void initState() {
    super.initState();
    // 页面加载时获取当月记录
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecordsProvider>().loadRecordsForMonth(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('记录'),
        centerTitle: true,
      ),
      body: Consumer<RecordsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.records.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // 月份选择器
              _buildMonthSelector(context, provider),

              // 日历视图
              _buildCalendar(context, provider),

              const SizedBox(height: 16),

              // 依从性统计卡片
              _buildStatsCard(context, provider),
            ],
          );
        },
      ),
    );
  }

  /// 月份选择器
  Widget _buildMonthSelector(BuildContext context, RecordsProvider provider) {
    final theme = Theme.of(context);
    final monthFormat = DateFormat('yyyy年M月');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: provider.goToPreviousMonth,
          ),
          GestureDetector(
            onTap: provider.goToToday,
            child: Text(
              monthFormat.format(provider.selectedMonth),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: provider.goToNextMonth,
          ),
        ],
      ),
    );
  }

  /// 日历视图
  Widget _buildCalendar(BuildContext context, RecordsProvider provider) {
    final theme = Theme.of(context);
    final datesWithRecords = provider.datesWithRecords;
    final selectedMonth = provider.selectedMonth;

    // 获取当月天数
    final firstDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;

    // 获取当月第一天是周几（1=周一，7=周日）
    int firstWeekday = firstDayOfMonth.weekday;

    // 周标题
    const weekDays = ['一', '二', '三', '四', '五', '六', '日'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 周标题行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays
                .map((day) => SizedBox(
                      width: 40,
                      child: Center(
                        child: Text(
                          day,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // 日历网格
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: 42, // 6行 * 7列
            itemBuilder: (context, index) {
              // 计算实际日期
              int dayOffset = index - (firstWeekday - 1);
              if (dayOffset < 1 || dayOffset > daysInMonth) {
                return const SizedBox(); // 空白单元格
              }

              final date = DateTime(
                selectedMonth.year,
                selectedMonth.month,
                dayOffset,
              );

              // 检查是否有记录
              final hasRecords = datesWithRecords.contains(date);
              final isToday = _isToday(date);

              return _buildDayCell(
                context,
                dayOffset,
                hasRecords,
                isToday,
                date,
              );
            },
          ),
        ],
      ),
    );
  }

  /// 构建日期单元格
  Widget _buildDayCell(
    BuildContext context,
    int day,
    bool hasRecords,
    bool isToday,
    DateTime date,
  ) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        if (hasRecords) {
          // 显示记录详情弹窗
          showDialog(
            context: context,
            builder: (context) => RecordDetailDialog(date: date),
          );
        } else {
          // 无记录日期显示提示
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${DateFormat('M月d日').format(date)} 无服药记录'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isToday
              ? theme.colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isToday
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (hasRecords)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 判断是否是今天
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// 依从性统计卡片
  Widget _buildStatsCard(BuildContext context, RecordsProvider provider) {
    final theme = Theme.of(context);

    return FutureBuilder<Map<String, int>>(
      future: provider.getComplianceStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'total': 0, 'taken': 0, 'skipped': 0, 'missed': 0, 'pending': 0};
        final complianceRate = provider.getComplianceRate(stats);
        final total = stats['total'] ?? 0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '依从性统计',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 依从率
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${complianceRate.toStringAsFixed(0)}%',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '(${(stats['taken'] ?? 0)}/${total}次)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 统计详情
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    context,
                    '已服',
                    stats['taken'] ?? 0,
                    theme.colorScheme.primary,
                    Icons.check_circle_outline,
                  ),
                  _buildStatItem(
                    context,
                    '跳过',
                    stats['skipped'] ?? 0,
                    Colors.orange,
                    Icons.skip_next_outlined,
                  ),
                  _buildStatItem(
                    context,
                    '错过',
                    stats['missed'] ?? 0,
                    Colors.red,
                    Icons.cancel_outlined,
                  ),
                  _buildStatItem(
                    context,
                    '待服',
                    stats['pending'] ?? 0,
                    Colors.grey,
                    Icons.schedule_outlined,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// 统计项
  Widget _buildStatItem(
    BuildContext context,
    String label,
    int count,
    Color color,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
