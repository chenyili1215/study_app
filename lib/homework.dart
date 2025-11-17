import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'timetable_importer.dart';

class Homework {
  final String subject;
  final String title;
  final DateTime deadline;

  Homework({required this.subject, required this.title, required this.deadline});

  Map<String, dynamic> toJson() => {
    'subject': subject,
    'title': title,
    'deadline': deadline.toIso8601String(),
  };

  factory Homework.fromJson(Map<String, dynamic> json) => Homework(
    subject: json['subject'],
    title: json['title'],
    deadline: DateTime.parse(json['deadline']),
  );
}

class HomeworkPage extends StatefulWidget {
  const HomeworkPage({super.key});

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  List<Homework> _homeworks = [];

  @override
  void initState() {
    super.initState();
    _loadHomeworks();
  }

  Future<void> _loadHomeworks() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('homeworks') ?? [];
    setState(() {
      _homeworks = list.map((e) => Homework.fromJson(Map<String, dynamic>.from(jsonDecode(e)))).toList();
    });
  }

  Future<void> _saveHomeworks() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _homeworks.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('homeworks', list);
  }

  void _showAddHomeworkDialog() async {
    final subjects = TimetableData().table.expand((e) => e).toSet().where((s) => s.isNotEmpty).toList();
    String? selectedSubject = subjects.isNotEmpty ? subjects.first : '';
    final titleController = TextEditingController();
    DateTime? deadline;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: const [
              Icon(Icons.assignment, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text('新增功課', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 220), // 固定最小高度
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedSubject,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: '課程',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                    ),
                    items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => selectedSubject = v),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: '功課名稱',
                      prefixIcon: const Icon(Icons.edit),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => deadline = picked);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: '截止日期',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        filled: true,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            deadline == null
                                ? '請選擇日期'
                                : '${deadline!.year}-${deadline!.month.toString().padLeft(2, '0')}-${deadline!.day.toString().padLeft(2, '0')}',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.cancel, color: Colors.grey),
              label: const Text('取消'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton.icon(
              icon: const Icon(Icons.save, color: Colors.blueAccent),
              label: const Text('儲存'),
              onPressed: () {
                if (selectedSubject != null && titleController.text.isNotEmpty && deadline != null) {
                  setState(() {
                    _homeworks.add(Homework(
                      subject: selectedSubject!,
                      title: titleController.text,
                      deadline: deadline!,
                    ));
                  });
                  _saveHomeworks();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('功課記錄', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _homeworks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final hw = _homeworks[index];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: colorScheme.surfaceContainerHighest,
            child: ListTile(
              leading: Icon(Icons.assignment, color: colorScheme.primary),
              title: Text(hw.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${hw.subject}  截止：${hw.deadline.year}-${hw.deadline.month.toString().padLeft(2, '0')}-${hw.deadline.day.toString().padLeft(2, '0')}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () async {
                  setState(() => _homeworks.removeAt(index));
                  await _saveHomeworks();
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        onPressed: _showAddHomeworkDialog,
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }
}