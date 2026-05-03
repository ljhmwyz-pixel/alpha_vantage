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

  @override
  void dispose() {
    _symbolController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alerts = ref.watch(alertsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Alerts'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _symbolController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Symbol'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _thresholdController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Threshold'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _ruleType,
                  decoration: const InputDecoration(labelText: 'Rule'),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(
                      value: 'price_above',
                      child: Text('Price above'),
                    ),
                    DropdownMenuItem(
                      value: 'price_below',
                      child: Text('Price below'),
                    ),
                    DropdownMenuItem(
                      value: 'percent_change_above',
                      child: Text('% change above'),
                    ),
                    DropdownMenuItem(
                      value: 'percent_change_below',
                      child: Text('% change below'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _ruleType = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: _createAlert,
                icon: const Icon(Icons.add_alert_outlined),
                label: const Text('Create'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          alerts.when(
            data: (items) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 64),
                  child: Center(child: Text('No alerts')),
                );
              }
              return Column(
                children: <Widget>[
                  for (final item in items) _AlertTile(item: item),
                ],
              );
            },
            error: (error, stackTrace) => Padding(
              padding: const EdgeInsets.only(top: 64),
              child: Center(
                child: Text(error.toString(), textAlign: TextAlign.center),
              ),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 64),
              child: Center(child: CircularProgressIndicator()),
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
}

class _AlertTile extends ConsumerWidget {
  const _AlertTile({required this.item});

  final AlertItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.notifications_active_outlined),
        title: Text('${item.symbol} · ${_labelForRule(item.ruleType)}'),
        subtitle: Text('${item.market} · ${item.threshold.toStringAsFixed(2)}'),
        trailing: IconButton(
          tooltip: 'Delete',
          onPressed: () async {
            await ref.read(alertsRepositoryProvider).deleteAlert(item.id);
            ref.invalidate(alertsProvider);
          },
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }

  String _labelForRule(String ruleType) {
    return switch (ruleType) {
      'price_above' => 'Price above',
      'price_below' => 'Price below',
      'percent_change_above' => '% change above',
      'percent_change_below' => '% change below',
      _ => ruleType,
    };
  }
}
