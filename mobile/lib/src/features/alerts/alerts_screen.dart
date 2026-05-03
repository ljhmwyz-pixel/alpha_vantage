import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'alert_models.dart';
import 'alerts_repository.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  final TextEditingController _symbolController = TextEditingController();
  final TextEditingController _thresholdController = TextEditingController();
  String _ruleType = 'price_above';
  String _selectedMarket = 'US';

  static const _markets = ['US', 'SH', 'SZ', 'HK', 'JP', 'KR', 'UK', 'DE'];

  @override
  void dispose() {
    _symbolController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Color _getRuleColor(String ruleType) {
    switch (ruleType) {
      case 'price_above':
        return const Color(0xFFEF4444);
      case 'price_below':
        return const Color(0xFF22C55E);
      case 'percent_change_above':
        return const Color(0xFF3B82F6);
      case 'percent_change_below':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _getRuleIcon(String ruleType) {
    switch (ruleType) {
      case 'price_above':
        return Icons.trending_up;
      case 'price_below':
        return Icons.trending_down;
      case 'percent_change_above':
        return Icons.arrow_upward;
      case 'percent_change_below':
        return Icons.arrow_downward;
      default:
        return Icons.notifications;
    }
  }

  String _getRuleLabel(String ruleType) {
    switch (ruleType) {
      case 'price_above':
        return '价格高于';
      case 'price_below':
        return '价格低于';
      case 'percent_change_above':
        return '涨幅大于';
      case 'percent_change_below':
        return '跌幅大于';
      default:
        return ruleType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final alerts = ref.watch(alertsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          tooltip: '返回',
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          '价格提醒',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: () => ref.invalidate(alertsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.3),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withOpacity(0.5),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _symbolController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: '股票代码',
                          hintText: '例如：AAPL',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Theme.of(context).colorScheme.outline),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedMarket,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: _markets
                              .map((m) =>
                                  DropdownMenuItem(value: m, child: Text(m)))
                              .toList(),
                          onChanged: (v) => setState(
                              () => _selectedMarket = v ?? _selectedMarket),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _thresholdController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        decoration: InputDecoration(
                          labelText: '阈值',
                          hintText: '提醒价格或涨跌幅',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _createAlert,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add_alert_outlined),
                      label: const Text('创建'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _RuleTypeSelector(
                  selectedRule: _ruleType,
                  onRuleChanged: (rule) => setState(() => _ruleType = rule),
                  getColor: _getRuleColor,
                  getIcon: _getRuleIcon,
                  getLabel: _getRuleLabel,
                ),
              ],
            ),
          ),
          Expanded(
            child: alerts.when(
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_none,
                            size: 40,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '暂无价格提醒',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '创建提醒，实时掌握行情变化',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _AlertCard(
                      alert: item,
                      onDelete: () => _deleteAlert(item.id),
                      onToggle: (enabled) => _toggleAlert(item.id, enabled),
                      getRuleColor: _getRuleColor,
                      getRuleIcon: _getRuleIcon,
                      getRuleLabel: _getRuleLabel,
                    );
                  },
                );
              },
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '加载失败',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => ref.invalidate(alertsProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('重试'),
                    ),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createAlert() async {
    final symbol = _symbolController.text.trim().toUpperCase();
    final threshold = double.tryParse(_thresholdController.text.trim());
    if (symbol.isEmpty || threshold == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入有效的股票代码和阈值'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await ref.read(alertsRepositoryProvider).createAlert(
          symbol: symbol,
          ruleType: _ruleType,
          threshold: threshold,
        );
    _symbolController.clear();
    _thresholdController.clear();
    ref.invalidate(alertsProvider);
  }

  Future<void> _deleteAlert(int id) async {
    await ref.read(alertsRepositoryProvider).deleteAlert(id);
    ref.invalidate(alertsProvider);
  }

  Future<void> _toggleAlert(int id, bool enabled) async {
    await ref.read(alertsRepositoryProvider).toggleAlert(id, enabled);
    ref.invalidate(alertsProvider);
  }
}

class _RuleTypeSelector extends StatelessWidget {
  const _RuleTypeSelector({
    required this.selectedRule,
    required this.onRuleChanged,
    required this.getColor,
    required this.getIcon,
    required this.getLabel,
  });

  final String selectedRule;
  final void Function(String) onRuleChanged;
  final Color Function(String) getColor;
  final IconData Function(String) getIcon;
  final String Function(String) getLabel;

  static const _ruleTypes = [
    'price_above',
    'price_below',
    'percent_change_above',
    'percent_change_below'
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _ruleTypes.map((rule) {
        final isSelected = selectedRule == rule;
        final color = getColor(rule);
        return InkWell(
          onTap: () => onRuleChanged(rule),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withOpacity(0.2)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? color
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  getIcon(rule),
                  size: 16,
                  color: isSelected
                      ? color
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  getLabel(rule),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? color
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.onDelete,
    required this.onToggle,
    required this.getRuleColor,
    required this.getRuleIcon,
    required this.getRuleLabel,
  });

  final AlertItem alert;
  final VoidCallback onDelete;
  final void Function(bool) onToggle;
  final Color Function(String) getRuleColor;
  final IconData Function(String) getRuleIcon;
  final String Function(String) getRuleLabel;

  @override
  Widget build(BuildContext context) {
    final ruleColor = getRuleColor(alert.ruleType);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: ruleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                getRuleIcon(alert.ruleType),
                color: ruleColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        alert.symbol,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          alert.market,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${getRuleLabel(alert.ruleType)} ${alert.threshold}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (alert.isEnabled)
                    Text(
                      '触发状态：${alert.isTriggered ? "已触发" : "监控中"}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: alert.isTriggered
                                ? ruleColor
                                : Theme.of(context).colorScheme.outline,
                          ),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                Switch(
                  value: alert.isEnabled,
                  onChanged: onToggle,
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                    size: 20,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
