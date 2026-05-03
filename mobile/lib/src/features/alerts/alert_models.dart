class AlertItem {
  const AlertItem({
    required this.id,
    required this.symbol,
    required this.market,
    required this.ruleType,
    required this.threshold,
    required this.isEnabled,
    required this.isTriggered,
  });

  final int id;
  final String symbol;
  final String market;
  final String ruleType;
  final double threshold;
  final bool isEnabled;
  final bool isTriggered;

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    return AlertItem(
      id: json['id'] as int,
      symbol: json['symbol'] as String,
      market: json['market'] as String,
      ruleType: json['rule_type'] as String,
      threshold: _asDouble(json['threshold']),
      isEnabled: json['is_enabled'] as bool? ?? true,
      isTriggered: json['is_triggered'] as bool? ?? false,
    );
  }
}

double _asDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.parse(value.toString());
}