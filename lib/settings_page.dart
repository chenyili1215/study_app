import 'package:flutter/material.dart';
import 'main.dart'; // 匯入 themeModeNotifier, localeNotifier
import 'app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  ThemeMode get _themeMode => themeModeNotifier.value;
  int _aboutTapCount = 0;

  // 新增主色管理
  final List<Color> _seedColors = [
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.red,
    Colors.teal,
    Colors.pink,
    Colors.brown,
    Colors.indigo,
    Colors.cyan,
    Colors.amber,
    Colors.deepOrange,
  ];
  Color _selectedColor = Colors.blue;

  // 新增：顏色名稱對照表
  final Map<Color, String> _colorNames = {
    Colors.blue: '藍色',
    Colors.green: '綠色',
    Colors.purple: '紫色',
    Colors.orange: '橙色',
    Colors.red: '紅色',
    Colors.teal: '藍綠',
    Colors.pink: '粉紅',
    Colors.brown: '咖啡',
    Colors.indigo: '靛藍',
    Colors.cyan: '青色',
    Colors.amber: '琥珀',
    Colors.deepOrange: '深橙',
  };

  @override
  void initState() {
    super.initState();
    _loadSeedColor();
  }

  Future<void> _loadSeedColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt('seedColor') ?? Colors.blue.value;
    setState(() {
      _selectedColor = Color(colorValue);
    });
    seedColorNotifier.value = _selectedColor;
  }

  Future<void> _setSeedColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('seedColor', color.value);
    setState(() {
      _selectedColor = color;
    });
    seedColorNotifier.value = color; // 這行會即時套用主題色
  }

  void _chooseTheme() async {
    final mode = await showModalBottomSheet<ThemeMode>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.brightness_auto),
            title: Text(AppLocalizations.of(context).t('system')),
            onTap: () => Navigator.pop(context, ThemeMode.system),
          ),
          ListTile(
            leading: const Icon(Icons.light_mode),
            title: Text('Light'),
            onTap: () => Navigator.pop(context, ThemeMode.light),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: Text('Dark'),
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

  // 切換語言
  void _chooseLanguage() async {
    final choice = await showModalBottomSheet<String?>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(AppLocalizations.of(context).t('system')),
            onTap: () => Navigator.pop(context, ''),
          ),
          ListTile(
            leading: const Icon(Icons.flag),
            title: Text(AppLocalizations.of(context).t('lang_zh')),
            onTap: () => Navigator.pop(context, 'zh'),
          ),
          ListTile(
            leading: const Icon(Icons.flag),
            title: Text(AppLocalizations.of(context).t('lang_en')),
            onTap: () => Navigator.pop(context, 'en'),
          ),
          ListTile(
            leading: const Icon(Icons.flag),
            title: Text(AppLocalizations.of(context).t('lang_ja')),
            onTap: () => Navigator.pop(context, 'ja'),
          ),
        ],
      ),
    );
    if (choice != null) {
      final prefs = await SharedPreferences.getInstance();
      if (choice.isEmpty) {
        await prefs.remove('locale');
        localeNotifier.value = null;
      } else {
        await prefs.setString('locale', choice);
        localeNotifier.value = Locale(choice);
      }
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

  void _showColorPicker() async {
    final picked = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('選擇主題顏色'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            children: _seedColors.map((color) {
              return GestureDetector(
                onTap: () => Navigator.of(context).pop(color),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color == _selectedColor ? Colors.black : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  width: 40,
                  height: 40,
                  child: color == _selectedColor
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('取消'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
    if (picked != null) {
      await _setSeedColor(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).t('settings'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: Text(AppLocalizations.of(context).t('theme_mode') ?? '主題模式'),
            subtitle: Text(_themeLabel),
            onTap: _chooseTheme,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(AppLocalizations.of(context).t('language')),
            subtitle: Text(localeNotifier.value == null
                ? AppLocalizations.of(context).t('system')
                : (AppLocalizations.of(context).t('lang_${localeNotifier.value!.languageCode}') ?? localeNotifier.value!.languageCode)),
            onTap: _chooseLanguage,
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.palette, color: _selectedColor),
            title: Text(AppLocalizations.of(context).t('theme_color') ?? '主題顏色'),
            subtitle: Text(_colorNames[_selectedColor] ?? AppLocalizations.of(context).t('custom_color') ?? '自訂顏色'),
            trailing: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _selectedColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
            ),
            onTap: _showColorPicker,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(AppLocalizations.of(context).t('about') ?? '關於'),
            subtitle: const Text('Study App v1.0.12'),
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