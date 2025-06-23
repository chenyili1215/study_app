import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// 全域課表單例
class TimetableData {
  static final TimetableData _instance = TimetableData._internal();
  factory TimetableData() => _instance;
  TimetableData._internal();

  List<List<String>> table = List.generate(5, (_) => List.generate(7, (_) => ''));

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(table);
    await prefs.setString('timetable', data);
  }

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

class TimetableImporter extends StatefulWidget {
  const TimetableImporter({super.key});

  @override
  State<TimetableImporter> createState() => _TimetableImporterState();
}

class _TimetableImporterState extends State<TimetableImporter> {
  final TimetableData timetable = TimetableData();
  List<List<dynamic>>? timetableData;

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
    );
    if (result != null) {
      final file = File(result.files.single.path!);
      if (file.path.endsWith('.csv')) {
        final csvString = await file.readAsString();
        final csvTable = CsvToListConverter().convert(csvString);
        setState(() => timetableData = csvTable);
      } else if (file.path.endsWith('.xlsx')) {
        final bytes = await file.readAsBytes();
        final excel = Excel.decodeBytes(bytes);
        final sheet = excel.tables[excel.tables.keys.first]!;
        setState(() => timetableData = sheet.rows);
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final today = DateTime.now().weekday; // 1=Monday, 7=Sunday
    bool isEditing = _isEditing ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('課表'),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.close : Icons.edit),
            tooltip: isEditing ? '取消編輯' : '編輯課表',
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
                                '星期${d + 1}',
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
                    ...List.generate(7, (period) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 60,
                            child: Text(
                              '第${period + 1}節',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.secondary,
                              ),
                            ),
                          ),
                          ...List.generate(5, (day) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                              child: AspectRatio(
                                aspectRatio: 1, // 正方形
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
                                          child: Text(
                                            breakSubject(timetable.table[day][period]),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 16),
                                            softWrap: true,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          )),
                        ],
                      ),
                    )),
                    if (isEditing)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.save),
                                label: const Text('儲存課表'),
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
                                    _isEditing = false; // 儲存後自動退出編輯模式
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('課表已儲存')),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.upload_file),
                                label: const Text('匯入課表'),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                onPressed: pickFile,
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
              '當日課表',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: colorScheme.surfaceContainerHighest,
              child: SizedBox(
                height: 320,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: 7,
                  itemBuilder: (context, period) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        child: Text('${period + 1}', style: TextStyle(color: colorScheme.onPrimaryContainer)),
                      ),
                      title: Text(
                        timetable.table[(today - 1).clamp(0, 4)][period],
                        style: const TextStyle(fontSize: 18),
                      ),
                      subtitle: Text('第${period + 1}節'),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// class _TimetableImporterState extends State<TimetableImporter> {
bool? _isEditing = false;
// ...其餘不變...