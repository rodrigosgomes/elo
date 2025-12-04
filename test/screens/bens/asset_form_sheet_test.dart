import 'package:elo/models/asset_model.dart';
import 'package:elo/screens/bens/asset_form_sheet.dart';
import 'package:elo/screens/bens/assets_controller.dart';
import 'package:elo/services/asset_proof_service.dart';
import 'package:elo/services/assets_filter_storage.dart';
import 'package:elo/services/assets_repository.dart';
import 'package:elo/services/fx_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AssetFormSheet valida campos e aplica máscara monetária',
      (tester) async {
    final controller = _FormTestController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AssetFormSheet(controller: controller),
        ),
      ),
    );

    final titleField = find.byType(TextFormField).first;
    await tester.enterText(titleField, 'AB');
    await _tapAndSettle(tester, find.text('Cadastrar bem'));

    expect(find.text('Informe pelo menos 3 caracteres'), findsOneWidget);

    await tester.enterText(titleField, 'Apartamento Centro');

    final valueField = find.byType(TextFormField).at(1);

    await tester.enterText(valueField, '123456');
    await tester.pump();

    final valueWidget = tester.widget<TextFormField>(valueField);
    expect(valueWidget.controller?.text, '1.234,56');

    await _tapAndSettle(tester, find.text('Já possui comprovante?'));

    await _tapAndSettle(tester, find.text('Campos avançados'));
    await tester.enterText(
      find.byType(TextFormField).last,
      'Documento original guardado no cofre.',
    );

    await _tapAndSettle(tester, find.text('Cadastrar bem'));

    expect(controller.lastCreated, isNotNull);
    expect(controller.lastCreated!.valueEstimated, 1234.56);
    expect(controller.lastCreated!.status, AssetStatus.active);
    expect(controller.lastCreated!.hasProof, isTrue);
    expect(controller.lastCreated!.description,
        'Documento original guardado no cofre.');
  });
}

class _FormTestController extends AssetsController {
  _FormTestController()
      : super(
          repository: AssetsRepository(),
          fxService: FxService(),
          filterStorage: AssetsFilterStorage(),
          proofService: AssetProofService(),
        );

  AssetInput? lastCreated;

  @override
  Future<AssetModel> createAsset(AssetInput input) async {
    lastCreated = input;
    return AssetModel(
      id: 99,
      userId: 'user',
      category: input.category,
      title: input.title,
      description: input.description,
      valueEstimated: input.valueEstimated,
      valueCurrency: input.valueCurrency,
      valueUnknown: input.valueUnknown,
      ownershipPercentage: input.ownershipPercentage,
      hasProof: input.hasProof,
      status: input.status,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

Future<void> _tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
  await tester.pumpAndSettle();
}
