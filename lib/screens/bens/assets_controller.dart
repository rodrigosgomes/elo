import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/asset_model.dart';
import '../../services/assets_event_bus.dart';
import '../../services/assets_repository.dart';
import '../../services/fx_service.dart';
import '../../services/assets_filter_storage.dart';
import '../../services/asset_proof_service.dart';

class AssetsController extends ChangeNotifier {
  AssetsController({
    AssetsRepository? repository,
    FxService? fxService,
    AssetsFilterStorage? filterStorage,
    AssetProofService? proofService,
    AssetsEventBus? eventBus,
  })  : _repository = repository ?? AssetsRepository(),
        _fxService = fxService ?? FxService(),
        _filterStorage = filterStorage ?? AssetsFilterStorage(),
        _ownsFxService = fxService == null,
        _eventBus = eventBus {
    _proofService = proofService ?? AssetProofService(repository: _repository);
  }

  final AssetsRepository _repository;
  final FxService _fxService;
  final AssetsFilterStorage _filterStorage;
  final bool _ownsFxService;
  final AssetsEventBus? _eventBus;
  late final AssetProofService _proofService;

  static const int pageSize = 50;

  final List<AssetModel> _assets = [];
  AssetFilters _filters = const AssetFilters();
  NetWorthSummary _netWorth = NetWorthSummary.empty();
  RealtimeChannel? _assetsChannel;
  final Map<int, List<AssetDocumentModel>> _documentsCache = {};
  final Map<int, bool> _documentsLoading = {};

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  Timer? _searchDebounce;
  bool _disposed = false;

  List<AssetModel> get assets => List.unmodifiable(_assets);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  AssetFilters get filters => _filters;
  NetWorthSummary get netWorth => _netWorth;
  List<AssetDocumentModel> documentsFor(int assetId) => List.unmodifiable(
      _documentsCache[assetId] ?? const <AssetDocumentModel>[]);
  bool isLoadingDocuments(int assetId) => _documentsLoading[assetId] ?? false;

  Future<AssetModel> createAsset(AssetInput input) async {
    final created = await _repository.insertAsset(input);
    final userId = _repository.currentUserId;
    if (userId != null) {
      final checklistResult =
          await _repository.upsertChecklistAfterFirstAsset(userId);
      await _handleChecklistProgress(userId, checklistResult);
      await _logAssetEvent(
        'ASSET_CREATED',
        'Bem cadastrado',
        metadata: _assetMetadata(created),
      );
    }
    await refresh();
    return created;
  }

  Future<AssetModel> updateAsset(int assetId, AssetInput input) async {
    final updated = await _repository.updateAsset(
      assetId: assetId,
      input: input,
    );
    await _logAssetEvent(
      'ASSET_UPDATED',
      'Bem atualizado',
      metadata: _assetMetadata(updated),
    );
    await refresh();
    return updated;
  }

  Future<void> archiveAsset(
    int assetId, {
    String? factorUsed,
  }) async {
    await _repository.archiveAsset(assetId);
    await _logAssetEvent(
      'ASSET_ARCHIVED',
      'Bem arquivado',
      metadata: {'asset_id': assetId},
    );
    if (factorUsed != null) {
      await _logStepUpEvent(
        'ASSET_ARCHIVED',
        factorUsed: factorUsed,
        metadata: {
          'asset_id': assetId,
          'reason': 'archive',
        },
      );
    }
    await refresh();
  }

  Future<void> restoreAssetStatus({
    required int assetId,
    required AssetStatus previousStatus,
  }) async {
    await _repository.updateAssetStatus(
      assetId: assetId,
      status: previousStatus,
    );
    await _logAssetEvent(
      'ASSET_STATUS_RESTORED',
      'Status do bem revertido',
      metadata: {
        'asset_id': assetId,
        'restored_status': previousStatus.supabaseValue,
      },
    );
    await refresh();
  }

  Future<void> deleteAsset(
    int assetId, {
    String? factorUsed,
  }) async {
    await _repository.deleteAsset(assetId);
    await _logAssetEvent(
      'ASSET_DELETED',
      'Bem removido',
      metadata: {'asset_id': assetId},
    );
    if (factorUsed != null) {
      await _logStepUpEvent(
        'ASSET_DELETED',
        factorUsed: factorUsed,
        metadata: {
          'asset_id': assetId,
          'reason': 'delete',
        },
      );
    }
    await refresh();
  }

  Future<List<AssetDocumentModel>> loadAssetDocuments(int assetId) async {
    _documentsLoading[assetId] = true;
    notifyListeners();
    try {
      final docs = await _repository.fetchDocuments(assetId);
      _documentsCache[assetId] = docs;
      return docs;
    } catch (error, stackTrace) {
      debugPrint('Failed to load asset documents: $error\n$stackTrace');
      rethrow;
    } finally {
      _documentsLoading[assetId] = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<AssetDocumentModel?> uploadProof(int assetId) async {
    final document = await _proofService.pickAndUploadProof(assetId);
    if (document != null) {
      final nextDocs = List<AssetDocumentModel>.from(
        _documentsCache[assetId] ?? const <AssetDocumentModel>[],
      )..insert(0, document);
      _documentsCache[assetId] = nextDocs;
      notifyListeners();
      await refresh();
    }
    return document;
  }

  Future<void> removeProof(AssetDocumentModel document) async {
    await _proofService.deleteProof(document);
    final docs = List<AssetDocumentModel>.from(
      _documentsCache[document.assetId] ?? const <AssetDocumentModel>[],
    )..removeWhere((entry) => entry.id == document.id);
    _documentsCache[document.assetId] = docs;
    notifyListeners();
    await refresh();
  }

  Future<String> downloadProof(
    AssetDocumentModel document, {
    String? factorUsed,
  }) {
    return _proofService.downloadProof(
      document,
      factorUsed: factorUsed,
    );
  }

  Future<AssetModel> duplicateAsset(AssetModel source) async {
    final duplicateInput = AssetInput(
      category: source.category,
      title: _buildDuplicateTitle(source.title),
      description: source.description,
      valueEstimated: source.valueEstimated,
      valueCurrency: source.valueCurrency,
      valueUnknown: source.valueUnknown,
      ownershipPercentage: source.ownershipPercentage,
      hasProof: false,
      status: AssetStatus.pendingReview,
    );
    final duplicated = await _repository.insertAsset(duplicateInput);
    await _logAssetEvent(
      'ASSET_DUPLICATED',
      'Bem duplicado a partir de ${source.id}',
      metadata: {
        'source_asset_id': source.id,
        ..._assetMetadata(duplicated),
      },
    );
    await refresh();
    return duplicated;
  }

  Future<void> bootstrap() async {
    await _loadPersistedFilters();
    await refresh();
    _subscribeToAssetsChannel();
  }

  Future<void> refresh() async {
    _hasMore = true;
    await _fetchAssets(refresh: true);
  }

  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();
    await _fetchAssets(refresh: false);
  }

  void updateSearchTerm(String value) {
    final sanitized = value.trim();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _filters = _filters.copyWith(
        searchTerm: sanitized.isEmpty ? null : sanitized,
      );
      _persistFilters();
      refresh();
    });
  }

  void toggleCategory(AssetCategory category) {
    final next = Set<AssetCategory>.from(_filters.categories);
    if (next.contains(category)) {
      next.remove(category);
    } else {
      next.add(category);
    }
    _filters = _filters.copyWith(categories: next);
    _persistFilters();
    refresh();
  }

  void setProofFilter(ProofFilter filter) {
    switch (filter) {
      case ProofFilter.all:
        _filters = _filters.copyWith(hasProof: null);
        break;
      case ProofFilter.withProof:
        _filters = _filters.copyWith(hasProof: true);
        break;
      case ProofFilter.withoutProof:
        _filters = _filters.copyWith(hasProof: false);
        break;
    }
    _persistFilters();
    refresh();
  }

  void clearFilters() {
    _filters = const AssetFilters();
    _clearPersistedFilters();
    refresh();
  }

  void applyAdvancedFilters(AssetFilters next) {
    _filters = next;
    _persistFilters();
    refresh();
  }

  Future<void> _fetchAssets({required bool refresh}) async {
    if (_disposed) return;

    if (refresh) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    final offset = refresh ? 0 : _assets.length;
    try {
      final result = await _repository.fetchAssets(
        filters: _filters,
        limit: pageSize,
        offset: offset,
      );

      if (refresh) {
        _assets
          ..clear()
          ..addAll(result);
      } else {
        _assets.addAll(result);
      }

      _hasMore = result.length == pageSize;
      await _recalculateNetWorth(_assets);

      _errorMessage = null;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('AssetsController error: $error\n$stackTrace');
      }
      _errorMessage = 'Não foi possível carregar seus bens agora.';
      _hasMore = false;
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  Future<void> _recalculateNetWorth(List<AssetModel> source) async {
    double assetsTotal = 0;
    double debtsTotal = 0;
    final pendingValuations = <AssetModel>[];
    final fxPending = <String, double>{};
    final breakdown = <AssetCategory, double>{};

    for (final asset in source) {
      if (asset.isArchived) continue;
      final portion = asset.valuePortion;
      if (portion == null) {
        pendingValuations.add(asset);
        continue;
      }

      double amount = portion;
      if (asset.valueCurrency != 'BRL') {
        final converted =
            await _fxService.convertToBrl(asset.valueCurrency, amount);
        if (converted == null) {
          fxPending.update(
            asset.valueCurrency,
            (current) => current + amount,
            ifAbsent: () => amount,
          );
          continue;
        }
        amount = converted;
      }

      breakdown.update(
        asset.category,
        (current) => current + amount,
        ifAbsent: () => amount,
      );

      if (asset.isDebt) {
        debtsTotal += amount;
      } else {
        assetsTotal += amount;
      }
    }

    final totalNetWorth = assetsTotal - debtsTotal;
    NetWorthHistoryReference? historyReference;
    final historyUserId = _repository.currentUserId;
    if (historyUserId != null) {
      try {
        historyReference = await _repository.fetchNetWorthHistoryReference(
          userId: historyUserId,
          threshold: DateTime.now().subtract(const Duration(days: 28)),
        );
      } catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint('Failed to fetch net worth history: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      }
    }

    _netWorth = NetWorthSummary(
      totalInBrl: source.isEmpty && assetsTotal == 0 && debtsTotal == 0
          ? null
          : double.parse(totalNetWorth.toStringAsFixed(2)),
      totalAssets: double.parse(assetsTotal.toStringAsFixed(2)),
      totalDebts: double.parse(debtsTotal.toStringAsFixed(2)),
      pendingValuations: pendingValuations,
      fxPending: fxPending.map(
        (key, value) => MapEntry(key, double.parse(value.toStringAsFixed(2))),
      ),
      breakdownByCategory: breakdown.map(
        (key, value) => MapEntry(key, double.parse(value.toStringAsFixed(2))),
      ),
      historyReference: historyReference,
    );

    await _persistNetWorthSnapshot(_netWorth);
  }

  Future<void> _loadPersistedFilters() async {
    try {
      _filters = await _filterStorage.loadFilters(_repository.currentUserId);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Failed to load stored filters: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      _filters = const AssetFilters();
    }
  }

  void _persistFilters() {
    unawaited(_filterStorage.saveFilters(_repository.currentUserId, _filters));
  }

  void _clearPersistedFilters() {
    unawaited(_filterStorage.clear(_repository.currentUserId));
  }

  void _subscribeToAssetsChannel() {
    final userId = _repository.currentUserId;
    if (userId == null) return;

    if (_assetsChannel != null) {
      unawaited(_assetsChannel!.unsubscribe());
      _assetsChannel = null;
    }

    final channel = Supabase.instance.client.channel('public:assets');
    _assetsChannel = channel;
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'assets',
          callback: (payload) {
            final newUserId = payload.newRecord['user_id'];
            final oldUserId = payload.oldRecord['user_id'];
            final matchesUser = newUserId == userId || oldUserId == userId;
            if (!matchesUser || _disposed) return;
            unawaited(refresh());
          },
        )
        .subscribe();
  }

  Future<void> _persistNetWorthSnapshot(NetWorthSummary summary) async {
    if (!summary.hasSnapshot) return;
    final userId = _repository.currentUserId;
    if (userId == null) return;

    final snapshot = NetWorthSnapshot(
      userId: userId,
      netWorthInBrl: summary.netWorth,
      capturedAt: DateTime.now(),
      breakdown: NetWorthBreakdown(
        totalAssets: summary.totalAssets,
        totalDebts: summary.totalDebts,
        byCategory:
            Map<AssetCategory, double>.from(summary.breakdownByCategory),
        pendingValuations: summary.pendingValuations.length,
        fxPending: Map<String, double>.from(summary.fxPending),
      ),
    );

    try {
      await _repository.insertKpiSnapshot(snapshot);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Failed to persist KPI snapshot: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
    _eventBus?.emit(
      AssetsEvent(
        AssetsEventType.netWorthChanged,
        metadata: {
          'net_worth': summary.netWorth,
          'total_assets': summary.totalAssets,
          'total_debts': summary.totalDebts,
        },
      ),
    );
  }

  Future<void> _logAssetEvent(
    String eventType,
    String description, {
    Map<String, dynamic>? metadata,
  }) async {
    final userId = _repository.currentUserId;
    if (userId == null) return;
    await _repository.insertTrustEvent(
      userId: userId,
      eventType: eventType,
      description: description,
      metadata: metadata,
    );
  }

  Future<void> _logStepUpEvent(
    String eventType, {
    required String factorUsed,
    Map<String, dynamic>? metadata,
  }) async {
    final userId = _repository.currentUserId;
    if (userId == null) return;
    await _repository.insertStepUpEvent(
      userId: userId,
      eventType: eventType,
      factorUsed: factorUsed,
      success: true,
      metadata: {
        'event_at': DateTime.now().toIso8601String(),
        ...?metadata,
      },
    );
  }

  Map<String, dynamic> _assetMetadata(AssetModel asset) {
    return {
      'asset_id': asset.id,
      'category': asset.category.supabaseValue,
      'status': asset.status.supabaseValue,
      'currency': asset.valueCurrency,
      'value_estimated': asset.valueEstimated,
      'ownership': asset.ownershipPercentage,
      'has_proof': asset.hasProof,
    };
  }

  @override
  void dispose() {
    _disposed = true;
    _searchDebounce?.cancel();
    if (_assetsChannel != null) {
      unawaited(_assetsChannel!.unsubscribe());
      _assetsChannel = null;
    }
    if (_ownsFxService) {
      _fxService.dispose();
    }
    super.dispose();
  }

  Future<void> _handleChecklistProgress(
    String userId,
    ChecklistAssetUpdateResult result,
  ) async {
    if (result.unlockedAsset) {
      await _repository.insertKpiMetric(
        userId: userId,
        metricType: 'CHECKLIST_ITEM_COMPLETED',
        metadata: {'item': 'asset'},
      );
    }
    if (result.checklistCompleted) {
      await _repository.insertKpiMetric(
        userId: userId,
        metricType: 'CHECKLIST_COMPLETED',
        metadata: {
          'completed_at': DateTime.now().toIso8601String(),
        },
      );
      await _repository.insertTrustEvent(
        userId: userId,
        eventType: 'CHECKLIST_COMPLETED',
        description: 'Checklist FLX-01 concluído via módulo de bens',
        metadata: {
          'completed_at': DateTime.now().toIso8601String(),
          'protection_ring_score': result.protectionRingScore,
        },
      );
    }
    if (result.unlockedAsset || result.checklistCompleted) {
      _eventBus?.emit(
        AssetsEvent(
          AssetsEventType.checklistUpdated,
          metadata: {
            'has_asset': true,
            'checklist_completed': result.checklistCompleted,
          },
        ),
      );
    }
  }

  String _buildDuplicateTitle(String original) {
    const suffix = ' (cópia)';
    if (original.endsWith(suffix)) {
      return original;
    }
    return '$original$suffix';
  }
}

class NetWorthSummary {
  const NetWorthSummary({
    required this.totalInBrl,
    required this.totalAssets,
    required this.totalDebts,
    required this.pendingValuations,
    required this.fxPending,
    required this.breakdownByCategory,
    required this.historyReference,
  });

  factory NetWorthSummary.empty() => const NetWorthSummary(
        totalInBrl: null,
        totalAssets: 0,
        totalDebts: 0,
        pendingValuations: [],
        fxPending: {},
        breakdownByCategory: {},
        historyReference: null,
      );

  final double? totalInBrl;
  final double totalAssets;
  final double totalDebts;
  final List<AssetModel> pendingValuations;
  final Map<String, double> fxPending;
  final Map<AssetCategory, double> breakdownByCategory;
  final NetWorthHistoryReference? historyReference;

  bool get hasSnapshot => totalInBrl != null;
  double get netWorth => totalInBrl ?? 0;
  bool get hasHistoryReference => historyReference != null;
  bool get meetsHistoryWindow =>
      hasHistoryReference && historyReference!.meetsWindowRequirement;
  double? get historyDelta => (meetsHistoryWindow && hasSnapshot)
      ? double.parse((netWorth - historyReference!.value).toStringAsFixed(2))
      : null;
  bool get hasInsufficientHistory =>
      hasHistoryReference && !historyReference!.meetsWindowRequirement;
}

enum ProofFilter {
  all,
  withProof,
  withoutProof,
}
