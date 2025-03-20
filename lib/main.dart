import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  String _notificationText = 'Waiting for Notifications...'; // Added this line for notification text

  @override
  void initState() {
    super.initState();
    _firebaseMessaging.requestPermission();
    _getFCMToken();

    // Foreground message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Foreground notification received: ${message.notification?.title}");
      setState(() {
        _notificationText = message.notification?.body ?? 'New notification received';
      });
      showFlutterNotification(message);
    });

    // Background message listener
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notification clicked: ${message.notification?.title}");
      setState(() {
        _notificationText = message.notification?.body ?? 'Notification clicked';
      });
    });
  }

  Future<void> _getFCMToken() async {
    String? token = await _firebaseMessaging.getToken();
    setState(() {
      _fcmToken = token ?? 'No token available';
    });
    print("FCM Token: $_fcmToken");

    // Now send the FCM token to your backend (Supabase) for storage
    if (_fcmToken.isNotEmpty) {
      await _storeFcmToken(_fcmToken, 'mobile'); // Assuming 'mobile' as device type
    }
  }

  // Function to send FCM token to your Supabase backend
  Future<void> _storeFcmToken(String fcmToken, String deviceType) async {
    final String apiUrl = 'https://fmtzufgmbciovdxflkqm.supabase.co/functions/v1/storeFcmToken'; // Your backend URL here
    final String bearerToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZtdHp1ZmdtYmNpb3ZkeGZsa3FtIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczNDE4MzU2MCwiZXhwIjoyMDQ5NzU5NTYwfQ.ZHuLemZsLLfLVZSL07_a72JH7PXyE1fDwHReuoRVTOk'; // Replace with your actual token

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $bearerToken', // Add the Authorization header with Bearer token
        },
        body: json.encode({
          'fcmToken': fcmToken,
          'deviceType': deviceType,
        }),
      );

      if (response.statusCode == 200) {
        print('FCM token stored successfully');
      } else {
        print('Failed to store FCM token: ${response.body}');
      }
    } catch (e) {
      print('Error storing FCM token: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Demo')),
      body: Center(
        child: Text(
          _notificationText, // Dynamically update the text when a notification is received
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
