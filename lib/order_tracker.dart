import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'models.dart';
import 'notification_service.dart';

class OrderTracker {
  static final OrderTracker _instance = OrderTracker._internal();
  factory OrderTracker() => _instance;
  OrderTracker._internal();

  Timer? _timer;
  bool _isChecking = false;

  void startTracking() {
    print('OrderTracker: Starting real-time order tracking...');
    _timer?.cancel();
    // Poll every 15 seconds when active to make it feel extremely responsive
    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      checkOrders();
    });
    // Trigger initial check immediately
    checkOrders();
  }

  void stopTracking() {
    print('OrderTracker: Stopping order tracking loop.');
    _timer?.cancel();
    _timer = null;
  }

  Future<void> checkOrders() async {
    print('OrderTracker: Checking order statuses on server...');
    if (_isChecking) {
      print('OrderTracker: Check already in progress, skipping polling.');
      return;
    }
    _isChecking = true;

    try {
      final apiService = ApiService();
      if (!apiService.isAuthenticated || apiService.currentUser == null) {
        print('OrderTracker: User is not authenticated. Stopping tracker.');
        stopTracking();
        _isChecking = false;
        return;
      }

      final userId = apiService.currentUser!.id;
      final orders = await apiService.getOrders();
      print('OrderTracker: Fetched ${orders.length} orders from server for user $userId.');
      if (orders.isEmpty) {
        _isChecking = false;
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'agrom_order_tracker_cache_$userId';
      final cachedString = prefs.getString(cacheKey);

      // Load previously cached order statuses
      final Map<String, Map<String, bool>> cachedStates = {};
      if (cachedString != null) {
        try {
          final decoded = jsonDecode(cachedString) as Map<String, dynamic>;
          decoded.forEach((key, value) {
            if (value is Map) {
              cachedStates[key] = {
                'isPaid': value['isPaid'] == true,
                'isDelivered': value['isDelivered'] == true,
              };
            }
          });
        } catch (e) {
          print('OrderTracker: Error decoding cache: $e');
        }
      }

      final Map<String, Map<String, bool>> nextStates = {};
      bool stateChanged = false;
      int notificationId = 200;

      for (final order in orders) {
        final orderId = order.id;
        final currentIsPaid = order.isPaid;
        final currentIsDelivered = order.isDelivered;

        print('OrderTracker: Order $orderId -> isPaid: $currentIsPaid, isDelivered: $currentIsDelivered');

        nextStates[orderId] = {
          'isPaid': currentIsPaid,
          'isDelivered': currentIsDelivered,
        };

        // Parse order timestamps to check for recent changes
        final paidAtUtc = order.paidAt?.toUtc();
        final deliveredAtUtc = order.deliveredAt?.toUtc();
        final nowUtc = DateTime.now().toUtc();

        // Check if status changes occurred within the last 15 minutes
        final isPaidRecent = paidAtUtc != null && nowUtc.difference(paidAtUtc).inMinutes.abs() < 15;
        final isDeliveredRecent = deliveredAtUtc != null && nowUtc.difference(deliveredAtUtc).inMinutes.abs() < 15;

        final orderName = order.orderItems.isNotEmpty ? order.orderItems.first.name : 'Mahsulotlar';

        // Check for state updates if the order was cached before
        if (cachedStates.containsKey(orderId)) {
          final previousState = cachedStates[orderId]!;
          final wasPaid = previousState['isPaid'] == true;
          final wasDelivered = previousState['isDelivered'] == true;

          // Paid transition check
          if (!wasPaid && currentIsPaid) {
            print('OrderTracker: Transition - Order $orderId was paid!');
            await NotificationService().showOrderUpdateNotification(
              id: notificationId++,
              title: 'Buyurtma to\'landi! ✅',
              body: 'Sizning "$orderName" buyurtmangiz uchun to\'lov muvaffaqiyatli qabul qilindi.',
            );
            stateChanged = true;
          }

          // Delivered transition check
          if (!wasDelivered && currentIsDelivered) {
            print('OrderTracker: Transition - Order $orderId was delivered!');
            await NotificationService().showOrderUpdateNotification(
              id: notificationId++,
              title: 'Buyurtma yetkazildi! 🚚',
              body: 'Sizning "$orderName" buyurtmangiz muvaffaqiyatli yetkazib berildi.',
            );
            stateChanged = true;
          }
          
          if (wasPaid != currentIsPaid || wasDelivered != currentIsDelivered) {
            stateChanged = true;
          }
        } else {
          // If the order is NOT in cache but was paid/delivered recently, notify user immediately (e.g. app just opened after state change)
          print('OrderTracker: Order $orderId is new to cache. Checking for recent status updates...');
          
          if (currentIsPaid && isPaidRecent) {
            print('OrderTracker: New order $orderId paid recently (${paidAtUtc}). Sending notification.');
            await NotificationService().showOrderUpdateNotification(
              id: notificationId++,
              title: 'Buyurtma to\'landi! ✅',
              body: 'Sizning "$orderName" buyurtmangiz uchun to\'lov muvaffaqiyatli qabul qilindi.',
            );
          }

          if (currentIsDelivered && isDeliveredRecent) {
            print('OrderTracker: New order $orderId delivered recently (${deliveredAtUtc}). Sending notification.');
            await NotificationService().showOrderUpdateNotification(
              id: notificationId++,
              title: 'Buyurtma yetkazildi! 🚚',
              body: 'Sizning "$orderName" buyurtmangiz muvaffaqiyatli yetkazib berildi.',
            );
          }
          
          stateChanged = true;
        }
      }

      // Update local storage cache if states have changed
      if (stateChanged || cachedStates.length != nextStates.length) {
        print('OrderTracker: Updating SharedPreferences cache with new states.');
        await prefs.setString(cacheKey, jsonEncode(nextStates));
      }
    } catch (e) {
      print('OrderTracker: Error in checkOrders loop: $e');
    } finally {
      _isChecking = false;
    }
  }
}
