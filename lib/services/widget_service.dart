import 'package:home_widget/home_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:gold_app/models/gold_price_latest_model.dart';
import 'package:intl/intl.dart';

class WidgetService {
  static const String appGroupId = 'group.gold_app_group';
  static const String androidWidgetName =
      'com.thaigoldview.app.GoldWidgetProvider'; // FQN

  Future<bool> updateWidget(GoldPriceLatest data) async {
    if (kIsWeb) return false;
    // Format numbers
    final formatter = NumberFormat("#,###");

    // Helper to parse and format
    String fmt(String val) {
      double? v = double.tryParse(val.replaceAll(',', ''));
      return v != null ? formatter.format(v) : val;
    }

    final values = <String, String>{
      'bullion_buy': fmt(data.bullionBuy),
      'bullion_sell': fmt(data.bullionSell),
      'ornament_buy': fmt(data.ornamentBuy),
      'ornament_sell': fmt(data.ornamentSell),
      'change': data.change,
      'date': '${data.date} ${data.time}',
    };

    var changed = false;
    for (final entry in values.entries) {
      final previous = await HomeWidget.getWidgetData<String>(entry.key);
      if (previous != entry.value) changed = true;
    }
    if (!changed) return false;

    for (final entry in values.entries) {
      await HomeWidget.saveWidgetData<String>(entry.key, entry.value);
    }

    // Update the widget
    await HomeWidget.updateWidget(
      name: androidWidgetName,
      androidName: androidWidgetName,
    );
    return true;
  }
}
