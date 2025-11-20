import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'timetable_importer.dart';
import 'label_engine.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'settings_page.dart';
import 'homework.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app_localizations.dart';

class TimetableData {
  static final TimetableData _instance = TimetableData._internal();
  factory TimetableData() => _instance;
  TimetableData._internal();

  List<List<String>> table = List.generate(5, (_) => List.generate(7, (_) => ''));

  int get periods => 7;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('timetable');
    if (data != null && data.isNotEmpty) {
      final decoded = jsonDecode(data);
      table = List<List<String>>.from(
        decoded.map((row) => List<String>.from(row)),
      );
    }
  }
}

ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.system);
ValueNotifier<Color> seedColorNotifier = ValueNotifier(Colors.blue);

// 新增：全域 locale notifier（null = 跟隨系統）
ValueNotifier<Locale?> localeNotifier = ValueNotifier<Locale?>(null);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final localeCode = prefs.getString('locale'); // null or '' 表示跟隨系統
  if (localeCode != null && localeCode.isNotEmpty) {
    localeNotifier.value = Locale(localeCode);
  } else {
    localeNotifier.value = null;
  }

  runApp(
    ValueListenableBuilder<Locale?>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        return ValueListenableBuilder<Color>(
          valueListenable: seedColorNotifier,
          builder: (context, seedColor, _) {
            return ValueListenableBuilder<ThemeMode>(
              valueListenable: themeModeNotifier,
              builder: (context, mode, _) => MyApp(themeMode: mode, seedColor: seedColor, locale: locale),
            );
          },
        );
      },
    ),
  );
}

class MyApp extends StatelessWidget {
  final ThemeMode themeMode;
  final Color seedColor;
  final Locale? locale;
  const MyApp({super.key, required this.themeMode, required this.seedColor, this.locale});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study App',
      debugShowCheckedModeBanner: false,
      locale: locale, // null = follow system
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh'),
        Locale('en'),
        Locale('ja'),
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return supportedLocales.first;
        for (var supported in supportedLocales) {
          if (supported.languageCode == locale.languageCode) return supported;
        }
        return supportedLocales.first;
      },
      theme: ThemeData(
        useMaterial3: true,
        colorScheme:
            ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.light),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme:
            ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark),
        brightness: Brightness.dark,
      ),
      themeMode: themeMode,
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  static List<Widget> _pagesWithCallback(void Function(int) onNav) => [
        HomePage(onQuickNav: onNav),
        TimetableImporter(),
        LabelEngine(),
        HomeworkPage(),
        const SettingsPage(),
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pagesWithCallback(_onItemTapped)[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: AppLocalizations.of(context).t('home')),
          BottomNavigationBarItem(
              icon: Icon(Icons.table_chart),
              label: AppLocalizations.of(context).t('timetable')),
          BottomNavigationBarItem(
              icon: Icon(Icons.label),
              label: AppLocalizations.of(context).t('photo_notes')),
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment),
              label: AppLocalizations.of(context).t('homework')),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: AppLocalizations.of(context).t('settings')),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final void Function(int)? onQuickNav;
  const HomePage({super.key, this.onQuickNav});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late Timer _timer;
  DateTime _now = DateTime.now();
  List<Homework> _upcomingHomeworks = [];

  @override
  void initState() {
    super.initState();
    TimetableData().load().then((_) => setState(() {}));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _now = DateTime.now();
      });
    });
    _loadUpcomingHomeworks();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _timer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadUpcomingHomeworks();
    }
  }

  Future<void> _loadUpcomingHomeworks() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('homeworks') ?? [];
    final now = DateTime.now();
    final result = list.map((e) {
      try {
        return Homework.fromJson(Map<String, dynamic>.from(jsonDecode(e)));
      } catch (_) {
        return null;
      }
    }).whereType<Homework>().toList();

    final upcoming = result.where((h) {
      final diff = h.deadline.difference(DateTime(now.year, now.month, now.day)).inDays;
      return diff >= 0 && diff <= 7;
    }).toList();

    upcoming.sort((a, b) => a.deadline.compareTo(b.deadline));

    setState(() {
      _upcomingHomeworks = upcoming;
    });
  }

  String _formatDeadlineLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final days = target.difference(today).inDays;
    final loc = AppLocalizations.of(context);
    if (days == 0) return loc.t('today');
    if (days == 1) return loc.t('tomorrow');
    return loc.tWithNumber('days_remaining', days);
  }

  String getCurrentClass() {
    int period = getCurrentPeriod();
    int weekday = _now.weekday;
    final loc = AppLocalizations.of(context);
    if (weekday < 1 || weekday > 5) return loc.t('not_class_day');
    if (period == 0) return loc.t('not_class_time');
    String subject = TimetableData().table[weekday - 1][period - 1];
    if (subject.isEmpty) return '${loc.t('no_scheduled')} (第$period節)';
    return "$subject (第$period節)";
  }

  String getNextClass() {
    try {
      final now = DateTime.now();
      final weekday = now.weekday;
      final timetable = TimetableData();
      final loc = AppLocalizations.of(context);

      if (weekday < 1 || weekday > 5) return loc.t('not_class_day');

      final currentPeriod = getCurrentPeriod();
      final nextPeriod = currentPeriod + 1;

      if (nextPeriod < 1 || nextPeriod > timetable.periods) return loc.t('today_no_more_classes');

      if (timetable.table.isEmpty || timetable.table[weekday - 1].isEmpty) {
        return '${loc.t('no_scheduled')} (第$nextPeriod節)';
      }

      final subject = timetable.table[weekday - 1][nextPeriod - 1];
      return subject.isEmpty ? '${loc.t('no_scheduled')} (第$nextPeriod節)' : subject;
    } catch (e) {
      print('getNextClass 錯誤: $e');
      return AppLocalizations.of(context).t('no_scheduled');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            title: Row(
              children: [
                Icon(Icons.school, color: colorScheme.primary, size: 32),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).t('welcome_back'),
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context).t('upcoming_homeworks'),
                    style: TextStyle(
                      fontSize: 20,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        height: 220,
                        child: _upcomingHomeworks.isEmpty
                            ? Center(
                                child: Text(
                                  AppLocalizations.of(context).t('no_homeworks'),
                                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                                ),
                              )
                            : Scrollbar(
                                radius: const Radius.circular(8),
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                  itemCount: _upcomingHomeworks.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, idx) {
                                    final hw = _upcomingHomeworks[idx];
                                    return Material(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      clipBehavior: Clip.hardEdge,
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        title: Text(
                                          hw.title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            Text(
                                              hw.subject,
                                              style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${hw.deadline.year}-${hw.deadline.month.toString().padLeft(2, '0')}-${hw.deadline.day.toString().padLeft(2, '0')} • ${_formatDeadlineLabel(hw.deadline)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        onTap: () async {
                                          final nav = Navigator.of(context).push(
                                            MaterialPageRoute(builder: (_) => const HomeworkPage()),
                                          );
                                          await nav;
                                          _loadUpcomingHomeworks();
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context).t('course_info'),
                    style: TextStyle(
                      fontSize: 20,
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: colorScheme.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.class_, color: colorScheme.secondary, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context).t('current_course'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: colorScheme.onSecondaryContainer.withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      getCurrentClass(),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSecondaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Divider(color: colorScheme.onSecondaryContainer.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(Icons.arrow_forward, color: colorScheme.secondary, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context).t('next_course'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: colorScheme.onSecondaryContainer.withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      getNextClass(),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSecondaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

int getCurrentPeriod() {
  final now = TimeOfDay.now();
  final minutes = now.hour * 60 + now.minute;
  if (minutes >= 8 * 60 + 10 && minutes < 9 * 60 + 10) return 1;
  if (minutes >= 9 * 60 + 10 && minutes < 10 * 60 + 10) return 2;
  if (minutes >= 10 * 60 + 10 && minutes < 11 * 60 + 10) return 3;
  if (minutes >= 11 * 60 + 10 && minutes < 12 * 60 + 10) return 4;
  if (minutes >= 13 * 60 && minutes < 14 * 60) return 5;
  if (minutes >= 14 * 60 && minutes < 15 * 60) return 6;
  if (minutes >= 15 * 60 + 10 && minutes < 16 * 60 + 10) return 7;
  if (minutes >= 16 * 60 + 10 && minutes < 17 * 60 + 10) return 8;
  return 0;
}
