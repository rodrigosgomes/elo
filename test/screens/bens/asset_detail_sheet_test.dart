import 'package:elo/models/asset_model.dart';
import 'package:elo/screens/bens/asset_detail_sheet.dart';
import 'package:elo/screens/bens/assets_controller.dart';
import 'package:elo/services/asset_proof_service.dart';
import 'package:elo/services/assets_filter_storage.dart';
import 'package:elo/services/assets_repository.dart';
import 'package:elo/services/fx_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AssetDetailSheet', () {
    testWidgets('renders proof empty state with pending badge', (tester) async {
      final controller = _TestAssetsController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildHarness(controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('Comprovantes criptografados'), findsOneWidget);
      expect(
        find.text(
            'Nenhum comprovante enviado ainda. Adicione para destravar os KPIs de confiança.'),
        findsOneWidget,
      );
      expect(find.text('Pendente'), findsOneWidget);
      expect(find.text('Anexar comprovante'), findsOneWidget);
    });

    testWidgets('uploading a proof surfaces the document tile and status badge',
        (tester) async {
      final controller = _TestAssetsController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildHarness(controller: controller));
      await tester.pumpAndSettle();

      await _tapAndSettle(tester, find.text('Anexar comprovante'));

      expect(find.text('Comprovado'), findsOneWidget);
      expect(find.textContaining('ID'), findsOneWidget);
    });

    testWidgets('allows downloading and removing a proof document',
        (tester) async {
      final controller = _TestAssetsController(
        initialDocuments: [
          AssetDocumentModel(
            id: 42,
            assetId: 7,
            storagePath: 'user/7/proof.enc',
            encryptedChecksum: 'checksum',
            fileType: 'pdf',
            uploadedAt: DateTime(2024, 01, 01, 10, 30),
          ),
        ],
      );
      addTearDown(controller.dispose);

      final highValueAsset = _buildAsset(
        hasProof: true,
        category: AssetCategory.imoveis,
        valueEstimated: 350000,
      );
      await tester.pumpWidget(
        _buildHarness(
          controller: controller,
          hasProof: true,
          asset: highValueAsset,
        ),
      );
      await tester.pumpAndSettle();

      await _tapAndSettle(tester, find.byTooltip('Baixar comprovante'));

      await tester.enterText(
        find.bySemanticsLabel('Senha mestra'),
        'segredo1',
      );
      await _tapAndSettle(tester, find.text('Validar acesso'));

      expect(find.textContaining('/tmp/42.pdf'), findsOneWidget);

      await _tapAndSettle(tester, find.byTooltip('Remover comprovante'));
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Remover'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('ID 42'), findsNothing);
      expect(find.text('Pendente'), findsOneWidget);
    });

    testWidgets('fallbacks to archive when delete is blocked', (tester) async {
      final controller = _TestAssetsController(deleteShouldFail: true);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildHarness(controller: controller));
      await tester.pumpAndSettle();

      await _tapAndSettle(tester, find.text('Remover'));
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Remover'),
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.archiveInvoked, isTrue);
      expect(controller.fallbackLogged, isTrue);
    });
  });
}

Widget _buildHarness({
  required AssetsController controller,
  bool hasProof = false,
  AssetModel? asset,
}) {
  final resolvedAsset = asset ?? _buildAsset(hasProof: hasProof);
  return MaterialApp(
    home: Scaffold(
      body: AssetDetailSheet(
        asset: resolvedAsset,
        controller: controller,
      ),
    ),
  );
}

AssetModel _buildAsset({
  bool hasProof = false,
  AssetCategory category = AssetCategory.financeiro,
  double valueEstimated = 12000,
}) {
  final now = DateTime(2024, 01, 01);
  return AssetModel(
    id: 7,
    userId: 'user-1',
    category: category,
    title: 'Conta investimento',
    description: 'Reserva de emergência',
    valueEstimated: valueEstimated,
    valueCurrency: 'BRL',
    valueUnknown: false,
    ownershipPercentage: 100,
    hasProof: hasProof,
    status: AssetStatus.active,
    createdAt: now,
    updatedAt: now,
  );
}

Future<void> _tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
  await tester.pumpAndSettle();
}

class _TestAssetsController extends AssetsController {
  _TestAssetsController({
    List<AssetDocumentModel> initialDocuments = const [],
    this.deleteShouldFail = false,
  })  : _documents = List<AssetDocumentModel>.from(initialDocuments),
        super(
          repository: AssetsRepository(),
          fxService: FxService(),
          filterStorage: AssetsFilterStorage(),
          proofService: const _NoopProofService(),
        );

  final List<AssetDocumentModel> _documents;
  int _sequence = 1000;
  final bool deleteShouldFail;
  bool archiveInvoked = false;
  bool fallbackLogged = false;

  @override
  Future<List<AssetDocumentModel>> loadAssetDocuments(int assetId) async {
    return List<AssetDocumentModel>.from(_documents);
  }

  @override
  Future<AssetDocumentModel?> uploadProof(int assetId) async {
    final document = AssetDocumentModel(
      id: _sequence++,
      assetId: assetId,
      storagePath: 'test/$assetId/${DateTime.now().microsecondsSinceEpoch}.enc',
      encryptedChecksum: 'checksum',
      fileType: 'pdf',
      uploadedAt: DateTime.now(),
    );
    _documents.insert(0, document);
    notifyListeners();
    return document;
  }

  @override
  Future<void> removeProof(AssetDocumentModel document) async {
    _documents.removeWhere((entry) => entry.id == document.id);
    notifyListeners();
  }

  @override
  Future<String> downloadProof(
    AssetDocumentModel document, {
    String? factorUsed,
  }) async {
    return '/tmp/${document.id}.pdf';
  }

  @override
  Future<void> deleteAsset(
    int assetId, {
    String? factorUsed,
  }) async {
    if (deleteShouldFail) {
      throw PostgrestException(
        code: '23503',
        message: 'violates foreign key constraint',
        details: 'violates foreign key constraint',
      );
    }
  }

  @override
  Future<void> archiveAsset(
    int assetId, {
    String? factorUsed,
  }) async {
    archiveInvoked = true;
  }

  @override
  Future<void> logDeleteFallbackEvent({
    required int assetId,
    String? constraintCode,
    String? message,
  }) async {
    fallbackLogged = true;
  }
}

class _NoopProofService implements AssetProofService {
  const _NoopProofService();

  @override
  Future<void> deleteProof(AssetDocumentModel document) async {
    throw UnsupportedError('Not implemented in widget tests');
  }

  @override
  Future<String> downloadProof(
    AssetDocumentModel document, {
    String? factorUsed,
  }) async {
    throw UnsupportedError('Not implemented in widget tests');
  }

  @override
  Future<AssetDocumentModel?> pickAndUploadProof(int assetId) async {
    throw UnsupportedError('Not implemented in widget tests');
  }
}
