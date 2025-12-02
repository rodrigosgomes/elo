import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class FxService {
  FxService({http.Client? client, Duration? cacheTtl})
      : _client = client ?? http.Client(),
        _cacheTtl = cacheTtl ?? const Duration(hours: 1);

  final http.Client _client;
  final Duration _cacheTtl;
  final Map<String, _FxCacheEntry> _cache = {};

  Future<double?> convertToBrl(String currency, double amount) async {
    if (currency.toUpperCase() == 'BRL') {
      return amount;
    }

    final rate = await _fetchRate(currency.toUpperCase());
    if (rate == null) return null;
    return amount * rate;
  }

  Future<double?> _fetchRate(String currency) async {
    final cached = _cache[currency];
    final now = DateTime.now();
    if (cached != null && now.difference(cached.timestamp) < _cacheTtl) {
      return cached.rate;
    }

    try {
      final response = await _client.get(
        Uri.parse('https://open.er-api.com/v6/latest/$currency'),
      );
      if (response.statusCode != 200) {
        return null;
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final result = decoded['result'] as String?;
      if (result != 'success') return null;
      final rates = decoded['rates'] as Map<String, dynamic>;
      final rate = rates['BRL'];
      if (rate is num) {
        final rateDouble = rate.toDouble();
        _cache[currency] = _FxCacheEntry(rate: rateDouble, timestamp: now);
        return rateDouble;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  void dispose() => _client.close();
}

class _FxCacheEntry {
  _FxCacheEntry({required this.rate, required this.timestamp});
  final double rate;
  final DateTime timestamp;
}
