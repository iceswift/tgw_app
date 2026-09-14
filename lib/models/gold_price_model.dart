class GoldPrice {
  final String dateTime;
  final int no;
  final String goldBarBuy;
  final String goldBarSell;
  final String goldOrnamentBuy;
  final String goldOrnamentSell;
  final String spot;
  final String thb;
  final String change;

  GoldPrice({
    required this.dateTime,
    this.no = 0,
    required this.goldBarBuy,
    required this.goldBarSell,
    required this.goldOrnamentBuy,
    required this.goldOrnamentSell,
    required this.spot,
    required this.thb,
    required this.change,
  });

  factory GoldPrice.fromJson(Map<String, dynamic> json) {
    return GoldPrice(
      dateTime: '${json['date']} ${json['time']}',
      no: int.tryParse(json['round']?.toString() ?? '0') ?? 0,
      goldBarBuy: json['bullion_buy'] ?? '',
      goldBarSell: json['bullion_sell'] ?? '',
      goldOrnamentBuy: json['ornament_buy'] ?? '',
      goldOrnamentSell: json['ornament_sell'] ?? '',
      spot: json['gold_spot'] ?? '',
      thb: json['thb'] ?? '',
      change: json['change'] ?? '',
    );
  }
}
