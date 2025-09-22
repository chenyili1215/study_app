import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:photo_view/photo_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart'; // 請加這行
import 'package:share_plus/share_plus.dart'; // 新增
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;

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
  final DateTime dateTime;
  final DateTime? deletedAt; // 新增

  PhotoNote({
    required this.imagePath,
    required this.period,
    required this.subject,
    required this.dateTime,
    this.deletedAt,
  });

  Map<String, dynamic> toJson() => {
    'imagePath': imagePath,
    'period': period,
    'subject': subject,
    'dateTime': dateTime.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory PhotoNote.fromJson(Map<String, dynamic> json) => PhotoNote(
    imagePath: json['imagePath'],
    period: json['period'],
    subject: json['subject'],
    dateTime: DateTime.parse(json['dateTime'] ?? DateTime.now().toIso8601String()),
    deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
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

  Future<String> saveAndCompressImage(String originPath) async {
    // 讀取原始圖片
    final bytes = await File(originPath).readAsBytes();
    img.Image? image = img.decodeImage(bytes); // image 套件已支援 heic
    if (image == null) throw Exception('無法解碼圖片（可能格式不支援）');

    // 壓縮品質遞減直到小於2MB
    int quality = 95;
    List<int> jpg;
    do {
      jpg = img.encodeJpg(image, quality: quality);
      quality -= 10;
    } while (jpg.length > 2 * 1024 * 1024 && quality > 10);

    // 存到 app 文件資料夾
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savePath = p.join(dir.path, fileName);
    await File(savePath).writeAsBytes(jpg);
    return savePath;
  }

  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile == null) return;
      print('拍照路徑: ${pickedFile.path}');
      final savePath = await saveAndCompressImage(pickedFile.path);
      int period = getCurrentPeriod();
      DateTime now = DateTime.now();
      int weekday = now.weekday;
      String subject = '';
      if (weekday >= 1 && weekday <= 5 && period > 0) {
        subject = TimetableData().table[weekday - 1][period - 1];
      }
      if (subject.isEmpty) subject = '下課/未排課';
      setState(() {
        _photos.add(PhotoNote(
          imagePath: savePath,
          period: period,
          subject: subject,
          dateTime: now,
        ));
      });
      await _savePhotos();
    } catch (e, st) {
      print('拍照錯誤: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('拍照失敗: $e')),
      );
    }
  }

  Future<void> deletePhoto(int index, String subject) async {
    setState(() {
      _photos.removeWhere((note) => note.subject == subject && _photos.indexOf(note) == index);
    });
    await _savePhotos();
  }

  // 刪除時不要直接移除，改設 deletedAt
  void deletePhotoToTrash(int index) async {
    setState(() {
      _photos[index] = PhotoNote(
        imagePath: _photos[index].imagePath,
        period: _photos[index].period,
        subject: _photos[index].subject,
        dateTime: _photos[index].dateTime,
        deletedAt: DateTime.now(),
      );
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
    // 每科目照片依日期由新到舊排序（最新的在前面）
    map.forEach((key, list) {
      list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    });
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
    List<int> selectedIndexes = [];
    bool isSelecting = false;
    DateTime? selectedDate;
    List<PhotoNote> filteredPhotos = photos;

    void showCalendar(BuildContext context, StateSetter setState) async {
      final now = DateTime.now();
      final firstDate = photos.map((e) => e.dateTime).reduce((a, b) => a.isBefore(b) ? a : b);
      final lastDate = photos.map((e) => e.dateTime).reduce((a, b) => a.isAfter(b) ? a : b);
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedDate ?? now,
        firstDate: firstDate,
        lastDate: lastDate,
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme, dialogTheme: DialogThemeData(backgroundColor: Theme.of(context).colorScheme.surface),
          ),
          child: child!,
        ),
      );
      if (picked != null) {
        setState(() {
          selectedDate = picked;
          filteredPhotos = photos.where((e) =>
            e.dateTime.year == picked.year &&
            e.dateTime.month == picked.month &&
            e.dateTime.day == picked.day
          ).toList();
        });
      }
    }

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => Scaffold(
          appBar: isSelecting
              ? AppBar(
                  title: Text('已選擇 ${selectedIndexes.length} 張'),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.share),
                      tooltip: '分享',
                      onPressed: () async {
                        final files = selectedIndexes
                            .map((i) => XFile(filteredPhotos[i].imagePath))
                            .toList();
                        if (files.isNotEmpty) {
                          await Share.shareXFiles(files, text: '分享我的課堂照片');
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        setState(() {
                          selectedIndexes
                            ..sort((a, b) => b.compareTo(a))
                            ..forEach((i) {
                              final path = filteredPhotos[i].imagePath;
                              File(path).delete(); // 實體檔案也刪除
                              filteredPhotos.removeAt(i);
                            });
                          selectedIndexes.clear();
                          isSelecting = false;
                        });
                        // 這裡同步刪除主資料
                        _photos.removeWhere((p) => photos.contains(p) && !filteredPhotos.contains(p));
                        await _savePhotos();
                      },
                    ),
                  ],
                )
              : AppBar(
                  title: Text(subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      tooltip: '選擇日期',
                      onPressed: () => showCalendar(context, setState),
                    ),
                    if (selectedDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: '清除日期篩選',
                        onPressed: () {
                          setState(() {
                            selectedDate = null;
                            filteredPhotos = photos;
                          });
                        },
                      ),
                  ],
                ),
          body: filteredPhotos.isEmpty
              ? Center(
                  child: Text(
                    selectedDate == null ? '沒有照片' : '這天沒有照片',
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1, // 這行讓每格是正方形
                  ),
                  itemCount: filteredPhotos.length,
                  itemBuilder: (context, index) {
                    final note = filteredPhotos[index];
                    final selected = selectedIndexes.contains(index);
                    return GestureDetector(
                      onLongPress: () {
                        setState(() {
                          isSelecting = true;
                          selectedIndexes.add(index);
                        });
                      },
                      onTap: () {
                        if (isSelecting) {
                          setState(() {
                            if (selected) {
                              selectedIndexes.remove(index);
                              if (selectedIndexes.isEmpty) isSelecting = false;
                            } else {
                              selectedIndexes.add(index);
                            }
                          });
                        } else {
                          openGallery(index, filteredPhotos);
                        }
                      },
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: AspectRatio(
                              aspectRatio: 1, // 保持正方形
                              child: Image.file(
                                File(note.imagePath),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          if (selected)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 28),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    ));
  }



  Future<void> _deleteSelectedPhotos() async {
    setState(() {
      _selectedIndexes.toList()
        ..sort((a, b) => b.compareTo(a))
        ..forEach((index) {
          final path = _photos[index].imagePath;
          File(path).delete(); // 實體檔案也刪除
          _photos.removeAt(index);
        });
      _selectedIndexes.clear();
      _isSelecting = false;
    });
    await _savePhotos();
  }

  Future<void> pickFileAndChooseSubject() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final savePath = await saveAndCompressImage(result.files.single.path!);
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
                        imagePath: savePath,
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

  void _openTrash() {
    // 自動清理超過30天的照片
    final now = DateTime.now();
    final trashPhotos = _photos.where((p) => p.deletedAt != null).toList();
    trashPhotos.removeWhere((p) {
      final expired = now.difference(p.deletedAt!).inDays >= 30;
      if (expired) File(p.imagePath).delete();
      return expired;
    });
    setState(() {
      _photos.removeWhere((p) => p.deletedAt != null && now.difference(p.deletedAt!).inDays >= 30);
    });
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('垃圾桶')),
        body: trashPhotos.isEmpty
          ? const Center(child: Text('垃圾桶是空的'))
          : ListView.builder(
              itemCount: trashPhotos.length,
              itemBuilder: (context, index) {
                final note = trashPhotos[index];
                return ListTile(
                  leading: Image.file(File(note.imagePath), width: 48, height: 48, fit: BoxFit.cover),
                  title: Text(note.subject),
                  subtitle: Text('刪除於：${note.deletedAt!.toLocal().toString().split(' ')[0]}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.restore),
                        tooltip: '復原',
                        onPressed: () async {
                          setState(() {
                            final idx = _photos.indexOf(note);
                            if (idx != -1) {
                              _photos[idx] = PhotoNote(
                                imagePath: note.imagePath,
                                period: note.period,
                                subject: note.subject,
                                dateTime: note.dateTime,
                                deletedAt: null,
                              );
                            }
                          });
                          await _savePhotos();
                          Navigator.of(context).pop();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever),
                        tooltip: '永久刪除',
                        onPressed: () async {
                          File(note.imagePath).delete();
                          setState(() {
                            _photos.remove(note);
                          });
                          await _savePhotos();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '照片筆記',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '垃圾桶',
            onPressed: () => _openTrash(),
          ),
        ],
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
  final photos = groupedBySubject[subject]!.where((p) => p.deletedAt == null).toList();
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          subject,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded),
        onTap: () => _openSubjectPhotos(subject, photos),
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