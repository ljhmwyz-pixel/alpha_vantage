class AlertItem {
  const AlertItem({
    required this.id,
    required this.symbol,
    required this.market,
    required this.ruleType,
    required this.threshold,
    required this.isActive,
  });

  final int id;
  final String symbol;
  final String market;
  final String ruleType;
  final double threshold;
  final bool isActive;

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    return AlertItem(
      id: json['id'] as int,
      symbol: json['symbol'] as String,
      market: json['market'] as String,
      ruleType: json['rule_type'] as String,
      threshold: _asDouble(json['threshold']),
      isActive: json['is_active'] as bool,
    );
  }
}

double _asDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.parse(value.toString());
}
