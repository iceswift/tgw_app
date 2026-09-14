import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:gold_app/repositories/gold_data_repository.dart';
import 'package:gold_app/utils/custom_http_overrides.dart';

// --- Constants ---
const String checkPriceTask = "checkPriceTask";

// --- Top-Level Function for Background Execution ---
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (kDebugMode) {
      print("Background Task Started: $task");
    }

    if (task == checkPriceTask) {
      // 0. Set HttpOverrides for background isolate (Debug only)
      if (kDebugMode) {
        HttpOverrides.global = CustomHttpOverrides();
      }

      try {
        final repository = GoldDataRepository();
        await repository.initialize();
        await repository.refreshIfStale(const Duration(minutes: 10));

        if (kDebugMode) {
          print("Background Task Completed Successfully (Widget Updated)");
        }
      } catch (e) {
        if (kDebugMode) {
          print("Background Task Failed: $e");
        }
        return Future.value(false);
      }
    }

    return Future.value(true);
  });
}

// --- Main Service Class to be called from UI ---
class BackgroundService {
  static Future<void> initialize() async {
    if (kIsWeb) return; // Not supported on Web

    // Init Workmanager
    await Workmanager().initialize(callbackDispatcher);
  }

  static Future<void> registerTask() async {
    if (kIsWeb) return;

    await Workmanager().registerPeriodicTask(
      "1", // Unique Name
      checkPriceTask, // Task Name
      initialDelay: const Duration(seconds: 15),
      frequency: const Duration(minutes: 15), // Fallback sync every 15 mins
      constraints: Constraints(networkType: NetworkType.connected),
    );

    if (kDebugMode) {
      print("Background Task Registered (Fallback Sync)");
    }
  }
}
