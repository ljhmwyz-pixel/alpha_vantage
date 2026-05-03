import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import 'alert_models.dart';

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  return AlertsRepository(ref.watch(apiClientProvider));
});

final alertsProvider = FutureProvider<List<AlertItem>>((ref) async {
  return ref.watch(alertsRepositoryProvider).fetchAlerts();
});

class AlertsRepository {
  const AlertsRepository(this._client);

  final Dio _client;

  Future<List<AlertItem>> fetchAlerts() async {
    final response = await _client.get<List<dynamic>>('/alerts');
    final data = response.data ?? <dynamic>[];
    return data
        .cast<Map<String, dynamic>>()
        .map(AlertItem.fromJson)
        .toList(growable: false);
  }

  Future<void> createAlert({
    required String symbol,
    required String ruleType,
    required double threshold,
    String market = 'US',
  }) async {
    await _client.post<void>(
      '/alerts',
      data: <String, dynamic>{
        'symbol': symbol.toUpperCase(),
        'market': market.toUpperCase(),
        'rule_type': ruleType,
        'threshold': threshold,
      },
    );
  }

  Future<void> deleteAlert(int id) async {
    await _client.delete<void>('/alerts/$id');
  }

  Future<void> toggleAlert(int id, bool enabled) async {
    await _client.patch<void>(
      '/alerts/$id',
      data: <String, dynamic>{
        'is_enabled': enabled,
      },
    );
  }
}