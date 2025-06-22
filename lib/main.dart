import 'package:flutter/material.dart';
import 'timetable_importer.dart';
import 'label_engine.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system, // 跟隨系統
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

  static const List<Widget> _pages = <Widget>[
    HomePage(),
    TimetableImporter(),
    LabelEngine(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    TimetableData().load().then((_) {
      setState(() {}); // 課表載入後刷新畫面
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // 取得目前課程
  String getCurrentClass() {
    int period = getCurrentPeriod();
    int weekday = _now.weekday; // 1=Monday, 7=Sunday
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
    return "$subject(第$period節)";
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                color: colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        "歡迎",
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
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
                          fontSize: 28,
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        "目前課程",
                        style: TextStyle(
                          fontSize: 24,
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          getCurrentClass(),
                          style: TextStyle(
                            fontSize: 24,
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
  return 0; // 非上課時間
}
