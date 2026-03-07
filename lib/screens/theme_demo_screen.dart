import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/vibrant_theme.dart';
import '../theme/warm_theme.dart';
import '../theme/professional_theme.dart';

/// 主题演示页面 - 展示三套UI风格供选择
class ThemeDemoScreen extends StatefulWidget {
  const ThemeDemoScreen({super.key});

  @override
  State<ThemeDemoScreen> createState() => _ThemeDemoScreenState();
}

class _ThemeDemoScreenState extends State<ThemeDemoScreen> {
  int _selectedScheme = 0; // 0: 明亮活力, 1: 温暖舒适, 2: 专业技术

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: Column(
            children: [
              // 顶部标题
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      '选择你的UI风格',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '三套风格各有特点，选择你喜欢的',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // 风格选择器
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    _buildSchemeChip(0, '明亮活力', VibrantTheme.primary),
                    const SizedBox(width: 8),
                    _buildSchemeChip(1, '温暖舒适', WarmTheme.primary),
                    const SizedBox(width: 8),
                    _buildSchemeChip(2, '专业技术', ProfessionalTheme.primary),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 预览区域
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildPreview(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchemeChip(int index, String label, Color color) {
    final isSelected = _selectedScheme == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedScheme = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    switch (_selectedScheme) {
      case 0:
        return _buildVibrantPreview();
      case 1:
        return _buildWarmPreview();
      case 2:
        return _buildProfessionalPreview();
      default:
        return _buildVibrantPreview();
    }
  }

  // ========== 方案一：明亮活力 ==========
  Widget _buildVibrantPreview() {
    return Column(
      children: [
        // 统计卡片
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: VibrantTheme.bgSurface,
            borderRadius: BorderRadius.circular(VibrantTheme.radius2xl),
            border: Border.all(color: VibrantTheme.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '3',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: VibrantTheme.success,
                      ),
                    ),
                    Text(
                      '待服用',
                      style: TextStyle(
                        fontSize: 12,
                        color: VibrantTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: VibrantTheme.border,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '5',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: VibrantTheme.primary,
                      ),
                    ),
                    Text(
                      '已完成',
                      style: TextStyle(
                        fontSize: 12,
                        color: VibrantTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 今日待服标题
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '今日待服',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: VibrantTheme.textPrimary,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 药品卡片
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: VibrantTheme.bgPage,
            borderRadius: BorderRadius.circular(VibrantTheme.radius2xl),
            border: Border.all(color: VibrantTheme.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // 药品图标
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: VibrantTheme.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '硝',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: VibrantTheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 药品信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '硝苯地平缓释片',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: VibrantTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '1片 · 餐后',
                          style: TextStyle(
                            fontSize: 14,
                            color: VibrantTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 时间
                  Text(
                    '08:00',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: VibrantTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 操作按钮
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VibrantTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('✓ 已服'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('稍后'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('跳过'),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 骨架屏示例
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '骨架屏加载',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: VibrantTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const VibrantSkeleton(
          width: double.infinity,
          height: 150,
          borderRadius: 24,
        ),

        const SizedBox(height: 20),

        // 空状态示例
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '空状态',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: VibrantTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        VibrantEmptyState(
          icon: Icons.medication_outlined,
          title: '还没有添加药品',
          description: '点击右下角按钮添加你的第一种药品',
          actionText: '添加药品',
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  // ========== 方案二：温暖舒适 ==========
  Widget _buildWarmPreview() {
    return Column(
      children: [
        // 统计卡片 - 带阴影
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: WarmTheme.bgSurface,
            borderRadius: BorderRadius.circular(WarmTheme.radiusLg),
            boxShadow: WarmTheme.shadowMd,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '3',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: WarmTheme.primary,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '待服用',
                      style: TextStyle(
                        fontSize: 12,
                        color: WarmTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '5',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: WarmTheme.accent,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '已完成',
                      style: TextStyle(
                        fontSize: 12,
                        color: WarmTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 今日待服标题
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Today's Schedule",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: WarmTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 药品卡片 - 柔和阴影
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: WarmTheme.bgSurface,
            borderRadius: BorderRadius.circular(WarmTheme.radiusLg),
            boxShadow: WarmTheme.shadowMd,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: WarmTheme.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'N',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: WarmTheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nifedipine SR',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: WarmTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '1 tablet · After meals',
                          style: TextStyle(
                            fontSize: 13,
                            color: WarmTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '8:00 AM',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: WarmTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WarmTheme.primary,
                      ),
                      child: const Text('Take'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Later'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 骨架屏示例
        const WarmSkeleton(
          width: double.infinity,
          height: 150,
          borderRadius: 16,
        ),

        const SizedBox(height: 24),

        // 温暖风格空状态
        WarmEmptyState(
          icon: Icons.medication_outlined,
          title: '还没有添加药品',
          description: '点击右下角按钮添加你的第一种药品',
          actionText: '添加药品',
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  // ========== 方案三：专业技术 ==========
  Widget _buildProfessionalPreview() {
    return Column(
      children: [
        // 标题区域 - 杂志风格
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "TODAY'S MEDICATIONS",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ProfessionalTheme.textTertiary,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'March 7, 2025',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w500,
              color: ProfessionalTheme.textPrimary,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // 统计行 - 紧凑数据风格
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ProfessionalTheme.bgSurface,
                  borderRadius: BorderRadius.circular(ProfessionalTheme.radius2xl),
                  border: ProfessionalTheme.borderDefault,
                ),
                child: Column(
                  children: [
                    Text(
                      '03',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: ProfessionalTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PENDING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: ProfessionalTheme.textTertiary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ProfessionalTheme.bgSurface,
                  borderRadius: BorderRadius.circular(ProfessionalTheme.radius2xl),
                  border: ProfessionalTheme.borderDefault,
                ),
                child: Column(
                  children: [
                    Text(
                      '05',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: ProfessionalTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'COMPLETED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: ProfessionalTheme.textTertiary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 分隔线
        Container(
          height: 1,
          color: ProfessionalTheme.border,
        ),

        const SizedBox(height: 20),

        // 药品卡片 - 细边框
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ProfessionalTheme.bgSurface,
            borderRadius: BorderRadius.circular(ProfessionalTheme.radius2xl),
            border: ProfessionalTheme.borderDefault,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: ProfessionalTheme.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nifedipine',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: ProfessionalTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '1 tablet • After meals',
                          style: TextStyle(
                            fontSize: 12,
                            color: ProfessionalTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '08:00',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ProfessionalTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('TAKEN'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('LATER'),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('SKIP'),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 骨架屏示例
        const ProfessionalSkeleton(
          width: double.infinity,
          height: 150,
          borderRadius: 12,
        ),

        const SizedBox(height: 24),

        // 专业风格空状态
        ProfessionalEmptyState(
          icon: Icons.medication_outlined,
          title: 'No medications added',
          description: 'Tap the button below to add your first medication',
          actionText: 'Add medication',
        ),

        const SizedBox(height: 40),
      ],
    );
  }
}
