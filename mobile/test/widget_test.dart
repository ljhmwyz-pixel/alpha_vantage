import 'package:alpha_vantage_monitor/src/app.dart';
import 'package:alpha_vantage_monitor/src/features/watchlist/stock_models.dart';
import 'package:alpha_vantage_monitor/src/features/watchlist/watchlist_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeWatchlistRepository extends WatchlistRepository {
  _FakeWatchlistRepository() : super(Dio());

  @override
  Future<List<WatchlistItem>> fetchWatchlist() async {
    return <WatchlistItem>[];
  }
}

void main() {
  testWidgets('renders watchlist screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          watchlistRepositoryProvider.overrideWithValue(_FakeWatchlistRepository()),
        ],
        child: const AlphaVantageApp(),
      ),
    );

    expect(find.text('行情监控'), findsOneWidget);
  });
}
