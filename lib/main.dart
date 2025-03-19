import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Initialize Flutter Local Notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  showFlutterNotification(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await setupFlutterNotifications();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(MyApp());
}

Future<void> setupFlutterNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      print("Notification clicked: ${response.payload}");
    },
  );
}

void showFlutterNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
  AndroidNotificationDetails(
    'high_importance_channel', // Channel ID
    'High Importance Notifications', // Channel Name
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails notificationDetails =
  NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0, // Notification ID
    message.notification?.title ?? "No Title",
    message.notification?.body ?? "No Body",
    notificationDetails,
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FCM with Local Notifications',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String _fcmToken = '';

  @override
  void initState() {
    super.initState();
    _firebaseMessaging.requestPermission();
    _getFCMToken();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Foreground notification received: ${message.notification?.title}");
      showFlutterNotification(message);
    });
  }

  Future<void> _getFCMToken() async {
    String? token = await _firebaseMessaging.getToken();
    setState(() {
      _fcmToken = token ?? 'No token available';
    });
    print("FCM Token: $_fcmToken");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('FCM Demo')),
      body: Center(
        child: Text(
          'Waiting for Notifications...',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
