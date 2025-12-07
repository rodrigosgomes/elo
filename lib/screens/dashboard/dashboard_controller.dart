import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/assets_event_bus.dart';
import '../../services/fx_service.dart';
import 'dashboard_repository.dart';

class DashboardController extends ChangeNotifier {
  DashboardController({
    DashboardRepository? repository,
    FxService? fxService,
    AssetsEventBus? assetsEventBus,
    this.testUserId,
  })  : _repository = repository ?? SupabaseDashboardRepository(),
        _fxService = fxService ?? FxService(),
        _ownsFxService = fxService == null,
        _assetsEventBus = assetsEventBus;

  final DashboardRepository _repository;
  final FxService _fxService;
  final bool _ownsFxService;
  final String? testUserId;
  final AssetsEventBus? _assetsEventBus;
  StreamSubscription<AssetsEvent>? _assetsEventSubscription;

  DashboardViewData _data = DashboardViewData.initial();
  bool _isLoading = true;
  String? _error;
  bool _timelineLogged = false;
  bool _twoFactorBannerLogged = false;
  bool _silentRefreshInProgress = false;
  RealtimeChannel? _channel;
  bool _disposed = false;

  DashboardViewData get data => _data;
  bool get isLoading => _isLoading;
  String? get errorMessage => _error;
  bool get hasError => _error != null;

  @visibleForTesting
  void seedWithData(DashboardViewData data) {
    _data = data;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  Future<void> bootstrap() async {
    if (_disposed) return;
    await loadInitialData();
    await _initRealtimeChannel();
    _subscribeToAssetsEvents();
  }

  Future<void> loadInitialData({bool silent = false}) async {
    final userId = _resolveUserId();
    if (userId == null) {
      _setError('Sessão expirada. Faça login novamente.');
      return;
    }

    if (_isLoading && silent) return;

    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    } else if (_silentRefreshInProgress) {
      return;
    } else {
      _silentRefreshInProgress = true;
    }

    try {
      final bundle = await _repository.fetchBundle(userId);
      final viewData = await _mapBundleToViewData(bundle);
      _data = viewData;
      _isLoading = false;
      _error = null;
      _silentRefreshInProgress = false;
      notifyListeners();
      _maybeLogTwoFactorBanner();
    } catch (error, stackTrace) {
      _silentRefreshInProgress = false;
      _setError('Não foi possível carregar o dashboard.');
      await _logError(
        'DASHBOARD_ERROR',
        'Falha ao carregar dashboard',
        {
          'error': error.toString(),
          'stack': stackTrace.toString(),
        },
      );
    }
  }

  Future<void> dismissTrustHeader() async {
    final userId = _resolveUserId();
    final profile = _data.profile;
    if (userId == null || profile == null) return;

    final now = DateTime.now().toUtc();
    await _repository.updateProfile(userId, {
      'trust_header_dismissed_at': now.toIso8601String(),
    });
    _data = _data.copyWith(
      profile: profile.copyWith(trustHeaderDismissedAt: now),
    );
    notifyListeners();
  }

  Future<void> markChecklistItem(String item) async {
    final userId = _resolveUserId();
    final checklist = _data.checklist;
    final profile = _data.profile;
    if (userId == null || checklist == null || profile == null) return;

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    switch (item) {
      case 'asset':
        if (checklist.hasAsset) return;
        updates['has_asset'] = true;
        break;
      case 'guardian':
        if (checklist.hasGuardian) return;
        updates['has_guardian'] = true;
        break;
      case 'life_check':
        if (checklist.lifeCheckEnabled) return;
        updates['life_check_enabled'] = true;
        break;
      default:
        return;
    }

    final newScore = _calculateProtectionRingScore(
      hasAsset: updates['has_asset'] as bool? ?? checklist.hasAsset,
      hasGuardian: updates['has_guardian'] as bool? ?? checklist.hasGuardian,
      lifeCheckEnabled:
          updates['life_check_enabled'] as bool? ?? checklist.lifeCheckEnabled,
      twoFactorEnabled: profile.twoFactorEnforced,
    );
    updates['protection_ring_score'] = newScore;

    final updated = await _repository.updateChecklist(userId, updates);
    final updatedChecklist = checklist.copyWith(
      hasAsset: updated['has_asset'] as bool? ?? checklist.hasAsset,
      hasGuardian: updated['has_guardian'] as bool? ?? checklist.hasGuardian,
      lifeCheckEnabled:
          updated['life_check_enabled'] as bool? ?? checklist.lifeCheckEnabled,
      protectionRingScore: newScore,
    );
    _data = _data.copyWith(checklist: updatedChecklist);
    notifyListeners();

    await recordTelemetria(
      'CHECKLIST_ITEM_COMPLETED',
      {
        'item': item,
        'score': newScore,
      },
      description: 'Checklist FLX-01 item completo',
    );

    if (updatedChecklist.isComplete) {
      await _repository.insertTrustEvent(
        userId: userId,
        eventType: 'CHECKLIST_DONE',
        description: 'Checklist FLX-01 concluído',
        metadata: {
          'score': newScore,
          'completed_at': DateTime.now().toIso8601String(),
        },
      );
      await recordTelemetria(
        'CHECKLIST_COMPLETED',
        {
          'items': ['asset', 'guardian', 'life_check'],
        },
        description: 'Checklist FLX-01 concluído',
      );
    }
  }

  Future<void> recordTelemetria(
    String type,
    Map<String, dynamic> metadata, {
    required String description,
  }) async {
    final userId = _resolveUserId();
    if (userId == null) return;
    await _repository.insertKpiMetric(
      userId: userId,
      metricType: type,
      metadata: metadata,
    );
    await _repository.insertTrustEvent(
      userId: userId,
      eventType: 'TELEMETRY_$type',
      description: description,
      metadata: metadata,
    );
  }

  Future<void> updateLifeCheckSettings({
    required String channel,
    required bool stepUpRequired,
  }) async {
    final protocol = _data.protocol;
    final checklist = _data.checklist;
    if (protocol == null) return;

    await _repository.updateEmergencyProtocol(protocol.id, {
      'life_check_channel': channel,
      'step_up_required': stepUpRequired,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });

    _data = _data.copyWith(
      protocol: protocol.copyWith(
        lifeCheckChannel: channel,
        stepUpRequired: stepUpRequired,
      ),
    );
    notifyListeners();

    if (checklist != null && !checklist.lifeCheckEnabled) {
      await markChecklistItem('life_check');
    }
  }

  Future<void> logTwoFactorPromptCta() async {
    final userId = _resolveUserId();
    if (userId == null) return;
    await _repository.insertTrustEvent(
      userId: userId,
      eventType: '2FA_PROMPT',
      description: 'CTA do banner 2FA acionado',
      metadata: {
        'triggered_at': DateTime.now().toIso8601String(),
        'origin': 'dashboard',
      },
    );
  }

  Future<void> logTimelineViewed() async {
    if (_timelineLogged || !_data.timeline.hasContent) return;
    final userId = _resolveUserId();
    if (userId == null) return;
    _timelineLogged = true;
    await _repository.insertTrustEvent(
      userId: userId,
      eventType: 'TIMELINE_VIEWED',
      description: 'Usuário abriu timeline de próximas ações',
      metadata: {
        'viewed_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> refresh() => loadInitialData(silent: true);

  Future<void> _maybeLogTwoFactorBanner() async {
    if (_twoFactorBannerLogged) return;
    final userId = _resolveUserId();
    if (userId == null) return;
    if (!_data.showTwoFactorBanner) return;
    _twoFactorBannerLogged = true;
    await _repository.insertTrustEvent(
      userId: userId,
      eventType: '2FA_PROMPT_SHOWN',
      description: 'Banner 2FA exibido no dashboard',
      metadata: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> _initRealtimeChannel() async {
    final client = Supabase.instance.client;
    final userId = _resolveUserId();
    if (userId == null) return;

    _channel?.unsubscribe();
    _channel = client.channel('dashboard-$userId');

    final tables = [
      'assets',
      'documents',
      'legacy_accounts',
      'guardians',
      'user_checklists',
      'kpi_metrics',
      'emergency_protocols',
      'subscriptions',
    ];

    for (final table in tables) {
      _channel!.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (_) => refresh(),
      );
    }

    _channel!.subscribe();
  }

  Future<void> _logError(
    String eventType,
    String description,
    Map<String, dynamic> metadata,
  ) async {
    final userId = _resolveUserId();
    if (userId == null) return;
    await _repository.insertTrustEvent(
      userId: userId,
      eventType: eventType,
      description: description,
      metadata: metadata,
    );
  }

  void _setError(String message) {
    _error = message;
    _isLoading = false;
    notifyListeners();
  }

  String? _resolveUserId() => testUserId ?? _repository.currentUserId;

  Future<DashboardViewData> _mapBundleToViewData(
    DashboardDataBundle bundle,
  ) async {
    final profile = ProfileData.fromMap(bundle.profile);
    final checklist = UserChecklistData.fromMap(bundle.checklist);
    final protocol = bundle.emergencyProtocol != null
        ? EmergencyProtocolData.fromMap(bundle.emergencyProtocol!)
        : null;

    final assetTotals = _groupAssets(bundle.assets);
    final brlTotal = await _calculateBrlTotal(assetTotals);

    final documentsEncrypted =
        bundle.documents.where((doc) => doc['status'] == 'ENCRYPTED').length;

    final legacyCount = bundle.legacyAccounts.length;
    final masterCredentialCount = bundle.masterCredentials.length;
    final hasMedicalDirective = bundle.medicalDirective != null;
    final hasFuneralPreference = bundle.funeralPreference != null;
    final capsuleCount = bundle.capsules.length;

    final metrics =
        bundle.kpiMetrics.map((row) => KpiMetric.fromMap(row)).toList();

    final timeline = _buildTimelineData(
      protocol: protocol,
      guardians: bundle.guardians,
      lifeChecks: bundle.lifeChecks,
      subscriptions: bundle.subscriptions,
    );

    final derivedHeadline =
        profile.headlineStatus ?? _deriveHeadline(checklist);

    return DashboardViewData(
      profile: profile.copyWith(headlineStatus: derivedHeadline),
      checklist: checklist,
      protocol: protocol,
      pillarSummary: PillarSummary(
        assetTotalsByCurrency: assetTotals,
        assetsInBrl: brlTotal,
        activeAssets: _countActiveAssets(bundle.assets),
        encryptedDocuments: documentsEncrypted,
        legacyAccounts: legacyCount,
        masterCredentials: masterCredentialCount,
        hasMedicalDirective: hasMedicalDirective,
        hasFuneralPreference: hasFuneralPreference,
        capsuleCount: capsuleCount,
      ),
      metrics: metrics,
      timeline: timeline,
    );
  }

  Map<String, double> _groupAssets(List<Map<String, dynamic>> assets) {
    final totals = <String, double>{};
    for (final asset in assets) {
      final status = (asset['status'] as String?) ?? 'ACTIVE';
      if (status == 'ARCHIVED') continue;
      final currency =
          (asset['value_currency'] as String?)?.toUpperCase() ?? 'BRL';
      final value = (asset['value_estimated'] as num?)?.toDouble();
      if (value == null) continue;
      totals.update(currency, (current) => current + value,
          ifAbsent: () => value);
    }
    return totals;
  }

  int _countActiveAssets(List<Map<String, dynamic>> assets) {
    return assets.where((asset) => asset['status'] != 'ARCHIVED').length;
  }

  Future<double?> _calculateBrlTotal(Map<String, double> totals) async {
    double sum = 0;
    bool hasAnyConversion = false;
    for (final entry in totals.entries) {
      final converted = await _fxService.convertToBrl(entry.key, entry.value);
      if (converted != null) {
        hasAnyConversion = true;
        sum += converted;
      }
    }
    if (!hasAnyConversion) return null;
    return double.parse(sum.toStringAsFixed(2));
  }

  DashboardTimelineData _buildTimelineData({
    EmergencyProtocolData? protocol,
    List<Map<String, dynamic>>? guardians,
    List<Map<String, dynamic>>? lifeChecks,
    List<Map<String, dynamic>>? subscriptions,
  }) {
    LifeCheckTimelineItem? lifeCheckItem;
    GuardianTimelineItem? guardianItem;
    SubscriptionTimelineItem? subscriptionItem;

    if (protocol != null && lifeChecks != null && lifeChecks.isNotEmpty) {
      final scheduled = lifeChecks
          .map(LifeCheckTimelineItem.fromMap)
          .where((item) => item.status == 'SCHEDULED')
          .toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      if (scheduled.isNotEmpty) {
        lifeCheckItem = scheduled.first;
      }
    }

    if (guardians != null && guardians.isNotEmpty) {
      final invited = guardians
          .map(GuardianTimelineItem.fromMap)
          .where((item) => item.status == 'INVITED')
          .toList()
        ..sort((a, b) => (a.invitedAt ?? DateTime.now())
            .compareTo(b.invitedAt ?? DateTime.now()));
      if (invited.isNotEmpty) {
        guardianItem = invited.first;
      }
    }

    if (subscriptions != null && subscriptions.isNotEmpty) {
      final flagged = subscriptions
          .map(SubscriptionTimelineItem.fromMap)
          .where((item) => item.cancelOnEmergency && item.cancelledAt == null)
          .toList()
        ..sort((a, b) => (a.nextChargeAt ?? DateTime.now())
            .compareTo(b.nextChargeAt ?? DateTime.now()));
      if (flagged.isNotEmpty) {
        subscriptionItem = flagged.first;
      }
    }

    return DashboardTimelineData(
      nextLifeCheck: lifeCheckItem,
      pendingGuardian: guardianItem,
      subscriptionToReview: subscriptionItem,
    );
  }

  String _deriveHeadline(UserChecklistData checklist) {
    final score = checklist.protectionRingScore;
    if (score >= 80) return 'Seguro';
    if (score >= 40) return 'Atenção';
    return 'Risco';
  }

  int _calculateProtectionRingScore({
    required bool hasAsset,
    required bool hasGuardian,
    required bool lifeCheckEnabled,
    required bool twoFactorEnabled,
  }) {
    final baseScore = (hasAsset ? 30 : 0) +
        (hasGuardian ? 30 : 0) +
        (lifeCheckEnabled ? 30 : 0);
    final bonus = twoFactorEnabled ? 10 : 0;
    return math.min(baseScore + bonus, 100);
  }

  @override
  void dispose() {
    _disposed = true;
    _channel?.unsubscribe();
    _assetsEventSubscription?.cancel();
    if (_ownsFxService) {
      _fxService.dispose();
    }
    super.dispose();
  }

  void _subscribeToAssetsEvents() {
    if (_assetsEventBus == null) return;
    _assetsEventSubscription = _assetsEventBus!.stream.listen((event) {
      if (_disposed) return;
      switch (event.type) {
        case AssetsEventType.netWorthChanged:
        case AssetsEventType.checklistUpdated:
          loadInitialData(silent: true);
      }
    });
  }
}

class DashboardViewData {
  const DashboardViewData({
    required this.profile,
    required this.checklist,
    required this.protocol,
    required this.pillarSummary,
    required this.metrics,
    required this.timeline,
  });

  factory DashboardViewData.initial() => DashboardViewData(
        profile: null,
        checklist: null,
        protocol: null,
        pillarSummary: PillarSummary.empty(),
        metrics: const [],
        timeline: DashboardTimelineData.empty(),
      );

  final ProfileData? profile;
  final UserChecklistData? checklist;
  final EmergencyProtocolData? protocol;
  final PillarSummary pillarSummary;
  final List<KpiMetric> metrics;
  final DashboardTimelineData timeline;

  bool get showTrustHeader =>
      profile != null && profile!.trustHeaderDismissedAt == null;
  bool get showTwoFactorBanner =>
      profile != null && profile!.twoFactorEnforced == false;

  DashboardViewData copyWith({
    ProfileData? profile,
    UserChecklistData? checklist,
    EmergencyProtocolData? protocol,
    PillarSummary? pillarSummary,
    List<KpiMetric>? metrics,
    DashboardTimelineData? timeline,
  }) {
    return DashboardViewData(
      profile: profile ?? this.profile,
      checklist: checklist ?? this.checklist,
      protocol: protocol ?? this.protocol,
      pillarSummary: pillarSummary ?? this.pillarSummary,
      metrics: metrics ?? this.metrics,
      timeline: timeline ?? this.timeline,
    );
  }
}

class ProfileData {
  ProfileData({
    required this.id,
    required this.fullName,
    required this.twoFactorEnforced,
    required this.zeroKnowledgeReady,
    required this.onboardingStage,
    required this.headlineStatus,
    required this.trustHeaderDismissedAt,
    required this.lastActivity,
  });

  factory ProfileData.fromMap(Map<String, dynamic> map) {
    return ProfileData(
      id: map['id'] as String,
      fullName: map['full_name'] as String? ?? 'Usuário',
      twoFactorEnforced: map['two_factor_enforced'] as bool? ?? false,
      zeroKnowledgeReady: map['zero_knowledge_ready'] as bool? ?? false,
      onboardingStage: map['onboarding_stage'] as String? ?? 'start',
      headlineStatus: map['headline_status'] as String?,
      trustHeaderDismissedAt: _parseDate(map['trust_header_dismissed_at']),
      lastActivity: _parseDate(map['deleted_at']) ??
          _parseDate(map['updated_at']) ??
          _parseDate(map['created_at']) ??
          DateTime.now(),
    );
  }

  final String id;
  final String fullName;
  final bool twoFactorEnforced;
  final bool zeroKnowledgeReady;
  final String onboardingStage;
  final String? headlineStatus;
  final DateTime? trustHeaderDismissedAt;
  final DateTime lastActivity;

  ProfileData copyWith({
    bool? twoFactorEnforced,
    String? headlineStatus,
    DateTime? trustHeaderDismissedAt,
  }) {
    return ProfileData(
      id: id,
      fullName: fullName,
      twoFactorEnforced: twoFactorEnforced ?? this.twoFactorEnforced,
      zeroKnowledgeReady: zeroKnowledgeReady,
      onboardingStage: onboardingStage,
      headlineStatus: headlineStatus ?? this.headlineStatus,
      trustHeaderDismissedAt:
          trustHeaderDismissedAt ?? this.trustHeaderDismissedAt,
      lastActivity: lastActivity,
    );
  }
}

class UserChecklistData {
  UserChecklistData({
    required this.hasAsset,
    required this.hasGuardian,
    required this.lifeCheckEnabled,
    required this.protectionRingScore,
  });

  factory UserChecklistData.fromMap(Map<String, dynamic> map) {
    return UserChecklistData(
      hasAsset: map['has_asset'] as bool? ?? false,
      hasGuardian: map['has_guardian'] as bool? ?? false,
      lifeCheckEnabled: map['life_check_enabled'] as bool? ?? false,
      protectionRingScore: map['protection_ring_score'] as int? ?? 0,
    );
  }

  final bool hasAsset;
  final bool hasGuardian;
  final bool lifeCheckEnabled;
  final int protectionRingScore;

  bool get isComplete => hasAsset && hasGuardian && lifeCheckEnabled;

  UserChecklistData copyWith({
    bool? hasAsset,
    bool? hasGuardian,
    bool? lifeCheckEnabled,
    int? protectionRingScore,
  }) {
    return UserChecklistData(
      hasAsset: hasAsset ?? this.hasAsset,
      hasGuardian: hasGuardian ?? this.hasGuardian,
      lifeCheckEnabled: lifeCheckEnabled ?? this.lifeCheckEnabled,
      protectionRingScore: protectionRingScore ?? this.protectionRingScore,
    );
  }
}

class EmergencyProtocolData {
  EmergencyProtocolData({
    required this.id,
    required this.lifeCheckChannel,
    required this.stepUpRequired,
    required this.status,
    required this.lastActivityAt,
  });

  factory EmergencyProtocolData.fromMap(Map<String, dynamic> map) {
    return EmergencyProtocolData(
      id: map['id'] as int,
      lifeCheckChannel: map['life_check_channel'] as String? ?? 'PUSH',
      stepUpRequired: map['step_up_required'] as bool? ?? true,
      status: map['status'] as String? ?? 'MONITORING',
      lastActivityAt: _parseDate(map['last_activity_at']) ??
          _parseDate(map['updated_at']) ??
          DateTime.now(),
    );
  }

  final int id;
  final String lifeCheckChannel;
  final bool stepUpRequired;
  final String status;
  final DateTime lastActivityAt;

  EmergencyProtocolData copyWith({
    String? lifeCheckChannel,
    bool? stepUpRequired,
  }) {
    return EmergencyProtocolData(
      id: id,
      lifeCheckChannel: lifeCheckChannel ?? this.lifeCheckChannel,
      stepUpRequired: stepUpRequired ?? this.stepUpRequired,
      status: status,
      lastActivityAt: lastActivityAt,
    );
  }
}

class PillarSummary {
  const PillarSummary({
    required this.assetTotalsByCurrency,
    required this.assetsInBrl,
    required this.activeAssets,
    required this.encryptedDocuments,
    required this.legacyAccounts,
    required this.masterCredentials,
    required this.hasMedicalDirective,
    required this.hasFuneralPreference,
    required this.capsuleCount,
  });

  factory PillarSummary.empty() => const PillarSummary(
        assetTotalsByCurrency: {},
        assetsInBrl: null,
        activeAssets: 0,
        encryptedDocuments: 0,
        legacyAccounts: 0,
        masterCredentials: 0,
        hasMedicalDirective: false,
        hasFuneralPreference: false,
        capsuleCount: 0,
      );

  final Map<String, double> assetTotalsByCurrency;
  final double? assetsInBrl;
  final int activeAssets;
  final int encryptedDocuments;
  final int legacyAccounts;
  final int masterCredentials;
  final bool hasMedicalDirective;
  final bool hasFuneralPreference;
  final int capsuleCount;
}

class KpiMetric {
  KpiMetric({
    required this.metricType,
    required this.metricValue,
    required this.recordedAt,
    required this.metadata,
  });

  factory KpiMetric.fromMap(Map<String, dynamic> map) {
    return KpiMetric(
      metricType: map['metric_type'] as String,
      metricValue: (map['metric_value'] as num?)?.toDouble(),
      recordedAt: _parseDate(map['recorded_at']) ?? DateTime.now(),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  final String metricType;
  final double? metricValue;
  final DateTime recordedAt;
  final Map<String, dynamic>? metadata;
}

class DashboardTimelineData {
  const DashboardTimelineData({
    required this.nextLifeCheck,
    required this.pendingGuardian,
    required this.subscriptionToReview,
  });

  factory DashboardTimelineData.empty() => const DashboardTimelineData(
        nextLifeCheck: null,
        pendingGuardian: null,
        subscriptionToReview: null,
      );

  final LifeCheckTimelineItem? nextLifeCheck;
  final GuardianTimelineItem? pendingGuardian;
  final SubscriptionTimelineItem? subscriptionToReview;

  bool get hasContent =>
      nextLifeCheck != null ||
      pendingGuardian != null ||
      subscriptionToReview != null;
}

class LifeCheckTimelineItem {
  LifeCheckTimelineItem({
    required this.id,
    required this.status,
    required this.channel,
    required this.scheduledAt,
  });

  factory LifeCheckTimelineItem.fromMap(Map<String, dynamic> map) {
    return LifeCheckTimelineItem(
      id: map['id'] as int,
      status: map['status'] as String? ?? 'SCHEDULED',
      channel: map['channel'] as String? ?? 'PUSH',
      scheduledAt: _parseDate(map['scheduled_at']) ?? DateTime.now(),
    );
  }

  final int id;
  final String status;
  final String channel;
  final DateTime scheduledAt;
}

class GuardianTimelineItem {
  GuardianTimelineItem({
    required this.id,
    required this.name,
    required this.status,
    this.invitedAt,
  });

  factory GuardianTimelineItem.fromMap(Map<String, dynamic> map) {
    return GuardianTimelineItem(
      id: map['id'] as int,
      name: map['name'] as String? ?? 'Guardião',
      status: map['status'] as String? ?? 'INVITED',
      invitedAt: _parseDate(map['invited_at']),
    );
  }

  final int id;
  final String name;
  final String status;
  final DateTime? invitedAt;
}

class SubscriptionTimelineItem {
  SubscriptionTimelineItem({
    required this.id,
    required this.serviceName,
    required this.cancelOnEmergency,
    required this.nextChargeAt,
    required this.cancelledAt,
  });

  factory SubscriptionTimelineItem.fromMap(Map<String, dynamic> map) {
    return SubscriptionTimelineItem(
      id: map['id'] as int,
      serviceName: map['service_name'] as String? ?? 'Serviço',
      cancelOnEmergency: map['cancel_on_emergency'] as bool? ?? false,
      nextChargeAt: _parseDate(map['next_charge_at']),
      cancelledAt: _parseDate(map['cancelled_at']),
    );
  }

  final int id;
  final String serviceName;
  final bool cancelOnEmergency;
  final DateTime? nextChargeAt;
  final DateTime? cancelledAt;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isEmpty) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}
