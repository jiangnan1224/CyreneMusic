import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent_ui;
import '../../utils/theme_manager.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import '../../services/layout_preference_service.dart';
import '../../services/player_background_service.dart';
import '../../widgets/custom_color_picker_dialog.dart';
import '../../widgets/fluent_settings_card.dart';
import 'player_background_dialog.dart';

/// 外观设置组件
class AppearanceSettings extends StatefulWidget {
  const AppearanceSettings({super.key});

  @override
  State<AppearanceSettings> createState() => _AppearanceSettingsState();
}

class _AppearanceSettingsState extends State<AppearanceSettings> {
  @override
  Widget build(BuildContext context) {
    // 检查是否使用 Fluent UI
    final isFluentUI = Platform.isWindows && ThemeManager().isFluentFramework;
    
    if (isFluentUI) {
      return _buildFluentUI();
    }
    
    return _buildMaterialUI();
  }

  /// 构建 Material UI 版本
  Widget _buildMaterialUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('外观'),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode),
                title: const Text('深色模式'),
                subtitle: const Text('启用深色主题'),
                value: ThemeManager().isDarkMode,
                onChanged: (value) {
                  ThemeManager().toggleDarkMode(value);
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.auto_awesome),
                title: const Text('跟随系统主题色'),
                subtitle: Text(_getFollowSystemColorSubtitle()),
                value: ThemeManager().followSystemColor,
                onChanged: (value) async {
                  await ThemeManager().setFollowSystemColor(value, context: context);
                  setState(() {});
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.color_lens),
                title: const Text('主题色'),
                subtitle: Text(_getCurrentThemeColorName()),
                trailing: ThemeManager().followSystemColor
                    ? Icon(Icons.lock_outline, color: Theme.of(context).disabledColor)
                    : const Icon(Icons.chevron_right),
                onTap: ThemeManager().followSystemColor 
                    ? null
                    : () => _showThemeColorPicker(),
                enabled: !ThemeManager().followSystemColor,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.wallpaper),
                title: const Text('播放器背景'),
                subtitle: Text(
                  '${PlayerBackgroundService().getBackgroundTypeName()} - ${PlayerBackgroundService().getBackgroundTypeDescription()}'
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showPlayerBackgroundDialog(),
              ),
              if (Platform.isWindows) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.layers),
                  title: const Text('桌面主题样式'),
                  subtitle: Text(_getThemeFrameworkSubtitle()),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showThemeFrameworkDialog(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.view_quilt),
                  title: const Text('布局模式'),
                  subtitle: Text(LayoutPreferenceService().getLayoutDescription()),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showLayoutModeDialog(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// 构建 Fluent UI 版本（Windows 11 风格 - 每个选项独立卡片）
  Widget _buildFluentUI() {
    return FluentSettingsGroup(
      title: '外观',
      children: [
        // 主题模式（亮色/暗色/跟随系统）
        FluentSettingsTile(
          icon: fluent_ui.FluentIcons.clear_night,
          title: '主题模式',
          subtitle: _themeModeLabel(ThemeManager().themeMode),
          trailing: SizedBox(
            width: 180,
            child: fluent_ui.ComboBox<ThemeMode>(
              placeholder: const Text('选择主题模式'),
              value: ThemeManager().themeMode,
              items: const [
                fluent_ui.ComboBoxItem<ThemeMode>(
                  value: ThemeMode.light,
                  child: Text('亮色'),
                ),
                fluent_ui.ComboBoxItem<ThemeMode>(
                  value: ThemeMode.dark,
                  child: Text('暗色'),
                ),
                fluent_ui.ComboBoxItem<ThemeMode>(
                  value: ThemeMode.system,
                  child: Text('跟随系统'),
                ),
              ],
              onChanged: (mode) {
                if (mode != null) {
                  ThemeManager().setThemeMode(mode);
                  if (mounted) setState(() {});
                }
              },
            ),
          ),
        ),
        // 主题色设置（折叠项）：合并“跟随系统主题色”和“自定义主题色”
        fluent_ui.Card(
          padding: EdgeInsets.zero,
          child: fluent_ui.Expander(
            initiallyExpanded: false,
            header: Row(
              children: [
                const Icon(fluent_ui.FluentIcons.color_solid, size: 20),
                const SizedBox(width: 8),
                const Expanded(child: Text('主题色设置')),
                Text(
                  ThemeManager().followSystemColor ? '跟随系统' : '自定义',
                  style: fluent_ui.FluentTheme.of(context).typography.caption,
                ),
              ],
            ),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('跟随系统主题色')),
                    fluent_ui.ToggleSwitch(
                      checked: ThemeManager().followSystemColor,
                      onChanged: (value) async {
                        await ThemeManager().setFollowSystemColor(value, context: context);
                        if (mounted) setState(() {});
                      },
                    ),
                  ],
                ),
                if (!ThemeManager().followSystemColor) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Expanded(child: Text('自定义主题色')),
                      fluent_ui.Button(
                        onPressed: _showFluentThemeColorDialog,
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 18,
                              decoration: BoxDecoration(
                                color: ThemeManager().seedColor,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: (fluent_ui.FluentTheme.of(context).brightness == Brightness.light)
                                      ? Colors.black.withOpacity(0.12)
                                      : Colors.white.withOpacity(0.18),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('选择颜色'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        FluentSettingsTile(
          icon: fluent_ui.FluentIcons.picture_library,
          title: '播放器背景',
          subtitle: '${PlayerBackgroundService().getBackgroundTypeName()} - ${PlayerBackgroundService().getBackgroundTypeDescription()}',
          trailing: const Icon(fluent_ui.FluentIcons.chevron_right, size: 12),
          onTap: () => _showPlayerBackgroundDialog(),
        ),
        FluentSettingsTile(
          icon: fluent_ui.FluentIcons.design,
          title: '桌面主题样式',
          subtitle: _getThemeFrameworkSubtitle(),
          trailing: const Icon(fluent_ui.FluentIcons.chevron_right, size: 12),
          onTap: () => _showThemeFrameworkDialog(),
        ),
        // 窗口材质（仅 Windows 生效）
        FluentSettingsTile(
          icon: fluent_ui.FluentIcons.transition_effect,
          title: '窗口材质',
          subtitle: _windowEffectLabel(ThemeManager().windowEffect),
          trailing: SizedBox(
            width: 200,
            child: fluent_ui.ComboBox<WindowEffect>(
              value: ThemeManager().windowEffect,
              items: const [
                fluent_ui.ComboBoxItem(value: WindowEffect.disabled, child: Text('默认')),
                fluent_ui.ComboBoxItem(value: WindowEffect.mica, child: Text('云母')),
                fluent_ui.ComboBoxItem(value: WindowEffect.acrylic, child: Text('亚克力')),
                fluent_ui.ComboBoxItem(value: WindowEffect.transparent, child: Text('透明')),
              ],
              onChanged: (effect) async {
                if (effect != null) {
                  await ThemeManager().setWindowEffect(effect);
                  if (mounted) setState(() {});
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return '亮色';
      case ThemeMode.dark:
        return '暗色';
      case ThemeMode.system:
        return '跟随系统';
    }
  }

  String _getCurrentThemeColorName() {
    if (ThemeManager().followSystemColor) {
      return '${ThemeManager().getThemeColorSource()} (当前跟随系统)';
    }
    final currentIndex = ThemeManager().getCurrentColorIndex();
    return ThemeColors.presets[currentIndex].name;
  }

  String _getFollowSystemColorSubtitle() {
    if (ThemeManager().followSystemColor) {
      if (Platform.isAndroid) {
        return '自动获取 Material You 动态颜色 (Android 12+)';
      } else if (Platform.isWindows) {
        return '从系统个性化设置读取强调色';
      }
      return '自动跟随系统主题色';
    } else {
      return '手动选择主题色';
    }
  }

  String _getThemeFrameworkSubtitle() {
    switch (ThemeManager().themeFramework) {
      case ThemeFramework.material:
        return 'Material Design 3（默认推荐）';
      case ThemeFramework.fluent:
        return 'Fluent UI（Windows 原生风格）';
    }
  }
  
  String _windowEffectLabel(WindowEffect effect) {
    switch (effect) {
      case WindowEffect.disabled:
        return '默认';
      case WindowEffect.mica:
        return '云母';
      case WindowEffect.acrylic:
        return '亚克力';
      case WindowEffect.transparent:
        return '透明';
      default:
        return '默认';
    }
  }

  void _showFluentThemeColorDialog() {
    Color temp = ThemeManager().seedColor;
    fluent_ui.showDialog(
      context: context,
      builder: (context) => fluent_ui.ContentDialog(
        title: const Text('选择主题色'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 420,
            maxHeight: 480,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: temp,
                onColorChanged: (color) {
                  temp = color;
                },
                enableAlpha: false,
                displayThumbColor: true,
                pickerAreaHeightPercent: 0.75,
                portraitOnly: true,
                // 去除宽标签行以避免横向溢出
                labelTypes: const [],
                hexInputBar: false,
              ),
            ),
          ),
        ),
        actions: [
          fluent_ui.Button(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          fluent_ui.FilledButton(
            onPressed: () {
              ThemeManager().setSeedColor(temp);
              if (mounted) setState(() {});
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showThemeColorPicker() {
    final currentIndex = ThemeManager().getCurrentColorIndex();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题色'),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: ThemeColors.presets.length + 1,
            itemBuilder: (context, index) {
              if (index == ThemeColors.presets.length) {
                return InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _showCustomColorPicker();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '自定义',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              final colorScheme = ThemeColors.presets[index];
              final isSelected = index == currentIndex;
              
              return InkWell(
                onTap: () {
                  ThemeManager().setSeedColor(colorScheme.color);
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? colorScheme.color 
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colorScheme.color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSelected ? Icons.check : colorScheme.icon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        colorScheme.name,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showCustomColorPicker() {
    showDialog(
      context: context,
      builder: (context) => CustomColorPickerDialog(
        currentColor: ThemeManager().seedColor,
        onColorSelected: (color) {
          ThemeManager().setSeedColor(color);
        },
      ),
    );
  }

  void _showLayoutModeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择布局模式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Windows 专属功能',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• 切换布局时窗口会自动调整大小\n• 桌面模式：1200x800\n• 移动模式：400x850（竖屏）',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            RadioListTile<LayoutMode>(
              title: const Text('桌面模式'),
              subtitle: const Text('侧边导航栏，横屏宽屏布局'),
              secondary: const Icon(Icons.desktop_windows),
              value: LayoutMode.desktop,
              groupValue: LayoutPreferenceService().layoutMode,
              onChanged: (value) {
                LayoutPreferenceService().setLayoutMode(value!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('已切换到桌面模式，窗口已调整为 1200x800'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            RadioListTile<LayoutMode>(
              title: const Text('移动模式'),
              subtitle: const Text('底部导航栏，竖屏手机布局'),
              secondary: const Icon(Icons.smartphone),
              value: LayoutMode.mobile,
              groupValue: LayoutPreferenceService().layoutMode,
              onChanged: (value) {
                LayoutPreferenceService().setLayoutMode(value!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('已切换到移动模式，窗口已调整为 400x850'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showPlayerBackgroundDialog() {
    final isFluentUI = Platform.isWindows && ThemeManager().isFluentFramework;
    if (isFluentUI) {
      fluent_ui.showDialog(
        context: context,
        builder: (context) => PlayerBackgroundDialog(
          onChanged: () {
            if (mounted) {
              setState(() {});
            }
          },
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => PlayerBackgroundDialog(
          onChanged: () {
            if (mounted) {
              setState(() {});
            }
          },
        ),
      );
    }
  }

  void _showThemeFrameworkDialog() {
    final isFluentUI = Platform.isWindows && ThemeManager().isFluentFramework;
    if (isFluentUI) {
      fluent_ui.showDialog(
        context: context,
        builder: (context) => fluent_ui.ContentDialog(
          title: const Text('选择桌面主题样式'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              fluent_ui.RadioButton(
                content: const Text('Material Design 3'),
                checked: ThemeManager().themeFramework == ThemeFramework.material,
                onChanged: (v) {
                  ThemeManager().setThemeFramework(ThemeFramework.material);
                  Navigator.pop(context);
                  if (mounted) setState(() {});
                  final messenger = ScaffoldMessenger.maybeOf(context);
                  if (messenger != null) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('已切换到 Material Design 3 样式'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              fluent_ui.RadioButton(
                content: const Text('Fluent UI'),
                checked: ThemeManager().themeFramework == ThemeFramework.fluent,
                onChanged: (v) {
                  ThemeManager().setThemeFramework(ThemeFramework.fluent);
                  Navigator.pop(context);
                  if (mounted) setState(() {});
                  final messenger = ScaffoldMessenger.maybeOf(context);
                  if (messenger != null) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('已切换到 Fluent UI 样式'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            fluent_ui.Button(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('选择桌面主题样式'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeFramework>(
                title: const Text('Material Design 3'),
                subtitle: const Text('保持现有设计语言，适合跨平台体验'),
                secondary: const Icon(Icons.layers_outlined),
                value: ThemeFramework.material,
                groupValue: ThemeManager().themeFramework,
                onChanged: (value) {
                  if (value == null) return;
                  ThemeManager().setThemeFramework(value);
                  Navigator.pop(context);
                  if (mounted) setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('已切换到 Material Design 3 样式'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              RadioListTile<ThemeFramework>(
                title: const Text('Fluent UI'),
                subtitle: const Text('与 Windows 11 外观保持一致'),
                secondary: const Icon(Icons.desktop_windows),
                value: ThemeFramework.fluent,
                groupValue: ThemeManager().themeFramework,
                onChanged: (value) {
                  if (value == null) return;
                  ThemeManager().setThemeFramework(value);
                  Navigator.pop(context);
                  if (mounted) setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('已切换到 Fluent UI 样式'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    }
  }
}

