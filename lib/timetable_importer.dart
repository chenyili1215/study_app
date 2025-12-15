import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_localizations.dart';
import 'dart:convert';

// 全域課表單例
class TimetableData {
  static final TimetableData _instance = TimetableData._internal();
  factory TimetableData() => _instance;
  TimetableData._internal();

  int periods = 7; // 新增：預設 7 節
  List<List<String>> table = List.generate(5, (_) => List.generate(7, (_) => ''));
  List<List<String>> locations = List.generate(5, (_) => List.generate(7, (_) => ''));
  List<List<String>> teachers = List.generate(5, (_) => List.generate(7, (_) => ''));
  String name = '我的課表';

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('timetable', jsonEncode(table));
    await prefs.setString('timetable_locations', jsonEncode(locations));
    await prefs.setString('timetable_teachers', jsonEncode(teachers));
    await prefs.setString('timetable_name', name);
    await prefs.setInt('timetable_periods', periods); // 儲存節數
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final tableData = prefs.getString('timetable');
    if (tableData != null) {
      final decoded = jsonDecode(tableData);
      table = List<List<String>>.from(decoded.map((row) => List<String>.from(row)));
    }
    final locData = prefs.getString('timetable_locations');
    if (locData != null) {
      final decoded = jsonDecode(locData);
      locations = List<List<String>>.from(decoded.map((row) => List<String>.from(row)));
    }
    final teacherData = prefs.getString('timetable_teachers');
    if (teacherData != null) {
      final decoded = jsonDecode(teacherData);
      teachers = List<List<String>>.from(decoded.map((row) => List<String>.from(row)));
    }
    name = prefs.getString('timetable_name') ?? '我的課表';
    periods = prefs.getInt('timetable_periods') ?? 7; // 讀取節數
    // 若資料長度不符，重建
    if (table.length != 5 || table.any((row) => row.length != periods)) {
      table = List.generate(5, (_) => List.generate(periods, (_) => ''));
      locations = List.generate(5, (_) => List.generate(periods, (_) => ''));
      teachers = List.generate(5, (_) => List.generate(periods, (_) => ''));
    }
  }
}

class TimetableImporter extends StatefulWidget {
  const TimetableImporter({super.key});

  @override
  State<TimetableImporter> createState() => _TimetableImporterState();
}

class _TimetableImporterState extends State<TimetableImporter> {
  final TimetableData timetable = TimetableData();
  bool? _isEditing = false;

  @override
  void initState() {
    super.initState();
    timetable.load().then((_) => setState(() {}));
  }

  // 新增：課名自動換行函式
  String breakSubject(String subject) {
    if (subject.length <= 2) return subject;
    int mid = (subject.length / 2).ceil();
    return '${subject.substring(0, mid)}\n${subject.substring(mid)}';
  }

  void _showSetPeriodsDialog() async {
    final controller = TextEditingController(text: timetable.periods.toString());
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context).t('set_periods_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).t('enter_periods_label'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            child: Text(AppLocalizations.of(context).t('cancel')),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text(AppLocalizations.of(context).t('save')),
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0 && val <= 12) {
                setState(() {
                  timetable.periods = val;
                  timetable.table = List.generate(5, (_) => List.generate(val, (_) => ''));
                  timetable.locations = List.generate(5, (_) => List.generate(val, (_) => ''));
                  timetable.teachers = List.generate(5, (_) => List.generate(val, (_) => ''));
                });
                timetable.save();
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final today = DateTime.now().weekday;
    bool isEditing = _isEditing ?? false;

    return Scaffold(
      appBar: AppBar(
        title: isEditing
            ? SizedBox(
                height: 48,
                child: TextFormField(
                  initialValue: timetable.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: AppLocalizations.of(context).t('enter_timetable_name'),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                  onChanged: (v) {
                    timetable.name = v;
                  },
                ),
              )
            : Text(
                timetable.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.close : Icons.edit),
            tooltip: isEditing ? AppLocalizations.of(context).t('cancel') : AppLocalizations.of(context).t('edit_periods'),
            onPressed: () {
              setState(() {
                _isEditing = !isEditing;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              color: colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 60),
                        ...List.generate(
                          5,
                          (d) => Expanded(
                            child: Center(
                              child: Text(
                                AppLocalizations.of(context).t('weekday_${d + 1}'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    // 課表表格
                    ...List.generate(
                      timetable.periods,
                      (period) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 60,
                              child: Text(
                                AppLocalizations.of(context).tWithNumber('period_format', period + 1),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.secondary,
                                ),
                              ),
                            ),
                            ...List.generate(
                              5,
                              (day) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: GestureDetector(
                                      onLongPress: () async {
                                        final subjectController = TextEditingController(text: timetable.table[day][period]);
                                        final locationController = TextEditingController(text: timetable.locations[day][period]);
                                        final teacherController = TextEditingController(text: timetable.teachers[day][period]);
                                        await showGeneralDialog(
                                          context: context,
                                          barrierDismissible: true,
                                          barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
                                          transitionDuration: const Duration(milliseconds: 320),
                                          pageBuilder: (context, animation, secondaryAnimation) {
                                            return Center(
                                              child: Material(
                                                color: Colors.transparent,
                                                child: AlertDialog(
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                                  title: Row(
                                                    children: [
                                                      const Icon(Icons.edit, color: Colors.blueAccent),
                                                      const SizedBox(width: 8),
                                                      Text(AppLocalizations.of(context).t('details'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                                                    ],
                                                  ),
                                                  content: SingleChildScrollView(
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        TextField(
                                                          controller: subjectController,
                                                          decoration: InputDecoration(
                                                            labelText: AppLocalizations.of(context).t('subject_label'),
                                                            prefixIcon: const Icon(Icons.book),
                                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                                            filled: true,
                                                            fillColor: Colors.blue.shade50,
                                                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                                          ),
                                                        ),
                                                        const SizedBox(height: 16),
                                                        TextField(
                                                          controller: locationController,
                                                          decoration: InputDecoration(
                                                            labelText: AppLocalizations.of(context).t('location_label'),
                                                            prefixIcon: const Icon(Icons.location_on),
                                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                                            filled: true,
                                                            fillColor: Colors.green.shade50,
                                                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                                          ),
                                                        ),
                                                        const SizedBox(height: 16),
                                                        TextField(
                                                          controller: teacherController,
                                                          decoration: InputDecoration(
                                                            labelText: AppLocalizations.of(context).t('teacher_label'),
                                                            prefixIcon: const Icon(Icons.person),
                                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                                            filled: true,
                                                            fillColor: Colors.orange.shade50,
                                                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  actions: [
                                                    TextButton.icon(
                                                      icon: const Icon(Icons.save, color: Colors.blueAccent),
                                                      label: Text(AppLocalizations.of(context).t('save'), style: const TextStyle(fontWeight: FontWeight.bold)),
                                                      onPressed: () {
                                                        final subject = subjectController.text;
                                                        final location = locationController.text;
                                                        final teacher = teacherController.text;

                                                        // 先儲存目前格
                                                        timetable.table[day][period] = subject;
                                                        timetable.locations[day][period] = location;
                                                        timetable.teachers[day][period] = teacher;

                                                        // 新增：同步所有同課程名稱的格子
                                                        for (int d = 0; d < 5; d++) {
                                                          for (int p = 0; p < timetable.periods; p++) {
                                                            if (timetable.table[d][p] == subject && subject.isNotEmpty) {
                                                              timetable.locations[d][p] = location;
                                                              timetable.teachers[d][p] = teacher;
                                                            }
                                                          }
                                                        }

                                                        timetable.save();
                                                        Navigator.of(context).pop();
                                                        setState(() {});
                                                      },
                                                    ),
                                                    TextButton.icon(
                                                      icon: const Icon(Icons.cancel, color: Colors.grey),
                                                      label: Text(AppLocalizations.of(context).t('cancel')),
                                                      onPressed: () => Navigator.of(context).pop(),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                      child: Material(
                                        elevation: 1,
                                        borderRadius: BorderRadius.circular(12),
                                        color: colorScheme.surface,
                                        child: isEditing
                                            ? Center(
                                                child: TextFormField(
                                                  initialValue: timetable.table[day][period],
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  style: const TextStyle(fontSize: 16),
                                                  decoration: InputDecoration(
                                                    isDense: true,
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                      borderSide: BorderSide.none,
                                                    ),
                                                    filled: true,
                                                    fillColor: colorScheme.surface,
                                                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                                  ),
                                                  onChanged: (v) {
                                                    timetable.table[day][period] = v.replaceAll("'", "");
                                                  },
                                                ),
                                              )
                                            : Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      breakSubject(timetable.table[day][period]),
                                                      textAlign: TextAlign.center,
                                                      style: const TextStyle(fontSize: 16),
                                                      softWrap: true,
                                                    ),
                                                    if (timetable.locations[day][period].isNotEmpty)
                                                      Text(
                                                        timetable.locations[day][period],
                                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                      ),
                                                    if (timetable.teachers[day][period].isNotEmpty)
                                                      Text(
                                                        timetable.teachers[day][period],
                                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isEditing)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.save),
                                label: Text(AppLocalizations.of(context).t('save_timetable')),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                onPressed: () async {
                                  await timetable.save();
                                  setState(() {
                                    _isEditing = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(AppLocalizations.of(context).t('timetable_saved'))),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.settings),
                                label: Text(AppLocalizations.of(context).t('edit_periods')),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                onPressed: _showSetPeriodsDialog,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).t('current_class_info'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 當節課程
                Expanded(
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    color: colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      child: Builder(
                        builder: (context) {
                          final now = TimeOfDay.now();
                          final minutes = now.hour * 60 + now.minute;
                          final periods = [
                            8 * 60 + 10,
                            9 * 60 + 10,
                            10 * 60 + 10,
                            11 * 60 + 10,
                            13 * 60,
                            14 * 60,
                            15 * 60 + 10,
                            16 * 60 + 10,
                          ];
                          int currentPeriod = periods.lastIndexWhere((start) => minutes >= start) + 1;

                          if (currentPeriod > 7) currentPeriod = 0;

                          int todayIdx = (today - 1).clamp(0, 4);

                          String getSubject(int period) {
                            if (period < 1 || period > timetable.periods) return AppLocalizations.of(context).t('not_class_time');
                            final subject = timetable.table[todayIdx][period - 1];
                            return subject.isEmpty ? AppLocalizations.of(context).t('no_scheduled') : subject;
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context).t('current_class'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                getSubject(currentPeriod),
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // 下節課程
                Expanded(
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    color: colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      child: Builder(
                        builder: (context) {
                          final now = TimeOfDay.now();
                          final minutes = now.hour * 60 + now.minute;
                          final periods = [
                            8 * 60 + 10,
                            9 * 60 + 10,
                            10 * 60 + 10,
                            11 * 60 + 10,
                            13 * 60,
                            14 * 60,
                            15 * 60 + 10,
                            16 * 60 + 10,
                          ];
                          int currentPeriod = periods.lastIndexWhere((start) => minutes >= start) + 1;
                          int nextPeriod = currentPeriod < 7 ? currentPeriod + 1 : 0;
                          int todayIdx = (today - 1).clamp(0, 4);

                          String getSubject(int period) {
                            if (period < 1 || period > 7) return AppLocalizations.of(context).t('none');
                            final subject = timetable.table[todayIdx][period - 1];
                            return subject.isEmpty ? AppLocalizations.of(context).t('no_scheduled') : subject;
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context).t('next_class'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                getSubject(nextPeriod),
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}