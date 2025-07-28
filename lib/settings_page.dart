import 'package:flutter/material.dart';
import 'main.dart'; // 匯入 themeModeNotifier

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  ThemeMode get _themeMode => themeModeNotifier.value;
  int _aboutTapCount = 0;

  void _chooseTheme() async {
    final mode = await showModalBottomSheet<ThemeMode>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.brightness_auto),
            title: const Text('跟隨系統'),
            onTap: () => Navigator.pop(context, ThemeMode.system),
          ),
          ListTile(
            leading: const Icon(Icons.light_mode),
            title: const Text('亮色'),
            onTap: () => Navigator.pop(context, ThemeMode.light),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('暗色'),
            onTap: () => Navigator.pop(context, ThemeMode.dark),
          ),
        ],
      ),
    );
    if (mode != null && mode != _themeMode) {
      themeModeNotifier.value = mode;
      setState(() {});
    }
  }

  String get _themeLabel {
    switch (_themeMode) {
      case ThemeMode.light:
        return '亮色';
      case ThemeMode.dark:
        return '暗色';
      default:
        return '跟隨系統';
    }
  }

  void _showEasterEgg() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🎉 小彩蛋！', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('你發現了隱藏彩蛋！\n\n真是個聰明的學習者 😄'),
        actions: [
          TextButton(
            child: const Text('關閉'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('主題模式'),
            subtitle: Text(_themeLabel),
            onTap: _chooseTheme,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('關於'),
            subtitle: const Text('Study App v1.0.11'),
            onTap: () {
              _aboutTapCount++;
              if (_aboutTapCount >= 5) {
                _aboutTapCount = 0;
                _showEasterEgg();
              }
            },
          ),
        ],
      ),
    );
  }
}