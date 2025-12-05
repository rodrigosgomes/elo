import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<String?> showStepUpPrompt({
  required BuildContext context,
  required String actionLabel,
}) async {
  final preferredMethod = await _fetchPreferredStepUpMethod();
  if (!context.mounted) return null;
  if (preferredMethod == StepUpMethod.masterPassword) {
    final approved = await _showMasterPasswordSheet(context, actionLabel);
    return approved == true ? preferredMethod.identifier : null;
  }

  if (!context.mounted) return null;
  final decision = await showModalBottomSheet<_PreferredFlowDecision>(
    context: context,
    backgroundColor: const Color(0xFF161A1E),
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (ctx) => _PreferredFactorSheet(
      method: preferredMethod,
      actionLabel: actionLabel,
    ),
  );

  if (decision == _PreferredFlowDecision.success) {
    return preferredMethod.identifier;
  }
  if (decision == _PreferredFlowDecision.fallback) {
    if (!context.mounted) return null;
    final approved = await _showMasterPasswordSheet(context, actionLabel);
    if (approved == true) {
      return StepUpMethod.masterPassword.identifier;
    }
  }
  return null;
}

Future<StepUpMethod> _fetchPreferredStepUpMethod() async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return StepUpMethod.masterPassword;
  try {
    final response = await client
        .from('user_keys')
        .select('step_up_method')
        .eq('user_id', userId)
        .maybeSingle();
    final method = response?['step_up_method'] as String?;
    return StepUpMethodX.fromStorage(method);
  } catch (_) {
    return StepUpMethod.masterPassword;
  }
}

Future<bool?> _showMasterPasswordSheet(
  BuildContext context,
  String actionLabel,
) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: const Color(0xFF161A1E),
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (ctx) => _MasterPasswordSheet(actionLabel: actionLabel),
  );
}

enum StepUpMethod { biometrics, securityKey, masterPassword }

extension StepUpMethodX on StepUpMethod {
  static StepUpMethod fromStorage(String? value) {
    switch (value) {
      case 'BIOMETRICS':
        return StepUpMethod.biometrics;
      case 'SECURITY_KEY':
        return StepUpMethod.securityKey;
      case 'MASTER_PASSWORD':
      default:
        return StepUpMethod.masterPassword;
    }
  }

  String get identifier {
    switch (this) {
      case StepUpMethod.biometrics:
        return 'biometrics';
      case StepUpMethod.securityKey:
        return 'security_key';
      case StepUpMethod.masterPassword:
        return 'master_password';
    }
  }

  IconData get icon {
    switch (this) {
      case StepUpMethod.biometrics:
        return Icons.fingerprint_rounded;
      case StepUpMethod.securityKey:
        return Icons.usb_rounded;
      case StepUpMethod.masterPassword:
        return Icons.lock_outline;
    }
  }

  String get label {
    switch (this) {
      case StepUpMethod.biometrics:
        return 'Biometria';
      case StepUpMethod.securityKey:
        return 'Chave de segurança';
      case StepUpMethod.masterPassword:
        return 'Senha mestra';
    }
  }

  String get description {
    switch (this) {
      case StepUpMethod.biometrics:
        return 'Use Face ID ou impressão digital registrada no dispositivo.';
      case StepUpMethod.securityKey:
        return 'Conecte sua chave FIDO e toque para validar o acesso.';
      case StepUpMethod.masterPassword:
        return 'Informe a senha mestra cadastrada no Elo.';
    }
  }
}

enum _PreferredFlowDecision { success, fallback }

class _PreferredFactorSheet extends StatefulWidget {
  const _PreferredFactorSheet({
    required this.method,
    required this.actionLabel,
  });

  final StepUpMethod method;
  final String actionLabel;

  @override
  State<_PreferredFactorSheet> createState() => _PreferredFactorSheetState();
}

class _PreferredFactorSheetState extends State<_PreferredFactorSheet> {
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
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
                    _processing ? null : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              child: Icon(widget.method.icon,
                  color: Theme.of(context).colorScheme.primary),
            ),
            title: Text(widget.method.label),
            subtitle: Text(widget.method.description),
          ),
          const SizedBox(height: 12),
          Text(
            'Para ${widget.actionLabel}, validaremos seu fator preferido. Se não estiver disponível, você pode usar a senha mestra.',
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _processing ? null : _handlePrimary,
            icon: _processing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.verified_user_outlined),
            label: Text('Validar com ${widget.method.label}'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _processing ? null : _handleFallback,
            child: const Text('Não consigo usar este método'),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePrimary() async {
    setState(() => _processing = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    Navigator.of(context).pop(_PreferredFlowDecision.success);
  }

  void _handleFallback() {
    Navigator.of(context).pop(_PreferredFlowDecision.fallback);
  }
}

class _MasterPasswordSheet extends StatefulWidget {
  const _MasterPasswordSheet({required this.actionLabel});

  final String actionLabel;

  @override
  State<_MasterPasswordSheet> createState() => _MasterPasswordSheetState();
}

class _MasterPasswordSheetState extends State<_MasterPasswordSheet> {
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
    Navigator.of(context).pop(true);
  }
}
