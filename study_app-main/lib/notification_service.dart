import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'homework.dart';
import 'app_localizations.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;
  bool _isInitialized = false;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  FlutterLocalNotificationsPlugin get flutterLocalNotificationsPlugin {
    if (_flutterLocalNotificationsPlugin == null) {
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      print('⚠ 通知服務未完全初始化，使用備用實例');
    }
    return _flutterLocalNotificationsPlugin!;
  }

  bool get isInitialized => _isInitialized;

  Future<void> initNotifications() async {
    if (_isInitialized) {
      print('⚠ 通知系統已初始化，跳過重複初始化');
      return;
    }

    try {
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      const AndroidInitializationSettings androidInitializationSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings darwinInitializationSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: androidInitializationSettings,
            iOS: darwinInitializationSettings,
          );

      await _flutterLocalNotificationsPlugin!.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );
      print('✓ 通知插件初始化完成');

      // Android 13+ 創建通知渠道
      if (Platform.isAndroid) {
        print('Android: 創建通知渠道...');
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'homework_channel',
          '功課通知',
          description: '提醒即將到期的功課',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
          ledColor: Color.fromARGB(255, 255, 0, 0),
        );

        await _flutterLocalNotificationsPlugin!
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(channel);
        print('✓ Android 通知渠道已創建（優先級：高）');
      }

      _isInitialized = true;
      print('✓ 通知服務初始化成功，_isInitialized = true');

      // 請求通知權限（會在 Android 13+ 上顯示系統對話框）
      print('正在請求通知權限...');
      await _requestNotificationPermission();
    } catch (e, stackTrace) {
      print('✗ 通知系統初始化錯誤: $e');
      print('StackTrace: $stackTrace');
      _isInitialized = false;
      rethrow;
    }
  }

  // 請求通知權限
  Future<void> _requestNotificationPermission() async {
    try {
      if (Platform.isAndroid) {
        print('Android: 請求通知權限...');

        // 檢查當前通知狀態
        final androidImplementation = _flutterLocalNotificationsPlugin
            ?.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final areEnabled =
            await androidImplementation?.areNotificationsEnabled() ?? false;
        print('當前通知狀態: $areEnabled');

        // Android 13+ 使用 permission_handler 請求 POST_NOTIFICATIONS 權限
        if (!areEnabled && Platform.isAndroid) {
          print('Android 13+: 使用 permission_handler 請求權限...');
          final status = await Permission.notification.request();

          if (status.isDenied) {
            print('⚠️ 用戶拒絕了通知權限');
          } else if (status.isGranted) {
            print('✓ 用戶已授予通知權限');
          } else if (status.isPermanentlyDenied) {
            print('⚠️ 用戶永久拒絕了通知權限，請到設置中開啟');
            _showOpenSettingsRequest();
          }
        }
      } else if (Platform.isIOS) {
        print('iOS: 請求通知權限...');
        try {
          final iosImplementation = _flutterLocalNotificationsPlugin
              ?.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();
          final result = await iosImplementation?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          print('✓ iOS 通知權限結果: $result');
        } catch (e) {
          print('✗ iOS 權限請求失敗: $e');
        }
      }
    } catch (e, stackTrace) {
      print('⚠️ 權限請求異常: $e');
      print('StackTrace: $stackTrace');
    }
  }

  // 提示用戶打開設置（如果權限被永久拒絕）
  void _showOpenSettingsRequest() {
    print('提示用戶打開系統設置以啟用通知權限');
    // 這可以在 UI 層調用
  }

  void _onNotificationResponse(NotificationResponse response) {
    print('通知被點擊: ${response.payload}');
  }

  // 為功課設定通知
  Future<void> scheduleHomeworkNotification(Homework homework) async {
    try {
      if (!_isInitialized) {
        print('通知系統未初始化，嘗試初始化...');
        await initNotifications();
      }

      final prefs = await SharedPreferences.getInstance();
      final notificationIds =
          prefs.getStringList('homework_notification_ids') ?? [];
      final langCode = prefs.getString('locale') ?? 'zh';

      // 通知 ID（基於功課資訊）
      final notificationId =
          '${homework.subject}_${homework.deadline.toIso8601String()}'.hashCode
              .abs();

      // 截止前 24 小時提醒
      final notifyTime24h = homework.deadline.subtract(Duration(hours: 24));
      if (notifyTime24h.isAfter(DateTime.now())) {
        await _scheduleNotification(
          notificationId,
          AppLocalizations.tStatic('notification_homework_reminder', langCode),
          AppLocalizations.tStaticWithArgs(
            'notification_homework_24h',
            langCode,
            {'subject': homework.subject, 'title': homework.title},
          ),
          notifyTime24h,
          '${notificationId}_24h',
        );
      }

      // 截止前 1 小時提醒
      final notifyTime1h = homework.deadline.subtract(Duration(hours: 1));
      if (notifyTime1h.isAfter(DateTime.now())) {
        await _scheduleNotification(
          notificationId + 1,
          AppLocalizations.tStatic('notification_urgent_reminder', langCode),
          AppLocalizations.tStaticWithArgs(
            'notification_homework_1h',
            langCode,
            {'subject': homework.subject, 'title': homework.title},
          ),
          notifyTime1h,
          '${notificationId}_1h',
        );
      }

      // 記錄通知 ID
      notificationIds.add(notificationId.toString());
      await prefs.setStringList('homework_notification_ids', notificationIds);
      print('✓ 功課通知已排程: ${homework.subject} - ${homework.title}');
    } catch (e) {
      print('設定通知失敗: $e');
    }
  }

  Future<void> _scheduleNotification(
    int id,
    String title,
    String body,
    DateTime scheduledDate,
    String payload,
  ) async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'homework_channel',
            '功課通知',
            channelDescription: '提醒即將到期的功課',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            sound: 'default',
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exact,
        payload: payload,
      );
    } catch (e) {
      print('排程通知失敗: $e');
    }
  }

  // 取消功課通知
  Future<void> cancelHomeworkNotification(Homework homework) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationId =
          '${homework.subject}_${homework.deadline.toIso8601String()}'.hashCode
              .abs();

      // 取消 24 小時和 1 小時提醒
      await flutterLocalNotificationsPlugin.cancel(notificationId);
      await flutterLocalNotificationsPlugin.cancel(notificationId + 1);

      // 更新記錄
      final notificationIds =
          prefs.getStringList('homework_notification_ids') ?? [];
      notificationIds.removeWhere((id) => id == notificationId.toString());
      await prefs.setStringList('homework_notification_ids', notificationIds);
    } catch (e) {
      print('取消通知失敗: $e');
    }
  }

  // 為所有功課設定通知
  Future<void> scheduleAllHomeworkNotifications(
    List<Homework> homeworks,
  ) async {
    for (final homework in homeworks) {
      await scheduleHomeworkNotification(homework);
    }
  }
}
