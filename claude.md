# Study App - 專案記錄

## 專案概述

Flutter 學習輔助 App，支援 Android / iOS / Desktop。
- **SDK**: Dart ^3.8.1, Flutter (Material 3)
- **語言支援**: 中文、英文、日文
- **版本**: v1.0.12 (pubspec: 1.0.0+6)

## 架構

- **狀態管理**: `ValueNotifier` + `ValueListenableBuilder`（全域主題/語言），`setState`（局部）
- **資料持久化**: `SharedPreferences`（JSON 序列化）
- **設計模式**: Singleton（`TimetableData`、`NotificationService`）
- **導航**: `BottomNavigationBar` 5 頁切換（非 named routes）

## 檔案結構

| 檔案 | 功能 |
|------|------|
| `lib/main.dart` | 入口、首頁（歡迎頁、功課預覽、當前/下節課） |
| `lib/timetable_importer.dart` | 課表管理、`TimetableData` 單例、`getCurrentPeriod()` |
| `lib/label_engine.dart` | 照片筆記（拍照/相簿、壓縮、分類、分享、軟刪除回收站） |
| `lib/homework.dart` | 功課管理（新增/刪除、`Homework` model） |
| `lib/notification_service.dart` | 通知系統（功課截止前 24h/1h 提醒） |
| `lib/settings_page.dart` | 設定（主題模式/語言/主題色/彩蛋） |
| `lib/app_localizations.dart` | 多語言系統（手動 i18n，100+ key） |
| `lib/notification_debug.dart` | 通知除錯工具 |

## 關鍵設計決策

- `getCurrentPeriod()` 定義在 `timetable_importer.dart` 作為**唯一來源**，所有檔案共用
- `TimetableData` 單例僅在 `timetable_importer.dart` 定義（`main.dart` 中的重複版本已刪除）
- 通知服務使用 `AppLocalizations.tStatic()` 靜態方法取得翻譯（無 BuildContext 場景）
- 課表節數變更使用 `_resizeToFit()` 保留既有資料

## SharedPreferences Keys

| Key | 型態 | 用途 |
|-----|------|------|
| `timetable` | String (JSON 2D array) | 課表科目 |
| `timetable_locations` | String (JSON 2D array) | 上課地點 |
| `timetable_teachers` | String (JSON 2D array) | 老師名字 |
| `timetable_name` | String | 課表名稱 |
| `timetable_periods` | int | 每天節數 |
| `homeworks` | StringList (JSON) | 功課列表 |
| `photos` | StringList (JSON) | 照片筆記列表 |
| `seedColor` | int | 主題色 |
| `locale` | String | 語言代碼（zh/en/ja） |
| `homework_notification_ids` | StringList | 通知 ID 記錄 |

## 上課時間表（硬編碼）

| 節次 | 時間 |
|------|------|
| 1 | 08:10 - 09:10 |
| 2 | 09:10 - 10:10 |
| 3 | 10:10 - 11:10 |
| 4 | 11:10 - 12:10 |
| 5 | 13:00 - 14:00 |
| 6 | 14:00 - 15:00 |
| 7 | 15:10 - 16:10 |
| 8 | 16:10 - 17:10 |

## 已完成的修復（2026-01-26）

### 嚴重 Bug
1. **`TimetableData` 重複定義** — 刪除 `main.dart` 中簡化版，統一用 `timetable_importer.dart` 完整版
2. **`getCurrentPeriod()` 三處定義邏輯不一致** — 統一到 `timetable_importer.dart`，刪除 main.dart 和 label_engine.dart 的副本
3. **課表節數變更清除所有資料** — 新增 `_resizeToFit()` 保留既有資料

### 中等 Bug
4. **30+ 處硬編碼中文字串** — 新增 35+ 翻譯 key（中/英/日），全部改用 `AppLocalizations`
5. **垃圾桶頁面每次操作都 pop** — 改用 `StatefulBuilder` 就地更新
6. **照片載入無 try-catch** — 加入錯誤處理，跳過損壞資料
7. **功課刪除無確認** — 新增確認對話框
8. **`groupedBySubject` 包含已刪除照片** — 加入 `deletedAt != null` 過濾
9. **功課新增後列表不刷新** — `StatefulBuilder` setState 改名 `setDialogState`，dialog 關閉後呼叫 `_loadHomeworks()`

### 輕微問題
10. `bool?` → `bool`（`_isEditing`）
11. Timer 每秒 → 每 60 秒
12. `static const Map<Color>` → `static final`（Color 覆寫 `==`）
13. 移除 `??` dead code
14. 通知服務新增 `tStatic` / `tStaticWithArgs` 靜態翻譯方法

## 已知的 info 級警告（非破壞性）

- `withOpacity` deprecated → 應改用 `.withValues(alpha:)`
- `avoid_print` — notification_service 大量 print 語句
- `use_build_context_synchronously` — async gap 中使用 context
- `depend_on_referenced_packages` — label_engine 引用 `path` 但未在 pubspec 宣告

## 未來可改善方向

### 效能優化
- 圖片壓縮移到 `compute()` / Isolate（目前在主執行緒）
- 快取 `SharedPreferences` instance
- 使用 `IndexedStack` 保留頁面狀態（目前切換 tab 會重建）
- 照片 lazy loading / 分頁載入

### 功能建議
- **高優先**: 功課完成標記、自訂上課時間、匯出/匯入資料、自訂通知時間、日曆檢視
- **中優先**: 考試追蹤、成績記錄、番茄鐘、課前提醒通知、照片 OCR、多課表支援
- **低優先**: 雲端同步、桌面小工具、AI 學習建議、同學分享

### 架構改善
- 引入 Repository 層統一資料存取
- 考慮 SQLite (`sqflite`) 取代 SharedPreferences
- 將上課時間配置化（存入設定而非硬編碼）
