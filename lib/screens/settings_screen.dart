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

              // 隐私与协议
              _buildSectionCard(
                title: '隐私与协议',
                children: [
                  ListTile(
                    title: const Text('用户协议'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showUserAgreementDialog(context),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
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

  /// 显示用户协议弹窗
  void _showUserAgreementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('用户协议'),
        content: const SingleChildScrollView(
          child: Text(
            '服药宝用户协议\n\n'
            '欢迎使用服药宝！在开始使用本应用前，请仔细阅读以下服务条款。\n\n'
            '一、服务说明\n'
            '服药宝是一款帮助用户管理用药提醒的移动应用。我们提供药品提醒、服药记录查询等功能，旨在帮助您更好地管理用药时间。\n\n'
            '二、账号与数据\n'
            '1. 本应用无需注册账号，通过设备唯一标识符识别用户\n'
            '2. 您在使用过程中添加的药品信息、用药记录等数据存储在您的本地设备中\n'
            '3. 请妥善保管您的设备，因设备丢失或数据清除导致的数据丢失，我们不承担责任\n'
            '4. 我们不会将您的用药数据上传至服务器或分享给第三方\n\n'
            '三、用户行为规范\n'
            '1. 您应保证所提供的药品信息真实准确\n'
            '2. 请勿将本应用用于任何非法目的\n'
            '3. 严禁利用本应用传播违法、违规内容\n'
            '4. 您需对通过本应用添加的所有信息负责\n\n'
            '四、知识产权\n'
            '1. 服药宝应用及其所有内容（包括但不限于图标、界面设计、功能实现等）的知识产权归本产品所有\n'
            '2. 未经授权，任何人不得复制、修改、传播本应用或其中的任何内容\n'
            '3. 用户在使用本应用过程中产生的任何原创内容，其知识产权归用户所有\n\n'
            '五、免责声明（重要）\n'
            '1. 服药提醒仅作为辅助提醒工具，本应用不保证提醒的绝对及时性和准确性\n'
            '2. 因用户未查看或未按时服药造成的任何后果，包括但不限于病情延误、健康损害等，产品不承担任何责任\n'
            '3. 本应用提供的用药信息仅供参考，不能替代医疗专业建议\n'
            '4. 用户应自行承担使用本应用的风险\n'
            '5. 我们不保证服务完全没有错误或中断\n'
            '6. 对于因不可抗力或第三方原因导致的服务中断，我们不承担责任\n\n'
            '六、服务变更\n'
            '我们保留随时修改或终止服务的权利，恕不另行通知。\n\n'
            '七、联系方式\n'
            '如有问题，请联系我们：medreminder@163.com',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
