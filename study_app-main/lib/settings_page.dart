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
  bool _easterEggShown = false;

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

  // 顏色對應的 i18n key
  static final Map<Color, String> _colorKeys = {
    Colors.blue: 'color_blue',
    Colors.green: 'color_green',
    Colors.purple: 'color_purple',
    Colors.orange: 'color_orange',
    Colors.red: 'color_red',
    Colors.teal: 'color_teal',
    Colors.pink: 'color_pink',
    Colors.brown: 'color_brown',
    Colors.indigo: 'color_indigo',
    Colors.cyan: 'color_cyan',
    Colors.amber: 'color_amber',
    Colors.deepOrange: 'color_deep_orange',
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
            title: Text(AppLocalizations.of(context).t('theme_light')),
            onTap: () => Navigator.pop(context, ThemeMode.light),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: Text(AppLocalizations.of(context).t('theme_dark')),
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

  String _themeLabel(BuildContext context) {
    final loc = AppLocalizations.of(context);
    switch (_themeMode) {
      case ThemeMode.light:
        return loc.t('theme_light');
      case ThemeMode.dark:
        return loc.t('theme_dark');
      default:
        return loc.t('theme_follow_system');
    }
  }

  void _showEasterEgg() {
    _easterEggShown = true;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context).t('easter_egg_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(AppLocalizations.of(context).t('easter_egg_content')),
        actions: [
          TextButton(
            child: Text(AppLocalizations.of(context).t('close')),
            onPressed: () {
              _easterEggShown = false;
              _aboutTapCount = 0;
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showColorPicker() async {
    final picked = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).t('choose_theme_color')),
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
                      color: color == _selectedColor
                          ? Colors.black
                          : Colors.transparent,
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
            child: Text(AppLocalizations.of(context).t('cancel')),
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
        title: Text(
          AppLocalizations.of(context).t('settings'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: Text(AppLocalizations.of(context).t('theme_mode')),
            subtitle: Text(_themeLabel(context)),
            onTap: _chooseTheme,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(AppLocalizations.of(context).t('language')),
            subtitle: Text(
              localeNotifier.value == null
                  ? AppLocalizations.of(context).t('system')
                  : AppLocalizations.of(context).t(
                      'lang_${localeNotifier.value!.languageCode}',
                    ),
            ),
            onTap: _chooseLanguage,
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.palette, color: _selectedColor),
            title: Text(AppLocalizations.of(context).t('theme_color')),
            subtitle: Text(
              _colorKeys.containsKey(_selectedColor)
                  ? AppLocalizations.of(context).t(_colorKeys[_selectedColor]!)
                  : AppLocalizations.of(context).t('custom_color'),
            ),
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
            title: Text(AppLocalizations.of(context).t('about')),
            subtitle: const Text('Study App v1.0.12'),
            onTap: () {
              if (!_easterEggShown) {
                _aboutTapCount++;
                if (_aboutTapCount >= 5) {
                  _showEasterEgg();
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
