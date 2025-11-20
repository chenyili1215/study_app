import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'timetable_importer.dart';
import 'app_localizations.dart';

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

  void _showAddHomeworkDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    final titleController = TextEditingController();
    DateTime? deadline;
    String? selectedSubject;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Icon(Icons.assignment, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context).t('add_homework'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    hint: Text(AppLocalizations.of(context).t('choose_subject')),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: TimetableData().table.expand((e) => e).toSet().where((s) => s.isNotEmpty).map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => selectedSubject = v,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).t('homework_title'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => deadline = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(border: Border.all()),
                      child: Text(deadline == null ? AppLocalizations.of(context).t('select_deadline') : '${deadline!.year}-${deadline!.month.toString().padLeft(2, '0')}-${deadline!.day.toString().padLeft(2, '0')}'),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context).t('cancel')),
              ),
              TextButton.icon(
                icon: Icon(Icons.save, color: colorScheme.primary),
                label: Text(AppLocalizations.of(context).t('save')),
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
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).t('homework_record'), style: const TextStyle(fontWeight: FontWeight.bold)),
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
              subtitle: Text('${hw.subject}  ${AppLocalizations.of(context).t('deadline_prefix')}${hw.deadline.year}-${hw.deadline.month.toString().padLeft(2, '0')}-${hw.deadline.day.toString().padLeft(2, '0')}'),
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