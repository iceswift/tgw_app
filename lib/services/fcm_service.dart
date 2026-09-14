import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:gold_app/repositories/gold_data_repository.dart';
import 'package:gold_app/config/firebase_web_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

enum WebNotificationResult {
  enabled,
  denied,
  unsupported,
  notConfigured,
  failed,
}

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // Browsers require notification permission to be requested from a direct
    // user action, so Web uses enableWebNotifications() from the Settings UI.
    if (!kIsWeb) {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (kDebugMode) {
        print('FCM: User granted permission: ${settings.authorizationStatus}');
      }

      await _messaging.subscribeToTopic('gold_price_updates');
      if (kDebugMode) {
        print('FCM: Subscribed to topic "gold_price_updates"');
      }
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

    if (kIsWeb) {
      _messaging.onTokenRefresh.listen((token) {
        unawaited(_registerWebToken(token));
      });
    }
  }

  static Future<WebNotificationResult> enableWebNotifications() async {
    if (!kIsWeb) return WebNotificationResult.unsupported;
    if (!FirebaseWebConfig.notificationsReady) {
      return WebNotificationResult.notConfigured;
    }

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return WebNotificationResult.denied;
      }

      final token = await _messaging.getToken(
        vapidKey: FirebaseWebConfig.vapidKey,
      );
      if (token == null || token.isEmpty) return WebNotificationResult.failed;
      return await _registerWebToken(token)
          ? WebNotificationResult.enabled
          : WebNotificationResult.failed;
    } catch (error) {
      if (kDebugMode) print('FCM Web: $error');
      return WebNotificationResult.failed;
    }
  }

  static Future<bool> _registerWebToken(String token) async {
    if (!kIsWeb || FirebaseWebConfig.pushSubscribeUrl.isEmpty) return false;
    final response = await http
        .post(
          Uri.parse(FirebaseWebConfig.pushSubscribeUrl),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'token': token,
            'topic': 'gold_price_updates',
            'platform': 'web',
          }),
        )
        .timeout(const Duration(seconds: 15));
    return response.statusCode >= 200 && response.statusCode < 300;
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
