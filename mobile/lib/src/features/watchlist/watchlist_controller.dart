import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'stock_models.dart';
import 'watchlist_repository.dart';

final watchlistControllerProvider =
    AsyncNotifierProvider<WatchlistController, List<Quote>>(
  WatchlistController.new,
);

class WatchlistController extends AsyncNotifier<List<Quote>> {
  WatchlistRepository get _repository => ref.read(watchlistRepositoryProvider);

  @override
  Future<List<Quote>> build() async {
    return _loadQuotes();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<Quote>>();
    state = await AsyncValue.guard(_loadQuotes);
  }

  Future<void> addSymbol(String symbol, {String market = 'US'}) async {
    final normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) {
      return;
    }
    await _repository.addSymbol(normalized, market: market.toUpperCase());
    await refresh();
  }

  Future<void> removeSymbol(int id) async {
    await _repository.removeSymbol(id);
    await refresh();
  }

  Future<List<Quote>> _loadQuotes() async {
    final items = await _repository.fetchWatchlist();
    return Future.wait(
      items.map((item) => _repository.fetchQuote(item.symbol, market: item.market)),
    );
  }
}
