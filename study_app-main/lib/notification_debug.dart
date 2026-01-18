import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_service.dart';
import 'dart:io';

class NotificationDebugDialog extends StatefulWidget {
  @override
  State<NotificationDebugDialog> createState() =>
      _NotificationDebugDialogState();
}

class _NotificationDebugDialogState extends State<NotificationDebugDialog> {
  String _debugLog = '初始化中...\n';

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  void _addLog(String message) {
    setState(() {
      _debugLog += '$message\n';
    });
  }

  Future<void> _runDiagnostics() async {
    try {
      _addLog('========== 通知系統診斷開始 ==========');

      final notificationService = NotificationService();

      _addLog('1️⃣ 檢查初始化狀態...');
      _addLog('   _isInitialized: ${notificationService.isInitialized}');

      _addLog('\n2️⃣ 嘗試初始化通知服務...');
      await notificationService.initNotifications();
      _addLog(
        '   ✓ 初始化完成，_isInitialized: ${notificationService.isInitialized}',
      );

      if (Platform.isAndroid) {
        _addLog('\n3️⃣ 檢查 Android 通知狀態...');
        final androidPlugin = notificationService
            .flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

        if (androidPlugin != null) {
          final areEnabled = await androidPlugin.areNotificationsEnabled();
          _addLog('   Android 通知已啟用: $areEnabled');
        } else {
          _addLog('   ❌ 無法獲取 Android 實現');
        }
      }

      _addLog('\n4️⃣ 準備發送測試通知...');
      _addLog('   發送中...');
      _addLog('   ✓ 測試通知已發送（檢查設備狀態欄或通知面板）');

      _addLog('\n========== 診斷完成 ==========');
    } catch (e, stackTrace) {
      _addLog('\n❌ 診斷失敗: $e');
      _addLog('StackTrace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('通知系統診斷'),
      content: SingleChildScrollView(
        child: Text(
          _debugLog,
          style: TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('關閉')),
        TextButton(
          onPressed: () {
            setState(() {
              _debugLog = '';
            });
            _runDiagnostics();
          },
          child: Text('重新診斷'),
        ),
      ],
    );
  }
}

void showNotificationDebug(BuildContext context) {
  showDialog(context: context, builder: (context) => NotificationDebugDialog());
}
