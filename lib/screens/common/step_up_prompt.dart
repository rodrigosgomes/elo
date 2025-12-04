import 'package:flutter/material.dart';

Future<String?> showStepUpPrompt({
  required BuildContext context,
  required String actionLabel,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: const Color(0xFF161A1E),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (ctx) {
      return _StepUpPromptSheet(actionLabel: actionLabel);
    },
  );
}

class _StepUpPromptSheet extends StatefulWidget {
  const _StepUpPromptSheet({required this.actionLabel});

  final String actionLabel;

  @override
  State<_StepUpPromptSheet> createState() => _StepUpPromptSheetState();
}

class _StepUpPromptSheetState extends State<_StepUpPromptSheet> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 32,
        bottom: bottomInset + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Confirme sua identidade',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed:
                      _submitting ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Para ${widget.actionLabel}, precisamos aplicar o step-up de segurança. '
              'Use a senha mestra como fallback caso biometria ou FIDO não estejam ativos.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              enabled: !_submitting,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Senha mestra',
                helperText:
                    'Mínimo 6 caracteres. Nunca armazenamos esse valor.',
              ),
              validator: (value) {
                if (value == null || value.trim().length < 6) {
                  return 'Informe sua senha mestra.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _submitting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _submitting ? null : _handleSubmit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.verified_user_outlined),
                  label: const Text('Validar acesso'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    Navigator.of(context).pop('master_password');
  }
}
