import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show debugPrint;

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  NotificationService._init();

  Future<void> initialize() async {
    try {
      tz_data.initializeTimeZones();

      final AndroidInitializationSettings androidSettings =
          const AndroidInitializationSettings('@mipmap/ic_launcher');

      final DarwinInitializationSettings iosSettings =
          const DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      final LinuxInitializationSettings? linuxSettings = null;

      final InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        linux: linuxSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      await _requestPermissions();
    } catch (e) {
    }
  }

  Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  void _onNotificationTapped(NotificationResponse response) {
  }

  Future<void> scheduleDailyReminder() async {
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        debugPrint(
            'Scheduled notifications not fully supported on desktop platforms');
        return;
      }

      final now = DateTime.now();
      final scheduledTime =
          DateTime(now.year, now.month, now.day, 20, 0);

      final targetTime = scheduledTime.isBefore(now)
          ? scheduledTime.add(const Duration(days: 1))
          : scheduledTime;

      final tzDateTime = tz.TZDateTime.from(
        targetTime,
        tz.local,
      );

      await _notifications.zonedSchedule(
        999,
        'Daily Journal Reminder',
        'Don\'t forget to write in your journal today! 📔',
        tzDateTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'journal_channel',
            'Journal Reminders',
            channelDescription: 'Daily reminders to write in your journal',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents:
            DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Could not schedule daily reminder: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    try {
      NotificationDetails notificationDetails;

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        notificationDetails = const NotificationDetails();
      } else {
        notificationDetails = const NotificationDetails(
          android: AndroidNotificationDetails(
            'journal_channel',
            'Journal Reminders',
            channelDescription: 'Daily reminders to write in your journal',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        );
      }

      await _notifications.show(
        0,
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
      debugPrint('Could not show notification: $e');
    }
  }
}
