import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:gold_app/services/widget_service.dart';
import 'package:gold_app/services/gold_api_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // 1. Request Permissions (iOS/Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      print('FCM: User granted permission: ${settings.authorizationStatus}');
    }

    // 2. Subscribe to Topics
    await _messaging.subscribeToTopic('gold_price_updates');
    if (kDebugMode) {
      print('FCM: Subscribed to topic "gold_price_updates"');
    }

    // 3. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('FCM: Received foreground message: ${message.notification?.title}');
        print('FCM: Data payload: ${message.data}');
      }
      _handleMessage(message);
    });

    // 4. Handle Background/Terminated Messages (App opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('FCM: App opened from notification: ${message.notification?.title}');
      }
      // Usually updates are already handled by background handler, 
      // but we can trigger a refresh if needed when app opens.
      _handleMessage(message);
    });
  }

  static void _handleMessage(RemoteMessage message) async {
    // When a message is received (via topic gold_price_updates), 
    // fetch latest price and update the home widget.
    try {
      if (kDebugMode) {
        print('FCM: Fetching latest price for widget update...');
      }
      
      final apiService = GoldApiService();
      final latestPrice = await apiService.getLatestPrice();

      // Update Widget
      await WidgetService().updateWidget(latestPrice);

      if (kDebugMode) {
        print('FCM: Home widget updated successfully with latest price: ${latestPrice.bullionBuy}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('FCM Error: Failed to handle message update: $e');
      }
    }
  }
}

// Background Message Handler (Must be top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized for background isolate
  await Firebase.initializeApp();

  if (kDebugMode) {
    print("FCM: Handling background message: ${message.messageId}");
    print("FCM: Topic: ${message.from}");
  }

  // Update Widget in background
  try {
    final apiService = GoldApiService();
    final latestPrice = await apiService.getLatestPrice();
    await WidgetService().updateWidget(latestPrice);
    
    if (kDebugMode) {
      print("FCM: Background widget update complete.");
    }
  } catch (e) {
    if (kDebugMode) {
      print('FCM Error (Background): Failed to update widget: $e');
    }
  }
}
