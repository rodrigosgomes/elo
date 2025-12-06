import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/asset_model.dart';
import '../common/step_up_prompt.dart';
import 'asset_form_sheet.dart';
import 'asset_proofs_sheet.dart';
import 'asset_security.dart';
import 'assets_controller.dart';

Future<void> showAssetDetailSheet(
  BuildContext context,
  AssetModel asset, {
  AssetsController? controller,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF161A1E),
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (ctx) {
      final resolvedController =
          controller ?? Provider.of<AssetsController>(ctx, listen: false);
      return AssetDetailSheet(
        asset: asset,
        controller: resolvedController,
      );
    },
  );
}

class AssetDetailSheet extends StatefulWidget {
  const AssetDetailSheet(
      {super.key, required this.asset, required this.controller});

  final AssetModel asset;
  final AssetsController controller;

  @override
  State<AssetDetailSheet> createState() => _AssetDetailSheetState();
}

class _AssetDetailSheetState extends State<AssetDetailSheet> {
  late AssetModel _asset;
  bool _processing = false;
  bool _proofProcessing = false;
  bool _documentsLoading = true;
  List<AssetDocumentModel> _documents = const <AssetDocumentModel>[];
  final Set<int> _documentActions = <int>{};

  bool get _requiresHighSecurity => requiresHighSecurityForAsset(_asset);

  Future<String?> _requestStepUp(String actionLabel) {
    if (!_requiresHighSecurity) return Future.value(null);
    return showStepUpPrompt(
      context: context,
      actionLabel: actionLabel,
    );
  }

  Future<bool?> _confirmDeleteAction() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1F24),
          title: const Text('Remover definitivamente?'),
          content: const Text(
            'Este bem será excluído do cofre. Você pode optar por arquivar caso queira manter o histórico.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Remover'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _asset = widget.asset;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadDocuments();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final valueText = _asset.valueUnknown
        ? 'Valor desconhecido'
        : formatter.format(_asset.valueEstimated ?? 0);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _asset.title,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed:
                      _processing ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(_asset.category.label, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(valueText, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
            _buildBadges(theme),
            const SizedBox(height: 24),
            _buildFinancialSummary(theme, formatter),
            const SizedBox(height: 24),
            _buildDescriptionBlock(theme),
            const SizedBox(height: 24),
            _buildProofSection(theme),
            const SizedBox(height: 24),
            _buildTimelineSection(theme),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: _processing ? null : _handleEdit,
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar'),
                ),
                OutlinedButton.icon(
                  onPressed: _processing ? null : _handleArchive,
                  icon: const Icon(Icons.archive_outlined),
                  label: const Text('Arquivar'),
                ),
                TextButton.icon(
                  onPressed: _processing ? null : _handleDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remover'),
                  style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleEdit() async {
    await showAssetFormSheet(
      context,
      asset: _asset,
      controller: widget.controller,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _handleArchive() async {
    if (_processing) return;
    String? factor;
    if (_requiresHighSecurity) {
      factor = await _requestStepUp('arquivar este bem');
      if (!mounted || factor == null) {
        return;
      }
    }
    final controller = widget.controller;
    setState(() => _processing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await controller.archiveAsset(
        _asset.id,
        factorUsed: factor,
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Bem arquivado.')),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Não foi possível arquivar: $error')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _handleDelete() async {
    if (_processing) return;
    final confirmed = await _confirmDeleteAction();
    if (!mounted || confirmed != true) return;
    final factor = await _requestStepUp('remover este bem');
    if (!mounted) return;
    if (_requiresHighSecurity && factor == null) {
      return;
    }
    final controller = widget.controller;
    setState(() => _processing = true);
    final messenger = ScaffoldMessenger.of(context);
    var completed = false;
    try {
      await controller.deleteAsset(
        _asset.id,
        factorUsed: factor,
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Bem removido.')),
      );
      completed = true;
    } catch (error) {
      final handled = await _attemptArchiveFallback(
        controller,
        messenger,
        factor,
        error,
      );
      completed = handled;
      if (!handled) {
        messenger.showSnackBar(
          SnackBar(content: Text('Falha ao remover: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
    if (!mounted) return;
    if (completed) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _loadDocuments() async {
    setState(() => _documentsLoading = true);
    try {
      final docs = await widget.controller.loadAssetDocuments(_asset.id);
      if (!mounted) return;
      setState(() {
        _documents = docs;
        _asset = _asset.copyWith(hasProof: docs.isNotEmpty);
        _documentsLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _documentsLoading = false);
      _showSnack('Falha ao carregar comprovantes: $error');
    }
  }

  Future<void> _handleUploadProof() async {
    setState(() => _proofProcessing = true);
    try {
      final document = await widget.controller.uploadProof(_asset.id);
      if (!mounted) return;
      if (document != null) {
        setState(() {
          _documents = [document, ..._documents];
          _asset = _asset.copyWith(hasProof: true);
        });
        _showSnack('Comprovante protegido no cofre.');
      }
    } catch (error) {
      if (!mounted) return;
      _showSnack('Falha ao anexar comprovante: $error');
    } finally {
      if (mounted) setState(() => _proofProcessing = false);
    }
  }

  Future<void> _handleDownloadProof(AssetDocumentModel document) async {
    String? factor;
    if (_requiresHighSecurity) {
      factor = await _requestStepUp('baixar este comprovante');
      if (!mounted || factor == null) return;
    }
    setState(() => _documentActions.add(document.id));
    try {
      final savedPath = await widget.controller.downloadProof(
        document,
        factorUsed: factor,
      );
      if (!mounted) return;
      _showSnack('Comprovante salvo em $savedPath');
    } catch (error) {
      if (!mounted) return;
      _showSnack('Falha ao baixar comprovante: $error');
    } finally {
      if (mounted) {
        setState(() => _documentActions.remove(document.id));
      }
    }
  }

  Future<void> _confirmRemoveProof(AssetDocumentModel document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1F24),
          title: const Text('Remover comprovante?'),
          content: const Text(
            'O arquivo será deletado do cofre criptografado. Essa ação não pode ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Remover'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await _handleRemoveProof(document);
    }
  }

  Future<void> _handleRemoveProof(AssetDocumentModel document) async {
    setState(() => _documentActions.add(document.id));
    try {
      await widget.controller.removeProof(document);
      if (!mounted) return;
      setState(() {
        _documents = _documents
            .where((entry) => entry.id != document.id)
            .toList(growable: false);
        _asset = _asset.copyWith(hasProof: _documents.isNotEmpty);
      });
      _showSnack('Comprovante removido.');
    } catch (error) {
      if (!mounted) return;
      _showSnack('Não foi possível remover: $error');
    } finally {
      if (mounted) {
        setState(() => _documentActions.remove(document.id));
      }
    }
  }

  Widget _buildBadges(ThemeData theme) {
    final chips = <Widget>[
      _buildBadgeChip(
        theme,
        icon: Icons.verified_user_outlined,
        label: _asset.status.label,
      ),
      _buildBadgeChip(
        theme,
        icon: Icons.currency_exchange,
        label: _asset.valueCurrency,
      ),
      _buildBadgeChip(
        theme,
        icon: Icons.pie_chart_outline,
        label: '${_asset.ownershipPercentage.toStringAsFixed(0)}% posse',
      ),
    ];
    if (_asset.valueUnknown) {
      chips.add(
        _buildBadgeChip(
          theme,
          icon: Icons.help_outline,
          label: 'Valor em aberto',
          color: Colors.orangeAccent,
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  Widget _buildFinancialSummary(ThemeData theme, NumberFormat formatter) {
    final primaryValue = _asset.valueUnknown
        ? 'Valor desconhecido'
        : formatter.format(_asset.valueEstimated ?? 0);
    final portion = _asset.valuePortion;
    final portionLabel = portion == null ? '--' : formatter.format(portion);
    final fxLabel = _asset.valueCurrency == 'BRL'
        ? 'Conversão não necessária'
        : 'Aguardando conversão para BRL';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2024),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumo financeiro', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _SummaryMetric(
            label: 'Valor estimado',
            value: primaryValue,
            subtitle: _asset.valueUnknown
                ? 'Tudo bem, você pode preencher depois.'
                : null,
          ),
          const SizedBox(height: 12),
          _SummaryMetric(
            label: 'Quota proporcional',
            value: portionLabel,
          ),
          const SizedBox(height: 12),
          _SummaryMetric(
            label: 'Conversão BRL',
            value: fxLabel,
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionBlock(ThemeData theme) {
    final description = _asset.description?.trim();
    final hasDescription = description != null && description.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1F23),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Descrição e notas', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            hasDescription
                ? description
                : 'Nenhuma anotação adicionada até o momento.',
            style: hasDescription
                ? theme.textTheme.bodyMedium
                : theme.textTheme.bodyMedium?.copyWith(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(ThemeData theme) {
    final dateFormat = DateFormat('dd/MM/yyyy • HH:mm', 'pt_BR');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2024),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Timeline de auditoria', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _TimelineEntry(
            icon: Icons.bolt_outlined,
            title: 'Cadastro do bem',
            subtitle: 'Por você',
            dateLabel: dateFormat.format(_asset.createdAt),
          ),
          const SizedBox(height: 12),
          _TimelineEntry(
            icon: Icons.update,
            title: 'Última atualização',
            subtitle: 'Por você',
            dateLabel: dateFormat.format(_asset.updatedAt),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeChip(
    ThemeData theme, {
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Chip(
      backgroundColor:
          theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      avatar: Icon(icon, size: 16, color: color ?? Colors.white70),
      label: Text(label),
    );
  }

  Widget _buildProofSection(ThemeData theme) {
    final statusColor = _asset.hasProof
        ? Colors.greenAccent.withValues(alpha: 0.24)
        : Colors.orangeAccent.withValues(alpha: 0.16);
    final statusLabel = _asset.hasProof ? 'Comprovado' : 'Pendente';
    final dateFormat = DateFormat('dd/MM/yyyy • HH:mm', 'pt_BR');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2024),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.lock_outline, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comprovantes criptografados',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Armazene recibos e notas no cofre zero-knowledge. Apenas você consegue descriptografar.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _proofProcessing ? null : _handleUploadProof,
            icon: _proofProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_rounded),
            label: Text(_asset.hasProof
                ? 'Adicionar novo comprovante'
                : 'Anexar comprovante'),
          ),
          const SizedBox(height: 16),
          _buildDocumentsList(theme, dateFormat),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _openProofsVault(context),
              icon: const Icon(Icons.folder_copy_outlined),
              label: const Text('Abrir cofre completo'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList(ThemeData theme, DateFormat dateFormat) {
    if (_documentsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_documents.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Nenhum comprovante enviado ainda. Adicione para destravar os KPIs de confiança.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return Column(
      children: _documents
          .map((doc) => _buildDocumentTile(theme, dateFormat, doc))
          .toList(growable: false),
    );
  }

  Widget _buildDocumentTile(
    ThemeData theme,
    DateFormat dateFormat,
    AssetDocumentModel document,
  ) {
    final isBusy = _documentActions.contains(document.id);
    final fileLabel = (document.fileType ?? 'arquivo').toUpperCase();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2429),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.description_outlined, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$fileLabel · ID ${document.id}',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  dateFormat.format(document.uploadedAt),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (isBusy)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _handleDownloadProof(document),
                  tooltip: 'Baixar comprovante',
                  icon: const Icon(Icons.download_rounded),
                ),
                IconButton(
                  onPressed: () => _confirmRemoveProof(document),
                  tooltip: 'Remover comprovante',
                  color: theme.colorScheme.error,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openProofsVault(BuildContext context) {
    Navigator.of(context).pushNamed(
      '/bens/${_asset.id}/comprovantes',
      arguments: AssetProofsEntryArgs(
        controller: widget.controller,
        asset: _asset,
      ),
    );
  }

  Future<bool> _attemptArchiveFallback(
    AssetsController controller,
    ScaffoldMessengerState messenger,
    String? factor,
    Object error,
  ) async {
    if (!_isConstraintViolation(error)) {
      return false;
    }
    await controller.logDeleteFallbackEvent(
      assetId: _asset.id,
      constraintCode: _constraintCode(error),
      message: error.toString(),
    );
    try {
      await controller.archiveAsset(
        _asset.id,
        factorUsed: factor,
      );
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Encontramos dependências ligadas a este bem. Arquivamos para preservar o histórico.',
          ),
        ),
      );
      return true;
    } catch (archiveError) {
      messenger.showSnackBar(
        SnackBar(content: Text('Falha ao arquivar: $archiveError')),
      );
      return false;
    }
  }

  bool _isConstraintViolation(Object error) {
    if (error is PostgrestException) {
      final code = error.code?.toUpperCase();
      if (code == '23503' || code == '23505') {
        return true;
      }
      final details = (error.details as String?)?.toLowerCase() ?? '';
      if (details.contains('violates foreign key constraint')) {
        return true;
      }
      final message = error.message.toLowerCase();
      return message.contains('constraint');
    }
    return false;
  }

  String? _constraintCode(Object error) {
    if (error is PostgrestException) {
      return error.code;
    }
    return null;
  }
}

class AssetDetailEntryScreen extends StatefulWidget {
  const AssetDetailEntryScreen({super.key});

  @override
  State<AssetDetailEntryScreen> createState() => _AssetDetailEntryScreenState();
}

class _AssetDetailEntryScreenState extends State<AssetDetailEntryScreen> {
  bool _hasOpenedSheet = false;
  AssetDetailEntryArgs? _args;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasOpenedSheet) return;
    _hasOpenedSheet = true;
    final incoming = ModalRoute.of(context)?.settings.arguments;
    if (incoming is AssetDetailEntryArgs) {
      _args = incoming;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final resolvedArgs = _args;
      if (resolvedArgs == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Fluxo inválido. Abra os detalhes pela lista de bens.')),
        );
        if (mounted) Navigator.of(context).maybePop();
        return;
      }
      await showAssetDetailSheet(
        context,
        resolvedArgs.asset,
        controller: resolvedArgs.controller,
      );
      if (!mounted) return;
      Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(backgroundColor: Colors.transparent);
  }
}

class AssetDetailEntryArgs {
  const AssetDetailEntryArgs({required this.controller, required this.asset});

  final AssetsController controller;
  final AssetModel asset;
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    this.subtitle,
  });

  final String label;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleMedium),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.dateLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.bodyLarge),
              Text(subtitle, style: theme.textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(dateLabel, style: theme.textTheme.labelSmall),
            ],
          ),
        ),
      ],
    );
  }
}
