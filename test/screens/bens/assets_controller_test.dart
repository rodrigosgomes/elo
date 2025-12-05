import 'package:elo/models/asset_model.dart';
import 'package:elo/screens/bens/assets_controller.dart';
import 'package:elo/services/asset_proof_service.dart';
import 'package:elo/services/assets_event_bus.dart';
import 'package:elo/services/assets_filter_storage.dart';
import 'package:elo/services/assets_repository.dart';
import 'package:elo/services/fx_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAssetsRepository extends Mock implements AssetsRepository {}

class MockFxService extends Mock implements FxService {}

class MockFilterStorage extends Mock implements AssetsFilterStorage {}

class MockProofService extends Mock implements AssetProofService {}

class _FakeNetWorthSnapshot extends Fake implements NetWorthSnapshot {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(_FakeNetWorthSnapshot());
    registerFallbackValue(const AssetFilters());
  });

  group('AssetsController', () {
    late MockAssetsRepository repository;
    late MockFxService fxService;
    late MockFilterStorage filterStorage;
    late MockProofService proofService;
    late AssetsEventBus eventBus;

    setUp(() {
      repository = MockAssetsRepository();
      fxService = MockFxService();
      filterStorage = MockFilterStorage();
      proofService = MockProofService();
      eventBus = AssetsEventBus();

      when(() => repository.currentUserId).thenReturn('user-1');
      when(() => filterStorage.loadFilters(any()))
          .thenAnswer((_) async => const AssetFilters());
      when(() => repository.fetchProofPresence(any()))
          .thenAnswer((_) async => {});
      when(() => repository.fetchNetWorthHistoryReference(
            userId: any(named: 'userId'),
            threshold: any(named: 'threshold'),
          )).thenAnswer((_) async => null);
      when(() => repository.insertKpiSnapshot(any())).thenAnswer((_) async {});
    });

    tearDown(() {
      eventBus.dispose();
    });

    test('recalculateNetWorth converte moedas e desconta dívidas', () async {
      when(
        () => repository.fetchAssets(
          filters: any(named: 'filters'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => [
            _buildAsset(id: 1, value: 100000),
            _buildAsset(id: 2, value: 100, currency: 'USD'),
            _buildAsset(id: 3, value: 5000, category: AssetCategory.dividas),
          ]);

      when(() => fxService.convertToBrl('USD', any())).thenAnswer(
        (invocation) async => (invocation.positionalArguments[1] as double) * 5,
      );

      final controller = AssetsController(
        repository: repository,
        fxService: fxService,
        filterStorage: filterStorage,
        proofService: proofService,
        eventBus: eventBus,
      );
      addTearDown(controller.dispose);

      await controller.refresh();

      expect(controller.netWorth.totalAssets, 100500);
      expect(controller.netWorth.totalDebts, 5000);
      expect(controller.netWorth.netWorth, 95500);
      expect(controller.netWorth.breakdownByCategory[AssetCategory.financeiro],
          100500);
      expect(
          controller.netWorth.breakdownByCategory[AssetCategory.dividas], 5000);
    });

    test('loadMore respeita paginação e concatena resultados', () async {
      final firstPage = List<AssetModel>.generate(
        AssetsController.pageSize,
        (index) => _buildAsset(id: index + 1, value: 1000 + index.toDouble()),
      );
      final secondPage = List<AssetModel>.generate(
        5,
        (index) => _buildAsset(id: 100 + index, value: 900 + index.toDouble()),
      );
      when(
        () => repository.fetchAssets(
          filters: any(named: 'filters'),
          limit: any(named: 'limit'),
          offset: 0,
        ),
      ).thenAnswer((_) async => firstPage);
      when(
        () => repository.fetchAssets(
          filters: any(named: 'filters'),
          limit: any(named: 'limit'),
          offset: firstPage.length,
        ),
      ).thenAnswer((_) async => secondPage);

      final controller = AssetsController(
        repository: repository,
        fxService: fxService,
        filterStorage: filterStorage,
        proofService: proofService,
        eventBus: eventBus,
      );
      addTearDown(controller.dispose);

      await controller.refresh();
      await controller.loadMore();

      expect(controller.assets.length, firstPage.length + secondPage.length);
      verify(
        () => repository.fetchAssets(
          filters: any(named: 'filters'),
          limit: AssetsController.pageSize,
          offset: 0,
        ),
      ).called(1);
      verify(
        () => repository.fetchAssets(
          filters: any(named: 'filters'),
          limit: AssetsController.pageSize,
          offset: firstPage.length,
        ),
      ).called(1);
    });

    test('uploadProof e removeProof atualizam cache de documentos', () async {
      final document = AssetDocumentModel(
        id: 77,
        assetId: 2,
        storagePath: 'user/2/doc.enc',
        encryptedChecksum: 'checksum',
        fileType: 'pdf',
        uploadedAt: DateTime.now(),
      );

      when(
        () => repository.fetchAssets(
          filters: any(named: 'filters'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => [_buildAsset(id: 2, value: 2000)]);
      when(() => proofService.pickAndUploadProof(2))
          .thenAnswer((_) async => document);
      when(() => proofService.deleteProof(document)).thenAnswer((_) async {});

      final controller = AssetsController(
        repository: repository,
        fxService: fxService,
        filterStorage: filterStorage,
        proofService: proofService,
        eventBus: eventBus,
      );
      addTearDown(controller.dispose);

      await controller.refresh();
      await controller.uploadProof(2);

      expect(controller.documentsFor(2), contains(document));

      await controller.removeProof(document);
      expect(controller.documentsFor(2), isEmpty);
    });
  });
}

AssetModel _buildAsset({
  required int id,
  required double value,
  AssetCategory category = AssetCategory.financeiro,
  String currency = 'BRL',
}) {
  final now = DateTime(2024, 1, 1);
  return AssetModel(
    id: id,
    userId: 'user-1',
    category: category,
    title: 'Asset $id',
    description: 'Descrição',
    valueEstimated: value,
    valueCurrency: currency,
    valueUnknown: false,
    ownershipPercentage: 100,
    hasProof: false,
    status: AssetStatus.active,
    createdAt: now,
    updatedAt: now,
  );
}
