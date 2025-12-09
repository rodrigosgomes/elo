import 'package:elo/models/asset_model.dart';
import 'package:elo/screens/bens/assets_controller.dart';
import 'package:elo/screens/bens/bens_screen.dart';
import 'package:elo/screens/common/vault_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAssetsController extends Mock implements AssetsController {}

class MockNetWorthSummary extends Mock implements NetWorthSummary {}

void main() {
  late MockAssetsController mockController;
  late MockNetWorthSummary mockSummary;

  setUpAll(() {
    registerFallbackValue(const AssetFilters());
  });

  setUp(() {
    mockController = MockAssetsController();
    mockSummary = MockNetWorthSummary();

    // Default mock behaviors
    when(() => mockController.isLoading).thenReturn(false);
    when(() => mockController.isLoadingMore).thenReturn(false);
    when(() => mockController.hasMore).thenReturn(false);
    when(() => mockController.assets).thenReturn([]);
    when(() => mockController.netWorth).thenReturn(mockSummary);
    when(() => mockController.filters).thenReturn(const AssetFilters());
    when(() => mockController.errorMessage).thenReturn(null);
    when(() => mockController.bootstrap()).thenAnswer((_) async {});

    // NetWorthSummary defaults
    when(() => mockSummary.netWorth).thenReturn(0);
    when(() => mockSummary.hasSnapshot).thenReturn(true);
    when(() => mockSummary.pendingValuations).thenReturn([]);
    when(() => mockSummary.fxPending).thenReturn({});
    when(() => mockSummary.historyDelta).thenReturn(null);
    when(() => mockSummary.hasInsufficientHistory).thenReturn(false);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BensScreen(controller: mockController),
      routes: {
        '/bens/novo': (context) => const Scaffold(body: Text('Novo Bem')),
      },
    );
  }

  testWidgets('BensScreen displays correct title "Patrimônio Pessoal"',
      (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Patrimônio Pessoal'), findsOneWidget);

    // Verify it is not centered (by checking logic or visual if possible,
    // but flutter test mainly checks widget presence/properties)
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.centerTitle, false);
  });

  testWidgets('BensScreen displays download icon for export', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    final exportButton = find.byIcon(Icons.file_download_outlined);
    expect(exportButton, findsOneWidget);

    // Previous "Exportar" text should not exist
    expect(find.text('Exportar'), findsNothing);
  });

  testWidgets('BensScreen displays filter icons', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byIcon(Icons.all_inclusive), findsOneWidget); // Todos
    expect(find.byIcon(Icons.domain_outlined), findsOneWidget); // Imóveis
    expect(find.byIcon(Icons.directions_car_filled_outlined),
        findsOneWidget); // Veículos
    expect(find.byIcon(Icons.savings_outlined), findsOneWidget); // Financeiro
    expect(find.byIcon(Icons.currency_bitcoin), findsOneWidget); // Cripto
    expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget); // Dívidas
  });

  testWidgets('BensScreen displays filters above NetWorthCard', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    final filtersFinder = find.byType(Wrap); // The filters are in a Wrap
    final cardFinder = find.byType(Card); // NetWorthCard is a Card

    final filtersPosition = tester.getTopLeft(filtersFinder).dy;
    final cardPosition = tester.getTopLeft(cardFinder).dy;

    expect(filtersPosition, lessThan(cardPosition));
  });

  testWidgets('BensScreen hides "Histórico insuficiente" warning when true',
      (tester) async {
    when(() => mockSummary.hasInsufficientHistory).thenReturn(true);
    when(() => mockSummary.historyDelta).thenReturn(null);

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Histórico insuficiente'), findsNothing);
    expect(find.byIcon(Icons.info_outline), findsNothing);
  });

  testWidgets('Navigation bar has "Patrimônio" label', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(VaultNavigationBar), findsOneWidget);
    expect(find.widgetWithText(NavigationDestination, 'Patrimônio'),
        findsOneWidget);
    expect(find.text('Bens'), findsNothing);
  });
}
