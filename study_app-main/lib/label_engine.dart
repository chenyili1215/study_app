import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:photo_view/photo_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart'; // 新增
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;

import 'timetable_importer.dart';
import 'app_localizations.dart';

// 根據時間取得第幾節
int getCurrentPeriod() {
  final now = TimeOfDay.now();
  final minutes = now.hour * 60 + now.minute;
  if (minutes >= 8 * 60 + 10 && minutes < 9 * 60 + 10) return 1; // 8:10~9:10
  if (minutes >= 9 * 60 + 10 && minutes < 10 * 60 + 10) return 2; // 9:10~10:10
  if (minutes >= 10 * 60 + 10 && minutes < 11 * 60 + 10)
    return 3; // 10:10~11:10
  if (minutes >= 11 * 60 + 10 && minutes < 12 * 60 + 10)
    return 4; // 11:10~12:10
  if (minutes >= 13 * 60 && minutes < 14 * 60) return 5; // 13:00~14:00
  if (minutes >= 14 * 60 && minutes < 15 * 60) return 6; // 14:00~15:00
  if (minutes >= 15 * 60 + 10 && minutes < 16 * 60 + 10)
    return 7; // 15:10~16:10
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
    dateTime: DateTime.parse(
      json['dateTime'] ?? DateTime.now().toIso8601String(),
    ),
    deletedAt: json['deletedAt'] != null
        ? DateTime.parse(json['deletedAt'])
        : null,
  );
}

class LabelEngine extends StatefulWidget {
  const LabelEngine({super.key});

  @override
  State<LabelEngine> createState() => _LabelEngineState();
}

class _LabelEngineState extends State<LabelEngine> {
  final List<PhotoNote> _photos = [];
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadPhotos();
    // 初始化時清理已過期的已刪除照片
    Future.delayed(const Duration(seconds: 1), cleanupDeletedPhotos);
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
    img.Image? image = img.decodeImage(bytes);
    if (image == null) throw Exception('無法解碼圖片（可能格式不支援）');

    // 激進的尺寸調整：限制寬度為1280像素（更小的檔案）
    if (image.width > 1280) {
      final ratio = 1280 / image.width;
      image = img.copyResize(
        image,
        width: 1280,
        height: (image.height * ratio).toInt(),
      );
    }

    // 激進的壓縮策略
    int quality = 70; // 初始品質降低
    List<int> jpg;
    do {
      jpg = img.encodeJpg(image, quality: quality);
      quality -= 5;
    } while (jpg.length > 1 * 1024 * 1024 && quality > 20); // 目標 1MB

    // 存到 app 文件資料夾
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savePath = p.join(dir.path, fileName);
    await File(savePath).writeAsBytes(jpg);

    print(
      '圖片壓縮完成: 原始 ${(bytes.length / 1024 / 1024).toStringAsFixed(2)}MB -> '
      '壓縮後 ${(jpg.length / 1024 / 1024).toStringAsFixed(2)}MB',
    );

    return savePath;
  }

  // 清理已刪除30天以上的照片文件
  Future<void> cleanupDeletedPhotos() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final filesToDelete = <String>[];
    for (final photo in _photos) {
      if (photo.deletedAt != null && photo.deletedAt!.isBefore(thirtyDaysAgo)) {
        filesToDelete.add(photo.imagePath);
      }
    }

    for (final filePath in filesToDelete) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('刪除文件失敗: $e');
      }
    }

    setState(() {
      _photos.removeWhere((p) => filesToDelete.contains(p.imagePath));
    });
    await _savePhotos();
  }

  // 獲取儲存空間使用情況
  Future<int> getStorageUsage() async {
    int totalSize = 0;
    for (final photo in _photos) {
      try {
        final file = File(photo.imagePath);
        if (await file.exists()) {
          totalSize += await file.length();
        }
      } catch (e) {
        print('計算文件大小失敗: $e');
      }
    }
    return totalSize;
  }

  // 永久刪除照片
  Future<void> permanentlyDeletePhoto(int index) async {
    if (index < 0 || index >= _photos.length) return;
    try {
      final file = File(_photos[index].imagePath);
      if (await file.exists()) {
        await file.delete();
      }
      setState(() {
        _photos.removeAt(index);
      });
      await _savePhotos();
    } catch (e) {
      print('永久刪除失敗: $e');
    }
  }

  // 恢復已刪除的照片
  Future<void> restoreDeletedPhoto(int index) async {
    if (index < 0 || index >= _photos.length) return;
    setState(() {
      _photos[index] = PhotoNote(
        imagePath: _photos[index].imagePath,
        period: _photos[index].period,
        subject: _photos[index].subject,
        dateTime: _photos[index].dateTime,
        deletedAt: null,
      );
    });
    await _savePhotos();
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
        _photos.add(
          PhotoNote(
            imagePath: savePath,
            period: period,
            subject: subject,
            dateTime: now,
          ),
        );
      });
      await _savePhotos();
    } catch (e, st) {
      print('拍照錯誤: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context).t('take_photo_failed')}: $e',
          ),
        ),
      );
    }
  }

  Future<void> deletePhoto(int index, String subject) async {
    // 找到該科目（未刪除）的照片清單，將對應項目標記為 deletedAt（移到垃圾桶）
    final subjectPhotos = _photos
        .where((p) => p.subject == subject && p.deletedAt == null)
        .toList();
    if (index < 0 || index >= subjectPhotos.length) return;
    final note = subjectPhotos[index];
    final idx = _photos.indexWhere(
      (p) => p.imagePath == note.imagePath && p.dateTime == note.dateTime,
    );
    if (idx != -1) {
      setState(() {
        _photos[idx] = PhotoNote(
          imagePath: _photos[idx].imagePath,
          period: _photos[idx].period,
          subject: _photos[idx].subject,
          dateTime: _photos[idx].dateTime,
          deletedAt: DateTime.now(),
        );
      });
      await _savePhotos();
    }
  }

  // 刪除時不要直接移除，改設 deletedAt
  void deletePhotoToTrash(int index) async {
    if (index < 0 || index >= _photos.length) return;
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
      final firstDate = photos
          .map((e) => e.dateTime)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final lastDate = photos
          .map((e) => e.dateTime)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedDate ?? now,
        firstDate: firstDate,
        lastDate: lastDate,
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
            dialogTheme: DialogThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
          ),
          child: child!,
        ),
      );
      if (picked != null) {
        setState(() {
          selectedDate = picked;
          filteredPhotos = photos
              .where(
                (e) =>
                    e.dateTime.year == picked.year &&
                    e.dateTime.month == picked.month &&
                    e.dateTime.day == picked.day,
              )
              .toList();
        });
      }
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StatefulBuilder(
          builder: (context, setState) => Scaffold(
            appBar: isSelecting
                ? AppBar(
                    title: Text(
                      AppLocalizations.of(
                        context,
                      ).tWithNumber('selected_count', selectedIndexes.length),
                    ),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.share),
                        tooltip: AppLocalizations.of(context).t('share'),
                        onPressed: () async {
                          final files = selectedIndexes
                              .map((i) => XFile(filteredPhotos[i].imagePath))
                              .toList();
                          if (files.isNotEmpty) {
                            await Share.shareXFiles(
                              files,
                              text: AppLocalizations.of(
                                context,
                              ).t('share_my_class_photos'),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          final now = DateTime.now();
                          setState(() {
                            // 從大到小處理選取索引，並在 _photos 中標記 deletedAt
                            selectedIndexes
                              ..sort((a, b) => b.compareTo(a))
                              ..forEach((i) {
                                final note = filteredPhotos[i];
                                final idx = _photos.indexWhere(
                                  (p) =>
                                      p.imagePath == note.imagePath &&
                                      p.dateTime == note.dateTime,
                                );
                                if (idx != -1) {
                                  _photos[idx] = PhotoNote(
                                    imagePath: _photos[idx].imagePath,
                                    period: _photos[idx].period,
                                    subject: _photos[idx].subject,
                                    dateTime: _photos[idx].dateTime,
                                    deletedAt: now,
                                  );
                                }
                              });
                            // 重新過濾出未刪除的照片供畫面顯示
                            filteredPhotos = photos.where((p) {
                              final idx = _photos.indexWhere(
                                (x) =>
                                    x.imagePath == p.imagePath &&
                                    x.dateTime == p.dateTime,
                              );
                              return idx != -1 &&
                                  _photos[idx].deletedAt == null;
                            }).toList();
                            selectedIndexes.clear();
                            isSelecting = false;
                          });
                          await _savePhotos();
                        },
                      ),
                    ],
                  )
                : AppBar(
                    title: Text(
                      subject,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        tooltip: AppLocalizations.of(context).t('select_date'),
                        onPressed: () => showCalendar(context, setState),
                      ),
                      if (selectedDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: AppLocalizations.of(
                            context,
                          ).t('clear_date_filter'),
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
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                                if (selectedIndexes.isEmpty)
                                  isSelecting = false;
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
                                child: Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 28,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> pickFileAndChooseSubject() async {
    try {
      final picker = ImagePicker();
      // 從相簿選圖（改成 single pick）
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final savePath = await saveAndCompressImage(picked.path);

      // 取得所有課表科目（去除重複與空白）
      final subjects = TimetableData().table
          .expand((e) => e)
          .toSet()
          .where((s) => s.isNotEmpty)
          .toList();
      String? selectedSubject = subjects.isNotEmpty ? subjects.first : '';

      await showDialog(
        context: context,
        builder: (context) {
          String? tempSubject = selectedSubject;
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              AppLocalizations.of(context).t('choose_subject'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: DropdownButtonFormField<String>(
              value: tempSubject,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                filled: true,
              ),
              items: subjects
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => tempSubject = v,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(AppLocalizations.of(context).t('cancel')),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  if (tempSubject != null && tempSubject!.isNotEmpty) {
                    setState(() {
                      _photos.add(
                        PhotoNote(
                          imagePath: savePath,
                          period: 0,
                          subject: tempSubject!,
                          dateTime: DateTime.now(),
                        ),
                      );
                    });
                    _savePhotos();
                    Navigator.pop(context);
                  }
                },
                child: Text(AppLocalizations.of(context).t('confirm')),
              ),
            ],
          );
        },
      );
    } catch (e, st) {
      print('從相簿加入錯誤: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context).t('add_image_failed')}: $e',
          ),
        ),
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
      _photos.removeWhere(
        (p) => p.deletedAt != null && now.difference(p.deletedAt!).inDays >= 30,
      );
    });
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(AppLocalizations.of(context).t('trash'))),
          body: trashPhotos.isEmpty
              ? Center(
                  child: Text(AppLocalizations.of(context).t('trash_empty')),
                )
              : ListView.builder(
                  itemCount: trashPhotos.length,
                  itemBuilder: (context, index) {
                    final note = trashPhotos[index];
                    return ListTile(
                      leading: Image.file(
                        File(note.imagePath),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                      title: Text(note.subject),
                      subtitle: Text(
                        '${AppLocalizations.of(context).t('deleted_on')}${note.deletedAt!.toLocal().toString().split(' ')[0]}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.restore),
                            tooltip: AppLocalizations.of(context).t('restore'),
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
                            tooltip: AppLocalizations.of(
                              context,
                            ).t('delete_forever'),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).t('photo_notes'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: AppLocalizations.of(context).t('trash'),
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
                  hintText: AppLocalizations.of(context).t('search_courses'),
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
                        AppLocalizations.of(context).t('no_photos_yet'),
                        style: TextStyle(
                          fontSize: 20,
                          color: colorScheme.outline,
                        ),
                      ),
                    ),
                  ...filteredSubjects.map((subject) {
                    final photos = groupedBySubject[subject]!
                        .where((p) => p.deletedAt == null)
                        .toList();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Material(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
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
            tooltip: AppLocalizations.of(context).t('from_file'),
            child: const Icon(Icons.attach_file, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'camera',
            onPressed: pickImage,
            backgroundColor: colorScheme.primary,
            tooltip: AppLocalizations.of(context).t('camera'),
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
