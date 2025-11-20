import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      AppLocalizations(const Locale('zh'));

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'zh': {
      'app_title': 'Study App',
      'home': '首頁',
      'timetable': '課表',
      'photo_notes': '照片筆記',
      'homework': '功課',
      'settings': '設定',
      'welcome_back': '歡迎回來！',
      'upcoming_homeworks': '接下來 7 天要交的功課',
      'no_homeworks': '未來 7 天內沒有功課',
      'course_info': '課程資訊',
      'current_course': '目前課程',
      'next_course': '下節課程',
      'today': '今天',
      'tomorrow': '明天',
      'days_remaining': '還有 {n} 天',
      'not_class_day': '今天不是上課日',
      'not_class_time': '目前非上課時間',
      'no_scheduled': '未排課',
      'today_no_more_classes': '今天已無課程',
      'error': '錯誤',
      // label_engine
      'trash': '垃圾桶',
      'trash_empty': '垃圾桶是空的',
      'deleted_on': '刪除於：',
      'share': '分享',
      'select_date': '選擇日期',
      'clear_date_filter': '清除日期篩選',
      'no_photos': '沒有照片',
      'no_photos_on_day': '這天沒有照片',
      'choose_subject': '選擇科目',
      'cancel': '取消',
      'confirm': '確定',
      'add_image_failed': '加入圖片失敗',
      'from_file': '從檔案加入',
      'camera': '拍照',
      'search_courses': '搜尋課程',
      'selected_count': '已選擇 {n} 張',
      'share_my_class_photos': '分享我的課堂照片',
      'restore': '復原',
      'delete_forever': '永久刪除',
      // homework
      'add_homework': '新增功課',
      'homework_record': '功課記錄',
      'homework_title': '功課標題',
      'select_deadline': '選擇截止日期',
      'save': '儲存',
      'deadline_prefix': '截止：',
      'language': '語言',
      'system': '跟隨系統',
      'lang_zh': '中文',
      'lang_en': 'English',
      'lang_ja': '日本語',
    },
    'en': {
      'app_title': 'Study App',
      'home': 'Home',
      'timetable': 'Timetable',
      'photo_notes': 'Photo Notes',
      'homework': 'Homework',
      'settings': 'Settings',
      'welcome_back': 'Welcome back!',
      'upcoming_homeworks': 'Homework due in next 7 days',
      'no_homeworks': 'No homework in the next 7 days',
      'course_info': 'Course info',
      'current_course': 'Current class',
      'next_course': 'Next class',
      'today': 'Today',
      'tomorrow': 'Tomorrow',
      'days_remaining': '{n} days left',
      'not_class_day': 'Today is not a school day',
      'not_class_time': 'Not in class time',
      'no_scheduled': 'No class scheduled',
      'today_no_more_classes': 'No more classes today',
      'error': 'Error',
      // label_engine
      'trash': 'Trash',
      'trash_empty': 'Trash is empty',
      'deleted_on': 'Deleted on: ',
      'share': 'Share',
      'select_date': 'Select date',
      'clear_date_filter': 'Clear date filter',
      'no_photos': 'No photos',
      'no_photos_on_day': 'No photos on this day',
      'choose_subject': 'Choose subject',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'add_image_failed': 'Failed to add image',
      'from_file': 'Add from file',
      'camera': 'Camera',
      'search_courses': 'Search subject',
      'selected_count': 'Selected {n}',
      'share_my_class_photos': 'Share my class photos',
      'restore': 'Restore',
      'delete_forever': 'Delete forever',
      // homework
      'add_homework': 'Add homework',
      'homework_record': 'Homework',
      'homework_title': 'Homework title',
      'select_deadline': 'Select deadline',
      'save': 'Save',
      'deadline_prefix': 'Deadline: ',
      'language': 'Language',
      'system': 'System default',
      'lang_zh': '中文',
      'lang_en': 'English',
      'lang_ja': '日本語',
    },
    'ja': {
      'app_title': 'Study App',
      'home': 'ホーム',
      'timetable': '時間割',
      'photo_notes': '写真ノート',
      'homework': '宿題',
      'settings': '設定',
      'welcome_back': 'お帰りなさい！',
      'upcoming_homeworks': '今後7日間の提出物',
      'no_homeworks': '今後7日間に宿題はありません',
      'course_info': '授業情報',
      'current_course': '現在の授業',
      'next_course': '次の授業',
      'today': '今日',
      'tomorrow': '明日',
      'days_remaining': 'あと{n}日',
      'not_class_day': '今日は授業日ではありません',
      'not_class_time': '現在は授業時間ではありません',
      'no_scheduled': '未登録',
      'today_no_more_classes': '今日はこれ以上授業はありません',
      'error': 'エラー',
      // label_engine
      'trash': 'ゴミ箱',
      'trash_empty': 'ゴミ箱は空です',
      'deleted_on': '削除日：',
      'share': '共有',
      'select_date': '日付選択',
      'clear_date_filter': '日付フィルタを解除',
      'no_photos': '写真がありません',
      'no_photos_on_day': 'この日は写真がありません',
      'choose_subject': '科目を選択',
      'cancel': 'キャンセル',
      'confirm': '決定',
      'add_image_failed': '画像の追加に失敗しました',
      'from_file': 'ファイルから追加',
      'camera': 'カメラ',
      'search_courses': '科目を検索',
      'selected_count': '{n} 枚選択',
      'share_my_class_photos': '授業の写真を共有',
      'restore': '復元',
      'delete_forever': '完全に削除',
      // homework
      'add_homework': '宿題を追加',
      'homework_record': '宿題一覧',
      'homework_title': '宿題タイトル',
      'select_deadline': '締切日を選択',
      'save': '保存',
      'deadline_prefix': '締切：',
      'language': '言語',
      'system': 'システムに合わせる',
      'lang_zh': '中文',
      'lang_en': 'English',
      'lang_ja': '日本語',
    },
  };

  String t(String key) {
    final code = locale.languageCode;
    return _localizedValues[code]?[key] ??
        _localizedValues['zh']![key] ??
        key;
  }

  String tWithNumber(String key, int n) {
    final raw = t(key);
    return raw.replaceAll('{n}', n.toString());
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['zh', 'en', 'ja'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}