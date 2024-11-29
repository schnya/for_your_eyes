import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the timezone database
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Makassar'));

  // Initialize notification settings for iOS
  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const InitializationSettings initializationSettings =
      InitializationSettings(iOS: initializationSettingsDarwin);
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
  );
  runApp(const MyApp());
}

// Handle user interaction with a notification
void onDidReceiveNotificationResponse(NotificationResponse response) {
  print('Notification Tapped: ${response.payload}');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'For Your Eyes👀',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void scheduleNotification() async {
    print("Scheduling notification...");
    try {
      const DarwinNotificationDetails iosNotificationDetails =
          DarwinNotificationDetails(
              presentAlert: true, presentSound: true, presentBadge: true);

      const NotificationDetails notificationDetails = NotificationDetails(
        iOS: iosNotificationDetails,
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        'Scheduled Notification',
        'This is a test notification!',
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
        notificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exact,
        payload: 'Test Payload',
      );
      print("Notification scheduled successfully.");
    } catch (e) {
      print("Error scheduling notification: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications Example')),
      body: Center(
        child: ElevatedButton(
          onPressed: scheduleNotification,
          child: const Text('Schedule Notification'),
        ),
      ),
    );
  }
}
