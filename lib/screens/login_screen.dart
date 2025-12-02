import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

enum _AuthMode { signIn, signUp }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  _AuthMode _mode = _AuthMode.signIn;

  @override
  void initState() {
    super.initState();
    _emailController.text = 'rodrigo.s.gomes@gmail.com';
    _passwordController.text = '12345678';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    final authService = context.read<AuthService>();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_mode == _AuthMode.signIn) {
        await authService.signIn(email: email, password: password);
        if (!mounted) return;
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/dashboard', (_) => false);
      } else {
        await authService.signUp(email: email, password: password);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Conta criada com sucesso! Verifique seu e-mail para confirmar o acesso.',
            ),
          ),
        );
        setState(() => _mode = _AuthMode.signIn);
      }
    } on AuthException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Não foi possível continuar agora. Tente novamente.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Informe seu e-mail para receber o link de redefinição.');
      return;
    }

    final authService = context.read<AuthService>();
    try {
      await authService.sendPasswordReset(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enviamos um link de redefinição para o seu e-mail.',
          ),
        ),
      );
    } on AuthException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Não foi possível enviar o e-mail agora.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _mode == _AuthMode.signIn ? 'Entrar no Elo' : 'Criar conta';
    final primaryCta = _mode == _AuthMode.signIn ? 'Entrar' : 'Criar conta';
    final secondaryCta = _mode == _AuthMode.signIn
        ? 'Novo aqui? Crie uma conta'
        : 'Já possui conta? Entrar';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _LoginHeader(theme: theme),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(title, style: theme.textTheme.headlineSmall),
                            const SizedBox(height: 8),
                            Text(
                              'Use seu e-mail para acessar seu Cofre ou criar uma nova conta protegida.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(
                                labelText: 'E-mail',
                                prefixIcon:
                                    Icon(Icons.alternate_email_outlined),
                              ),
                              onFieldSubmitted: (_) =>
                                  FocusScope.of(context).nextFocus(),
                              validator: (value) {
                                final input = value?.trim() ?? '';
                                if (input.isEmpty) {
                                  return 'Informe um e-mail válido.';
                                }
                                final emailRegex =
                                    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                                if (!emailRegex.hasMatch(input)) {
                                  return 'Formato de e-mail inválido.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              decoration: InputDecoration(
                                labelText: 'Senha',
                                prefixIcon:
                                    const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  tooltip: _obscurePassword
                                      ? 'Mostrar senha'
                                      : 'Ocultar senha',
                                ),
                              ),
                              validator: (value) {
                                final input = value ?? '';
                                if (input.isEmpty) {
                                  return 'Informe sua senha.';
                                }
                                if (input.length < 8) {
                                  return 'A senha deve ter pelo menos 8 caracteres.';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => _handleSubmit(),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed:
                                    _isLoading ? null : _handleForgotPassword,
                                child: const Text('Esqueci minha senha'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            FilledButton(
                              onPressed: _isLoading ? null : _handleSubmit,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : Text(primaryCta),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => setState(() {
                                        _mode = _mode == _AuthMode.signIn
                                            ? _AuthMode.signUp
                                            : _AuthMode.signIn;
                                      }),
                              child: Text(secondaryCta),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bem-vindo ao Elo',
          style: theme.textTheme.displaySmall,
        ),
        const SizedBox(height: 8),
        Text(
          'O elo entre o que você construiu e quem você ama. Segurança, confiança e controle em um único Cofre.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.textSecondary,
          ),
        ),
      ],
    );
  }
}
