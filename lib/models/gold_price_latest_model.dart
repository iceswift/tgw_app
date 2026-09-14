class GoldPriceLatest {
  final String date;
  final String time;
  final String round; // Optional, may be empty if closed
  final String marketStatus; // Optional
  final String bullionBuy;
  final String bullionSell;
  final String ornamentBuy;
  final String ornamentSell;
  final String spot; // Optional
  final String thb; // Optional
  final String change;

  GoldPriceLatest({
    required this.date,
    required this.time,
    required this.round,
    required this.marketStatus,
    required this.bullionBuy,
    required this.bullionSell,
    required this.ornamentBuy,
    required this.ornamentSell,
    required this.spot,
    required this.thb,
    required this.change,
  });

  factory GoldPriceLatest.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return GoldPriceLatest(
      date: data['date'] ?? '',
      time: data['time'] ?? '',
      round: data['round'] ?? '',
      marketStatus: json['market_status'] ?? '',
      bullionBuy: data['bullion_buy'] ?? '',
      bullionSell: data['bullion_sell'] ?? '',
      ornamentBuy: data['ornament_buy'] ?? '',
      ornamentSell: data['ornament_sell'] ?? '',
      spot: data['gold_spot'] ?? '',
      thb: data['thb'] ?? '',
      change: data['change'] ?? '',
    );
  }
}
