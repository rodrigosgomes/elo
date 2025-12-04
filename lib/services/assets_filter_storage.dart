import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/asset_model.dart';

class AssetsFilterStorage {
  AssetsFilterStorage({Future<SharedPreferences>? preferences})
      : _prefsFuture = preferences ?? SharedPreferences.getInstance();

  final Future<SharedPreferences> _prefsFuture;

  static const String _storageKey = 'assets_filters';

  Future<AssetFilters> loadFilters(String? userId) async {
    final prefs = await _prefsFuture;
    final raw = prefs.getString(_keyFor(userId));
    if (raw == null) {
      return const AssetFilters();
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return AssetFilters.fromStorage(decoded);
    } catch (_) {
      await prefs.remove(_storageKey);
      return const AssetFilters();
    }
  }

  Future<void> saveFilters(String? userId, AssetFilters filters) async {
    final prefs = await _prefsFuture;
    final encoded = jsonEncode(filters.toStorage());
    await prefs.setString(_keyFor(userId), encoded);
  }

  Future<void> clear(String? userId) async {
    final prefs = await _prefsFuture;
    await prefs.remove(_keyFor(userId));
  }

  String _keyFor(String? userId) {
    final suffix = (userId == null || userId.isEmpty) ? 'anonymous' : userId;
    return '${_storageKey}_$suffix';
  }
}
