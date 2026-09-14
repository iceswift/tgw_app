import 'package:home_widget/home_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:gold_app/models/gold_price_latest_model.dart';
import 'package:intl/intl.dart';

class WidgetService {
  static const String appGroupId = 'group.gold_app_group';
  static const String androidWidgetName =
      'com.thaigoldview.app.GoldWidgetProvider'; // FQN

  Future<void> updateWidget(GoldPriceLatest data) async {
    if (kIsWeb) return;
    // Format numbers
    final formatter = NumberFormat("#,###");

    // Helper to parse and format
    String fmt(String val) {
      double? v = double.tryParse(val.replaceAll(',', ''));
      return v != null ? formatter.format(v) : val;
    }

    // Save data (Stable Set)
    await HomeWidget.saveWidgetData<String>(
      'bullion_buy',
      fmt(data.bullionBuy),
    );
    await HomeWidget.saveWidgetData<String>(
      'bullion_sell',
      fmt(data.bullionSell),
    );
    await HomeWidget.saveWidgetData<String>(
      'ornament_buy',
      fmt(data.ornamentBuy),
    );
    await HomeWidget.saveWidgetData<String>(
      'ornament_sell',
      fmt(data.ornamentSell),
    );
    await HomeWidget.saveWidgetData<String>('change', data.change);
    await HomeWidget.saveWidgetData<String>(
      'date',
      '${data.date} ${data.time}',
    );

    // Update the widget
    await HomeWidget.updateWidget(
      name: androidWidgetName,
      androidName: androidWidgetName,
    );
  }
}
