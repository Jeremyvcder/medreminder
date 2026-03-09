import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/medication_provider.dart';
import '../providers/reminder_provider.dart';
import '../widgets/medication_card.dart';
import '../widgets/merged_reminder_card.dart';
import '../widgets/completed_section.dart';
import 'add_medication_screen.dart';

/// 首页 - 今日待服清单
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 使用addPostFrameCallback确保Provider已准备好
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final reminderProvider = context.read<ReminderProvider>();
    final medicationProvider = context.read<MedicationProvider>();

    await Future.wait([
      reminderProvider.loadTodayReminders(),
      reminderProvider.loadCompletedReminders(),
      medicationProvider.loadMedications(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateFormat('yyyy年M月d日 EEEE', 'zh_CN').format(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 顶部标题区域
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '今日提醒',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    today,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // 统计信息
            Consumer<ReminderProvider>(
              builder: (context, provider, _) {
                final stats = provider.getTodayStats();
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: '待服',
                        value: stats['pending'].toString(),
                        color: theme.colorScheme.primary,
                      ),
                      _StatItem(
                        label: '已服',
                        value: stats['taken'].toString(),
                        color: Colors.green,
                      ),
                      _StatItem(
                        label: '跳过',
                        value: stats['skipped'].toString(),
                        color: Colors.orange,
                      ),
                      _StatItem(
                        label: '错过',
                        value: stats['missed'].toString(),
                        color: Colors.red,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // 今日待服清单
            Expanded(
              child: Consumer<ReminderProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final pendingItems = provider.pendingReminders;
                  final completedItems = provider.completedReminders;
                  final mergedReminders = provider.mergedReminders;

                  if (pendingItems.isEmpty && completedItems.isEmpty) {
                    return _EmptyState(
                      onAddPressed: () => _navigateToAdd(),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 80),
                      children: [
                        // 待服清单标题
                        if (pendingItems.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              '待服',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                        // 合并提醒显示
                        ...mergedReminders.entries.map((entry) {
                          final items = entry.value;
                          if (items.length == 1) {
                            // 单个药品
                            return MedicationCard(
                              medication: items.first.medication,
                              scheduledTime: items.first.record.scheduledTime,
                              onConfirm: () => _confirmMedication(
                                items.first.record.id,
                              ),
                              onSkip: () => _skipMedication(
                                items.first.record.id,
                              ),
                              onSnooze: () => _snoozeReminder(
                                items.first.record.id,
                              ),
                            );
                          } else {
                            // 合并提醒
                            return MergedReminderCard(
                              scheduledTime: items.first.record.scheduledTime,
                              medications: items
                                  .map((i) => i.medication)
                                  .toList(),
                              onConfirmAll: () => _confirmMultipleMedications(
                                items.map((i) => i.record.id).toList(),
                              ),
                              onSkip: () {
                                // 跳过所有
                                for (var item in items) {
                                  _skipMedication(item.record.id);
                                }
                              },
                              onSnooze: () {
                                // 稍后提醒所有
                                for (var item in items) {
                                  _snoozeReminder(item.record.id);
                                }
                              },
                            );
                          }
                        }),

                        // 已完成区域
                        if (completedItems.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          CompletedSection(
                            completedItems: completedItems
                                .map((item) => {
                                      'record': item.record.toMap(),
                                      'medication': item.medication.toMap(),
                                    })
                                .toList(),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAdd(),
        icon: const Icon(Icons.add),
        label: const Text('添加药品'),
      ),
    );
  }

  Future<void> _confirmMedication(String recordId) async {
    final provider = context.read<ReminderProvider>();
    await provider.confirmMedication(recordId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已确认服药')),
      );
    }
  }

  Future<void> _confirmMultipleMedications(List<String> recordIds) async {
    final provider = context.read<ReminderProvider>();
    await provider.confirmMultipleMedications(recordIds);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已确认${recordIds.length}项服药')),
      );
    }
  }

  Future<void> _skipMedication(String recordId) async {
    final provider = context.read<ReminderProvider>();
    await provider.skipMedication(recordId);
  }

  Future<void> _snoozeReminder(String recordId) async {
    final provider = context.read<ReminderProvider>();
    await provider.snoozeReminder(recordId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已设置10分钟后提醒')),
      );
    }
  }

  void _navigateToAdd() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddMedicationScreen(),
      ),
    );
  }
}

/// 统计项组件
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
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
            Icons.medication_outlined,
            size: 80,
            color: theme.colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            '今日暂无提醒',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮添加药品',
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
