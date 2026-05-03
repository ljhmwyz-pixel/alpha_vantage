import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../watchlist/stock_models.dart';
import '../watchlist/watchlist_controller.dart';

final marketIndicesProvider = FutureProvider<List<MarketIndex>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return [
    MarketIndex(symbol: '000001', name: '上证指数', price: 3154.32, change: 45.67, changePercent: 1.47, market: 'SH'),
    MarketIndex(symbol: '399001', name: '深证成指', price: 10235.78, change: 128.45, changePercent: 1.27, market: 'SZ'),
    MarketIndex(symbol: 'HSI', name: '恒生指数', price: 18456.12, change: -123.45, changePercent: -0.66, market: 'HK'),
    MarketIndex(symbol: 'IXIC', name: '纳斯达克', price: 14532.67, change: 234.56, changePercent: 1.64, market: 'US'),
    MarketIndex(symbol: 'SPX', name: '标普500', price: 4567.89, change: 12.34, changePercent: 0.27, market: 'US'),
  ];
});

class MarketIndex {
  const MarketIndex({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.market,
  });

  final String symbol;
  final String name;
  final double price;
  final double change;
  final double changePercent;
  final String market;
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<DashboardScreen> {
  final TextEditingController _symbolController = TextEditingController();
  String _selectedMarket = 'US';

  @override
  void dispose() {
    _symbolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quotes = ref.watch(watchlistControllerProvider);
    final indices = ref.watch(marketIndicesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Row(
          children: [
            Icon(
              Icons.show_chart,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text(
              '行情监控',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: '刷新',
            onPressed: () {
              ref.read(watchlistControllerProvider.notifier).refresh();
              ref.invalidate(marketIndicesProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: '提醒',
            onPressed: () => context.go('/alerts'),
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            tooltip: '设置',
            onPressed: () => context.go('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(watchlistControllerProvider.notifier).refresh();
          ref.invalidate(marketIndicesProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _MarketOverviewSection(indices: indices),
            ),
            SliverToBoxAdapter(
              child: _SearchSection(
                symbolController: _symbolController,
                selectedMarket: _selectedMarket,
                onAddSymbol: _addSymbol,
                onMarketChanged: (market) => setState(() => _selectedMarket = market),
                onShowSearch: () => _showStockSearchDialog(context),
              ),
            ),
            quotes.when(
              data: (items) => items.isEmpty
                  ? SliverToBoxAdapter(child: _EmptyWatchlist(onAddStock: () => _showStockSearchDialog(context)))
                  : SliverToBoxAdapter(
                      child: _WatchlistSection(
                        quotes: items,
                        onShowSearch: () => _showStockSearchDialog(context),
                      ),
                    ),
              error: (error, stackTrace) => SliverToBoxAdapter(child: _ErrorState(error: error.toString())),
              loading: () => const SliverToBoxAdapter(child: _LoadingWatchlist()),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  void _addSymbol() {
    final symbol = _symbolController.text.trim();
    if (symbol.isEmpty) return;
    _symbolController.clear();
    ref.read(watchlistControllerProvider.notifier).addSymbol(symbol, market: _selectedMarket);
  }

  void _showStockSearchDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StockSearchSheet(
        onSelect: (symbol, market) {
          ref.read(watchlistControllerProvider.notifier).addSymbol(symbol, market: market);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _MarketOverviewSection extends StatelessWidget {
  const _MarketOverviewSection({required this.indices});

  final AsyncValue<List<MarketIndex>> indices;

  @override
  Widget build(BuildContext context) {
    return indices.when(
      data: (list) => Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '大盘指数',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  DateFormat('MM-dd HH:mm').format(DateTime.now()),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) => _IndexCard(indexData: list[index]),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      error: (_, __) => const SizedBox(height: 130),
      loading: () => const SizedBox(height: 130, child: Center(child: CircularProgressIndicator())),
    );
  }
}

class _IndexCard extends StatelessWidget {
  const _IndexCard({required this.indexData});

  final MarketIndex indexData;

  @override
  Widget build(BuildContext context) {
    final isUp = indexData.change >= 0;
    final changeColor = isUp ? const Color(0xFFEF4444) : const Color(0xFF22C55E);
    final bgColor = isUp ? const Color(0xFFfef2f2) : const Color(0xFFf0fdf4);

    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: changeColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            indexData.name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          Text(
            indexData.price.toStringAsFixed(2),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Icon(isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: changeColor, size: 20),
              Text(
                '${isUp ? '+' : ''}${indexData.changePercent.toStringAsFixed(2)}%',
                style: TextStyle(color: changeColor, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchSection extends StatelessWidget {
  const _SearchSection({
    required this.symbolController,
    required this.selectedMarket,
    required this.onAddSymbol,
    required this.onMarketChanged,
    required this.onShowSearch,
  });

  final TextEditingController symbolController;
  final String selectedMarket;
  final VoidCallback onAddSymbol;
  final void Function(String) onMarketChanged;
  final VoidCallback onShowSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: symbolController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: '输入股票代码',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onSubmitted: (_) => onAddSymbol(),
                  ),
                ),
                _MarketDropdown(value: selectedMarket, onChanged: onMarketChanged),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onAddSymbol,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text('我的自选', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(onPressed: onShowSearch, icon: const Icon(Icons.add, size: 18), label: const Text('添加')),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _MarketDropdown extends StatelessWidget {
  const _MarketDropdown({required this.value, required this.onChanged});

  final String value;
  final void Function(String) onChanged;

  static const _markets = ['US', 'SH', 'SZ', 'HK', 'JP', 'KR', 'UK', 'DE'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: _markets.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
        onChanged: (v) => onChanged(v ?? value),
      ),
    );
  }
}

class _WatchlistSection extends StatelessWidget {
  const _WatchlistSection({required this.quotes, required this.onShowSearch});

  final List<Quote> quotes;
  final VoidCallback onShowSearch;

  @override
  Widget build(BuildContext context) {
    final metrics = _WatchlistMetrics.fromQuotes(quotes);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _WatchlistSummaryCard(metrics: metrics),
          const SizedBox(height: 16),
          ...quotes.map((quote) => _StockCard(quote: quote)),
        ],
      ),
    );
  }
}

class _WatchlistSummaryCard extends StatelessWidget {
  const _WatchlistSummaryCard({required this.metrics});

  final _WatchlistMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final averageColor = metrics.averageChange >= 0 ? const Color(0xFFEF4444) : const Color(0xFF22C55E);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primaryContainer, Theme.of(context).colorScheme.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(label: '自选', value: '${metrics.count}', icon: Icons.star_outline),
          _SummaryItem(label: '上涨', value: '${metrics.risers}', icon: Icons.trending_up, color: const Color(0xFFEF4444)),
          _SummaryItem(label: '下跌', value: '${metrics.fallers}', icon: Icons.trending_down, color: const Color(0xFF22C55E)),
          _SummaryItem(
            label: '平均',
            value: '${metrics.averageChange >= 0 ? '+' : ''}${metrics.averageChange.toStringAsFixed(2)}%',
            icon: Icons.show_chart,
            color: averageColor,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value, required this.icon, this.color});

  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color ?? Theme.of(context).colorScheme.primary, size: 20),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _StockCard extends StatelessWidget {
  const _StockCard({required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.currency(symbol: '');
    final isUp = quote.change >= 0;
    final changeColor = isUp ? const Color(0xFFEF4444) : const Color(0xFF22C55E);
    final bgColor = isUp ? const Color(0xFFfef2f2) : const Color(0xFFf0fdf4);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/stock/${quote.symbol}?market=${quote.market}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                child: Center(
                  child: Text(
                    quote.symbol.substring(0, quote.symbol.length > 2 ? 2 : quote.symbol.length),
                    style: TextStyle(fontWeight: FontWeight.bold, color: changeColor, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(quote.symbol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(quote.market, style: const TextStyle(fontSize: 10)),
                        ),
                        const SizedBox(width: 8),
                        Text(_getMarketName(quote.market), style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(numberFormat.format(quote.price), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: changeColor, size: 16),
                        Text(
                          '${isUp ? '+' : ''}${quote.changePercent.toStringAsFixed(2)}%',
                          style: TextStyle(color: changeColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMarketName(String code) {
    const names = {'US': '美股', 'SH': '上海', 'SZ': '深圳', 'HK': '港股', 'JP': '日经', 'KR': '韩股', 'UK': '英股', 'DE': '德股'};
    return names[code] ?? code;
  }
}

class _EmptyWatchlist extends StatelessWidget {
  const _EmptyWatchlist({required this.onAddStock});

  final VoidCallback onAddStock;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.trending_up, size: 40, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text('暂无自选股票', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            '添加您关注的股票，实时掌握行情动态',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAddStock,
            icon: const Icon(Icons.add),
            label: const Text('添加股票'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text('加载失败', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(error, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _LoadingWatchlist extends StatelessWidget {
  const _LoadingWatchlist();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(
          3,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class _WatchlistMetrics {
  const _WatchlistMetrics({
    required this.count,
    required this.risers,
    required this.fallers,
    required this.averageChange,
    required this.topMoverLabel,
    required this.sortedQuotes,
  });

  final int count;
  final int risers;
  final int fallers;
  final double averageChange;
  final String topMoverLabel;
  final List<Quote> sortedQuotes;

  factory _WatchlistMetrics.fromQuotes(List<Quote> quotes) {
    if (quotes.isEmpty) {
      return const _WatchlistMetrics(
        count: 0, risers: 0, fallers: 0, averageChange: 0, topMoverLabel: '-', sortedQuotes: [],
      );
    }

    final sorted = List<Quote>.from(quotes)..sort((left, right) => right.changePercent.abs().compareTo(left.changePercent.abs()));
    final average = quotes.fold<double>(0, (sum, quote) => sum + quote.changePercent) / quotes.length;
    final topMover = sorted.first;

    return _WatchlistMetrics(
      count: quotes.length,
      risers: quotes.where((quote) => quote.change >= 0).length,
      fallers: quotes.where((quote) => quote.change < 0).length,
      averageChange: average,
      topMoverLabel: '${topMover.symbol} ${topMover.changePercent >= 0 ? '+' : ''}${topMover.changePercent.toStringAsFixed(2)}%',
      sortedQuotes: sorted,
    );
  }
}

class _StockSearchSheet extends StatefulWidget {
  const _StockSearchSheet({required this.onSelect});

  final void Function(String symbol, String market) onSelect;

  @override
  State<_StockSearchSheet> createState() => _StockSearchSheetState();
}

class _StockSearchSheetState extends State<_StockSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedMarket = 'US';
  String _searchQuery = '';

  static const _markets = ['US', 'SH', 'SZ', 'HK', 'JP', 'KR', 'UK', 'DE'];

  static final List<List<String>> _popularStocks = [
    ['AAPL', 'Apple Inc.', '178.50', '2.35'],
    ['GOOGL', 'Alphabet Inc.', '141.25', '-0.87'],
    ['MSFT', 'Microsoft Corp.', '378.90', '1.56'],
    ['AMZN', 'Amazon.com Inc.', '178.25', '0.92'],
    ['TSLA', 'Tesla Inc.', '248.50', '-1.23'],
    ['NVDA', 'NVIDIA Corp.', '875.30', '4.56'],
    ['META', 'Meta Platforms', '505.75', '1.89'],
    ['JPM', 'JPMorgan Chase', '195.40', '0.45'],
    ['600519', '贵州茅台', '1688.00', '1.25'],
    ['600036', '招商银行', '35.80', '0.56'],
    ['600000', '浦发银行', '8.15', '-0.24'],
    ['601318', '中国平安', '45.60', '0.89'],
    ['000001', '平安银行', '11.25', '0.67'],
    ['000002', '万科A', '8.45', '-1.23'],
    ['300750', '宁德时代', '186.50', '3.45'],
    ['0700', '腾讯控股', '298.00', '1.56'],
    ['9988', '阿里巴巴', '72.50', '-0.89'],
    ['3690', '美团', '98.30', '2.34'],
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredStocks = _searchQuery.isEmpty
        ? _popularStocks
        : _popularStocks.where((s) => s[0].toLowerCase().contains(_searchQuery.toLowerCase()) || s[1].contains(_searchQuery)).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: '搜索股票...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (value) => setState(() => _searchQuery = value),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedMarket,
                        underline: const SizedBox(),
                        items: _markets.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                        onChanged: (v) => setState(() => _selectedMarket = v ?? _selectedMarket),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredStocks.length + 1,
              itemBuilder: (context, index) {
                if (index == 0 && _searchQuery.isNotEmpty) {
                  return _SearchResultItem(
                    symbol: _searchQuery.toUpperCase(),
                    name: 'Add: $_searchQuery',
                    price: 0,
                    change: 0,
                    market: _selectedMarket,
                    onTap: () => widget.onSelect(_searchQuery.toUpperCase(), _selectedMarket),
                  );
                }
                final stock = filteredStocks[index - (_searchQuery.isNotEmpty ? 1 : 0)];
                final price = double.tryParse(stock[2]) ?? 0;
                final change = double.tryParse(stock[3]) ?? 0;
                return _SearchResultItem(
                  symbol: stock[0],
                  name: stock[1],
                  price: price,
                  change: change,
                  market: _selectedMarket,
                  onTap: () => widget.onSelect(stock[0], _selectedMarket),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultItem extends StatelessWidget {
  const _SearchResultItem({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.market,
    required this.onTap,
  });

  final String symbol;
  final String name;
  final double price;
  final double change;
  final String market;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUp = change >= 0;
    final changeColor = isUp ? const Color(0xFFEF4444) : const Color(0xFF22C55E);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(symbol.substring(0, symbol.length > 2 ? 2 : symbol.length), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        title: Text(symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(name),
        trailing: price > 0
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(price.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${isUp ? '+' : ''}${change.toStringAsFixed(2)}%',
                    style: TextStyle(color: changeColor, fontSize: 12),
                  ),
                ],
              )
            : const Icon(Icons.add_circle_outline),
        onTap: onTap,
      ),
    );
  }
}