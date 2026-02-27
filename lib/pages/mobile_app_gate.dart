import 'dart:io';
import 'package:flutter/material.dart';
import '../services/audio_source_service.dart';
import '../services/auth_service.dart';
import '../services/persistent_storage_service.dart';
import '../layouts/main_layout.dart';
import 'mobile_setup_page.dart';

/// 移动端应用入口控制器
/// 
/// 根据音源配置和登录状态决定显示引导页还是主布局。
/// 使用内部状态管理避免重建 Navigator。
class MobileAppGate extends StatefulWidget {
  const MobileAppGate({super.key});

  @override
  State<MobileAppGate> createState() => _MobileAppGateState();
}

class _MobileAppGateState extends State<MobileAppGate> {
  @override
  void initState() {
    super.initState();
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
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConfigured = AudioSourceService().isConfigured;
    final isLoggedIn = AuthService().isLoggedIn;
    final isTermsAccepted = PersistentStorageService().getBool('terms_accepted') ?? false;
    final isLocalMode = PersistentStorageService().enableLocalMode;

    // 只要用户已确认协议（不论是完成配置、跳过配置还是本地模式），即可进入主布局
    if (isTermsAccepted) {
      return const MainLayout();
    }

    // 否则显示引导页
    return const MobileSetupPage();
  }
}
