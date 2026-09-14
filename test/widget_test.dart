import 'package:flutter_test/flutter_test.dart';
import 'package:gold_app/models/gold_price_latest_model.dart';

void main() {
  test('latest gold price model parses the API response shape', () {
    final price = GoldPriceLatest.fromJson({
      'market_status': 'open',
      'data': {
        'date': '2026-09-14',
        'time': '13:30',
        'no': '1',
        'bullion_buy': '60,000',
        'bullion_sell': '60,100',
        'ornament_buy': '58,912.12',
        'ornament_sell': '60,900',
        'spot': '2,500',
        'thb': '32.00',
        'change': '+100',
      },
    });

    expect(price.marketStatus, 'open');
    expect(price.bullionBuy, '60,000');
    expect(price.bullionSell, '60,100');
  });
}
