import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:screen_brightness/screen_brightness.dart';
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
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isRunning = false;
  bool _isScreenOn = true;
  int _currentNotificationIndex = 0;

  final List<Map<String, dynamic>> _notificationSchedule = [
    {
      'id': 0,
      'interval': const Duration(minutes: 10),
      'title': '10-Minute Timer',
      'body': '10 minutes have passed!',
    },
    {
      'id': 1,
      'interval': const Duration(minutes: 20),
      'title': '20-Minute Timer',
      'body': '20 minutes have passed!',
    },
    {
      'id': 2,
      'interval': const Duration(minutes: 20, seconds: 20),
      'title': '20:20 Timer',
      'body': '20 minutes and 20 seconds have passed!',
    },
  ];

  @override
  void initState() {
    super.initState();
    _monitorScreenState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _monitorScreenState() async {
    while (true) {
      final brightness = await ScreenBrightness().application;
      if (brightness == 0.0 && _isScreenOn) {
        print("Screen OFF: Cancel notifications");
        _isScreenOn = false;
        _stopNotifications();
      } else if (brightness > 0.0 && !_isScreenOn) {
        print("Screen ON: Reschedule notifications");
        _isScreenOn = true;
        _startNotifications();
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  void _startNotifications() {
    if (_isRunning) return;
    _isRunning = true;
    _currentNotificationIndex = 0; // 最初の通知から開始
    _scheduleNextNotification();
  }

  Future<void> _scheduleNextNotification() async {
    if (!_isRunning) return;

    final currentNotification =
        _notificationSchedule[_currentNotificationIndex];
    final nextTriggerTime =
        tz.TZDateTime.now(tz.local).add(currentNotification['interval']);

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
            presentAlert: true, presentSound: true, presentBadge: true);

    const NotificationDetails notificationDetails = NotificationDetails(
      iOS: iosNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      currentNotification['id'],
      currentNotification['title'],
      currentNotification['body'],
      nextTriggerTime,
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exact,
    );

    Future.delayed(currentNotification['interval'], () {
      if (_isRunning) {
        _currentNotificationIndex =
            (_currentNotificationIndex + 1) % _notificationSchedule.length;
        _scheduleNextNotification();
      }
    });
  }

  void _stopNotifications() async {
    _isRunning = false;
    await flutterLocalNotificationsPlugin.cancelAll();
    print("All notifications cancelled");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Screen-Dependent Notifications')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _startNotifications,
              child: const Text('Start Notifications'),
            ),
            ElevatedButton(
              onPressed: _stopNotifications,
              child: const Text('Stop Notifications'),
            ),
          ],
        ),
      ),
    );
  }
}
