import 'package:flutter/material.dart';
import 'timetable_importer.dart';
import 'label_engine.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'settings_page.dart';
import 'homework.dart'; // 新增這行

// 引入課表資料
class TimetableData {
  static final TimetableData _instance = TimetableData._internal();
  factory TimetableData() => _instance;
  TimetableData._internal();

  // 5天，每天7節
  List<List<String>> table = List.generate(5, (_) => List.generate(7, (_) => ''));

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('timetable');
    if (data != null) {
      final decoded = jsonDecode(data);
      table = List<List<String>>.from(
        decoded.map((row) => List<String>.from(row)),
      );
    }
  }
}

ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.system);
ValueNotifier<Color> seedColorNotifier = ValueNotifier(Colors.blue);

void main() {
  runApp(
    ValueListenableBuilder<Color>(
      valueListenable: seedColorNotifier,
      builder: (context, seedColor, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeModeNotifier,
          builder: (context, mode, _) => MyApp(themeMode: mode, seedColor: seedColor),
        );
      },
    ),
  );
}

class MyApp extends StatelessWidget {
  final ThemeMode themeMode;
  final Color seedColor;
  const MyApp({super.key, required this.themeMode, required this.seedColor});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
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
        HomeworkPage(), // 新增功課分頁
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首頁',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.table_chart),
            label: '課表',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.label),
            label: '照片筆記',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment), // 新增：功課
            label: '功課',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '設定',
          ),
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

  // 新增：即將到期的功課清單
  List<Homework> _upcomingHomeworks = [];

  @override
  void initState() {
    super.initState();
    TimetableData().load().then((_) {
      setState(() {});
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _now = DateTime.now();
      });
    });

    // 載入功課
    _loadUpcomingHomeworks();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _timer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 當 App 回到 foreground 時重新載入（以便從功課頁回來後更新）
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

    // 過濾 7 天內 (包含今天)，並依截止日由近到遠排序
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
    if (days == 0) return '今天';
    if (days == 1) return '明天';
    return '還有 ${days} 天';
  }

  String getCurrentClass() {
    int period = getCurrentPeriod();
    int weekday = _now.weekday;
    if (weekday < 1 || weekday > 5) {
      return "今天不是上課日";
    }
    if (period == 0) {
      return "目前非上課時間";
    }
    String subject = TimetableData().table[weekday - 1][period - 1];
    if (subject.isEmpty) {
      return "未排課(第$period節)";
    }
    return "$subject (第$period節)";
  }

  // 新增：取得下一節課資訊（subject, period, startTime）
  Map<String, dynamic> getNextClassInfo() {
    final now = DateTime.now();
    final minutes = now.hour * 60 + now.minute;
    // period 時間區間改為開始時間映射（若你有不同時間表請調整）
    final periodStarts = {
      1: 8 * 60 + 10,
      2: 9 * 60 + 10,
      3: 10 * 60 + 10,
      4: 11 * 60 + 10,
      5: 13 * 60,
      6: 14 * 60,
      7: 15 * 60 + 10,
      8: 16 * 60 + 10,
    };

    // 找出目前還沒開始的最早節次
    for (int p = 1; p <= 8; p++) {
      final start = periodStarts[p]!;
      if (minutes < start) {
        // 找到下一節
        final weekday = now.weekday;
        String subject = '';
        if (weekday >= 1 && weekday <= 5 && p <= TimetableData().table[weekday - 1].length) {
          subject = TimetableData().table[weekday - 1][p - 1];
        }
        if (subject.isEmpty) subject = '未排課 (第$p節)';
        // 格式化時間顯示
        final hh = (start ~/ 60).toString().padLeft(2, '0');
        final mm = (start % 60).toString().padLeft(2, '0');
        return {
          'period': p,
          'subject': subject,
          'startTime': '$hh:$mm',
        };
      }
    }

    // 若當日已無下一節，回傳空
    return {'period': 0, 'subject': '今天沒有更多課程', 'startTime': ''};
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final nextInfo = getNextClassInfo(); // 取得資料
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
                  '歡迎回來！',
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
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    color: colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}",
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "${_now.year}-${_now.month.toString().padLeft(2, '0')}-${_now.day.toString().padLeft(2, '0')}",
                                style: TextStyle(
                                  fontSize: 20,
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.access_time_filled_rounded,
                            color: colorScheme.primary,
                            size: 48,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 新增：未來 7 天內要交的功課區塊
                  Text(
                    "接下來 7 天要交的功課",
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
                    color: colorScheme.surfaceVariant,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        height: 140, // 卡片內部固定高度，可滑動
                        child: _upcomingHomeworks.isEmpty
                            ? Center(
                                child: Text(
                                  '未來 7 天內沒有功課',
                                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                                ),
                              )
                            : Scrollbar(
                                radius: const Radius.circular(8),
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                  itemCount: _upcomingHomeworks.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                                  itemBuilder: (context, idx) {
                                    final hw = _upcomingHomeworks[idx];
                                    return Material(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        title: Text(hw.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text(hw.subject),
                                        trailing: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${hw.deadline.year}-${hw.deadline.month.toString().padLeft(2, '0')}-${hw.deadline.day.toString().padLeft(2, '0')}',
                                              style: TextStyle(color: colorScheme.onSurfaceVariant),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatDeadlineLabel(hw.deadline),
                                              style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                        onTap: () async {
                                          // 點擊可以跳到功課頁（需要刷新列表時可在返回時重新載入）
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
                    "目前課程",
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: colorScheme.secondaryContainer,
                    child: ListTile(
                      leading: Icon(Icons.class_, color: colorScheme.secondary, size: 32),
                      title: Text(
                        getCurrentClass(),
                        style: TextStyle(
                          fontSize: 22,
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 新增：下一節課程（放在目前課程下方）
                  Text(
                    "下一節課程",
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: colorScheme.surfaceVariant,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Icon(Icons.next_plan, color: colorScheme.primary, size: 36),
                      title: Text(
                        nextInfo['subject'] as String,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      subtitle: (nextInfo['period'] as int) > 0
                          ? Text('第${nextInfo['period']}節 • 開始時間 ${nextInfo['startTime']}')
                          : Text(nextInfo['subject'] as String),
                      trailing: nextInfo['period'] as int > 0
                          ? Text(
                              nextInfo['startTime'] as String,
                              style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                            )
                          : null,
                      onTap: () {
                        // 可跳轉到課表或顯示詳細，可自行修改需求
                        widget.onQuickNav?.call(1);
                      },
                    ),
                  ),

                  const SizedBox(height: 24),
                  // 可擴充更多功能入口
                  Text(
                    "快速功能",
                    style: TextStyle(
                      fontSize: 18,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          icon: const Icon(Icons.table_chart),
                          label: const Text("課表"),
                          onPressed: () {
                            widget.onQuickNav?.call(1); // 課表
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.secondary,
                            foregroundColor: colorScheme.onSecondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          icon: const Icon(Icons.label),
                          label: const Text("照片筆記"),
                          onPressed: () {
                            widget.onQuickNav?.call(2); // 照片筆記
                          },
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
    );
  }
}

// 不需要 fakeTimetable 與 getCurrentPeriod 重複定義
int getCurrentPeriod() {
  final now = TimeOfDay.now();
  final minutes = now.hour * 60 + now.minute;
  if (minutes >= 8 * 60 + 10 && minutes < 9 * 60 + 10) return 1;      // 8:10~9:10
  if (minutes >= 9 * 60 + 10 && minutes < 10 * 60 + 10) return 2;     // 9:10~10:10
  if (minutes >= 10 * 60 + 10 && minutes < 11 * 60 + 10) return 3;    // 10:10~11:10
  if (minutes >= 11 * 60 + 10 && minutes < 12 * 60 + 10) return 4;    // 11:10~12:10
  if (minutes >= 13 * 60 && minutes < 14 * 60) return 5;              // 13:00~14:00
  if (minutes >= 14 * 60 && minutes < 15 * 60) return 6;              // 14:00~15:00
  if (minutes >= 15 * 60 + 10 && minutes < 16 * 60 + 10) return 7;    // 15:10~16:10
  if (minutes >= 16 * 60 + 10 && minutes < 17 * 60 + 10) return 8; // 16:10~17:10
  return 0; // 非上課時間
}
