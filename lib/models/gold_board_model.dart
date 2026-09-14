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
}
