import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../watchlist/stock_models.dart';
import '../watchlist/watchlist_repository.dart';

final stockDetailProvider =
    FutureProvider.family<StockDetailData, ({String symbol, String market})>(
        (ref, key) async {
  final repository = ref.watch(watchlistRepositoryProvider);
  final quote = await repository.fetchQuote(key.symbol, market: key.market);
  final candles = await repository.fetchCandles(key.symbol, market: key.market);
  return StockDetailData(quote: quote, candles: candles);
});

class StockDetailData {
  const StockDetailData({required this.quote, required this.candles});

  final Quote quote;
  final List<CandlePoint> candles;

  StatisticsData get statistics {
    if (candles.isEmpty) {
      return const StatisticsData(
        high: 0,
        low: 0,
        open: 0,
        close: 0,
        volume: 0,
        avgVolume: 0,
        changePercent: 0,
      );
    }

    final high = candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    final low = candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    final open = candles.first.open;
    final close = candles.last.close;
    final volume = candles.last.volume;
    final avgVolume =
        candles.map((c) => c.volume).reduce((a, b) => a + b) ~/ candles.length;
    final changePercent = ((close - open) / open) * 100;

    return StatisticsData(
      high: high,
      low: low,
      open: open,
      close: close,
      volume: volume,
      avgVolume: avgVolume,
      changePercent: changePercent,
    );
  }
}

class StatisticsData {
  const StatisticsData({
    required this.high,
    required this.low,
    required this.open,
    required this.close,
    required this.volume,
    required this.avgVolume,
    required this.changePercent,
  });

  final double high;
  final double low;
  final double open;
  final double close;
  final int volume;
  final int avgVolume;
  final double changePercent;
}

class StockDetailScreen extends ConsumerStatefulWidget {
  const StockDetailScreen({
    required this.symbol,
    required this.market,
    super.key,
  });

  final String symbol;
  final String market;

  @override
  ConsumerState<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends ConsumerState<StockDetailScreen> {
  int _selectedPeriod = 0;

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(
        stockDetailProvider((symbol: widget.symbol, market: widget.market)));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '返回',
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.symbol.toUpperCase()),
            Text(
              _getMarketName(widget.market),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: () => ref.invalidate(stockDetailProvider(
                (symbol: widget.symbol, market: widget.market))),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: detail.when(
        data: (data) => _DetailBody(
          data: data,
          selectedPeriod: _selectedPeriod,
          onPeriodChanged: (p) => setState(() => _selectedPeriod = p),
        ),
        error: (error, stackTrace) => _ErrorView(error: error.toString()),
        loading: () => const _LoadingView(),
      ),
    );
  }

  String _getMarketName(String code) {
    const names = {
      'US': '美国',
      'SH': '上海',
      'SZ': '深圳',
      'HK': '香港',
      'JP': '日本',
      'KR': '韩国',
      'UK': '英国',
      'DE': '德国',
    };
    return names[code] ?? code;
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.data,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  final StockDetailData data;
  final int selectedPeriod;
  final void Function(int) onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final quote = data.quote;
    final isUp = quote.change >= 0;
    final changeColor =
        isUp ? const Color(0xFF15803D) : const Color(0xFFB91C1C);

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PriceHeader(quote: quote, changeColor: changeColor),
          const SizedBox(height: 24),
          _ChartSection(
            candles: data.candles,
            selectedPeriod: selectedPeriod,
            onPeriodChanged: onPeriodChanged,
          ),
          const SizedBox(height: 24),
          _StatisticsCard(
            statistics: data.statistics,
            currency: quote.currency,
          ),
          const SizedBox(height: 16),
          _InfoCard(quote: quote),
        ],
      ),
    );
  }
}

class _PriceHeader extends StatelessWidget {
  const _PriceHeader({required this.quote, required this.changeColor});

  final Quote quote;
  final Color changeColor;

  @override
  Widget build(BuildContext context) {
    final isUp = quote.change >= 0;
    final numberFormat = NumberFormat.currency(symbol: '${quote.currency} ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  numberFormat.format(quote.price),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                _ChangeTag(
                    isUp: isUp,
                    change: quote.change,
                    changePercent: quote.changePercent),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '最后更新: ${DateFormat.yMd().add_Hm().format(quote.asOf.toLocal())}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangeTag extends StatelessWidget {
  const _ChangeTag(
      {required this.isUp, required this.change, required this.changePercent});

  final bool isUp;
  final double change;
  final double changePercent;

  @override
  Widget build(BuildContext context) {
    final color = isUp ? const Color(0xFF15803D) : const Color(0xFFB91C1C);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.trending_up : Icons.trending_down,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 4),
          Text(
            '${isUp ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartSection extends StatelessWidget {
  const _ChartSection({
    required this.candles,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  final List<CandlePoint> candles;
  final int selectedPeriod;
  final void Function(int) onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  '价格走势',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('日')),
                    ButtonSegment(value: 1, label: Text('周')),
                    ButtonSegment(value: 2, label: Text('月')),
                  ],
                  selected: {selectedPeriod},
                  onSelectionChanged: (s) => onPeriodChanged(s.first),
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: _PriceChart(candles: candles),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceChart extends StatelessWidget {
  const _PriceChart({required this.candles});

  final List<CandlePoint> candles;

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    final spots = <FlSpot>[
      for (var index = 0; index < candles.length; index++)
        FlSpot(index.toDouble(), candles[index].close),
    ];

    final isUp = candles.last.close >= candles.first.open;
    final color = isUp ? const Color(0xFF15803D) : const Color(0xFFB91C1C);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (candles.length - 1).toDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _calculateInterval(candles),
          getDrawingHorizontalLine: (value) => FlLine(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatPrice(value),
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (candles.length / 5).ceilToDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= candles.length)
                  return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('MM/dd').format(candles[index].time),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: <LineChartBarData>[
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 2.5,
            color: color,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.3),
                  color.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                final candle = candles[index];
                return LineTooltipItem(
                  '${DateFormat('yyyy-MM-dd').format(candle.time)}\n${candle.close.toStringAsFixed(2)}',
                  TextStyle(color: color, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  double _calculateInterval(List<CandlePoint> candles) {
    if (candles.isEmpty) return 1;
    final prices = candles.map((c) => c.close).toList();
    final max = prices.reduce((a, b) => a > b ? a : b);
    final min = prices.reduce((a, b) => a < b ? a : b);
    return ((max - min) / 5).ceilToDouble();
  }

  String _formatPrice(double value) {
    if (value >= 10000) return '${(value / 1000).toStringAsFixed(0)}k';
    if (value >= 1000) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }
}

class _StatisticsCard extends StatelessWidget {
  const _StatisticsCard({required this.statistics, required this.currency});

  final StatisticsData statistics;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final currencySymbol = currency == 'USD' ? '\$' : currency;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '统计指标',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _StatItem(
                        label: '今开',
                        value:
                            '$currencySymbol${statistics.open.toStringAsFixed(2)}')),
                Expanded(
                    child: _StatItem(
                        label: '昨收',
                        value:
                            '$currencySymbol${statistics.close.toStringAsFixed(2)}')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _StatItem(
                        label: '最高',
                        value:
                            '$currencySymbol${statistics.high.toStringAsFixed(2)}',
                        color: const Color(0xFF15803D))),
                Expanded(
                    child: _StatItem(
                        label: '最低',
                        value:
                            '$currencySymbol${statistics.low.toStringAsFixed(2)}',
                        color: const Color(0xFFB91C1C))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _StatItem(
                        label: '成交量', value: _formatVolume(statistics.volume))),
                Expanded(
                    child: _StatItem(
                        label: '均量',
                        value: _formatVolume(statistics.avgVolume))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatVolume(int volume) {
    if (volume >= 100000000)
      return '${(volume / 100000000).toStringAsFixed(2)}亿';
    if (volume >= 10000) return '${(volume / 10000).toStringAsFixed(0)}万';
    return volume.toString();
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '详细信息',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _InfoRow(label: '市场', value: _getMarketName(quote.market)),
            _InfoRow(label: '数据源', value: quote.provider.toUpperCase()),
            _InfoRow(
                label: '更新时间',
                value: DateFormat.yMd().add_Hm().format(quote.asOf.toLocal())),
          ],
        ),
      ),
    );
  }

  String _getMarketName(String code) {
    const names = {
      'US': '美国 (NYSE/NASDAQ)',
      'SH': '上海证券交易所',
      'SZ': '深圳证券交易所',
      'HK': '香港证券交易所',
      'JP': '东京证券交易所',
      'KR': '韩国证券交易所',
      'UK': '伦敦证券交易所',
      'DE': '法兰克福证券交易所',
    };
    return names[code] ?? code;
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Container(
            height: 120,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    width: 150,
                    height: 32,
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest),
                const SizedBox(height: 12),
                Container(
                    width: 100,
                    height: 20,
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Container(
            height: 320,
            padding: const EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
