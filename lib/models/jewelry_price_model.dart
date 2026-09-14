class JewelryPrice {
  final String type;
  final String perGramBuy;
  final String perBahtBuy;
  final String perBahtSell;

  JewelryPrice({
    required this.type,
    required this.perGramBuy,
    required this.perBahtBuy,
    required this.perBahtSell,
  });

  factory JewelryPrice.fromJson(Map<String, dynamic> json) {
    return JewelryPrice(
      type: json['type'] ?? '',
      perGramBuy: json['per_gram_buy'] ?? 'n/a',
      perBahtBuy: json['per_baht_buy'] ?? 'n/a',
      perBahtSell: json['per_baht_sell'] ?? 'n/a',
    );
  }
}
