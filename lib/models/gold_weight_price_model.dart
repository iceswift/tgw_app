class GoldWeightPrice {
  final String weight;
  final String price;
  final String total;

  GoldWeightPrice({
    required this.weight,
    required this.price,
    required this.total,
  });

  factory GoldWeightPrice.fromJson(Map<String, dynamic> json) {
    return GoldWeightPrice(
      weight: json['weight'] ?? '',
      price: json['price'] ?? '',
      total: json['total'] ?? '',
    );
  }
}
