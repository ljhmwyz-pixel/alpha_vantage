import 'dart:math' as math;
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

  TechnicalIndicators get indicators =>
      TechnicalIndicators.fromCandles(candles);

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
  final double high, low, open, close;
  final int volume, avgVolume;
  final double changePercent;
}

class TechnicalIndicators {
  const TechnicalIndicators({
    required this.ma5,
    required this.ma10,
    required this.ma20,
    required this.ema12,
    required this.ema26,
    required this.macd,
    required this.signal,
    required this.histogram,
    required this.rsi,
    required this.upperBand,
    required this.middleBand,
    required this.lowerBand,
  });

  final List<double> ma5, ma10, ma20;
  final List<double> ema12, ema26;
  final List<double> macd, signal, histogram;
  final List<double> rsi;
  final List<double> upperBand, middleBand, lowerBand;

  factory TechnicalIndicators.fromCandles(List<CandlePoint> candles) {
    if (candles.isEmpty) {
      return const TechnicalIndicators(
        ma5: [],
        ma10: [],
        ma20: [],
        ema12: [],
        ema26: [],
        macd: [],
        signal: [],
        histogram: [],
        rsi: [],
        upperBand: [],
        middleBand: [],
        lowerBand: [],
      );
    }
    final closes = candles.map((c) => c.close).toList();
    return TechnicalIndicators(
      ma5: _calculateMA(closes, 5),
      ma10: _calculateMA(closes, 10),
      ma20: _calculateMA(closes, 20),
      ema12: _calculateEMA(closes, 12),
      ema26: _calculateEMA(closes, 26),
      macd: _calculateMACD(closes).$1,
      signal: _calculateMACD(closes).$2,
      histogram: _calculateMACD(closes).$3,
      rsi: _calculateRSI(closes, 14),
      upperBand: _calculateBollingerBands(closes, 20).$1,
      middleBand: _calculateBollingerBands(closes, 20).$2,
      lowerBand: _calculateBollingerBands(closes, 20).$3,
    );
  }

  static List<double> _calculateMA(List<double> data, int period) {
    final result = <double>[];
    for (var i = 0; i < data.length; i++) {
      if (i < period - 1) {
        result.add(0);
      } else {
        var sum = 0.0;
        for (var j = i - period + 1; j <= i; j++) {
          sum += data[j];
        }
        result.add(sum / period);
      }
    }
    return result;
  }

  static List<double> _calculateEMA(List<double> data, int period) {
    final result = <double>[];
    final multiplier = 2.0 / (period + 1);
    if (data.isEmpty) return result;
    result.add(data[0]);
    for (var i = 1; i < data.length; i++) {
      result.add((data[i] - result.last) * multiplier + result.last);
    }
    return result;
  }

  static (List<double>, List<double>, List<double>) _calculateMACD(
      List<double> data) {
    final ema12 = _calculateEMA(data, 12);
    final ema26 = _calculateEMA(data, 26);
    final macdLine = <double>[];
    for (var i = 0; i < data.length; i++) {
      macdLine.add(ema12[i] - ema26[i]);
    }
    final signalLine = _calculateEMA(macdLine, 9);
    final histogram = <double>[];
    for (var i = 0; i < macdLine.length; i++) {
      histogram.add(macdLine[i] - signalLine[i]);
    }
    return (macdLine, signalLine, histogram);
  }

  static List<double> _calculateRSI(List<double> data, int period) {
    final result = <double>[];
    if (data.length < period + 1) return result;
    final gains = <double>[];
    final losses = <double>[];
    for (var i = 1; i < data.length; i++) {
      final change = data[i] - data[i - 1];
      gains.add(change > 0 ? change : 0);
      losses.add(change < 0 ? -change : 0);
    }
    var avgGain = gains.sublist(0, period).reduce((a, b) => a + b) / period;
    var avgLoss = losses.sublist(0, period).reduce((a, b) => a + b) / period;
    for (var i = 0; i < period; i++) {
      result.add(0);
    }
    for (var i = period; i < data.length; i++) {
      if (i > period) {
        avgGain = (avgGain * (period - 1) + gains[i - 1]) / period;
        avgLoss = (avgLoss * (period - 1) + losses[i - 1]) / period;
      }
      final rs = avgLoss == 0 ? 100 : avgGain / avgLoss;
      result.add(100 - (100 / (1 + rs)));
    }
    return result;
  }

  static (List<double>, List<double>, List<double>) _calculateBollingerBands(
      List<double> data, int period) {
    final middle = _calculateMA(data, period);
    final upper = <double>[];
    final lower = <double>[];
    for (var i = 0; i < data.length; i++) {
      if (i < period - 1) {
        upper.add(0);
        lower.add(0);
      } else {
        final slice = data.sublist(i - period + 1, i + 1);
        final mean = middle[i];
        final variance =
            slice.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) /
                period;
        final stdDev = math.sqrt(variance);
        upper.add(mean + 2 * stdDev);
        lower.add(mean - 2 * stdDev);
      }
    }
    return (upper, middle, lower);
  }
}

class StockDetailScreen extends ConsumerStatefulWidget {
  const StockDetailScreen(
      {required this.symbol, required this.market, super.key});
  final String symbol;
  final String market;

  @override
  ConsumerState<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends ConsumerState<StockDetailScreen>
    with SingleTickerProviderStateMixin {
  int _selectedPeriod = 0;
  int _selectedChart = 0;
  late TabController _tabController;

  static const _periods = ['1分', '5分', '15分', '30分', '60分', '日', '周', '月'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(
        stockDetailProvider((symbol: widget.symbol, market: widget.market)));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/')),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.symbol.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(_getMarketName(widget.market),
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.star_border), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(stockDetailProvider(
                (symbol: widget.symbol, market: widget.market))),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.outline,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: const [Tab(text: '行情'), Tab(text: '详情')],
            ),
          ),
        ),
      ),
      body: detail.when(
        data: (data) => TabBarView(
          controller: _tabController,
          children: [
            _ChartTab(
              data: data,
              selectedPeriod: _selectedPeriod,
              selectedChart: _selectedChart,
              onPeriodChanged: (p) => setState(() => _selectedPeriod = p),
              onChartChanged: (c) => setState(() => _selectedChart = c),
            ),
            _DetailTab(data: data),
          ],
        ),
        error: (error, stackTrace) => _ErrorView(error: error.toString()),
        loading: () => const _LoadingView(),
      ),
    );
  }

  String _getMarketName(String code) {
    const names = {
      'US': '美股',
      'SH': '上海',
      'SZ': '深圳',
      'HK': '港股',
      'JP': '日经',
      'KR': '韩股',
      'UK': '英股',
      'DE': '德股'
    };
    return names[code] ?? code;
  }
}

class _ChartTab extends StatelessWidget {
  const _ChartTab({
    required this.data,
    required this.selectedPeriod,
    required this.selectedChart,
    required this.onPeriodChanged,
    required this.onChartChanged,
  });

  final StockDetailData data;
  final int selectedPeriod;
  final int selectedChart;
  final void Function(int) onPeriodChanged;
  final void Function(int) onChartChanged;

  @override
  Widget build(BuildContext context) {
    final quote = data.quote;
    final isUp = quote.change >= 0;
    final changeColor =
        isUp ? const Color(0xFFEF4444) : const Color(0xFF22C55E);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _PriceHeader(quote: quote, changeColor: changeColor),
        const SizedBox(height: 16),
        _ChartTypeSelector(
            selectedChart: selectedChart, onChanged: onChartChanged),
        const SizedBox(height: 12),
        _PeriodSelector(
            selectedPeriod: selectedPeriod, onChanged: onPeriodChanged),
        const SizedBox(height: 16),
        _CandlestickChart(candles: data.candles, indicators: data.indicators),
        const SizedBox(height: 16),
        _VolumeChart(candles: data.candles),
        const SizedBox(height: 16),
        _IndicatorSection(indicators: data.indicators, candles: data.candles),
      ],
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
    final numberFormat = NumberFormat.currency(symbol: '');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                numberFormat.format(quote.price),
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: changeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: changeColor),
                ),
                child: Row(
                  children: [
                    Icon(isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: changeColor, size: 20),
                    Text(
                      '${isUp ? '+' : ''}${quote.changePercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                          color: changeColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${isUp ? '+' : ''}${quote.change.toStringAsFixed(2)}',
                style:
                    TextStyle(color: changeColor, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 16),
              Text('今开: ${quote.changePercent.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartTypeSelector extends StatelessWidget {
  const _ChartTypeSelector(
      {required this.selectedChart, required this.onChanged});

  final int selectedChart;
  final void Function(int) onChanged;

  static const _types = ['分时', '日K', '周K', '月K', '年K'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_types.length, (index) {
        final isSelected = selectedChart == index;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            onTap: () => onChanged(index),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Text(
                _types[index],
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector(
      {required this.selectedPeriod, required this.onChanged});

  final int selectedPeriod;
  final void Function(int) onChanged;

  static const _periods = ['1分', '5分', '15分', '30分', '60分', '日', '周', '月'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_periods.length, (index) {
        final isSelected = selectedPeriod == index;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(index),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  _periods[index],
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _CandlestickChart extends StatelessWidget {
  const _CandlestickChart({required this.candles, required this.indicators});

  final List<CandlePoint> candles;
  final TechnicalIndicators indicators;

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty) {
      return Container(
        height: 300,
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.3),
        child: const Center(child: Text('暂无数据')),
      );
    }

    final minPrice = candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    final maxPrice = candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;
    final padding = priceRange * 0.1;

    return Container(
      height: 300,
      padding: const EdgeInsets.only(right: 60, top: 16),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (candles.length - 1).toDouble(),
          minY: minPrice - padding,
          maxY: maxPrice + padding,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: priceRange / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color:
                  Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) => Text(
                  _formatPrice(value),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _buildPriceSpots(),
              isCurved: true,
              barWidth: 1.5,
              color: const Color(0xFFEF4444),
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: _buildMASpots(indicators.ma5),
              isCurved: true,
              barWidth: 1,
              color: const Color(0xFFFF6B6B).withOpacity(0.7),
            ),
            LineChartBarData(
              spots: _buildMASpots(indicators.ma10),
              isCurved: true,
              barWidth: 1,
              color: const Color(0xFF4ECDC4).withOpacity(0.7),
            ),
            LineChartBarData(
              spots: _buildMASpots(indicators.ma20),
              isCurved: true,
              barWidth: 1,
              color: const Color(0xFFFFE66D).withOpacity(0.7),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index < candles.length) {
                  return LineTooltipItem(
                    '${DateFormat('MM/dd').format(candles[index].time)}\n${spot.y.toStringAsFixed(2)}',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                }
                return null;
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  List<FlSpot> _buildPriceSpots() => List.generate(
      candles.length, (i) => FlSpot(i.toDouble(), candles[i].close));
  List<FlSpot> _buildMASpots(List<double> ma) =>
      List.generate(ma.length, (i) => FlSpot(i.toDouble(), ma[i]));

  String _formatPrice(double value) {
    if (value >= 10000) return '${(value / 1000).toStringAsFixed(0)}k';
    if (value >= 1000) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }
}

class _VolumeChart extends StatelessWidget {
  const _VolumeChart({required this.candles});

  final List<CandlePoint> candles;

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty) return const SizedBox(height: 80);

    final maxVol =
        candles.map((c) => c.volume).reduce((a, b) => a > b ? a : b).toDouble();

    return Container(
      height: 80,
      padding: const EdgeInsets.only(right: 60),
      child: BarChart(
        BarChartData(
          maxY: maxVol,
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) => Text(
                  _formatVolume(value.toInt()),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 10),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(candles.length, (i) {
            final isUp = candles[i].close >= candles[i].open;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: candles[i].volume.toDouble(),
                  color: isUp
                      ? const Color(0xFFEF4444).withOpacity(0.6)
                      : const Color(0xFF22C55E).withOpacity(0.6),
                  width: 3,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(2)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  String _formatVolume(int volume) {
    if (volume >= 100000000)
      return '${(volume / 100000000).toStringAsFixed(1)}亿';
    if (volume >= 10000) return '${(volume / 10000).toStringAsFixed(0)}万';
    return volume.toString();
  }
}

class _IndicatorSection extends StatefulWidget {
  const _IndicatorSection({required this.indicators, required this.candles});

  final TechnicalIndicators indicators;
  final List<CandlePoint> candles;

  @override
  State<_IndicatorSection> createState() => _IndicatorSectionState();
}

class _IndicatorSectionState extends State<_IndicatorSection> {
  int _selectedIndicator = 0;

  static const _indicators = ['MACD', 'RSI', 'BOLL', 'KDJ'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(_indicators.length, (index) {
            final isSelected = _selectedIndicator == index;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => setState(() => _selectedIndicator = index),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _indicators[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        SizedBox(height: 120, child: _buildIndicatorChart()),
      ],
    );
  }

  Widget _buildIndicatorChart() {
    switch (_selectedIndicator) {
      case 0:
        return _MACDChart(
            histogram: widget.indicators.histogram,
            macd: widget.indicators.macd,
            signal: widget.indicators.signal);
      case 1:
        return _RSIChart(rsi: widget.indicators.rsi);
      case 2:
        return _BOLLChart(
            candles: widget.candles, indicators: widget.indicators);
      default:
        return _KDJChart(candles: widget.candles);
    }
  }
}

class _MACDChart extends StatelessWidget {
  const _MACDChart(
      {required this.histogram, required this.macd, required this.signal});

  final List<double> histogram, macd, signal;

  @override
  Widget build(BuildContext context) {
    if (histogram.isEmpty) return const Center(child: Text('暂无数据'));

    final minY = histogram.isEmpty
        ? 0.0
        : histogram.reduce((a, b) => a < b ? a : b) * 1.2;
    final maxY = histogram.isEmpty
        ? 0.0
        : histogram.reduce((a, b) => a > b ? a : b) * 1.2;

    return Container(
      padding: const EdgeInsets.only(right: 60, top: 8),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color:
                  Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                  macd.length, (i) => FlSpot(i.toDouble(), macd[i])),
              isCurved: true,
              barWidth: 1.5,
              color: const Color(0xFF3B82F6),
            ),
            LineChartBarData(
              spots: List.generate(
                  signal.length, (i) => FlSpot(i.toDouble(), signal[i])),
              isCurved: true,
              barWidth: 1.5,
              color: const Color(0xFFF59E0B),
            ),
            LineChartBarData(
              spots: List.generate(
                  histogram.length, (i) => FlSpot(i.toDouble(), histogram[i])),
              isCurved: false,
              barWidth: 2,
              color: const Color(0xFF10B981),
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _RSIChart extends StatelessWidget {
  const _RSIChart({required this.rsi});

  final List<double> rsi;

  @override
  Widget build(BuildContext context) {
    if (rsi.isEmpty) return const Center(child: Text('暂无数据'));

    return Container(
      padding: const EdgeInsets.only(right: 60, top: 8),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (value) => FlLine(
              color: value == 50
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                  : Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withOpacity(0.3),
              strokeWidth: 1,
              dashArray: value == 50 ? [5, 5] : null,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          rangeAnnotations: RangeAnnotations(
            horizontalRangeAnnotations: [
              HorizontalRangeAnnotation(
                  y1: 20,
                  y2: 80,
                  color: const Color(0xFF10B981).withOpacity(0.1)),
            ],
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                  rsi.length, (i) => FlSpot(i.toDouble(), rsi[i])),
              isCurved: true,
              barWidth: 2,
              color: const Color(0xFF8B5CF6),
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _BOLLChart extends StatelessWidget {
  const _BOLLChart({required this.candles, required this.indicators});

  final List<CandlePoint> candles;
  final TechnicalIndicators indicators;

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty || indicators.upperBand.isEmpty)
      return const Center(child: Text('暂无数据'));

    final closes = candles.map((c) => c.close).toList();
    final maxY = indicators.upperBand.reduce((a, b) => a > b ? a : b);
    final minY = indicators.lowerBand.reduce((a, b) => a < b ? a : b);

    return Container(
      padding: const EdgeInsets.only(right: 60, top: 8),
      child: LineChart(
        LineChartData(
          minY: minY * 0.98,
          maxY: maxY * 1.02,
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                  closes.length, (i) => FlSpot(i.toDouble(), closes[i])),
              isCurved: true,
              barWidth: 1.5,
              color: Colors.black,
            ),
            LineChartBarData(
              spots: List.generate(indicators.upperBand.length,
                  (i) => FlSpot(i.toDouble(), indicators.upperBand[i])),
              isCurved: true,
              barWidth: 1,
              color: const Color(0xFF6B7280).withOpacity(0.5),
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: List.generate(indicators.middleBand.length,
                  (i) => FlSpot(i.toDouble(), indicators.middleBand[i])),
              isCurved: true,
              barWidth: 1,
              color: const Color(0xFF6B7280).withOpacity(0.5),
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: List.generate(indicators.lowerBand.length,
                  (i) => FlSpot(i.toDouble(), indicators.lowerBand[i])),
              isCurved: true,
              barWidth: 1,
              color: const Color(0xFF6B7280).withOpacity(0.5),
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _KDJChart extends StatelessWidget {
  const _KDJChart({required this.candles});

  final List<CandlePoint> candles;

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty) return const Center(child: Text('暂无数据'));

    final kdj = _calculateKDJ(candles, 9, 3, 3);

    return Container(
      padding: const EdgeInsets.only(right: 60, top: 8),
      child: LineChart(
        LineChartData(
          minY: -20,
          maxY: 120,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) => FlLine(
              color:
                  Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                  kdj.$1.length, (i) => FlSpot(i.toDouble(), kdj.$1[i])),
              isCurved: true,
              barWidth: 1.5,
              color: const Color(0xFF3B82F6),
            ),
            LineChartBarData(
              spots: List.generate(
                  kdj.$2.length, (i) => FlSpot(i.toDouble(), kdj.$2[i])),
              isCurved: true,
              barWidth: 1.5,
              color: const Color(0xFFF59E0B),
            ),
            LineChartBarData(
              spots: List.generate(
                  kdj.$3.length, (i) => FlSpot(i.toDouble(), kdj.$3[i])),
              isCurved: true,
              barWidth: 1.5,
              color: const Color(0xFFEF4444),
            ),
          ],
        ),
      ),
    );
  }

  (List<double>, List<double>, List<double>) _calculateKDJ(
      List<CandlePoint> candles, int period, int kPeriod, int dPeriod) {
    final k = <double>[];
    final d = <double>[];
    final j = <double>[];

    for (var i = 0; i < candles.length; i++) {
      if (i < period - 1) {
        k.add(50);
        d.add(50);
        j.add(50);
      } else {
        final slice = candles.sublist(i - period + 1, i + 1);
        final high = slice.map((c) => c.high).reduce((a, b) => a > b ? a : b);
        final low = slice.map((c) => c.low).reduce((a, b) => a < b ? a : b);
        final rsv =
            high == low ? 50 : (candles[i].close - low) / (high - low) * 100;

        final kValue = k.isEmpty ? 50.0 : (2 * k.last + rsv) / 3;
        final dValue = d.isEmpty ? 50.0 : (2 * d.last + kValue) / 3;
        final jValue = 3.0 * kValue - 2.0 * dValue;

        k.add(kValue);
        d.add(dValue);
        j.add(jValue);
      }
    }
    return (k, d, j);
  }
}

class _DetailTab extends StatelessWidget {
  const _DetailTab({required this.data});

  final StockDetailData data;

  @override
  Widget build(BuildContext context) {
    final statistics = data.statistics;
    final quote = data.quote;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatisticsCard(statistics: statistics, currency: quote.currency),
        const SizedBox(height: 16),
        _TransactionInfoCard(quote: quote),
        const SizedBox(height: 16),
        _MarketInfoCard(quote: quote),
      ],
    );
  }
}

class _StatisticsCard extends StatelessWidget {
  const _StatisticsCard({required this.statistics, required this.currency});

  final StatisticsData statistics;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final currencySymbol = currency == 'USD' ? '\$' : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('股票统计',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _StatItem(
                      label: '今开',
                      value:
                          '$currencySymbol${statistics.open.toStringAsFixed(2)}',
                      color: null)),
              Expanded(
                  child: _StatItem(
                      label: '昨收',
                      value:
                          '$currencySymbol${statistics.close.toStringAsFixed(2)}',
                      color: null)),
              Expanded(
                  child: _StatItem(
                      label: '最高',
                      value:
                          '$currencySymbol${statistics.high.toStringAsFixed(2)}',
                      color: const Color(0xFFEF4444))),
              Expanded(
                  child: _StatItem(
                      label: '最低',
                      value:
                          '$currencySymbol${statistics.low.toStringAsFixed(2)}',
                      color: const Color(0xFF22C55E))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _StatItem(
                      label: '成交量',
                      value: _formatVolume(statistics.volume),
                      color: null)),
              Expanded(
                  child: _StatItem(
                      label: '成交额',
                      value: _formatAmount(statistics.volume, statistics.close),
                      color: null)),
              Expanded(
                  child: _StatItem(
                      label: '换手率',
                      value:
                          '${(statistics.volume / statistics.avgVolume * 100).toStringAsFixed(2)}%',
                      color: null)),
              Expanded(
                  child: _StatItem(
                      label: '振幅',
                      value:
                          '${((statistics.high - statistics.low) / statistics.low * 100).toStringAsFixed(2)}%',
                      color: null)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatVolume(int volume) {
    if (volume >= 100000000)
      return '${(volume / 100000000).toStringAsFixed(2)}亿';
    if (volume >= 10000) return '${(volume / 10000).toStringAsFixed(0)}万';
    return volume.toString();
  }

  String _formatAmount(int volume, double price) {
    final amount = volume * price;
    if (amount >= 100000000)
      return '${(amount / 100000000).toStringAsFixed(2)}亿';
    if (amount >= 10000) return '${(amount / 10000).toStringAsFixed(0)}万';
    return amount.toStringAsFixed(2);
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem(
      {required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline)),
        const SizedBox(height: 4),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _TransactionInfoCard extends StatelessWidget {
  const _TransactionInfoCard({required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('交易信息',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _InfoRow(label: '币种', value: quote.currency),
          _InfoRow(label: '最新价', value: quote.price.toStringAsFixed(2)),
          _InfoRow(
              label: '涨跌额',
              value:
                  '${quote.change >= 0 ? '+' : ''}${quote.change.toStringAsFixed(2)}'),
          _InfoRow(
              label: '涨跌幅',
              value:
                  '${quote.changePercent >= 0 ? '+' : ''}${quote.changePercent.toStringAsFixed(2)}%'),
          _InfoRow(
              label: '更新时间',
              value: DateFormat('yyyy-MM-dd HH:mm:ss')
                  .format(quote.asOf.toLocal())),
        ],
      ),
    );
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
          Text(label,
              style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _MarketInfoCard extends StatelessWidget {
  const _MarketInfoCard({required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('市场信息',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _InfoRow(label: '市场', value: _getMarketName(quote.market)),
          _InfoRow(label: '交易所', value: _getExchangeName(quote.market)),
          _InfoRow(label: '数据源', value: quote.provider.toUpperCase()),
          _InfoRow(label: '股票代码', value: quote.symbol),
        ],
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
      'DE': '德国'
    };
    return names[code] ?? code;
  }

  String _getExchangeName(String code) {
    const names = {
      'US': 'NYSE/NASDAQ',
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
            Icon(Icons.error_outline,
                size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('加载失败', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
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
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
    );
  }
}
