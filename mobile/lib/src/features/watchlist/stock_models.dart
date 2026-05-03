class WatchlistItem {
  const WatchlistItem({
    required this.id,
    required this.symbol,
    required this.market,
    this.name,
  });

  final int id;
  final String symbol;
  final String market;
  final String? name;

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      id: json['id'] as int,
      symbol: json['symbol'] as String,
      market: json['market'] as String,
      name: json['name'] as String?,
    );
  }
}

class Quote {
  const Quote({
    required this.symbol,
    required this.market,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.currency,
    required this.asOf,
    required this.provider,
  });

  final String symbol;
  final String market;
  final double price;
  final double change;
  final double changePercent;
  final String currency;
  final DateTime asOf;
  final String provider;

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      symbol: json['symbol'] as String,
      market: json['market'] as String,
      price: _asDouble(json['price']),
      change: _asDouble(json['change']),
      changePercent: _asDouble(json['change_percent']),
      currency: json['currency'] as String,
      asOf: DateTime.parse(json['as_of'] as String),
      provider: json['provider'] as String,
    );
  }
}

class CandlePoint {
  const CandlePoint({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;

  factory CandlePoint.fromJson(Map<String, dynamic> json) {
    return CandlePoint(
      time: DateTime.parse(json['time'] as String),
      open: _asDouble(json['open']),
      high: _asDouble(json['high']),
      low: _asDouble(json['low']),
      close: _asDouble(json['close']),
      volume: json['volume'] as int,
    );
  }
}

double _asDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.parse(value.toString());
}
