class ShopPrice {
  final String name;
  final ShopGoldData? goldBar965;
  final ShopGoldData? goldBar9999;
  final ShopGoldData? ornament965;
  final ShopGoldData? ornamentBuyBack;

  ShopPrice({
    required this.name,
    this.goldBar965,
    this.goldBar9999,
    this.ornament965,
    this.ornamentBuyBack,
  });

  factory ShopPrice.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return ShopPrice(
      name: json['name'] ?? '',
      goldBar965: data['gold_bar_965'] != null
          ? ShopGoldData.fromJson(data['gold_bar_965'])
          : null,
      goldBar9999: data['gold_bar_9999'] != null
          ? ShopGoldData.fromJson(data['gold_bar_9999'])
          : null,
      ornament965:
          (data['ornament_965'] != null || data['gold_ornament_965'] != null)
          ? ShopGoldData.fromJson(
              data['ornament_965'] ?? data['gold_ornament_965'],
            )
          : null,
      ornamentBuyBack: data['ornament_buy_back'] != null
          ? ShopGoldData.fromJson(data['ornament_buy_back'])
          : null,
    );
  }
}

class ShopGoldData {
  final String buy;
  final String sell;

  ShopGoldData({required this.buy, required this.sell});

  factory ShopGoldData.fromJson(Map<String, dynamic> json) {
    // Some shops might have 'baht'/'gram' instead of 'buy'/'sell' for buyback
    // But per example JSON, most std keys are buy/sell.
    // Example exception: "ornament_buy_back":{"baht":"66,400","gram":"4,380"}
    // We need to handle that if we want flexibility.

    // Check for buy/sell first
    String b = json['buy'] ?? '';
    String s = json['sell'] ?? '';

    // Fallback for ornament_buy_back (MTS Gold example) which uses baht/gram
    if (b.isEmpty && json.containsKey('baht')) {
      b = json['baht']; // Treat 'baht' price as the primary 'buy' value we show?
      // Actually 'buy' usually means we sell to them, so shop buys from us.
      // 'ornament_buy_back' means shop buys back.
    }

    return ShopGoldData(buy: b, sell: s);
  }
}
