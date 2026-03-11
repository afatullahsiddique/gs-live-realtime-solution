import 'package:bloc/bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class NotificationCubit extends Cubit<void> {
  NotificationCubit() : super(null) {
    init();
  }

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await requestPermissions();
    await getAndSaveFCMToken();
    await _initializeLocalNotifications();
    await initPushNotification();
  }

  /// Initialize local notification
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    _localNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("Notification clicked with payload: ${response.payload}");
      },
    );
  }

  /// Request permission
  Future<void> requestPermissions() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Show notification when app in foreground
  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      0,
      title,
      body,
      details,
    );
  }

  /// Get FCM token
  Future<void> getAndSaveFCMToken() async {
    final preferences = await SharedPreferences.getInstance();

    try {
      String? fcmToken = await _firebaseMessaging.getToken();

      if (fcmToken != null) {
        await preferences.setString('fcm_token', fcmToken);
        print("FCM Token: $fcmToken");
      } else {
        print("Failed to get FCM token.");
      }
    } catch (e) {
      print("Error getting FCM token: $e");
    }
  }

  /// Push notification listeners
  Future<void> initPushNotification() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Foreground notification: ${message.notification?.title}");

      _showLocalNotification(
        title: message.notification?.title ?? "No Title",
        body: message.notification?.body ?? "No Body",
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notification opened: ${message.notification?.title}");
    });

    final message = await _firebaseMessaging.getInitialMessage();

    if (message != null) {
      print("App opened via notification: ${message.notification?.title}");
    }
  }

  /// iOS token save
  Future<void> saveTokenForiOS() async {
    final preferences = await SharedPreferences.getInstance();

    try {
      if (Platform.isIOS) {
        await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        String? apnsToken = await _firebaseMessaging.getAPNSToken();
        print('APNs Token: $apnsToken');

        String? fcmToken = await _firebaseMessaging.getToken();

        if (fcmToken != null) {
          await preferences.setString('fcm_token', fcmToken);
          print("FCM Token for iOS: $fcmToken");
        }

        await _firebaseMessaging
            .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      print("Error in saveTokenForiOS: $e");
    }
  }

  /// Get saved token
  Future<String?> getSavedFCMToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }
}