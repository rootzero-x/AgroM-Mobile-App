import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'api_service.dart';
import 'notification_service.dart';
import 'order_tracker.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  print('BackgroundService: Configuring background service...');

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'agrom_order_channel',
      initialNotificationTitle: 'AgroM',
      initialNotificationContent: 'Buyurtmalar holati orqa fonda kuzatilmoqda',
      foregroundServiceTypes: [AndroidForegroundType.dataSync],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  await service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  print('BackgroundService: Isolate started. Initializing systems...');
  
  // Initialize APIs and local notification plugins inside the background isolate
  await ApiService().init();
  await NotificationService().init();

  // Run status checks every 20 seconds continuously
  Timer.periodic(const Duration(seconds: 20), (timer) async {
    print('BackgroundService: Executing periodic check timer...');
    try {
      final apiService = ApiService();
      // Force reload credentials to read latest token saved by main UI isolate
      await apiService.init();

      if (apiService.isAuthenticated && apiService.currentUser != null) {
        final tracker = OrderTracker();
        await tracker.checkOrders();
      } else {
        print('BackgroundService: Skipping check. User is not authenticated.');
      }
    } catch (e) {
      print('BackgroundService: Error inside background isolate checking: $e');
    }
  });
}
