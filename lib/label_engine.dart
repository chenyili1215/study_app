import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:photo_view/photo_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart'; // 請加這行
import 'package:share_plus/share_plus.dart'; // 新增

import 'timetable_importer.dart';

// 根據時間取得第幾節
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

class PhotoNote {
  final String imagePath;
  final int period;
  final String subject;
  final DateTime dateTime; // 新增

  PhotoNote({
    required this.imagePath,
    required this.period,
    required this.subject,
    required this.dateTime, // 新增
  });

  Map<String, dynamic> toJson() => {
        'imagePath': imagePath,
        'period': period,
        'subject': subject,
        'dateTime': dateTime.toIso8601String(), // 新增
      };

  factory PhotoNote.fromJson(Map<String, dynamic> json) => PhotoNote(
        imagePath: json['imagePath'],
        period: json['period'],
        subject: json['subject'],
        dateTime: DateTime.parse(json['dateTime'] ?? DateTime.now().toIso8601String()), // 新增
      );
}

class LabelEngine extends StatefulWidget {
  const LabelEngine({super.key});

  @override
  State<LabelEngine> createState() => _LabelEngineState();
}

class _LabelEngineState extends State<LabelEngine> {
  final List<PhotoNote> _photos = [];
  final Set<int> _selectedIndexes = {};
  bool _isSelecting = false;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('photos') ?? [];
    setState(() {
      _photos.clear();
      _photos.addAll(list.map((e) => PhotoNote.fromJson(jsonDecode(e))));
    });
  }

  Future<void> _savePhotos() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _photos.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('photos', list);
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      int period = getCurrentPeriod();
      DateTime now = DateTime.now();
      int weekday = now.weekday; // 1=Monday, 7=Sunday
      String subject = '';
      if (weekday >= 1 && weekday <= 5 && period > 0) {
        subject = TimetableData().table[weekday - 1][period - 1];
      }
      if (subject.isEmpty) subject = '下課/未排課';
      setState(() {
        _photos.add(PhotoNote(
          imagePath: pickedFile.path,
          period: period,
          subject: subject,
          dateTime: now, // 新增
        ));
      });
      await _savePhotos();
    }
  }

  Future<void> deletePhoto(int index, String subject) async {
    setState(() {
      _photos.removeWhere((note) => note.subject == subject && _photos.indexOf(note) == index);
    });
    await _savePhotos();
  }

  void openGallery(int initialIndex, List<PhotoNote> photos) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          body: PhotoViewGallery.builder(
            itemCount: photos.length,
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: FileImage(File(photos[index].imagePath)),
                minScale: PhotoViewComputedScale.contained * 1.0,
                maxScale: PhotoViewComputedScale.covered * 2.0,
              );
            },
            pageController: PageController(initialPage: initialIndex),
            scrollPhysics: const BouncingScrollPhysics(),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
        ),
      ),
    );
  }

  // 依科目分類
  Map<String, List<PhotoNote>> get groupedBySubject {
    Map<String, List<PhotoNote>> map = {};
    for (var note in _photos) {
      final key = note.subject;
      map.putIfAbsent(key, () => []).add(note);
    }
    return map;
  }

  // 搜尋用
  List<String> get filteredSubjects {
    final allSubjects = groupedBySubject.keys.toList();
    if (_searchText.trim().isEmpty) return allSubjects;
    return allSubjects.where((s) => s.contains(_searchText.trim())).toList();
  }

  // 進入單一科目所有相片頁
  void _openSubjectPhotos(String subject, List<PhotoNote> photos) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: Text(subject, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
        body: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final note = photos[index];
            return GestureDetector(
              onTap: () => openGallery(index, photos),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(note.imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        ),
      ),
    ));
  }

  void _onPhotoLongPress(int globalIndex) {
    setState(() {
      _isSelecting = true;
      _selectedIndexes.add(globalIndex);
    });
  }

  void _onPhotoTap(int globalIndex) {
    if (_isSelecting) {
      setState(() {
        if (_selectedIndexes.contains(globalIndex)) {
          _selectedIndexes.remove(globalIndex);
          if (_selectedIndexes.isEmpty) _isSelecting = false;
        } else {
          _selectedIndexes.add(globalIndex);
        }
      });
    } else {
      // 找到該照片在分組中的索引
      final entry = groupedBySubject.entries
          .expand((e) => e.value)
          .toList();
      final index = entry.indexWhere((note) => _photos[globalIndex] == note);
      openGallery(index >= 0 ? index : 0, entry);
    }
  }

  Future<void> _deleteSelectedPhotos() async {
    setState(() {
      _selectedIndexes.toList()
        ..sort((a, b) => b.compareTo(a)) // 先刪除大的index
        ..forEach((index) => _photos.removeAt(index));
      _selectedIndexes.clear();
      _isSelecting = false;
    });
    await _savePhotos();
  }

  Future<void> pickFileAndChooseSubject() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      // 取得所有課表科目（去除重複與空白）
      final subjects = TimetableData().table.expand((e) => e).toSet().where((s) => s.isNotEmpty).toList();
      String? selectedSubject = subjects.isNotEmpty ? subjects.first : '';
      await showDialog(
        context: context,
        builder: (context) {
          String? tempSubject = selectedSubject;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('選擇課程', style: TextStyle(fontWeight: FontWeight.bold)),
            content: DropdownButtonFormField<String>(
              value: tempSubject,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                filled: true,
              ),
              items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => tempSubject = v,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('取消'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  if (tempSubject != null && tempSubject!.isNotEmpty) {
                    setState(() {
                      _photos.add(PhotoNote(
                        imagePath: result.files.single.path!,
                        period: 0,
                        subject: tempSubject!,
                        dateTime: DateTime.now(),
                      ));
                    });
                    _savePhotos();
                    Navigator.pop(context);
                  }
                },
                child: const Text('確定'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: _isSelecting
          ? AppBar(
              title: Text('已選擇 ${_selectedIndexes.length} 張'),
              backgroundColor: colorScheme.primaryContainer,
              actions: [
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: '分享',
                  onPressed: () async {
                    final files = _selectedIndexes
                        .map((i) => XFile(_photos[i].imagePath))
                        .toList();
                    if (files.isNotEmpty) {
                      await Share.shareXFiles(files, text: '分享我的課堂照片');
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteSelectedPhotos,
                ),
              ],
            )
          : AppBar(
              title: const Text('照片筆記'),
              backgroundColor: colorScheme.primaryContainer,
            ),
      body: Column(
        children: [
          // 搜尋框
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(24),
              color: colorScheme.surfaceContainerHighest,
              child: TextField(
                decoration: InputDecoration(
                  hintText: '搜尋課程',
                  prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onChanged: (v) => setState(() => _searchText = v),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_photos.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: Text(
                        '尚未新增照片',
                        style: TextStyle(
                          fontSize: 20,
                          color: colorScheme.outline,
                        ),
                      ),
                    ),
                  ...filteredSubjects.map((subject) {
                    final photos = groupedBySubject[subject]!;
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      color: colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    subject,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.arrow_forward_ios_rounded, color: colorScheme.primary),
                                  tooltip: '檢視全部',
                                  onPressed: () => _openSubjectPhotos(subject, photos),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              alignment: WrapAlignment.start,
                              crossAxisAlignment: WrapCrossAlignment.start,
                              spacing: 12,
                              runSpacing: 12,
                              children: List.generate(
                                photos.length > 3 ? 3 : photos.length,
                                (index) {
                                  final note = photos[index];
                                  final globalIndex = _photos.indexOf(note);
                                  final selected = _selectedIndexes.contains(globalIndex);
                                  return GestureDetector(
                                    onLongPress: () => _onPhotoLongPress(globalIndex),
                                    onTap: () => _onPhotoTap(globalIndex),
                                    child: Stack(
                                      children: [
                                        Material(
                                          elevation: selected ? 8 : 2,
                                          borderRadius: BorderRadius.circular(16),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: Image.file(
                                              File(note.imagePath),
                                              width: 110,
                                              height: 110,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        if (selected)
                                          Positioned(
                                            top: 6,
                                            right: 6,
                                            child: Icon(Icons.check_circle, color: colorScheme.primary, size: 28),
                                          ),
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: colorScheme.secondaryContainer.withOpacity(0.85),
                                              borderRadius: const BorderRadius.only(
                                                bottomLeft: Radius.circular(16),
                                                bottomRight: Radius.circular(16),
                                              ),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            child: Text(
                                              // 顯示日期
                                              '${note.dateTime.year}-${note.dateTime.month.toString().padLeft(2, '0')}-${note.dateTime.day.toString().padLeft(2, '0')}',
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: colorScheme.onSecondaryContainer,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'attach',
            onPressed: pickFileAndChooseSubject,
            backgroundColor: colorScheme.secondary,
            tooltip: '從檔案加入',
            child: const Icon(Icons.attach_file, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'camera',
            onPressed: pickImage,
            backgroundColor: colorScheme.primary,
            tooltip: '拍照',
            child: const Icon(Icons.camera_alt, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// import 'package:google_mlkit_commons/google_mlkit_commons.dart';
// ...其他 ML Kit 相關 import