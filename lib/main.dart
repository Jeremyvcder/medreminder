import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme/warm_theme.dart';
import 'db/database_helper.dart';
import 'providers/medication_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/template_provider.dart';
import 'providers/records_provider.dart';
import 'services/scheduler_service.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'screens/medicine_box_screen.dart';
import 'screens/records_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化日期格式化（解决LocaleDataException）
  await initializeDateFormatting('zh_CN', null);

  // 先运行App，显示启动画面
  runApp(const MedReminderApp());

  // 在后台初始化数据库和调度服务（不阻塞UI）
  _initializeServices();
}

/// 后台初始化服务
Future<void> _initializeServices() async {
  try {
    // 初始化数据库
    await DatabaseHelper().database;
    print('数据库初始化完成');

    // 初始化调度服务
    await SchedulerService().initialize();
    print('调度服务初始化完成');
  } catch (e) {
    print('服务初始化失败: $e');
  }
}

class MedReminderApp extends StatefulWidget {
  const MedReminderApp({super.key});

  @override
  State<MedReminderApp> createState() => _MedReminderAppState();
}

class _MedReminderAppState extends State<MedReminderApp> {
  bool _showSplash = true;
  late SettingsProvider _settingsProvider;

  @override
  void initState() {
    super.initState();
    _settingsProvider = SettingsProvider();
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return MaterialApp(
        title: '服药宝',
        theme: WarmTheme.themeData,
        debugShowCheckedModeBanner: false,
        home: SplashScreen(
          onComplete: () async {
            // 欢迎页完成时，先加载设置
            await _settingsProvider.loadSettings();
            if (mounted) {
              setState(() {
                _showSplash = false;
              });
            }
          },
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _settingsProvider),
        ChangeNotifierProvider(create: (_) => MedicationProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
        ChangeNotifierProvider(create: (_) => TemplateProvider()..loadTemplates()),
        ChangeNotifierProvider(create: (_) => RecordsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          // 首次启动引导
          if (!settings.hasAgreedPrivacy) {
            return _buildOnboardingApp(context, settings);
          }

          return _buildMainApp(context, settings);
        },
      ),
    );
  }

  /// 构建引导页面App
  Widget _buildOnboardingApp(BuildContext context, SettingsProvider settings) {
    return MaterialApp(
      title: '服药宝',
      theme: WarmTheme.themeData,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: PrivacyPolicyPage(
          onAgreed: () async {
            await settings.agreePrivacy();
            // 直接请求系统通知权限，系统会自动弹出权限请求对话框
            await NotificationService().requestPermissions();
          },
        ),
      ),
    );
  }

  /// 构建主App
  Widget _buildMainApp(BuildContext context, SettingsProvider settings) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(settings.textScaleFactor),
      ),
      child: MaterialApp(
        title: '服药宝',
        theme: WarmTheme.themeData,
        debugShowCheckedModeBanner: false,
        home: const MainScreen(),
      ),
    );
  }

  /// 显示通知权限引导弹窗
  void _showNotificationPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('通知权限'),
        content: const Text(
          '服药宝需要通知权限来提醒您服药。\n\n是否开启通知权限？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('暂不开启'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await NotificationService().requestPermissions();
            },
            child: const Text('去开启'),
          ),
        ],
      ),
    );
  }
}

/// 隐私政策页面（首次引导）
class PrivacyPolicyPage extends StatefulWidget {
  final VoidCallback onAgreed;

  const PrivacyPolicyPage({super.key, required this.onAgreed});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WarmTheme.bgPage,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(WarmTheme.spaceLg),
          child: Column(
            children: [
              const Spacer(),
              Icon(
                Icons.medical_services,
                size: 80,
                color: WarmTheme.primary,
              ),
              const SizedBox(height: WarmTheme.space2xl),
              Text(
                '欢迎使用服药宝',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: WarmTheme.textPrimary,
                ),
              ),
              const SizedBox(height: WarmTheme.spaceLg),
              Expanded(
                flex: 3,
                child: Card(
                  elevation: 0,
                  color: WarmTheme.bgSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(WarmTheme.radiusLg),
                  ),
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        labelColor: WarmTheme.primary,
                        unselectedLabelColor: WarmTheme.textSecondary,
                        indicatorColor: WarmTheme.primary,
                        tabs: const [
                          Tab(text: '用户协议'),
                          Tab(text: '隐私政策'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // 用户协议
                            SingleChildScrollView(
                              padding: EdgeInsets.all(WarmTheme.spaceLg),
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
                                '1. 服药宝应用及其所有内容的知识产权归本产品所有\n'
                                '2. 未经授权，任何人不得复制、修改、传播本应用或其中的任何内容\n'
                                '3. 用户在使用本应用过程中产生的任何原创内容，其知识产权归用户所有\n\n'
                                '五、免责声明（重要）\n'
                                '1. 服药提醒仅作为辅助提醒工具，本应用不保证提醒的绝对及时性和准确性\n'
                                '2. 因用户未查看或未按时服药造成的任何后果，包括但不限于病情延误、健康损害等，产品不承担任何责任\n'
                                '3. 本应用提供的用药信息仅供参考，不能替代医疗专业建议\n'
                                '4. 用户应自行承担使用本应用的风险\n\n'
                                '六、服务变更\n'
                                '我们保留随时修改或终止服务的权利，恕不另行通知。\n\n'
                                '七、联系方式\n'
                                '如有问题，请联系我们：medreminder@163.com',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: WarmTheme.textPrimary,
                                ),
                              ),
                            ),
                            // 隐私政策
                            SingleChildScrollView(
                              padding: EdgeInsets.all(WarmTheme.spaceLg),
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
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: WarmTheme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: WarmTheme.spaceLg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onAgreed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WarmTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(WarmTheme.radiusLg),
                    ),
                  ),
                  child: const Text(
                    '同意',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: WarmTheme.spaceMd),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => SystemNavigator.pop(),
                  child: Text(
                    '不同意',
                    style: TextStyle(
                      fontSize: 14,
                      color: WarmTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    MedicineBoxScreen(),
    RecordsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 设置通知点击回调，点击通知后跳转到首页
    NotificationService.onNotificationTap = _navigateToHome;
  }

  void _navigateToHome() {
    if (mounted) {
      setState(() {
        _currentIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_services_outlined),
            selectedIcon: Icon(Icons.medical_services),
            label: '药箱',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: '记录',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
