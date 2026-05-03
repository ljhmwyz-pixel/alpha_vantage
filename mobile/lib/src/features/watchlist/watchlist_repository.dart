import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import 'stock_models.dart';

final watchlistRepositoryProvider = Provider<WatchlistRepository>((ref) {
  return WatchlistRepository(ref.watch(apiClientProvider));
});

class WatchlistRepository {
  const WatchlistRepository(this._client);

  final Dio _client;

  Future<List<WatchlistItem>> fetchWatchlist() async {
    final response = await _client.get<List<dynamic>>('/watchlist');
    final data = response.data ?? <dynamic>[];
    return data
        .cast<Map<String, dynamic>>()
        .map(WatchlistItem.fromJson)
        .toList(growable: false);
  }

  Future<WatchlistItem> addSymbol(String symbol, {String market = 'US'}) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/watchlist',
      data: <String, dynamic>{
        'symbol': symbol.toUpperCase(),
        'market': market.toUpperCase(),
      },
    );
    return WatchlistItem.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<void> removeSymbol(int id) async {
    await _client.delete<void>('/watchlist/$id');
  }

  Future<Quote> fetchQuote(String symbol, {String market = 'US'}) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/market/quotes/${symbol.toUpperCase()}',
      queryParameters: <String, dynamic>{'market': market.toUpperCase()},
    );
    return Quote.fromJson(response.data ?? <String, dynamic>{});
  }

  Future<List<CandlePoint>> fetchCandles(
    String symbol, {
    String market = 'US',
    int limit = 60,
  }) async {
    final response = await _client.get<List<dynamic>>(
      '/market/quotes/${symbol.toUpperCase()}/candles',
      queryParameters: <String, dynamic>{
        'market': market.toUpperCase(),
        'limit': limit,
      },
    );
    final data = response.data ?? <dynamic>[];
    return data
        .cast<Map<String, dynamic>>()
        .map(CandlePoint.fromJson)
        .toList(growable: false);
  }
}
