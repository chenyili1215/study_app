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
      'no_photos_yet': '尚未新增照片',
      'take_photo_failed': '拍照失敗',
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
      'theme_mode': '主題模式',
      'theme_color': '主題顏色',
      'custom_color': '自訂顏色',
      'about': '關於',
      'set_periods_title': '設定每天節數',
      'enter_periods_label': '每天幾節課',
      'enter_timetable_name': '請輸入課表名稱',
      'details': '詳細設定',
      'subject_label': '課程名稱',
      'location_label': '上課地點',
      'teacher_label': '老師名字',
      'save_timetable': '儲存課表',
      'timetable_saved': '課表已儲存',
      'edit_periods': '編輯課表節數',
      'current_class_info': '當前課程資訊',
      'current_class': '當節課程',
      'next_class': '下節課程',
   
      'none': '無',
      // 新增到各語系的 keys（示範三語系都加）
      'weekday_1': '星期一', // zh
      'weekday_2': '星期二',
      'weekday_3': '星期三',
      'weekday_4': '星期四',
      'weekday_5': '星期五',
      'period_format': '第{n}節',
      // label_engine
      'no_class_or_unscheduled': '下課/未排課',
      // settings
      'theme_light': '亮色',
      'theme_dark': '暗色',
      'theme_follow_system': '跟隨系統',
      'choose_theme_color': '選擇主題顏色',
      'close': '關閉',
      'easter_egg_title': '小彩蛋！',
      'easter_egg_content': '你發現了隱藏彩蛋！\n\n真是個聰明的學習者',
      'default_timetable_name': '我的課表',
      // color names
      'color_blue': '藍色',
      'color_green': '綠色',
      'color_purple': '紫色',
      'color_orange': '橙色',
      'color_red': '紅色',
      'color_teal': '藍綠',
      'color_pink': '粉紅',
      'color_brown': '咖啡',
      'color_indigo': '靛藍',
      'color_cyan': '青色',
      'color_amber': '琥珀',
      'color_deep_orange': '深橙',
      // notifications
      'notification_homework_reminder': '功課提醒',
      'notification_homework_24h': '{subject}：{title} 將在 24 小時後截止',
      'notification_urgent_reminder': '緊急提醒',
      'notification_homework_1h': '{subject}：{title} 將在 1 小時後截止！',
      // homework
      'confirm_delete': '確認刪除',
      'confirm_delete_homework': '確定要刪除這份功課嗎？',
      'delete': '刪除',
      'period_label': '第{n}節',
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
      'theme_mode': 'Theme mode',
      'theme_color': 'Theme color',
      'custom_color': 'Custom color',
      'about': 'About',
      'set_periods_title': 'Set periods per day',
      'enter_periods_label': 'How many periods per day',
      'enter_timetable_name': 'Enter timetable name',
      'details': 'Details',
      'subject_label': 'Subject',
      'location_label': 'Location',
      'teacher_label': 'Teacher',
      'save_timetable': 'Save timetable',
      'timetable_saved': 'Timetable saved',
      'edit_periods': 'Edit periods',
      'current_class_info': 'Current class info',
      'current_class': 'Current class',
      'next_class': 'Next class',
      'none': 'None',
      // 新增到各語系的 keys（示範三語系都加）
      'weekday_1': 'Mon',
      'weekday_2': 'Tue',
      'weekday_3': 'Wed',
      'weekday_4': 'Thu',
      'weekday_5': 'Fri',
      'period_format': 'Period {n}',
      'no_photos_yet': 'No photos yet',
      'take_photo_failed': 'Failed to take photo',
      // label_engine
      'no_class_or_unscheduled': 'Break / No class',
      // settings
      'theme_light': 'Light',
      'theme_dark': 'Dark',
      'theme_follow_system': 'Follow system',
      'choose_theme_color': 'Choose theme color',
      'close': 'Close',
      'easter_egg_title': 'Easter Egg!',
      'easter_egg_content': 'You found a hidden easter egg!\n\nYou are a smart learner',
      'default_timetable_name': 'My Timetable',
      // color names
      'color_blue': 'Blue',
      'color_green': 'Green',
      'color_purple': 'Purple',
      'color_orange': 'Orange',
      'color_red': 'Red',
      'color_teal': 'Teal',
      'color_pink': 'Pink',
      'color_brown': 'Brown',
      'color_indigo': 'Indigo',
      'color_cyan': 'Cyan',
      'color_amber': 'Amber',
      'color_deep_orange': 'Deep Orange',
      // notifications
      'notification_homework_reminder': 'Homework Reminder',
      'notification_homework_24h': '{subject}: {title} is due in 24 hours',
      'notification_urgent_reminder': 'Urgent Reminder',
      'notification_homework_1h': '{subject}: {title} is due in 1 hour!',
      // homework
      'confirm_delete': 'Confirm Delete',
      'confirm_delete_homework': 'Are you sure you want to delete this homework?',
      'delete': 'Delete',
      'period_label': 'Period {n}',
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
      'theme_mode': 'テーマモード',
      'theme_color': 'テーマカラー',
      'custom_color': 'カスタムカラー',
      'about': 'アプリについて',
      'set_periods_title': '毎日の授業数を設定',
      'enter_periods_label': '1日に何コマ',
      'enter_timetable_name': '時間割名を入力してください',
      'details': '詳細設定',
      'subject_label': '科目名',
      'location_label': '場所',
      'teacher_label': '先生名',
      'save_timetable': '時間割を保存',
      'timetable_saved': '時間割を保存しました',
      'edit_periods': 'コマ数を編集',
      'current_class_info': '現在の授業情報',
      'current_class': '当該授業',
      'next_class': '次の授業',
     
      'none': 'なし',
      // 新增到各語系的 keys（示範三語系都加）
      'weekday_1': '月',
      'weekday_2': '火',
      'weekday_3': '水',
      'weekday_4': '木',
      'weekday_5': '金',
      'period_format': '{n}時限',
      'no_photos_yet': 'まだ写真がありません',
      'take_photo_failed': '撮影に失敗しました',
      // label_engine
      'no_class_or_unscheduled': '休憩/未登録',
      // settings
      'theme_light': 'ライト',
      'theme_dark': 'ダーク',
      'theme_follow_system': 'システムに従う',
      'choose_theme_color': 'テーマカラーを選択',
      'close': '閉じる',
      'easter_egg_title': 'イースターエッグ！',
      'easter_egg_content': '隠しイースターエッグを見つけました！\n\nさすが賢い学習者ですね',
      'default_timetable_name': '時間割',
      // color names
      'color_blue': 'ブルー',
      'color_green': 'グリーン',
      'color_purple': 'パープル',
      'color_orange': 'オレンジ',
      'color_red': 'レッド',
      'color_teal': 'ティール',
      'color_pink': 'ピンク',
      'color_brown': 'ブラウン',
      'color_indigo': 'インディゴ',
      'color_cyan': 'シアン',
      'color_amber': 'アンバー',
      'color_deep_orange': 'ディープオレンジ',
      // notifications
      'notification_homework_reminder': '宿題リマインダー',
      'notification_homework_24h': '{subject}：{title} の締切まであと24時間',
      'notification_urgent_reminder': '緊急リマインダー',
      'notification_homework_1h': '{subject}：{title} の締切まであと1時間！',
      // homework
      'confirm_delete': '削除の確認',
      'confirm_delete_homework': 'この宿題を削除してもよろしいですか？',
      'delete': '削除',
      'period_label': '{n}時限目',
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

  /// 取得不需要 context 的靜態翻譯（供 notification 等無 context 場景使用）
  static String tStatic(String key, String langCode) {
    return _localizedValues[langCode]?[key] ??
        _localizedValues['zh']![key] ??
        key;
  }

  static String tStaticWithArgs(
    String key,
    String langCode,
    Map<String, String> args,
  ) {
    var raw = tStatic(key, langCode);
    args.forEach((k, v) => raw = raw.replaceAll('{$k}', v));
    return raw;
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