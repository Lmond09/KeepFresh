import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';
import '../services/storage_service.dart';
import 'package:timezone/timezone.dart' as tz;


class ReminderService {

  /// Displays a notification if any fridge items are expiring within the next 3 days
  static Future<void> showExpiryReminders(String username) async {
    final items = await StorageService.loadFridgeItems(username);
    final now = DateTime.now();
    final soonExpiring = items.where((item) {  // Filter items that are expiring in the next 3 days (inclusive)
      final daysLeft = item.expirationDate.difference(now).inDays;
      return daysLeft >= 0 && daysLeft <= 3;
    }).toList();

    if (soonExpiring.isEmpty) return;
    
     // Generate a list of expiring item names and their respective countdown
    final titles = soonExpiring.map((e) {
      final daysLeft = e.expirationDate.difference(now).inDays;
      return '- ${e.name} (in $daysLeft day${daysLeft == 1 ? '' : 's'})';
    }).join("\n");


    // Define notification details for Android platform
    final androidDetails = AndroidNotificationDetails(
      'expiry_channel',
      'Expiry Notifications',
      channelDescription: 'Alerts for items nearing expiration',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const notificationId = 0;
    // Display the notification
    await flutterLocalNotificationsPlugin.show(
      notificationId,
      'Expiring Soon!',
      'Tap to review expiring food items.',
      NotificationDetails(android: androidDetails),
      payload: titles,
    );
  }

 /// Schedules a daily notification at 8:00 AM to remind the user to check for expiring items
  static Future<void> scheduleDailyReminder(String username) async {
    final time = Time(8, 0, 0); // 8:00 AM

    final androidDetails = AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Expiry Check',
      channelDescription: 'Daily alert to check for expiring items',
      importance: Importance.max,
      priority: Priority.high,
    );

    // Schedule a daily notification using timezone-aware time
    await flutterLocalNotificationsPlugin.zonedSchedule(
      1,
      'Check your fridge today!',
      'Tap to see what might be expiring soon.',
      _nextInstanceOf(time),
      NotificationDetails(android: androidDetails),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,   // Repeat daily at the same time
      payload: 'daily-check',
    );
  }

 /// Returns the next instance of the given time 
  static tz.TZDateTime _nextInstanceOf(Time time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
