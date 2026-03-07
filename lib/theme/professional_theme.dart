import 'package:flutter/material.dart';

/// 服药宝 - 专业技术风格主题
/// 特点：青色主调、杂志数据风、细边框、理性严谨
class ProfessionalTheme {
  // ==================== 色彩系统 ====================

  // 主色板
  static const Color primary = Color(0xFF0D6E6E);
  static const Color primaryLight = Color(0xFF138B8B);
  static const Color primaryDark = Color(0xFF0A5555);
  static const Color primarySoft = Color(0xFF0D6E6E);

  // 辅助色
  static const Color success = Color(0xFF0D6E6A);
  static const Color accent = Color(0xFFE07B54);
  static const Color accentLight = Color(0xFFF0A090);
  static const Color warning = Color(0xFFB8860B);
  static const Color error = Color(0xFFC53030);

  // 中性色 - 克制理性
  static const Color bgPage = Color(0xFFFAFAFA);
  static const Color bgSurface = Color(0xFFFFFFFF);
  static const Color bgMuted = Color(0xFFF0F0F0);
  static const Color bgElevated = Color(0xFFF8F8F8);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF888888);
  static const Color textMuted = Color(0xFFAAAAAA);
  static const Color textSubtle = Color(0xFFBBBBBB);
  static const Color border = Color(0xFFE5E5E5);
  static const Color borderMuted = Color(0xFFDDDDDD);

  // ==================== 间距系统 ====================
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 12.0;
  static const double spaceLg = 16.0;
  static const double spaceXl = 20.0;
  static const double space2xl = 24.0;
  static const double space3xl = 32.0;

  // ==================== 圆角系统 ====================
  static const double radiusSm = 4.0;
  static const double radiusMd = 6.0;
  static const double radiusLg = 8.0;
  static const double radiusXl = 10.0;
  static const double radius2xl = 12.0;
  static const double radiusFull = 32.0;

  // ==================== 边框系统 ====================
  static Border get borderDefault => Border.all(color: border, width: 1);
  static Border get borderStrong => Border.all(color: borderMuted, width: 1);
  static Border get borderAccent => Border.all(color: primary, width: 1);

  // ==================== 阴影系统（微弱）====================
  static List<BoxShadow> get shadowTab => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          offset: const Offset(0, 2),
          blurRadius: 12,
        ),
      ];

  static List<BoxShadow> get shadowSegment => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          offset: const Offset(0, 1),
          blurRadius: 2,
        ),
      ];

  // ==================== 主题数据 ====================

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: bgPage,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        tertiary: warning,
        error: error,
        surface: bgSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgPage,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Newsreader',
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: bgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius2xl),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textSecondary,
          backgroundColor: bgMuted,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          side: BorderSide.none,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: textMuted,
        ),
        isDense: true,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bgSurface,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Newsreader',
          fontSize: 40,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Newsreader',
          fontSize: 32,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Newsreader',
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Newsreader',
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Newsreader',
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textTertiary,
        ),
        labelLarge: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        labelMedium: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textSecondary,
          letterSpacing: 1,
        ),
        labelSmall: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textTertiary,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

// ==================== 骨架屏组件 ====================

/// 骨架屏加载组件 - 专业风格
class ProfessionalSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ProfessionalSkeleton({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 4,
  });

  @override
  State<ProfessionalSkeleton> createState() => _ProfessionalSkeletonState();
}

class _ProfessionalSkeletonState extends State<ProfessionalSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // 专业风格：快速精准的动画
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _animation.value, 0),
              end: Alignment(_animation.value, 0),
              colors: const [
                Color(0xFFF0F0F0),
                Color(0xFFFAFAFA),
                Color(0xFFF0F0F0),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// 药品卡片骨架屏
class MedicationCardSkeleton extends StatelessWidget {
  const MedicationCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ProfessionalTheme.bgSurface,
        borderRadius: BorderRadius.circular(ProfessionalTheme.radius2xl),
        border: ProfessionalTheme.borderDefault,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ProfessionalTheme.border),
                ),
                child: const ProfessionalSkeleton(
                  width: 40,
                  height: 40,
                  borderRadius: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ProfessionalSkeleton(
                      width: 100,
                      height: 14,
                      borderRadius: 2,
                    ),
                    SizedBox(height: 6),
                    ProfessionalSkeleton(
                      width: 80,
                      height: 12,
                      borderRadius: 2,
                    ),
                  ],
                ),
              ),
              const ProfessionalSkeleton(
                width: 50,
                height: 16,
                borderRadius: 2,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ProfessionalSkeleton(
                  height: 36,
                  borderRadius: ProfessionalTheme.radiusSm,
                ),
              ),
              const SizedBox(width: 8),
              ProfessionalSkeleton(
                width: 60,
                height: 36,
                borderRadius: ProfessionalTheme.radiusSm,
              ),
              const SizedBox(width: 6),
              ProfessionalSkeleton(
                width: 60,
                height: 36,
                borderRadius: ProfessionalTheme.radiusSm,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================== 空状态组件 ====================

/// 专业风格空状态
class ProfessionalEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionText;
  final VoidCallback? onAction;

  const ProfessionalEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: ProfessionalTheme.border,
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: 32,
                color: ProfessionalTheme.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Newsreader',
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: ProfessionalTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: ProfessionalTheme.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionText!.toUpperCase()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==================== 错误状态组件 ====================

/// 专业风格错误状态
class ProfessionalErrorState extends StatelessWidget {
  final String title;
  final String message;
  final String? retryText;
  final VoidCallback? onRetry;

  const ProfessionalErrorState({
    super.key,
    this.title = 'ERROR',
    required this.message,
    this.retryText,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: ProfessionalTheme.error.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: ProfessionalTheme.error.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: ProfessionalTheme.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ProfessionalTheme.error,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: ProfessionalTheme.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            if (retryText != null && onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(retryText!.toUpperCase()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
