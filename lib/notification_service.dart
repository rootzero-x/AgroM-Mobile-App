import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  FlutterLocalNotificationsPlugin get notificationsPlugin => _notificationsPlugin;

  Future<void> init() async {
    print('NotificationService: Initializing local notifications...');
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initializationSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          print('NotificationService: Notification tapped. Payload: ${details.payload}');
        },
      );

      // Create Android Notification Channel explicitly
      const androidChannel = AndroidNotificationChannel(
        'agrom_order_channel',
        'AgroM Buyurtmalar',
        description: 'Buyurtmalar holati o\'zgarishi haqida xabarnomalar',
        importance: Importance.max,
        playSound: true,
      );
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      print('NotificationService: Local notifications initialized successfully.');
    } catch (e) {
      print('NotificationService: Failed to initialize local notifications: $e');
    }
  }

  Future<void> requestIgnoreBatteryOptimization() async {
    try {
      const platform = MethodChannel('com.snowden.mobile.mobile_app/battery');
      final bool isIgnoring = await platform.invokeMethod('isIgnoringBatteryOptimizations') ?? true;
      if (!isIgnoring) {
        print('NotificationService: Requesting user to ignore battery optimization...');
        await platform.invokeMethod('requestIgnoreBatteryOptimizations');
      } else {
        print('NotificationService: Battery optimization already disabled.');
      }
    } catch (e) {
      print('NotificationService: Error with battery optimizations request: $e');
    }
  }

  Future<void> requestPermissions() async {
    print('NotificationService: Requesting notification permissions...');
    try {
      // Request permission for Android 13+ (API 33+)
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        print('NotificationService: Android permission granted status: $granted');
      } else {
        print('NotificationService: Android implementation not found (maybe not on Android platform).');
      }

      // Request permission for iOS
      final iosPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        print('NotificationService: iOS permission granted status: $granted');
      }

      // Automatically request ignoring battery optimizations for background service robustness
      await requestIgnoreBatteryOptimization();
    } catch (e) {
      print('NotificationService: Error requesting permissions: $e');
    }
  }

  Future<void> showOrderUpdateNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    print('NotificationService: Showing notification id=$id, title="$title", body="$body"');
    try {
      const androidDetails = AndroidNotificationDetails(
        'agrom_order_channel',
        'AgroM Buyurtmalar',
        channelDescription: 'Buyurtmalar holati o\'zgarishi haqida xabarnomalar',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
      );
      print('NotificationService: Notification id=$id shown successfully.');
    } catch (e) {
      print('NotificationService: Failed to show notification id=$id: $e');
    }
  }
}
