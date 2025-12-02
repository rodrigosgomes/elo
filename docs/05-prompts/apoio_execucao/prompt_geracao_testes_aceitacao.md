# Prompt para Geração de Testes de Aceitação por PRD

## Contexto

Você é um assistente de desenvolvimento para o projeto Fluir, um app Flutter modular para finanças pessoais, usando Supabase como backend. O projeto segue uma arquitetura feature-first, com testes unitários em test/ e testes de aceitação (integration tests) em test_acceptance/. Os PRDs (Product Requirements Documents) definem funcionalidades-chave, e precisamos de testes de aceitação para validar cenários end-to-end, garantindo que as funcionalidades funcionem corretamente em um ambiente simulado (com dados de seed no Supabase). Os testes devem usar integration_test do Flutter, focando em UI, navegação e interações reais, sem mocks pesados. Critérios de aceitação foram mapeados previamente para cada PRD, cobrindo cenários essenciais como carregamento de dados, interações de usuário, validações e feedback.

## Objetivo

Gerar um arquivo de teste de aceitação completo e executável para um PRD específico, baseado nos critérios de aceitação mapeados. O teste deve cobrir os cenários principais do PRD, usando IntegrationTestWidgetsFlutterBinding, simulando ações de usuário (taps, drags, inputs) e verificando estados da UI e dados. O arquivo deve ser colocado em test_acceptance/features/{feature}/ (e.g., debts/debt_management_acceptance_test.dart), seguindo convenções do projeto: nomes em inglês, português para textos de usuário, e estrutura mirroring lib/. Garantir que o teste seja independente, com setup de dados via Supabase seeds, e que passe em CI (usando flutter test integration_test/).

## Passos

{PRD Name}: [#file]
Identificar o PRD e Critérios: Receba o PRD {PRD Name} (e.g., PRD 06: Gestão de Dívidas) e extraia os critérios de aceitação mapeados (e.g., "Dívidas listadas", "Estratégias simuladas"). Use-os para definir 3-5 cenários de teste principais, priorizando fluxos críticos (happy path) sobre edge cases.

### Estruturar o Arquivo de Teste

- Importe package:integration_test/integration_test.dart, flutter/material.dart, e flutter_test/flutter_test.dart.
- Use IntegrationTestWidgetsFlutterBinding.ensureInitialized() no main().
- Agrupe testes em group('{PRD Name} Acceptance Tests').
- Para cada cenário, crie um testWidgets com descrição clara (e.g., 'User can view active debts with details').
- Inicie o app com app.main() e simule login/navegação se necessário (assumindo usuário logado via seed).

### Implementar Cenários

- Setup: Use tester.pumpAndSettle() para estabilizar a UI. Assuma dados pré-seeded no Supabase (e.g., dívidas ativas para PRD 06).
- Ações de Usuário: Simule taps (tester.tap), drags (tester.drag para sliders), inputs (tester.enterText), e navegação.
- Verificações: Use expect(find.text(...), findsOneWidget) para textos/dados; verifique presença de widgets (find.byType(Slider)); confirme estados pós-ação (e.g., SnackBar de sucesso).
- Cobertura: Inclua validações de dados (e.g., saldos calculados), feedback (e.g., mensagens de erro/sucesso), e navegação (e.g., redirecionamento para dashboard).
- Limpeza: Não adicione teardown manual; o framework cuida disso.

### Garantir Qualidade e Convenções

- Mantenha testes concisos (<50 linhas por cenário); use comentários para explicar ações.
- Evite dependências externas; assuma .env configurado para Supabase.
- Siga padrões do projeto: async/await para operações, português para asserts de UI.
- Teste em isolamento: cada cenário independente, sem compartilhamento de estado.
- Validar e Finalizar: Após gerar, simule execução mentalmente contra os critérios. Adicione comentários no código indicando quais critérios cobrem. Sugira comandos para rodar (e.g., flutter test integration_test/debt_management_acceptance_test.dart).

## Exemplo de Saída

Para PRD 06 (Gestão de Dívidas), o arquivo gerado seria:

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:fluir/main.dart' as app;

void main() {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();

    group('Debt Management Acceptance Tests (PRD 06)', () {
        testWidgets('User can view active debts with details', (tester) async {
            app.main();
            await tester.pumpAndSettle();

            // Assume user is logged in and navigates to debt management page
            await tester.tap(find.text('Dívidas'));
            await tester.pumpAndSettle();

            // Verify debts are listed with balance, interest rate, etc.
            expect(find.text('Cartão'), findsOneWidget); // Example debt name
            expect(find.text('Saldo: R\$ 5.000'), findsOneWidget);
            expect(find.text('Juros: 18%'), findsOneWidget);
            expect(find.text('Pagamento mínimo: R\$ 400'), findsOneWidget);
        });

        testWidgets('User can simulate debt strategies and see recommendation', (tester) async {
            app.main();
            await tester.pumpAndSettle();

            await tester.tap(find.text('Dívidas'));
            await tester.pumpAndSettle();

            // Navigate to Estratégias tab
            await tester.tap(find.text('Estratégias'));
            await tester.pumpAndSettle();

            // Verify strategies are displayed
            expect(find.text('Avalanche'), findsOneWidget);
            expect(find.text('Bola de Neve'), findsOneWidget);

            // Check for recommendation badge on the strategy with higher savings
            expect(find.text('Recomendada'), findsOneWidget); // Assuming Avalanche has higher savings

            // Tap Simulate on Avalanche
            await tester.tap(find.widgetWithText(ElevatedButton, 'Simular').first);
            await tester.pumpAndSettle();

            // Verify simulation details (e.g., months to payoff, interest saved)
            expect(find.text('18 meses'), findsOneWidget);
            expect(find.text('Economia: R\$ 350'), findsOneWidget);
        });

        testWidgets('User can adopt a strategy plan and see confirmation', (tester) async {
            app.main();
            await tester.pumpAndSettle();

            await tester.tap(find.text('Dívidas'));
            await tester.pumpAndSettle();

            await tester.tap(find.text('Estratégias'));
            await tester.pumpAndSettle();

            // Simulate and adopt plan
            await tester.tap(find.widgetWithText(ElevatedButton, 'Simular').first);
            await tester.pumpAndSettle();

            await tester.tap(find.text('Adotar Este Plano'));
            await tester.pumpAndSettle();

            // Verify success message and navigation to dashboard
            expect(find.text('Plano adotado com sucesso!'), findsOneWidget);
            expect(find.text('Dashboard'), findsOneWidget); // Assuming redirected to dashboard
        });

        testWidgets('User can simulate debt negotiation and register intent', (tester) async {
            app.main();
            await tester.pumpAndSettle();

            await tester.tap(find.text('Dívidas'));
            await tester.pumpAndSettle();

            // Navigate to Simulador tab
            await tester.tap(find.text('Simulador'));
            await tester.pumpAndSettle();

            // Adjust sliders (assume sliders are present)
            await tester.drag(find.byType(Slider).first, const Offset(100, 0)); // Adjust debt value
            await tester.pumpAndSettle();

            await tester.drag(find.byType(Slider).last, const Offset(-50, 0)); // Adjust term
            await tester.pumpAndSettle();

            // Verify real-time updates
            expect(find.text('Pagamento à Vista: R\$ 2.000'), findsOneWidget); // Example discounted value
            expect(find.text('Parcelado: 12x de R\$ 450'), findsOneWidget);

            // Tap to initiate negotiation
            await tester.tap(find.text('Iniciar Negociação'));
            await tester.pumpAndSettle();

            // Verify intent registered (e.g., via success message)
            expect(find.text('Intenção de negociação registrada'), findsOneWidget);
        });
    });
}
```
