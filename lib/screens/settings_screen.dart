import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../theme/warm_theme.dart';

/// 设置页面
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarmTheme.bgPage,
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: WarmTheme.bgSurface,
        foregroundColor: WarmTheme.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            padding: const EdgeInsets.all(WarmTheme.spaceLg),
            children: [
              // 语音提醒设置
              _buildSectionCard(
                title: '语音提醒',
                initiallyExpanded: true,
                children: [
                  // 总开关
                  SwitchListTile(
                    title: const Text('语音提醒'),
                    subtitle: const Text('开启后，服药提醒将使用语音播报'),
                    value: settings.voiceEnabled,
                    onChanged: (value) => settings.setVoiceEnabled(value),
                    activeTrackColor: WarmTheme.primary,
                  ),
                  // 子开关 - 仅在总开关开启时显示
                  if (settings.voiceEnabled) ...[
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    // 药品语音
                    SwitchListTile(
                      title: const Text('药品语音'),
                      subtitle: const Text('仅对药品生效'),
                      value: settings.medicineVoiceEnabled,
                      onChanged: (value) =>
                          settings.setMedicineVoiceEnabled(value),
                      activeTrackColor: WarmTheme.primary,
                      contentPadding:
                          const EdgeInsets.only(left: 32, right: 16),
                    ),
                    // 保健品语音
                    SwitchListTile(
                      title: const Text('保健品语音'),
                      subtitle: const Text('仅对保健品生效'),
                      value: settings.supplementVoiceEnabled,
                      onChanged: (value) =>
                          settings.setSupplementVoiceEnabled(value),
                      activeTrackColor: WarmTheme.primary,
                      contentPadding:
                          const EdgeInsets.only(left: 32, right: 16),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    // 免打扰时段
                    ListTile(
                      title: const Text('免打扰时段'),
                      subtitle: const Text('24:00 - 08:00'),
                      trailing: Icon(
                        Icons.lock_outline,
                        color: WarmTheme.textSecondary,
                        size: 20,
                      ),
                      contentPadding:
                          const EdgeInsets.only(left: 16, right: 8),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: WarmTheme.spaceLg),

              // 大字模式
              _buildSectionCard(
                title: '显示',
                children: [
                  SwitchListTile(
                    title: const Text('大字模式'),
                    subtitle: Text(
                      settings.largeTextMode ? '已开启' : '未开启',
                      style: TextStyle(
                        color: settings.largeTextMode
                            ? WarmTheme.success
                            : WarmTheme.textSecondary,
                      ),
                    ),
                    value: settings.largeTextMode,
                    onChanged: (value) => settings.setLargeTextMode(value),
                    activeTrackColor: WarmTheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: WarmTheme.spaceLg),

              // 隐私政策
              _buildSectionCard(
                title: '隐私',
                children: [
                  ListTile(
                    title: const Text('隐私政策'),
                    subtitle: Text(
                      settings.hasAgreedPrivacy ? '已同意' : '未同意',
                      style: TextStyle(
                        color: settings.hasAgreedPrivacy
                            ? WarmTheme.success
                            : WarmTheme.warning,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showPrivacyPolicyDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: WarmTheme.spaceLg),

              // 关于
              _buildSectionCard(
                title: '关于',
                children: [
                  ListTile(
                    title: const Text('版本号'),
                    subtitle: const Text('v2.7.0'),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    title: const Text('联系我们'),
                    subtitle: const Text('medreminder@163.com'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('感谢使用服药宝！'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  /// 构建卡片Section
  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    return Card(
      elevation: 0,
      color: WarmTheme.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WarmTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              WarmTheme.spaceLg,
              WarmTheme.spaceLg,
              WarmTheme.spaceLg,
              WarmTheme.spaceSm,
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: WarmTheme.textSecondary,
              ),
            ),
          ),
          ...children,
          const SizedBox(height: WarmTheme.spaceSm),
        ],
      ),
    );
  }

  /// 显示隐私政策弹窗
  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('隐私政策'),
        content: const SingleChildScrollView(
          child: Text(
            '服药宝隐私政策\n\n'
            '我们非常重视用户的隐私保护。本应用将收集以下信息：\n\n'
            '1. 设备信息：用于推送服药提醒通知\n'
            '2. 用药记录：用于记录您的服药历史\n'
            '3. 药品信息：您添加的药品名称、剂量等信息\n\n'
            '数据存储：\n'
            '所有数据均存储在您的本地设备中，我们会严格保护您的个人隐私。\n\n'
            '信息使用：\n'
            '我们仅将收集的信息用于提供服药提醒服务，不会将其分享给第三方。\n\n'
            '联系我们：\n'
            '如有任何隐私问题，请联系我们。',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
          Consumer<SettingsProvider>(
            builder: (context, settings, child) {
              if (!settings.hasAgreedPrivacy) {
                return ElevatedButton(
                  onPressed: () {
                    settings.agreePrivacy();
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已同意隐私政策')),
                    );
                  },
                  child: const Text('同意'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
