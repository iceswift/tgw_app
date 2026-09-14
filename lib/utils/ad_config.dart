import 'dart:io';
import 'package:flutter/foundation.dart';

class AdConfig {
  static const String _androidTestId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _iosTestId = 'ca-app-pub-3940256099942544/2934735716';

  // Toggle for testing
  static const bool showAds = true;

  // Real Ad Unit IDs
  static const String _androidRealId = 'ca-app-pub-6833768369533754/2209221089';
  // Note: iOS Real ID not provided yet, using Test ID logic for now.

  static String get _adUnitId {
    if (kIsWeb) return '5266631204'; // AdSense Slot ID for Web

    if (Platform.isAndroid) {
      // internal: Use Test ID in Debug, Real ID in Release
      // But for "User Testing", we might want Real ID if they asked.
      // Standard practice: kReleaseMode ? _androidRealId : _androidTestId
      // However, user specifically asked to "connect service".
      // I will use kReleaseMode check to be safe.
      return const bool.fromEnvironment('dart.vm.product')
          ? _androidRealId
          : _androidTestId;
    } else {
      return _iosTestId;
    }
  }

  static String get homePageBanner => _adUnitId;
  static String get historyPageBanner => _adUnitId;
  static String get graphPageBanner => _adUnitId;
  static String get calculatorPageBanner => _adUnitId;
  static String get settingsPageBanner => _adUnitId;
}
