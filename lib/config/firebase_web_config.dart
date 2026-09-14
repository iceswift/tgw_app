import 'package:firebase_core/firebase_core.dart';

/// Firebase Web values are supplied at build time so deployment credentials
/// do not have to be hard-coded in the repository.
abstract final class FirebaseWebConfig {
  static const apiKey = String.fromEnvironment(
    'FIREBASE_WEB_API_KEY',
    defaultValue: 'AIzaSyCfil1FFA9HSUEnWJj3o49AX2_S1sOLTgA',
  );
  static const appId = String.fromEnvironment(
    'FIREBASE_WEB_APP_ID',
    defaultValue: '1:969347355598:web:a77716904b2ea21eab119f',
  );
  static const messagingSenderId = String.fromEnvironment(
    'FIREBASE_WEB_MESSAGING_SENDER_ID',
    defaultValue: '969347355598',
  );
  static const projectId = String.fromEnvironment(
    'FIREBASE_WEB_PROJECT_ID',
    defaultValue: 'thai-gold-view',
  );
  static const authDomain = String.fromEnvironment(
    'FIREBASE_WEB_AUTH_DOMAIN',
    defaultValue: 'thai-gold-view.firebaseapp.com',
  );
  static const storageBucket = String.fromEnvironment(
    'FIREBASE_WEB_STORAGE_BUCKET',
    defaultValue: 'thai-gold-view.firebasestorage.app',
  );
  static const measurementId = String.fromEnvironment(
    'FIREBASE_WEB_MEASUREMENT_ID',
    defaultValue: 'G-8Q6E1D8D2X',
  );
  static const vapidKey = String.fromEnvironment(
    'FIREBASE_WEB_VAPID_KEY',
    defaultValue:
        'BBeHpiqtri2ByeomBhyfBoZ5jauPtD3lBH0wo9skDH6zwLn7FWiqfs5h-MWjOzGyWKvXdlnsPSVxEoMXRBoe5Dg',
  );
  static const pushSubscribeUrl = String.fromEnvironment(
    'PUSH_SUBSCRIBE_URL',
    defaultValue: 'https://api.thaigoldview.com/api/push/subscribe',
  );

  static bool get firebaseReady =>
      apiKey.isNotEmpty && appId.isNotEmpty && messagingSenderId.isNotEmpty;

  static bool get notificationsReady =>
      firebaseReady && vapidKey.isNotEmpty && pushSubscribeUrl.isNotEmpty;

  static FirebaseOptions get options => FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    authDomain: authDomain.isEmpty ? null : authDomain,
    storageBucket: storageBucket.isEmpty ? null : storageBucket,
    measurementId: measurementId.isEmpty ? null : measurementId,
  );
}
