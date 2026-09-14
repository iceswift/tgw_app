import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  final String _apiKey = 'test_bUocAGxkyJVZZkDPMZBsNOAHpgY'; // Provided API Key
  final String _entitlementID = 'Thai Gold View Pro'; // Provided Entitlement ID

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    if (kIsWeb) return;

    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration configuration;
    if (kIsWeb) return;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(_apiKey);
    } else if (Platform.isIOS) {
      configuration = PurchasesConfiguration(_apiKey);
    } else {
      return; // Not supported on other platforms yet
    }

    await Purchases.configure(configuration);
    _isInitialized = true;
  }

  // Check if user has active entitlement
  Future<bool> get isPro async {
    if (kIsWeb) return false;
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[_entitlementID]?.isActive ?? false;
    } on PlatformException catch (_) {
      // Error fetching customer info, default to false (or true if you want to be generous offline, but usually false)
      return false;
    }
  }

  // Stream for real-time status updates

  // Alternative: Just expose the listener directly or wrap carefully
  // Since addCustomerInfoUpdateListener returns a StreamSubscription/Closure in valid dart?
  // No, the SDK method returns void and takes a callback.
  // We need to bridge this to a Stream if we want reactive updates in SettingsController.
  // However, simpler is to just check on start and resume.
  // But let's follow modern flutter pattern with a Stream.

  // Let's create a StreamController? Or simply use the callback to notify listeners in SettingsController.
  // For simplicity here, I will expose a method to add a listener.

  void addCustomerInfoUpdateListener(void Function(CustomerInfo) listener) {
    if (kIsWeb) return;
    Purchases.addCustomerInfoUpdateListener(listener);
  }

  // Present Paywall
  Future<void> showPaywall() async {
    if (kIsWeb) return;
    try {
      print('--- RevenueCat: Try Showing Paywall ---');
      if (!_isInitialized) {
        print('--- RevenueCat: Not Initialized, initializing now... ---');
        await initialize();
      }

      // Use presentPaywall to FORCE show it for debugging/testing
      // In production, you might want presentPaywallIfNeeded
      print('--- RevenueCat: Calling presentPaywall ---');
      final result = await RevenueCatUI.presentPaywall();
      print('--- RevenueCat: Paywall Result: $result ---');
    } on PlatformException catch (e) {
      print('--- RevenueCat Error: $e ---');
    } catch (e) {
      print('--- General Error: $e ---');
    }
  }

  // Present Paywall (Force)
  Future<void> showPaywallForce() async {
    if (kIsWeb) return;
    try {
      await RevenueCatUI.presentPaywall();
    } on PlatformException catch (e) {
      print('Error showing paywall: $e');
    }
  }

  // Present Customer Center
  Future<void> showCustomerCenter() async {
    if (kIsWeb) return;
    try {
      await RevenueCatUI.presentCustomerCenter();
    } on PlatformException catch (e) {
      print('Error showing customer center: $e');
    }
  }

  // Fetch Offerings (Products)
  Future<Offerings?> getOfferings() async {
    if (kIsWeb) return null;
    try {
      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null &&
          offerings.current!.availablePackages.isNotEmpty) {
        return offerings;
      } else {
        print('--- RevenueCat: No Offerings Available ---');
      }
    } on PlatformException catch (e) {
      print('--- RevenueCat Error Fetching Offerings: $e ---');
    }
    return null;
  }

  // Make Purchase
  Future<bool> purchasePackage(Package package) async {
    if (kIsWeb) return false;
    try {
      await Purchases.purchasePackage(package);
      // Fetch fresh info to be safe and avoid return type issues
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[_entitlementID]?.isActive ?? false;
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        print('--- RevenueCat Purchase Error: $e ---');
      }
      return false;
    }
  }

  // Deprecate Native UI methods if going fully custom
  // But keeping them for fallback or "Restore Purchase" UI if needed.
  // ...

  // Restore Purchases
  Future<void> restorePurchases() async {
    if (kIsWeb) return;
    try {
      await Purchases.restorePurchases();
    } on PlatformException catch (e) {
      print('Error restoring purchases: $e');
    }
  }
}
