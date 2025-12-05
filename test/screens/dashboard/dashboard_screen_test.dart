import 'package:elo/screens/dashboard/dashboard_controller.dart';
import 'package:elo/screens/dashboard/dashboard_repository.dart';
import 'package:elo/screens/dashboard/dashboard_screen.dart';
import 'package:elo/services/assets_event_bus.dart';
import 'package:elo/services/fx_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-anon-key',
    );
    await initializeDateFormatting('pt_BR');
  });

  group('DashboardScreen', () {
    late FakeDashboardRepository repository;
    late DashboardController controller;

    setUp(() {
      repository = FakeDashboardRepository();
      controller = DashboardController(
        repository: repository,
        fxService: FxService(),
      );
      controller.seedWithData(_buildViewData());
    });

    tearDown(() async {
      controller.dispose();
    });

    testWidgets('renders checklist when incomplete', (tester) async {
      final bus = AssetsEventBus();
      addTearDown(bus.dispose);
      await tester.pumpWidget(
        Provider<AssetsEventBus>.value(
          value: bus,
          child: MaterialApp(
            home: DashboardScreen(controllerOverride: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
        find.byKey(const ValueKey('checklist_asset')),
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      expect(find.text('Checklist FLX-01'), findsOneWidget);
      expect(find.byKey(const ValueKey('checklist_asset')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('checklist_asset')),
          matching: find.text('Cadastrar'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('allows dismissing trust header', (tester) async {
      final bus = AssetsEventBus();
      addTearDown(bus.dispose);
      await tester.pumpWidget(
        Provider<AssetsEventBus>.value(
          value: bus,
          child: MaterialApp(
            home: DashboardScreen(controllerOverride: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cabeçalho de Confiança'), findsOneWidget);
      await tester.tap(find.text('Entendi'));
      await tester.pumpAndSettle();

      expect(find.text('Cabeçalho de Confiança'), findsNothing);
      expect(repository.lastProfileUpdate, isNotNull);
      expect(
          repository.lastProfileUpdate!
              .containsKey('trust_header_dismissed_at'),
          isTrue);
    });
  });

  test('markChecklistItem updates score and telemetry', () async {
    final repository = FakeDashboardRepository();
    final controller = DashboardController(
      repository: repository,
      fxService: FxService(),
    );
    controller.seedWithData(_buildViewData());

    await controller.markChecklistItem('asset');

    expect(controller.data.checklist?.hasAsset, isTrue);
    expect(repository.lastChecklistUpdate?['protection_ring_score'], 30);
    expect(repository.loggedMetrics.map((m) => m['metric_type']),
        contains('CHECKLIST_ITEM_COMPLETED'));
    controller.dispose();
  });
}

DashboardViewData _buildViewData({bool trustDismissed = false}) {
  final profile = ProfileData(
    id: 'user-1',
    fullName: 'Ana',
    twoFactorEnforced: false,
    zeroKnowledgeReady: true,
    onboardingStage: 'start',
    headlineStatus: 'Seguro',
    trustHeaderDismissedAt: trustDismissed ? DateTime.now() : null,
    lastActivity: DateTime.now(),
  );
  final checklist = UserChecklistData(
    hasAsset: false,
    hasGuardian: false,
    lifeCheckEnabled: false,
    protectionRingScore: 0,
  );
  final protocol = EmergencyProtocolData(
    id: 1,
    lifeCheckChannel: 'PUSH',
    stepUpRequired: true,
    status: 'MONITORING',
    lastActivityAt: DateTime.now(),
  );
  const pillarSummary = PillarSummary(
    assetTotalsByCurrency: {'BRL': 0},
    assetsInBrl: 0,
    activeAssets: 0,
    encryptedDocuments: 0,
    legacyAccounts: 0,
    masterCredentials: 0,
    hasMedicalDirective: false,
    hasFuneralPreference: false,
    capsuleCount: 0,
  );
  const metrics = <KpiMetric>[];
  final timeline = DashboardTimelineData.empty();
  return DashboardViewData(
    profile: profile,
    checklist: checklist,
    protocol: protocol,
    pillarSummary: pillarSummary,
    metrics: metrics,
    timeline: timeline,
  );
}

class FakeDashboardRepository implements DashboardRepository {
  Map<String, dynamic> checklistRow = {
    'has_asset': false,
    'has_guardian': false,
    'life_check_enabled': false,
    'protection_ring_score': 0,
  };
  Map<String, dynamic> protocolRow = {
    'id': 1,
    'life_check_channel': 'PUSH',
    'step_up_required': true,
    'status': 'MONITORING',
    'updated_at': DateTime.now().toIso8601String(),
  };
  Map<String, dynamic>? lastProfileUpdate;
  Map<String, dynamic>? lastChecklistUpdate;
  final List<Map<String, dynamic>> loggedMetrics = [];
  final List<Map<String, dynamic>> loggedEvents = [];

  @override
  String? get currentUserId => 'user-test';

  @override
  Future<void> ensureChecklistSeeded(String userId) async {}

  @override
  Future<Map<String, dynamic>> ensureEmergencyProtocol(String userId) async {
    return protocolRow;
  }

  @override
  Future<DashboardDataBundle> fetchBundle(String userId) {
    throw UnsupportedError('fetchBundle not needed in tests');
  }

  @override
  Future<void> insertKpiMetric({
    required String userId,
    required String metricType,
    double? metricValue,
    Map<String, dynamic>? metadata,
  }) async {
    loggedMetrics.add({
      'metric_type': metricType,
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
    loggedEvents.add({
      'event_type': eventType,
      'description': description,
    });
  }

  @override
  Future<Map<String, dynamic>> updateChecklist(
    String userId,
    Map<String, dynamic> values,
  ) async {
    checklistRow = {
      ...checklistRow,
      ...values,
    };
    lastChecklistUpdate = values;
    return checklistRow;
  }

  @override
  Future<void> updateEmergencyProtocol(
    int protocolId,
    Map<String, dynamic> values,
  ) async {
    protocolRow = {
      ...protocolRow,
      ...values,
    };
  }

  @override
  Future<void> updateProfile(String userId, Map<String, dynamic> values) async {
    lastProfileUpdate = values;
  }
}
