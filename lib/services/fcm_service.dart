import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:gold_app/repositories/gold_data_repository.dart';

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
        print(
          'FCM: Received foreground message: ${message.notification?.title}',
        );
        print('FCM: Data payload: ${message.data}');
      }
      unawaited(_handleMessage(message));
    });

    // 4. Handle Background/Terminated Messages (App opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print(
          'FCM: App opened from notification: ${message.notification?.title}',
        );
      }
      // Usually updates are already handled by background handler,
      // but we can trigger a refresh if needed when app opens.
      unawaited(_handleMessage(message));
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await _handleMessage(initialMessage);
    }
  }

  static Future<void> _handleMessage(RemoteMessage message) async {
    try {
      if (kDebugMode) {
        print('FCM: Refreshing the shared gold snapshot...');
      }

      final revision = int.tryParse(message.data['revision']?.toString() ?? '');
      final refreshed = await GoldDataRepository.instance.refreshForRevision(
        revision,
      );

      if (kDebugMode) {
        print('FCM: Shared snapshot refresh requested: $refreshed');
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

  try {
    final repository = GoldDataRepository();
    await repository.initialize();
    final revision = int.tryParse(message.data['revision']?.toString() ?? '');
    await repository.refreshForRevision(revision);

    if (kDebugMode) {
      print("FCM: Background snapshot update complete.");
    }
  } catch (e) {
    if (kDebugMode) {
      print('FCM Error (Background): Failed to update widget: $e');
    }
  }
}
