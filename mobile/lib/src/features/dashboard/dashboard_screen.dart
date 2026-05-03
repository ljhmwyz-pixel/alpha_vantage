import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../watchlist/stock_models.dart';
import '../watchlist/watchlist_controller.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('行情监控'),
        actions: <Widget>[
          IconButton(
            tooltip: '刷新',
            onPressed: () =>
                ref.read(watchlistControllerProvider.notifier).refresh(),
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
        onRefresh: () =>
            ref.read(watchlistControllerProvider.notifier).refresh(),
        child: quotes.when(
          data: (items) => _DashboardContent(
            quotes: items,
            symbolController: _symbolController,
            selectedMarket: _selectedMarket,
            onAddSymbol: _addSymbol,
            onMarketChanged: (market) =>
                setState(() => _selectedMarket = market),
            onShowSearch: () => _showStockSearchDialog(context),
          ),
          error: (error, stackTrace) => ListView(
            children: <Widget>[
              const SizedBox(height: 128),
              const Icon(Icons.cloud_off_outlined, size: 46),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  void _addSymbol() {
    final symbol = _symbolController.text.trim();
    if (symbol.isEmpty) return;
    _symbolController.clear();
    ref
        .read(watchlistControllerProvider.notifier)
        .addSymbol(symbol, market: _selectedMarket);
  }

  void _showStockSearchDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StockSearchSheet(
        onSelect: (symbol, market) {
          ref
              .read(watchlistControllerProvider.notifier)
              .addSymbol(symbol, market: market);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.quotes,
    required this.symbolController,
    required this.selectedMarket,
    required this.onAddSymbol,
    required this.onMarketChanged,
    required this.onShowSearch,
  });

  final List<Quote> quotes;
  final TextEditingController symbolController;
  final String selectedMarket;
  final VoidCallback onAddSymbol;
  final void Function(String) onMarketChanged;
  final VoidCallback onShowSearch;

  @override
  Widget build(BuildContext context) {
    final metrics = _WatchlistMetrics.fromQuotes(quotes);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: <Widget>[
        _SummaryBand(metrics: metrics),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: symbolController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: '股票代码',
                ),
                onSubmitted: (_) => onAddSymbol(),
              ),
            ),
            const SizedBox(width: 10),
            _MarketDropdown(value: selectedMarket, onChanged: onMarketChanged),
            const SizedBox(width: 10),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: onAddSymbol,
                icon: const Icon(Icons.add),
                label: const Text('添加'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (quotes.isEmpty)
          _EmptyState(onAddStock: onShowSearch)
        else ...<Widget>[
          Row(
            children: <Widget>[
              Text(
                '我的自选 (${quotes.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onShowSearch,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final quote in metrics.sortedQuotes) _QuoteTile(quote: quote),
        ],
      ],
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
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: _markets
            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
            .toList(),
        onChanged: (v) => onChanged(v ?? value),
      ),
    );
  }
}

class _SummaryBand extends StatelessWidget {
  const _SummaryBand({required this.metrics});

  final _WatchlistMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final averageColor = metrics.averageChange >= 0
        ? const Color(0xFF15803D)
        : const Color(0xFFB91C1C);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '监控概览',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              _ProviderBadge(provider: metrics.providerLabel),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _MetricCell(
                  label: '自选',
                  value: metrics.count.toString(),
                ),
              ),
              Expanded(
                child: _MetricCell(
                  label: '上涨',
                  value: metrics.risers.toString(),
                  valueColor: const Color(0xFF15803D),
                ),
              ),
              Expanded(
                child: _MetricCell(
                  label: '下跌',
                  value: metrics.fallers.toString(),
                  valueColor: const Color(0xFFB91C1C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _MetricCell(
                  label: '平均涨跌',
                  value: '${metrics.averageChange >= 0 ? '+' : ''}'
                      '${metrics.averageChange.toStringAsFixed(2)}%',
                  valueColor: averageColor,
                ),
              ),
              Expanded(
                child: _MetricCell(
                  label: '最大波动',
                  value: metrics.topMoverLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _ProviderBadge extends StatelessWidget {
  const _ProviderBadge({required this.provider});

  final String provider;

  @override
  Widget build(BuildContext context) {
    final isMock = provider.toLowerCase() == 'mock';
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isMock ? scheme.errorContainer : scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        isMock ? '演示数据' : provider,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isMock
                  ? scheme.onErrorContainer
                  : scheme.onSecondaryContainer,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _QuoteTile extends StatelessWidget {
  const _QuoteTile({required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.currency(symbol: '${quote.currency} ');
    final isUp = quote.change >= 0;
    final changeColor =
        isUp ? const Color(0xFF15803D) : const Color(0xFFB91C1C);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () =>
            context.go('/stock/${quote.symbol}?market=${quote.market}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            quote.symbol,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isUp ? Icons.trending_up : Icons.trending_down,
                          color: changeColor,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${quote.market} · ${quote.provider} · '
                      '${DateFormat.Hm().format(quote.asOf.toLocal())}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    numberFormat.format(quote.price),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${isUp ? '+' : ''}${quote.change.toStringAsFixed(2)}  '
                    '${isUp ? '+' : ''}${quote.changePercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: changeColor,
                      fontWeight: FontWeight.w700,
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
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddStock});

  final VoidCallback onAddStock;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 72),
      child: Column(
        children: [
          Icon(
            Icons.trending_up,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无自选股',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '添加关注的股票，实时追踪行情',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAddStock,
            icon: const Icon(Icons.add),
            label: const Text('添加股票'),
          ),
        ],
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
    required this.providerLabel,
    required this.topMoverLabel,
    required this.sortedQuotes,
  });

  final int count;
  final int risers;
  final int fallers;
  final double averageChange;
  final String providerLabel;
  final String topMoverLabel;
  final List<Quote> sortedQuotes;

  factory _WatchlistMetrics.fromQuotes(List<Quote> quotes) {
    if (quotes.isEmpty) {
      return const _WatchlistMetrics(
        count: 0,
        risers: 0,
        fallers: 0,
        averageChange: 0,
        providerLabel: '未连接',
        topMoverLabel: '-',
        sortedQuotes: <Quote>[],
      );
    }

    final sorted = List<Quote>.from(quotes)
      ..sort(
        (left, right) =>
            right.changePercent.abs().compareTo(left.changePercent.abs()),
      );
    final average = quotes.fold<double>(
          0,
          (sum, quote) => sum + quote.changePercent,
        ) /
        quotes.length;
    final providers = quotes.map((quote) => quote.provider).toSet();
    final topMover = sorted.first;

    return _WatchlistMetrics(
      count: quotes.length,
      risers: quotes.where((quote) => quote.change >= 0).length,
      fallers: quotes.where((quote) => quote.change < 0).length,
      averageChange: average,
      providerLabel: providers.length == 1 ? providers.first : 'mixed',
      topMoverLabel:
          '${topMover.symbol} ${topMover.changePercent >= 0 ? '+' : ''}'
          '${topMover.changePercent.toStringAsFixed(2)}%',
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
  final _searchController = TextEditingController();
  String _selectedMarket = 'US';
  String _searchQuery = '';

  static const _markets = ['US', 'SH', 'SZ', 'HK', 'JP', 'KR', 'UK', 'DE'];

  static const _popularStocks = {
    'US': [
      ('AAPL', 'Apple Inc.'),
      ('GOOGL', 'Alphabet Inc.'),
      ('MSFT', 'Microsoft Corp.'),
      ('AMZN', 'Amazon.com Inc.'),
      ('TSLA', 'Tesla Inc.'),
      ('NVDA', 'NVIDIA Corp.'),
      ('META', 'Meta Platforms'),
      ('JPM', 'JPMorgan Chase'),
      ('BRK-B', 'Berkshire Hathaway'),
      ('V', 'Visa Inc.'),
    ],
    'SH': [
      ('600519', '贵州茅台'),
      ('600036', '招商银行'),
      ('600000', '浦发银行'),
      ('601318', '中国平安'),
      ('600276', '恒瑞医药'),
      ('600309', '万华化学'),
      ('601888', '中国中免'),
      ('600887', '伊利股份'),
    ],
    'SZ': [
      ('000001', '平安银行'),
      ('000002', '万科A'),
      ('000858', '五粮液'),
      ('300750', '宁德时代'),
      ('300015', '爱尔眼科'),
      ('300059', '东方财富'),
      ('002475', '立讯精密'),
      ('002594', '比亚迪'),
    ],
    'HK': [
      ('0700', '腾讯控股'),
      ('9988', '阿里巴巴'),
      ('3690', '美团'),
      ('9618', '京东集团'),
      ('1810', '小米集团'),
      ('0941', '中国移动'),
      ('2318', '中国平安'),
      ('2628', '中国人寿'),
    ],
    'JP': [
      ('7203', '丰田汽车'),
      ('9984', '软银集团'),
      ('6758', '索尼集团'),
      ('9432', '日本电信电话'),
      ('8035', '东京电子'),
      ('6367', '大金工业'),
    ],
    'KR': [
      ('005930', '三星电子'),
      ('000660', 'SK海力士'),
      ('035420', 'NAVER'),
      ('051910', 'LG化学'),
      ('006400', '三星SDI'),
    ],
    'UK': [
      ('HSBA', '汇丰控股'),
      ('SHEL', '壳牌'),
      ('AZN', '阿斯利康'),
      ('ULVR', '联合利华'),
      ('BP', '英国石油'),
    ],
    'DE': [
      ('SAP', 'SAP SE'),
      ('SIU', '西门子'),
      ('AMZN', '亚马逊'),
      ('BAS', '巴斯夫'),
      ('BMWG', '宝马'),
      ('VOW3', '大众'),
    ],
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final popularStocks = _popularStocks[_selectedMarket] ?? [];

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
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      '添加股票',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索股票代码或名称',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _markets.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final market = _markets[index];
                      final isSelected = market == _selectedMarket;
                      return FilterChip(
                        label: Text(market),
                        selected: isSelected,
                        onSelected: (_) =>
                            setState(() => _selectedMarket = market),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_searchQuery.isEmpty) ...[
                  Text(
                    '热门股票',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ...popularStocks.map((stock) => _StockListItem(
                        symbol: stock.$1,
                        name: stock.$2,
                        market: _selectedMarket,
                        onTap: () => widget.onSelect(stock.$1, _selectedMarket),
                      )),
                ] else ...[
                  _StockListItem(
                    symbol: _searchQuery.toUpperCase(),
                    name: '搜索: $_searchQuery',
                    market: _selectedMarket,
                    onTap: () => widget.onSelect(
                        _searchQuery.toUpperCase(), _selectedMarket),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StockListItem extends StatelessWidget {
  const _StockListItem({
    required this.symbol,
    required this.name,
    required this.market,
    required this.onTap,
  });

  final String symbol;
  final String name;
  final String market;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            market,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          symbol,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(name),
        trailing: const Icon(Icons.add_circle_outline),
        onTap: onTap,
      ),
    );
  }
}
