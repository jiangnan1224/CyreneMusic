import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/audio_source_service.dart';
import '../services/auth_service.dart';
import '../utils/theme_manager.dart';
import 'settings_page/audio_source_settings_page.dart';
import 'auth/auth_page.dart';

/// 移动端初始配置引导页
/// 
/// 多步引导流程：配置音源 → 登录 → 进入主应用
class MobileSetupPage extends StatefulWidget {
  const MobileSetupPage({super.key});

  @override
  State<MobileSetupPage> createState() => _MobileSetupPageState();
}

class _MobileSetupPageState extends State<MobileSetupPage> {
  /// 引导步骤
  /// 0 = 欢迎/音源配置入口
  /// 1 = 音源配置中
  /// 2 = 登录中
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    // 监听音源配置和登录状态变化
    AudioSourceService().addListener(_onStateChanged);
    AuthService().addListener(_onStateChanged);
  }

  @override
  void dispose() {
    AudioSourceService().removeListener(_onStateChanged);
    AuthService().removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {
        // 如果音源已配置且在配置步骤，自动进入下一步
        if (_currentStep == 1 && AudioSourceService().isConfigured) {
          _currentStep = 0; // 返回欢迎页，显示下一步按钮
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = ThemeManager();
    final isCupertino = (Platform.isIOS || Platform.isAndroid) && themeManager.isCupertinoFramework;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 音源配置页面
    if (_currentStep == 1) {
      return AudioSourceSettingsContent(
        onBack: () => setState(() => _currentStep = 0),
        embed: false,
      );
    }

    // 登录页面
    if (_currentStep == 2) {
      return _buildLoginPage(context, isCupertino, isDark);
    }

    // 欢迎/引导页面
    return _buildWelcomePage(context, isCupertino, colorScheme, isDark);
  }

  /// 构建欢迎引导页面
  Widget _buildWelcomePage(BuildContext context, bool isCupertino, ColorScheme colorScheme, bool isDark) {
    final audioConfigured = AudioSourceService().isConfigured;
    final isLoggedIn = AuthService().isLoggedIn;

    // 决定当前显示的引导内容
    String title;
    String subtitle;
    String buttonText;
    VoidCallback onButtonPressed;
    bool showSkip = true;

    if (!audioConfigured) {
      // 第一步：配置音源
      title = '欢迎使用 Cyrene Music';
      subtitle = '开始前，请先配置音源以解锁全部功能';
      buttonText = '配置音源';
      onButtonPressed = () => setState(() => _currentStep = 1);
    } else if (!isLoggedIn) {
      // 第二步：登录
      title = '音源配置完成 ✓';
      subtitle = '登录账号以同步您的收藏和播放记录';
      buttonText = '登录 / 注册';
      onButtonPressed = () => setState(() => _currentStep = 2);
    } else {
      // 全部完成（理论上不会到达这里，因为 main.dart 会跳转）
      title = '准备就绪!';
      subtitle = '开始探索音乐世界吧';
      buttonText = '进入首页';
      onButtonPressed = () => AudioSourceService().notifyListeners();
      showSkip = false;
    }

    return Scaffold(
      backgroundColor: isCupertino
          ? (isDark ? CupertinoColors.black : CupertinoColors.systemGroupedBackground)
          : colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              
              // App Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    'assets/icons/icon.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: colorScheme.primaryContainer,
                      child: Icon(
                        Icons.music_note,
                        size: 48,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 进度指示器
              _buildStepIndicator(audioConfigured, isLoggedIn, isDark),
              
              const SizedBox(height: 24),
              
              // 标题
              Text(
                title,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // 副标题
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(flex: 2),
              
              // 主按钮
              _buildMainButton(context, isCupertino, buttonText, onButtonPressed),
              
              const SizedBox(height: 16),
              
              // 跳过按钮
              if (showSkip)
                TextButton(
                  onPressed: () => _showSkipConfirmation(context, isCupertino),
                  child: Text(
                    '稍后再说',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontSize: 14,
                    ),
                  ),
                ),
              
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建步骤指示器
  Widget _buildStepIndicator(bool audioConfigured, bool isLoggedIn, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepDot(
          isCompleted: audioConfigured,
          isCurrent: !audioConfigured,
          isDark: isDark,
        ),
        Container(
          width: 40,
          height: 2,
          color: audioConfigured 
              ? (isDark ? Colors.white54 : Colors.black38)
              : (isDark ? Colors.white24 : Colors.black12),
        ),
        _buildStepDot(
          isCompleted: isLoggedIn,
          isCurrent: audioConfigured && !isLoggedIn,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildStepDot({
    required bool isCompleted,
    required bool isCurrent,
    required bool isDark,
  }) {
    Color color;
    if (isCompleted) {
      color = Colors.green;
    } else if (isCurrent) {
      color = ThemeManager.iosBlue;
    } else {
      color = isDark ? Colors.white24 : Colors.black12;
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: isCompleted
          ? const Icon(Icons.check, size: 8, color: Colors.white)
          : null,
    );
  }

  /// 构建登录页面
  Widget _buildLoginPage(BuildContext context, bool isCupertino, bool isDark) {
    return Scaffold(
      backgroundColor: isCupertino
          ? (isDark ? CupertinoColors.black : CupertinoColors.systemGroupedBackground)
          : Theme.of(context).colorScheme.surface,
      appBar: isCupertino
          ? CupertinoNavigationBar(
              leading: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => setState(() => _currentStep = 0),
                child: const Icon(CupertinoIcons.back),
              ),
              middle: const Text('登录'),
              backgroundColor: Colors.transparent,
              border: null,
            ) as PreferredSizeWidget?
          : AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _currentStep = 0),
              ),
              title: const Text('登录'),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
      body: const AuthPage(initialTab: 0),
    );
  }

  Widget _buildMainButton(BuildContext context, bool isCupertino, String text, VoidCallback onPressed) {
    if (isCupertino) {
      return SizedBox(
        width: double.infinity,
        child: CupertinoButton.filled(
          onPressed: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showSkipConfirmation(BuildContext context, bool isCupertino) {
    final audioConfigured = AudioSourceService().isConfigured;
    String message;
    
    if (!audioConfigured) {
      message = '不配置音源将无法播放在线音乐。您可以稍后在设置中配置。';
    } else {
      message = '不登录将无法同步收藏和播放记录。您可以稍后在设置中登录。';
    }

    if (isCupertino) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('跳过配置'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('返回'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                _skipSetup();
              },
              child: const Text('确认跳过'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('跳过配置'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('返回'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _skipSetup();
              },
              child: const Text('确认跳过'),
            ),
          ],
        ),
      );
    }
  }

  void _skipSetup() {
    // 通知跳过 - 触发 main.dart 中的状态更新来进入主应用
    // 这里通过 notifyListeners 来触发 AnimatedBuilder 重建
    AudioSourceService().notifyListeners();
    AuthService().notifyListeners();
  }
}
