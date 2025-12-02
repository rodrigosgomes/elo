import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardDataBundle {
  DashboardDataBundle({
    required this.profile,
    required this.checklist,
    required this.emergencyProtocol,
    required this.assets,
    required this.documents,
    required this.guardians,
    required this.legacyAccounts,
    required this.masterCredentials,
    required this.medicalDirective,
    required this.funeralPreference,
    required this.capsules,
    required this.kpiMetrics,
    required this.subscriptions,
    required this.lifeChecks,
  });

  final Map<String, dynamic> profile;
  final Map<String, dynamic> checklist;
  final Map<String, dynamic>? emergencyProtocol;
  final List<Map<String, dynamic>> assets;
  final List<Map<String, dynamic>> documents;
  final List<Map<String, dynamic>> guardians;
  final List<Map<String, dynamic>> legacyAccounts;
  final List<Map<String, dynamic>> masterCredentials;
  final Map<String, dynamic>? medicalDirective;
  final Map<String, dynamic>? funeralPreference;
  final List<Map<String, dynamic>> capsules;
  final List<Map<String, dynamic>> kpiMetrics;
  final List<Map<String, dynamic>> subscriptions;
  final List<Map<String, dynamic>> lifeChecks;
}

abstract class DashboardRepository {
  String? get currentUserId;

  Future<void> ensureChecklistSeeded(String userId);

  Future<Map<String, dynamic>> ensureEmergencyProtocol(String userId);

  Future<DashboardDataBundle> fetchBundle(String userId);

  Future<void> updateProfile(String userId, Map<String, dynamic> values);

  Future<Map<String, dynamic>> updateChecklist(
    String userId,
    Map<String, dynamic> values,
  );

  Future<void> updateEmergencyProtocol(
    int protocolId,
    Map<String, dynamic> values,
  );

  Future<void> insertKpiMetric({
    required String userId,
    required String metricType,
    double? metricValue,
    Map<String, dynamic>? metadata,
  });

  Future<void> insertTrustEvent({
    required String userId,
    required String eventType,
    required String description,
    Map<String, dynamic>? metadata,
  });
}

class SupabaseDashboardRepository implements DashboardRepository {
  SupabaseDashboardRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<void> ensureChecklistSeeded(String userId) async {
    final existing = await _client
        .from('user_checklists')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (existing != null) return;

    await _client.from('user_checklists').insert({
      'user_id': userId,
      'has_asset': false,
      'has_guardian': false,
      'life_check_enabled': false,
      'protection_ring_score': 0,
    });
  }

  @override
  Future<Map<String, dynamic>> ensureEmergencyProtocol(String userId) async {
    final existing = await _client
        .from('emergency_protocols')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (existing != null) return existing;

    final insertResponse = await _client
        .from('emergency_protocols')
        .insert({
          'user_id': userId,
          'inactivity_timer_days': 60,
          'life_check_channel': 'PUSH',
          'step_up_required': true,
          'status': 'MONITORING',
        })
        .select()
        .single();
    return insertResponse;
  }

  @override
  Future<DashboardDataBundle> fetchBundle(String userId) async {
    await ensureChecklistSeeded(userId);
    final emergencyProtocol = await ensureEmergencyProtocol(userId);

    final futures = await Future.wait<dynamic>([
      _client.from('profiles').select().eq('id', userId).single(),
      _client.from('user_checklists').select().eq('user_id', userId).single(),
      _client.from('assets').select().eq('user_id', userId),
      _client.from('documents').select().eq('user_id', userId),
      _client.from('guardians').select().eq('user_id', userId),
      _client.from('legacy_accounts').select().eq('user_id', userId),
      _client.from('master_credentials').select().eq('user_id', userId),
      _client
          .from('medical_directives')
          .select()
          .eq('user_id', userId)
          .maybeSingle(),
      _client
          .from('funeral_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle(),
      _client.from('capsule_entries').select().eq('user_id', userId),
      _client
          .from('kpi_metrics')
          .select()
          .eq('user_id', userId)
          .order('recorded_at', ascending: false)
          .limit(30),
      _client.from('subscriptions').select().eq('user_id', userId),
    ]);

    final protocolId = emergencyProtocol['id'] as int;
    final lifeChecks = await _client
        .from('life_checks')
        .select()
        .eq('protocol_id', protocolId);

    return DashboardDataBundle(
      profile: futures[0] as Map<String, dynamic>,
      checklist: futures[1] as Map<String, dynamic>,
      emergencyProtocol: emergencyProtocol,
      assets: (futures[2] as List).cast<Map<String, dynamic>>(),
      documents: (futures[3] as List).cast<Map<String, dynamic>>(),
      guardians: (futures[4] as List).cast<Map<String, dynamic>>(),
      legacyAccounts: (futures[5] as List).cast<Map<String, dynamic>>(),
      masterCredentials: (futures[6] as List).cast<Map<String, dynamic>>(),
      medicalDirective: futures[7] as Map<String, dynamic>?,
      funeralPreference: futures[8] as Map<String, dynamic>?,
      capsules: (futures[9] as List).cast<Map<String, dynamic>>(),
      kpiMetrics: (futures[10] as List).cast<Map<String, dynamic>>(),
      subscriptions: (futures[11] as List).cast<Map<String, dynamic>>(),
      lifeChecks: lifeChecks.cast<Map<String, dynamic>>(),
    );
  }

  @override
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

  @override
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

  @override
  Future<Map<String, dynamic>> updateChecklist(
    String userId,
    Map<String, dynamic> values,
  ) async {
    final response = await _client
        .from('user_checklists')
        .update(values)
        .eq('user_id', userId)
        .select()
        .single();
    return response;
  }

  @override
  Future<void> updateEmergencyProtocol(
    int protocolId,
    Map<String, dynamic> values,
  ) async {
    await _client
        .from('emergency_protocols')
        .update(values)
        .eq('id', protocolId);
  }

  @override
  Future<void> updateProfile(String userId, Map<String, dynamic> values) async {
    await _client.from('profiles').update(values).eq('id', userId);
  }
}
