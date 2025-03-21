Here’s the **README** for the **Mobile App** side of the Supabase Notification System:

Mobile Notification System (Flutter + Supabase + FCM)
=====================================================

This **Flutter mobile app** is part of a **Supabase Notification System** that:

*   **Receives notifications** via Firebase Cloud Messaging (FCM).
    
*   **Saves its FCM token** to Supabase for future notification triggers.
    
*   Works with a **companion watch app** that triggers notifications via a Supabase Edge Function.
    

Setup Instructions
------------------

### Prerequisites

*   **Supabase account** ([Sign up here](https://supabase.com/))
    
*   **Flutter installed** ([Installation guide](https://docs.flutter.dev/get-started/install))
    
*   **Firebase project setup** ([Firebase setup guide](https://firebase.google.com/docs/flutter/setup))
    

Step 1: Configure Firebase for FCM
----------------------------------

1.  Follow the [**Firebase setup guide**](https://firebase.google.com/docs/flutter/setup) to integrate Firebase Cloud Messaging (FCM) into your Flutter app.
    
2.  Add the necessary Firebase configuration files:
    
    *   google-services.json (for Android) → Place in android/app/
        
    *   GoogleService-Info.plist (for iOS) → Place in ios/Runner/
        
3.  Enable **Cloud Messaging** in the Firebase Console.
    

Step 2: Create Supabase Table for FCM Tokens
--------------------------------------------

The mobile app needs to **store its FCM token** in Supabase to enable notifications.

Run the following SQL command in your **Supabase SQL Editor**:

``` sql
CREATE TABLE device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fcm_token TEXT NOT NULL,
    device_type TEXT NOT NULL
);
```
This will create a table where the mobile app can **store its FCM token**.

Step 3: Store FCM Token in Supabase
-----------------------------------

The mobile app should **send its FCM token** to Supabase when launching for the first time or when the token updates.

### Function: sendFcmToken

This function **sends the FCM token** to Supabase.

``` bash
import { createClient } from 'npm:@supabase/supabase-js@2';

// Supabase Configuration (replace with actual values)
const SUPABASE_URL = "YOUR_SUPABASE_URL";
const SUPABASE_KEY = "YOUR_SUPABASE_KEY";

// Initialize Supabase Client
const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

// Deno server to handle incoming requests
Deno.serve(async (req) => {
  console.log("Request received to store FCM token");

  // Parse the request body
  const body = await req.json();
  const { fcmToken, deviceType } = body;

  // Validate incoming data
  if (!fcmToken || !deviceType) {
    return new Response(
      JSON.stringify({ error: 'fcmToken and deviceType are required' }),
      { status: 400 }
    );
  }

  // Insert the FCM token into the device_tokens table
  const { data, error } = await supabase
    .from('device_tokens')
    .upsert(
      { device_type: deviceType, fcm_token: fcmToken },
      { onConflict: ['fcm_token'] } // Ensure fcm_token is unique
    );

  if (error) {
    console.error("Error storing FCM token:", error);
    return new Response(
      JSON.stringify({ error: 'Failed to store FCM token', details: error.message }),
      { status: 500 }
    );
  }

  console.log("FCM token stored successfully");

  // Respond with success
  return new Response(
    JSON.stringify({ message: 'FCM token stored successfully', data }),
    { headers: { 'Content-Type': 'application/json' } }
  );
});

```
Step 4: Request Notification Permissions
----------------------------------------

To **receive notifications**, the app must request permission from the user.

Add this in initState() of your main widget:

``` bash
void initState() {
  super.initState();
  _firebaseMessaging.requestPermission();
  _getFCMToken();
  
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("Foreground notification received: ${message.notification?.title}");
    showFlutterNotification(message);
  });
}


```
Step 5: Fetch and Store FCM Token
---------------------------------

The mobile app should **get its FCM token** and store it in Supabase.

### Function: \_getFCMToken

``` bash
import 'package:firebase_messaging/firebase_messaging.dart';


Future<void> _getFCMToken() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  
  String? token = await messaging.getToken();
  print("FCM Token: $token");


  if (token != null) {
    await sendFcmToken(token, 'mobile'); // Store FCM token in Supabase
  }
}
```
Call \_getFCMToken() in initState() to run when the app starts.

Step 6: Handle Notifications
----------------------------

### Background Notifications

When the app is **closed or in the background**, use this handler:

``` bash
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Background notification received: ${message.notification?.title}");
}


FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);


```
### Foreground Notifications

Use flutter\_local\_notifications to **display notifications** inside the app:
``` bash
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();


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


```


Step 7: Running the Mobile App
------------------------------

Run the app using the following command:

``` bash
flutter run

```
Summary of Workflow
-------------------

1.  **Mobile app starts** → Requests notification permissions.
    
2.  **Fetches FCM token** → Calls sendFcmToken() to store it in Supabase.
    
3.  **Watch app triggers notification** → Calls a **Supabase Edge Function**.
    
4.  **Edge Function fetches FCM token** from Supabase and sends a notification.
    
5.  **Mobile app receives notification** and displays it.
    

Notes
-----

*   **Replace placeholders** with actual values:
    
    *   your-supabase-url
        
    *   your-bearer-token
        
*   The **watch app does not receive notifications**, it only triggers them.
    
*   Ensure **Supabase Edge Function is deployed** before testing notifications.
    
*   If notifications **don't appear**, check Firebase Console > Cloud Messaging.
