import 'package:gold_app/models/gold_price_latest_model.dart';
import 'package:gold_app/models/gold_price_model.dart';
import 'package:gold_app/models/jewelry_price_model.dart';
import 'package:gold_app/models/shop_price_model.dart';

class GoldBoard {
  final int? revision;
  final String status;
  final String source;
  final String marketStatus;
  final String updatedAt;
  final bool stale;
  final int ageSeconds;
  final GoldPriceLatest latest;
  final List<GoldPrice> history;
  final List<JewelryPrice> jewelry;
  final List<ShopPrice> shops;

  GoldBoard({
    this.revision,
    required this.status,
    required this.source,
    required this.marketStatus,
    required this.updatedAt,
    required this.stale,
    required this.ageSeconds,
    required this.latest,
    required this.history,
    required this.jewelry,
    required this.shops,
  });

  factory GoldBoard.fromJson(Map<String, dynamic> json) {
    final latestData = json['latest'] as Map<String, dynamic>? ?? {};

    // Simulate the structure GoldPriceLatest.fromJson expects
    final simulatedLatestJson = {
      'market_status': json['market_status'] ?? '',
      'data': latestData,
    };

    return GoldBoard(
      revision: _parseRevision(json['revision']),
      status: json['status'] ?? '',
      source: json['source'] ?? '',
      marketStatus: json['market_status'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      stale: json['stale'] ?? false,
      ageSeconds: json['age_seconds'] ?? 0,
      latest: GoldPriceLatest.fromJson(simulatedLatestJson),
      history: (json['history'] as List<dynamic>? ?? [])
          .map((e) => GoldPrice.fromJson(e as Map<String, dynamic>))
          .toList(),
      jewelry: (json['jewelry'] as List<dynamic>? ?? []).map((e) {
        final item = e as Map<String, dynamic>;
        return JewelryPrice(
          type: item['type'] ?? '',
          perGramBuy: item['per_gram_buy'] ?? 'n/a',
          perBahtBuy: item['per_baht_buy'] ?? item['buy'] ?? 'n/a',
          perBahtSell: item['per_baht_sell'] ?? item['sell'] ?? 'n/a',
        );
      }).toList(),
      shops: (json['shops'] as List<dynamic>? ?? [])
          .map((e) => ShopPrice.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static int? _parseRevision(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  Map<String, dynamic> toJson() => {
    if (revision != null) 'revision': revision,
    'status': status,
    'source': source,
    'market_status': marketStatus,
    'updated_at': updatedAt,
    'stale': stale,
    'age_seconds': ageSeconds,
    'latest': {
      'date': latest.date,
      'time': latest.time,
      'round': latest.round,
      'bullion_buy': latest.bullionBuy,
      'bullion_sell': latest.bullionSell,
      'ornament_buy': latest.ornamentBuy,
      'ornament_sell': latest.ornamentSell,
      'gold_spot': latest.spot,
      'thb': latest.thb,
      'change': latest.change,
    },
    'history': history.map((item) {
      final separator = item.dateTime.lastIndexOf(' ');
      return {
        'date': separator < 0
            ? item.dateTime
            : item.dateTime.substring(0, separator),
        'time': separator < 0 ? '' : item.dateTime.substring(separator + 1),
        'round': item.no,
        'bullion_buy': item.goldBarBuy,
        'bullion_sell': item.goldBarSell,
        'ornament_buy': item.goldOrnamentBuy,
        'ornament_sell': item.goldOrnamentSell,
        'gold_spot': item.spot,
        'thb': item.thb,
        'change': item.change,
      };
    }).toList(),
    'jewelry': jewelry
        .map(
          (item) => {
            'type': item.type,
            'per_gram_buy': item.perGramBuy,
            'per_baht_buy': item.perBahtBuy,
            'per_baht_sell': item.perBahtSell,
          },
        )
        .toList(),
    'shops': shops
        .map(
          (shop) => {
            'name': shop.name,
            'data': {
              if (shop.goldBar965 != null)
                'gold_bar_965': _shopDataToJson(shop.goldBar965!),
              if (shop.goldBar9999 != null)
                'gold_bar_9999': _shopDataToJson(shop.goldBar9999!),
              if (shop.ornament965 != null)
                'ornament_965': _shopDataToJson(shop.ornament965!),
              if (shop.ornamentBuyBack != null)
                'ornament_buy_back': _shopDataToJson(shop.ornamentBuyBack!),
            },
          },
        )
        .toList(),
  };

  static Map<String, dynamic> _shopDataToJson(ShopGoldData data) => {
    'buy': data.buy,
    'sell': data.sell,
  };
}
