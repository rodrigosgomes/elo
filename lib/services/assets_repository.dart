import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/asset_model.dart';

class AssetsRepository {
  AssetsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<AssetModel>> fetchAssets({
    AssetFilters filters = const AssetFilters(),
    int limit = 50,
    int offset = 0,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw StateError('Sessão expirada. Faça login novamente.');
    }

    final rangeEnd = offset + limit - 1;
    var request = _client.from('assets').select('*');
    request = request.eq('user_id', userId);

    if (kDebugMode) {
      debugPrint(
        '[AssetsRepository] fetchAssets offset=$offset limit=$limit '
        'categories=${filters.categories.map((c) => c.supabaseValue).join(',')} '
        'statuses=${filters.statuses.map((s) => s.supabaseValue).join(',')} '
        'hasProof=${filters.hasProof}',
      );
    }

    if (filters.categories.isNotEmpty) {
      final values = filters.categories
          .map((category) => '"${category.supabaseValue}"')
          .join(',');
      request = request.filter('category', 'in', '($values)');
    }

    if (filters.statuses.isNotEmpty) {
      final values = filters.statuses
          .map((status) => '"${status.supabaseValue}"')
          .join(',');
      request = request.filter('status', 'in', '($values)');
    }

    if (filters.hasProof != null) {
      request = request.eq('has_proof', filters.hasProof!);
    }

    if (filters.currency != null && filters.currency!.isNotEmpty) {
      request = request.eq('value_currency', filters.currency!.toUpperCase());
    }

    if (filters.minValue != null) {
      request = request.gte('value_estimated', filters.minValue!);
    }

    if (filters.maxValue != null) {
      request = request.lte('value_estimated', filters.maxValue!);
    }

    if (filters.minOwnership != null) {
      request = request.gte('ownership_percentage', filters.minOwnership!);
    }

    if (filters.maxOwnership != null) {
      request = request.lte('ownership_percentage', filters.maxOwnership!);
    }

    if (filters.searchTerm != null && filters.searchTerm!.trim().length > 2) {
      final term = filters.searchTerm!.trim();
      request = request.or(
        'title.ilike.%$term%,description.ilike.%$term%',
      );
    }

    final order = _resolveOrder(filters.sortOrder);
    final response = await request
        .order(order.column, ascending: order.ascending)
        .range(offset, rangeEnd);
    final data = (response as List<dynamic>).cast<Map<String, dynamic>>();
    return data.map(AssetModel.fromMap).toList();
  }

  Future<List<AssetDocumentModel>> fetchDocuments(int assetId) async {
    final response = await _client
        .from('asset_documents')
        .select('*')
        .eq('asset_id', assetId)
        .order('uploaded_at', ascending: false);
    final data = (response as List<dynamic>).cast<Map<String, dynamic>>();
    return data.map(AssetDocumentModel.fromMap).toList();
  }

  Future<Map<int, bool>> fetchProofPresence(List<int> assetIds) async {
    if (assetIds.isEmpty) return const {};
    final uniqueIds = assetIds.toSet().toList(growable: false);
    final filterList = uniqueIds.join(',');
    final response = await _client
        .from('asset_documents')
        .select('asset_id')
        .filter('asset_id', 'in', '($filterList)');
    final data = (response as List<dynamic>).cast<Map<String, dynamic>>();
    final presence = <int, bool>{};
    for (final row in data) {
      final assetId = row['asset_id'];
      if (assetId is int) {
        presence[assetId] = true;
      }
    }
    return presence;
  }

  Future<AssetModel> insertAsset(AssetInput input) async {
    final userId = currentUserId;
    if (userId == null) {
      throw StateError('Sessão expirada. Faça login novamente.');
    }

    final response = await _client
        .from('assets')
        .insert(input.toInsertPayload(userId))
        .select()
        .single();
    return AssetModel.fromMap(response);
  }

  Future<AssetModel> updateAsset({
    required int assetId,
    required AssetInput input,
  }) async {
    final response = await _client
        .from('assets')
        .update(input.toUpdatePayload())
        .eq('id', assetId)
        .select()
        .single();
    return AssetModel.fromMap(response);
  }

  Future<void> archiveAsset(int assetId) async {
    await _client.from('assets').update({
      'status': AssetStatus.archived.supabaseValue,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', assetId);
  }

  Future<void> updateAssetStatus({
    required int assetId,
    required AssetStatus status,
  }) async {
    await _client.from('assets').update({
      'status': status.supabaseValue,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', assetId);
  }

  Future<void> deleteAsset(int assetId) async {
    await _client.from('assets').delete().eq('id', assetId);
  }

  Future<AssetDocumentModel> insertAssetDocument({
    required int assetId,
    required String storagePath,
    required String encryptedChecksum,
    String? fileType,
  }) async {
    final response = await _client
        .from('asset_documents')
        .insert({
          'asset_id': assetId,
          'storage_path': storagePath,
          'encrypted_checksum': encryptedChecksum,
          'file_type': fileType,
        })
        .select()
        .single();
    return AssetDocumentModel.fromMap(response);
  }

  Future<void> deleteAssetDocument(int documentId) async {
    await _client.from('asset_documents').delete().eq('id', documentId);
  }

  Future<int> countAssetDocuments(int assetId) async {
    final response = await _client
        .from('asset_documents')
        .select('id')
        .eq('asset_id', assetId);
    return (response as List<dynamic>).length;
  }

  Future<void> updateProofState({
    required int assetId,
    required bool hasProof,
  }) async {
    final updates = <String, dynamic>{
      'has_proof': hasProof,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (hasProof) {
      updates['status'] = AssetStatus.active.supabaseValue;
    } else {
      final current = await _client
          .from('assets')
          .select('status')
          .eq('id', assetId)
          .maybeSingle();
      final currentStatus =
          assetStatusFromString(current?['status'] as String?);
      if (currentStatus == AssetStatus.active) {
        updates['status'] = AssetStatus.pendingReview.supabaseValue;
      }
    }

    await _client.from('assets').update(updates).eq('id', assetId);
  }

  Future<void> insertTrustEvent({
    required String userId,
    required String eventType,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    await _client.from('trust_events').insert({
      'user_id': userId,
      'event_type': eventType,
      'description': description,
      'metadata': metadata,
    });
  }

  Future<void> insertKpiMetric({
    required String userId,
    required String metricType,
    double? metricValue,
    Map<String, dynamic>? metadata,
  }) async {
    await _client.from('kpi_metrics').insert({
      'user_id': userId,
      'metric_type': metricType,
      'metric_value': metricValue,
      'metadata': metadata,
    });
  }

  Future<void> insertKpiSnapshot(NetWorthSnapshot snapshot) async {
    await _client.from('kpi_metrics').insert(snapshot.toInsertPayload());
  }

  Future<NetWorthHistoryReference?> fetchNetWorthHistoryReference({
    required String userId,
    required DateTime threshold,
  }) async {
    final baselineResponse = await _client
        .from('kpi_metrics')
        .select('metric_value, recorded_at')
        .eq('user_id', userId)
        .eq('metric_type', NetWorthSnapshot.metricType)
        .lte('recorded_at', threshold.toUtc().toIso8601String())
        .order('recorded_at', ascending: false)
        .limit(1);
    final baseline =
        (baselineResponse as List<dynamic>).cast<Map<String, dynamic>>();
    if (baseline.isNotEmpty) {
      return NetWorthHistoryReference.fromMetricRow(
        baseline.first,
        meetsWindowRequirement: true,
      );
    }

    final fallbackResponse = await _client
        .from('kpi_metrics')
        .select('metric_value, recorded_at')
        .eq('user_id', userId)
        .eq('metric_type', NetWorthSnapshot.metricType)
        .order('recorded_at', ascending: true)
        .limit(1);
    final fallback =
        (fallbackResponse as List<dynamic>).cast<Map<String, dynamic>>();
    if (fallback.isEmpty) return null;
    return NetWorthHistoryReference.fromMetricRow(
      fallback.first,
      meetsWindowRequirement: false,
    );
  }

  Future<ChecklistAssetUpdateResult> upsertChecklistAfterFirstAsset(
      String userId) async {
    final checklist = await _client
        .from('user_checklists')
        .select('has_asset, has_guardian, life_check_enabled')
        .eq('user_id', userId)
        .maybeSingle();
    final hadAsset =
        checklist != null && (checklist['has_asset'] as bool? ?? false);
    if (hadAsset) {
      final hasGuardian = checklist['has_guardian'] as bool? ?? false;
      final lifeCheckEnabled =
          checklist['life_check_enabled'] as bool? ?? false;
      final protectionScore = await _loadProtectionScore(userId,
          fallbackHasAsset: hadAsset,
          fallbackGuardian: hasGuardian,
          fallbackLifeCheck: lifeCheckEnabled);
      return ChecklistAssetUpdateResult(
        unlockedAsset: false,
        checklistCompleted: hasGuardian && lifeCheckEnabled,
        protectionRingScore: protectionScore,
      );
    }

    final hasGuardian = checklist?['has_guardian'] as bool? ?? false;
    final lifeCheckEnabled = checklist?['life_check_enabled'] as bool? ?? false;
    final profile = await _client
        .from('profiles')
        .select('two_factor_enforced')
        .eq('id', userId)
        .maybeSingle();
    final twoFactorEnabled = profile?['two_factor_enforced'] as bool? ?? false;

    final score = _calculateProtectionRingScore(
      hasAsset: true,
      hasGuardian: hasGuardian,
      lifeCheckEnabled: lifeCheckEnabled,
      twoFactorEnabled: twoFactorEnabled,
    );

    await _client.from('user_checklists').upsert({
      'user_id': userId,
      'has_asset': true,
      'protection_ring_score': score,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    return ChecklistAssetUpdateResult(
      unlockedAsset: true,
      checklistCompleted: hasGuardian && lifeCheckEnabled,
      protectionRingScore: score,
    );
  }

  Future<void> insertStepUpEvent({
    required String userId,
    required String eventType,
    required String factorUsed,
    bool success = true,
    Map<String, dynamic>? metadata,
  }) async {
    await _client.from('step_up_events').insert({
      'user_id': userId,
      'event_type': eventType,
      'factor_used': factorUsed,
      'success': success,
      'related_resource': 'assets',
      'metadata': metadata,
    });
  }
}

int _calculateProtectionRingScore({
  required bool hasAsset,
  required bool hasGuardian,
  required bool lifeCheckEnabled,
  required bool twoFactorEnabled,
}) {
  final base = (hasAsset ? 30 : 0) +
      (hasGuardian ? 30 : 0) +
      (lifeCheckEnabled ? 30 : 0);
  final bonus = twoFactorEnabled ? 10 : 0;
  return math.min(base + bonus, 100);
}

Future<int> _loadProtectionScore(
  String userId, {
  required bool fallbackHasAsset,
  required bool fallbackGuardian,
  required bool fallbackLifeCheck,
}) async {
  final profile = await Supabase.instance.client
      .from('profiles')
      .select('two_factor_enforced')
      .eq('id', userId)
      .maybeSingle();
  final twoFactorEnabled = profile?['two_factor_enforced'] as bool? ?? false;
  return _calculateProtectionRingScore(
    hasAsset: fallbackHasAsset,
    hasGuardian: fallbackGuardian,
    lifeCheckEnabled: fallbackLifeCheck,
    twoFactorEnabled: twoFactorEnabled,
  );
}

class ChecklistAssetUpdateResult {
  const ChecklistAssetUpdateResult({
    required this.unlockedAsset,
    required this.checklistCompleted,
    required this.protectionRingScore,
  });

  final bool unlockedAsset;
  final bool checklistCompleted;
  final int protectionRingScore;
}

class _AssetsOrder {
  const _AssetsOrder(this.column, {required this.ascending});

  final String column;
  final bool ascending;
}

_AssetsOrder _resolveOrder(AssetSortOrder order) {
  switch (order) {
    case AssetSortOrder.valueAsc:
      return const _AssetsOrder('value_estimated', ascending: true);
    case AssetSortOrder.valueDesc:
      return const _AssetsOrder('value_estimated', ascending: false);
    case AssetSortOrder.nameAz:
      return const _AssetsOrder('title', ascending: true);
    case AssetSortOrder.category:
      return const _AssetsOrder('category', ascending: true);
    case AssetSortOrder.updatedDesc:
      return const _AssetsOrder('updated_at', ascending: false);
  }
}
