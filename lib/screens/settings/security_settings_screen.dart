import 'package:flutter/material.dart';

class SecuritySettingsScreen extends StatelessWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Segurança'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configurações de 2FA',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Este espaço reservará o fluxo completo de step-up e autenticação reforçada. Enquanto o backend é finalizado, utilize o Supabase Auth para ativar FIDO2/SMS e volte ao dashboard para atualizar o status.',
              style: theme.textTheme.bodyMedium,
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Voltar ao The Vault'),
            ),
          ],
        ),
      ),
    );
  }
}
