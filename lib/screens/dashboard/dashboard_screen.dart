import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';

import 'dashboard_controller.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.controllerOverride});

  final DashboardController? controllerOverride;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardController _controller;
  late final bool _ownsController;
  bool _canRender = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controllerOverride == null;
    _controller = widget.controllerOverride ?? DashboardController();
    if (!_ownsController) {
      _canRender = true;
      return;
    }
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      _canRender = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _controller.bootstrap();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _ensureAuthenticated();
      });
    }
  }

  Future<void> _ensureAuthenticated() async {
    final auth = Supabase.instance.client.auth;
    final current = auth.currentSession;
    if (current != null) {
      if (!mounted) return;
      setState(() {
        _canRender = true;
      });
      await _controller.bootstrap();
      return;
    }

    final state = await auth.onAuthStateChange.firstWhere(
      (event) =>
          event.session != null || event.event == AuthChangeEvent.signedOut,
    );
    if (!mounted) return;
    if (state.session == null) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      return;
    }
    setState(() {
      _canRender = true;
    });
    await _controller.bootstrap();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_canRender) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ChangeNotifierProvider<DashboardController>.value(
      value: _controller,
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Consumer<DashboardController>(
          builder: (context, controller, _) {
            if (controller.isLoading) {
              return const _DashboardSkeleton();
            }
            if (controller.hasError) {
              return _DashboardError(
                message: controller.errorMessage ??
                    'Não foi possível carregar o dashboard.',
                onRetry: () => controller.loadInitialData(),
              );
            }
            final data = controller.data;
            return RefreshIndicator(
              color: theme.colorScheme.primary,
              onRefresh: () => controller.refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  _DashboardHeader(profile: data.profile),
                  const SizedBox(height: 16),
                  if (data.showTrustHeader) ...[
                    _TrustHeader(onDismissed: controller.dismissTrustHeader),
                    const SizedBox(height: 16),
                  ],
                  if (data.showTwoFactorBanner) ...[
                    _TwoFactorBanner(onConfigure: () {
                      controller.logTwoFactorPromptCta();
                      Navigator.of(context).pushNamed('/settings/security');
                    }),
                    const SizedBox(height: 16),
                  ],
                  _ProtectionRingSection(data: data),
                  const SizedBox(height: 24),
                  _PillarsSection(data: data),
                  const SizedBox(height: 24),
                  _ChecklistSection(data: data),
                  const SizedBox(height: 24),
                  _KpiSection(metrics: data.metrics),
                  const SizedBox(height: 24),
                  _TimelineSection(data: data),
                  const SizedBox(height: 24),
                  const SizedBox(height: 48),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.profile});

  final ProfileData? profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The Vault',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Olá, ${profile?.fullName ?? 'legado seguro'}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Sair',
          icon: const Icon(Icons.logout),
          color: theme.colorScheme.onSurface,
          onPressed: () async {
            await Supabase.instance.client.auth.signOut();
            if (!context.mounted) return;
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/login', (_) => false);
          },
        ),
      ],
    );
  }
}

class _TrustHeader extends StatelessWidget {
  const _TrustHeader({required this.onDismissed});

  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: const Color(0xFF161A1E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cabeçalho de Confiança',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Criptografia ponta a ponta garante que somente você e os guardiões autorizados podem acessar seu legado.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onDismissed,
                child: const Text('Entendi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TwoFactorBanner extends StatelessWidget {
  const _TwoFactorBanner({required this.onConfigure});

  final VoidCallback onConfigure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: const Color(0xFF1C2127),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ative o 2FA para proteger sua conta',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A autenticação em duas etapas adiciona uma camada extra nas liberações do cofre.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: onConfigure,
              child: const Text('Configurar 2FA'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProtectionRingSection extends StatelessWidget {
  const _ProtectionRingSection({required this.data});

  final DashboardViewData data;

  @override
  Widget build(BuildContext context) {
    final checklist = data.checklist;
    final profile = data.profile;
    final protocol = data.protocol;
    final theme = Theme.of(context);
    final percent = (checklist?.protectionRingScore ?? 0) / 100.0;
    final lastActivity = protocol?.lastActivityAt ?? profile?.lastActivity;
    final formatter = DateFormat('dd MMM, HH:mm', 'pt_BR');

    return Card(
      color: const Color(0xFF161A1E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Semantics(
                    label:
                        'Anel de proteção ${((percent) * 100).round()} por cento',
                    child: SizedBox(
                      height: 140,
                      width: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: percent.clamp(0, 1),
                            strokeWidth: 10,
                            backgroundColor: theme.lineSoft,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary,
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${(percent * 100).round()}%',
                                style: theme.textTheme.headlineLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Anel de Proteção',
                                style: theme.textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Checklist FLX-01',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.profile?.headlineStatus ?? 'Seguro',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Última atividade do protocolo',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastActivity != null
                        ? formatter.format(lastActivity)
                        : 'Sem registros',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  _StatusBadge(label: protocol?.status ?? 'MONITORING'),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium,
      ),
    );
  }
}

class _PillarsSection extends StatelessWidget {
  const _PillarsSection({required this.data});

  final DashboardViewData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTwoColumns = constraints.maxWidth > 520;
        final cards = [
          _PillarCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Bens',
            subtitle: '${data.pillarSummary.activeAssets} ativos protegidos',
            highlight: _formatCurrency(
              data.pillarSummary.assetsInBrl,
              data.pillarSummary.assetTotalsByCurrency,
            ),
            chips: data.pillarSummary.assetTotalsByCurrency.entries
                .map(
                    (entry) => '${entry.key} ${entry.value.toStringAsFixed(2)}')
                .toList(),
            ctaLabel: 'Adicionar bem',
            onTap: () => Navigator.of(context).pushNamed('/bens/novo'),
          ),
          _PillarCard(
            icon: Icons.lock_outline,
            title: 'Documentos',
            subtitle: '${data.pillarSummary.encryptedDocuments} criptografados',
            highlight: 'Badge Encrypted',
            ctaLabel: 'Ver cofre',
            onTap: () => Navigator.of(context).pushNamed('/documentos'),
          ),
          _PillarCard(
            icon: Icons.language,
            title: 'Legado Digital',
            subtitle:
                '${data.pillarSummary.legacyAccounts} contas + ${data.pillarSummary.masterCredentials} credenciais',
            highlight: 'Pronto para emergência',
            ctaLabel: 'Gerenciar legado',
            onTap: () => Navigator.of(context).pushNamed('/legado'),
          ),
          _PillarCard(
            icon: Icons.favorite_outline,
            title: 'Diretivas',
            subtitle: _directivesSubtitle(
                data.pillarSummary.hasMedicalDirective,
                data.pillarSummary.hasFuneralPreference,
                data.pillarSummary.capsuleCount),
            highlight: 'Liberado pelos guardiões',
            ctaLabel: 'Configurar diretivas',
            onTap: () => Navigator.of(context).pushNamed('/diretivas'),
          ),
        ];

        return GridView.count(
          shrinkWrap: true,
          crossAxisCount: isTwoColumns ? 2 : 1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isTwoColumns ? 1.2 : 0.9,
          children: cards,
        );
      },
    );
  }

  String _directivesSubtitle(
      bool hasMedical, bool hasFuneral, int capsuleCount) {
    final pieces = <String>[];
    if (hasMedical) pieces.add('Testamento Vital');
    if (hasFuneral) pieces.add('Funeral');
    if (capsuleCount > 0) pieces.add('$capsuleCount cápsulas');
    if (pieces.isEmpty) return 'Configure seus desejos';
    return pieces.join(' · ');
  }

  String _formatCurrency(
    double? brl,
    Map<String, double> perCurrency,
  ) {
    if (brl != null) {
      return NumberFormat.simpleCurrency(locale: 'pt_BR').format(brl);
    }
    if (perCurrency.isEmpty) return 'Sem valores';
    final first = perCurrency.entries.first;
    return '${first.key} ${first.value.toStringAsFixed(2)}';
  }
}

class _PillarCard extends StatelessWidget {
  const _PillarCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.highlight,
    required this.ctaLabel,
    this.chips,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String highlight;
  final String ctaLabel;
  final List<String>? chips;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: const Color(0xFF161A1E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              highlight,
              style: theme.textTheme.bodyLarge,
            ),
            if (chips != null && chips!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: chips!
                    .map(
                      (chip) => Chip(
                        label: Text(chip),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.arrow_outward_rounded),
                label: Text(ctaLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistSection extends StatelessWidget {
  const _ChecklistSection({required this.data});

  final DashboardViewData data;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<DashboardController>();
    final checklist = data.checklist;
    final theme = Theme.of(context);
    return Card(
      color: const Color(0xFF161A1E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Checklist FLX-01', style: theme.textTheme.titleLarge),
                const Spacer(),
                _StatusBadge(
                    label: '${checklist?.protectionRingScore ?? 0} pts'),
              ],
            ),
            const SizedBox(height: 16),
            _ChecklistItem(
              itemKey: const ValueKey('checklist_asset'),
              isDone: checklist?.hasAsset ?? false,
              title: 'Registre um bem',
              description: 'Cadastre um bem com comprovantes e cifre os dados.',
              actionLabel:
                  checklist?.hasAsset ?? false ? 'Concluído' : 'Cadastrar',
              onTap: () => Navigator.of(context).pushNamed('/bens/novo'),
            ),
            _ChecklistItem(
              itemKey: const ValueKey('checklist_guardian'),
              isDone: checklist?.hasGuardian ?? false,
              title: 'Convide um guardião',
              description:
                  'Escolha alguém de confiança para liberar diretivas.',
              actionLabel: checklist?.hasGuardian ?? false
                  ? 'Concluído'
                  : 'Adicionar guardião',
              onTap: () => Navigator.of(context).pushNamed('/guardioes/novo'),
            ),
            _ChecklistItem(
              itemKey: const ValueKey('checklist_life_check'),
              isDone: checklist?.lifeCheckEnabled ?? false,
              title: 'Ative verificação de vida',
              description:
                  'Defina o canal e o guardião responsável pelos testes.',
              actionLabel: checklist?.lifeCheckEnabled ?? false
                  ? 'Configuração ativa'
                  : 'Configurar',
              onTap: () => _showLifeCheckSheet(context, controller),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLifeCheckSheet(
    BuildContext context,
    DashboardController controller,
  ) async {
    final theme = Theme.of(context);
    final protocol = controller.data.protocol;
    if (protocol == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Protocolo não encontrado.')),
      );
      return;
    }
    var channel = protocol.lifeCheckChannel;
    var stepUpRequired = protocol.stepUpRequired;

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161A1E),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: theme.lineSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Configurar verificação de vida',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Canal de verificação',
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'PUSH',
                        label: Text('Push'),
                        icon: Icon(Icons.notifications_active_outlined),
                      ),
                      ButtonSegment(
                        value: 'EMAIL',
                        label: Text('Email'),
                        icon: Icon(Icons.email_outlined),
                      ),
                      ButtonSegment(
                        value: 'SMS',
                        label: Text('SMS'),
                        icon: Icon(Icons.sms_outlined),
                      ),
                    ],
                    selected: {channel},
                    onSelectionChanged: (selection) {
                      if (selection.isEmpty) return;
                      setModalState(() => channel = selection.first);
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    value: stepUpRequired,
                    onChanged: (value) =>
                        setModalState(() => stepUpRequired = value),
                    title: const Text('Exigir step-up (2FA/Biometria)'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await controller.updateLifeCheckSettings(
                          channel: channel,
                          stepUpRequired: stepUpRequired,
                        );
                        if (context.mounted) Navigator.of(context).pop();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Verificação de vida atualizada.'),
                            ),
                          );
                        }
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Não foi possível atualizar agora. Tente novamente'),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Salvar'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({
    required this.isDone,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onTap,
    this.itemKey,
  });

  final bool isDone;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onTap;
  final Key? itemKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      key: itemKey,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isDone ? theme.colorScheme.primary : theme.lineStrong,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onTap,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _KpiSection extends StatelessWidget {
  const _KpiSection({required this.metrics});

  final List<KpiMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = metrics
        .where((metric) =>
            metric.metricType == 'CHECKLIST_COMPLETED' ||
            metric.metricType == 'PROTOCOL_TESTE')
        .toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    return Card(
      color: const Color(0xFF161A1E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seu desempenho', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              Text(
                'Complete itens da checklist para ver seus KPIs.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textSecondary,
                ),
              )
            else
              SizedBox(
                height: 180,
                child: CustomPaint(
                  painter: _KpiSparklinePainter(filtered),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _KpiSparklinePainter extends CustomPainter {
  _KpiSparklinePainter(this.metrics);

  final List<KpiMetric> metrics;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF5590A8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (metrics.isEmpty) return;

    final values = metrics
        .map((metric) =>
            metric.metricValue ??
            (metric.metricType == 'CHECKLIST_COMPLETED' ? 1.0 : 0.5))
        .toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = (maxValue - minValue).abs() < 0.001 ? 1 : maxValue - minValue;

    for (var i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = size.height - ((values[i] - minValue) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({required this.data});

  final DashboardViewData data;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<DashboardController>();
    if (data.timeline.hasContent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.logTimelineViewed();
      });
    }

    final theme = Theme.of(context);
    return Card(
      color: const Color(0xFF161A1E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Próximas ações', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            if (!data.timeline.hasContent)
              Text(
                'Tudo sincronizado. Voltaremos a avisar nos próximos eventos.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textSecondary,
                ),
              )
            else ...[
              if (data.timeline.nextLifeCheck != null)
                _TimelineItem(
                  icon: Icons.favorite_border,
                  title: 'Próxima verificação de vida',
                  date: data.timeline.nextLifeCheck!.scheduledAt,
                  description: 'Canal ${data.timeline.nextLifeCheck!.channel}',
                  ctaLabel: 'Configurar',
                  onTap: () =>
                      Navigator.of(context).pushNamed('/guardioes/novo'),
                ),
              if (data.timeline.pendingGuardian != null)
                _TimelineItem(
                  icon: Icons.group_add_outlined,
                  title: 'Guardião pendente',
                  date: data.timeline.pendingGuardian!.invitedAt,
                  description: data.timeline.pendingGuardian!.name,
                  ctaLabel: 'Lembrar guardião',
                  onTap: () =>
                      Navigator.of(context).pushNamed('/guardioes/novo'),
                ),
              if (data.timeline.subscriptionToReview != null)
                _TimelineItem(
                  icon: Icons.subscriptions_outlined,
                  title: 'Assinatura a revisar',
                  date: data.timeline.subscriptionToReview!.nextChargeAt,
                  description: data.timeline.subscriptionToReview!.serviceName,
                  ctaLabel: 'Revisar assinatura',
                  onTap: () => Navigator.of(context).pushNamed('/legado'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.ctaLabel,
    this.date,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final String ctaLabel;
  final DateTime? date;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('dd MMM, HH:mm', 'pt_BR');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall,
                ),
                if (date != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    formatter.format(date!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: Text(ctaLabel),
          ),
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: index == 0 ? 80 : 140,
          decoration: BoxDecoration(
            color: const Color(0xFF1C2127),
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
