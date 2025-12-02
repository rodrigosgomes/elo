import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:elo/screens/login_screen.dart';
import 'package:elo/services/auth_service.dart';

void main() {
  group('LoginScreen', () {
    testWidgets('toggles between sign-in and sign-up modes', (tester) async {
      final authService = _FakeAuthService();

      await tester.pumpWidget(_buildHarness(authService));

      expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);

      await tester.ensureVisible(find.textContaining('Novo aqui'));
      await tester.tap(find.textContaining('Novo aqui'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Criar conta'), findsOneWidget);
    });

    testWidgets('calls signIn when form is valid', (tester) async {
      final authService = _FakeAuthService();

      await tester.pumpWidget(_buildHarness(authService));

      await tester.enterText(find.bySemanticsLabel('E-mail'), 'user@elo.app');
      await tester.enterText(find.bySemanticsLabel('Senha'), '12345678');

      await tester.ensureVisible(find.text('Entrar'));
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(authService.didSignIn, isTrue);
    });

    testWidgets('forgot password requires email input', (tester) async {
      final authService = _FakeAuthService();

      await tester.pumpWidget(_buildHarness(authService));

      // Clear default credentials to mimic blank input scenario.
      await tester.enterText(find.bySemanticsLabel('E-mail'), '');
      await tester.ensureVisible(find.text('Esqueci minha senha'));
      await tester.tap(find.text('Esqueci minha senha'));
      await tester.pump();

      expect(
          find.text('Informe seu e-mail para receber o link de redefinição.'),
          findsOneWidget);
    });

    testWidgets('forgot password triggers service when email is present',
        (tester) async {
      final authService = _FakeAuthService();

      await tester.pumpWidget(_buildHarness(authService));

      await tester.enterText(find.bySemanticsLabel('E-mail'), 'user@elo.app');
      await tester.ensureVisible(find.text('Esqueci minha senha'));
      await tester.tap(find.text('Esqueci minha senha'));
      await tester.pumpAndSettle();

      expect(authService.didSendReset, isTrue);
    });
  });
}

Widget _buildHarness(AuthService service) {
  return Provider<AuthService>.value(
    value: service,
    child: const MaterialApp(home: LoginScreen()),
  );
}

class _FakeAuthService implements AuthService {
  bool didSignIn = false;
  bool didSendReset = false;

  @override
  Future<void> signIn({required String email, required String password}) async {
    didSignIn = true;
  }

  @override
  Future<void> signUp(
      {required String email, required String password}) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordReset(
      {required String email, String? redirectTo}) async {
    didSendReset = true;
  }

  @override
  User? getCurrentUser() => null;

  @override
  Stream<AuthState> authStateChanges() => const Stream<AuthState>.empty();
}
