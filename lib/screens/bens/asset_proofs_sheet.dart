import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/asset_model.dart';
import '../common/step_up_prompt.dart';
import 'asset_security.dart';
import 'assets_controller.dart';

Future<void> showAssetProofsSheet(
  BuildContext context,
  AssetModel asset, {
  AssetsController? controller,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF161A1E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (ctx) {
      final resolvedController =
          controller ?? Provider.of<AssetsController>(ctx, listen: false);
      return AssetProofsSheet(asset: asset, controller: resolvedController);
    },
  );
}

class AssetProofsSheet extends StatefulWidget {
  const AssetProofsSheet(
      {super.key, required this.asset, required this.controller});

  final AssetModel asset;
  final AssetsController controller;

  @override
  State<AssetProofsSheet> createState() => _AssetProofsSheetState();
}

class _AssetProofsSheetState extends State<AssetProofsSheet> {
  late AssetModel _asset;
  List<AssetDocumentModel> _documents = const <AssetDocumentModel>[];
  bool _documentsLoading = true;
  bool _uploading = false;
  final Set<int> _documentBusy = <int>{};

  bool get _requiresHighSecurity => requiresHighSecurityForAsset(_asset);

  @override
  void initState() {
    super.initState();
    _asset = widget.asset;
    final cached = widget.controller.documentsFor(_asset.id);
    if (cached.isNotEmpty) {
      _documents = cached;
      _documentsLoading = false;
    }
    _refreshDocuments();
  }

  Future<void> _refreshDocuments() async {
    setState(() => _documentsLoading = true);
    try {
      final docs = await widget.controller.loadAssetDocuments(_asset.id);
      if (!mounted) return;
      setState(() {
        _documents = docs;
        _documentsLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      _documentsLoading = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao carregar comprovantes: $error')),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cofre de comprovantes',
                        style: theme.textTheme.titleLarge,
                      ),
                      Text(
                        _asset.title,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Faça upload, baixe ou remova documentos criptografados deste bem.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _uploading ? null : _handleUpload,
              icon: _uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_outlined),
              label: const Text('Adicionar comprovante'),
            ),
            const SizedBox(height: 16),
            _buildDocumentsList(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsList(ThemeData theme) {
    final dateFormat = DateFormat('dd/MM/yyyy • HH:mm', 'pt_BR');
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
          'Nenhum comprovante adicionado ainda.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }
    return Column(
      children: _documents
          .map(
            (doc) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.description_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${(doc.fileType ?? 'arquivo').toUpperCase()} · ID ${doc.id}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          dateFormat.format(doc.uploadedAt),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (_documentBusy.contains(doc.id))
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
                          tooltip: 'Baixar',
                          icon: const Icon(Icons.download_rounded),
                          onPressed: () => _handleDownload(doc),
                        ),
                        IconButton(
                          tooltip: 'Remover',
                          icon: const Icon(Icons.delete_outline),
                          color: theme.colorScheme.error,
                          onPressed: () => _confirmRemoval(doc),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Future<void> _handleUpload() async {
    setState(() => _uploading = true);
    try {
      final document = await widget.controller.uploadProof(_asset.id);
      if (!mounted) return;
      if (document != null) {
        setState(() {
          _documents = [document, ..._documents];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comprovante protegido no cofre.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível anexar: $error')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _handleDownload(AssetDocumentModel document) async {
    String? factor;
    if (_requiresHighSecurity) {
      factor = await showStepUpPrompt(
        context: context,
        actionLabel: 'baixar este comprovante',
      );
      if (!mounted || factor == null) return;
    }
    setState(() => _documentBusy.add(document.id));
    try {
      final savedPath =
          await widget.controller.downloadProof(document, factorUsed: factor);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Comprovante salvo em $savedPath')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao baixar: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _documentBusy.remove(document.id));
      }
    }
  }

  Future<void> _confirmRemoval(AssetDocumentModel document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F24),
        title: const Text('Remover comprovante?'),
        content: const Text(
            'O arquivo será deletado do cofre criptografado e essa ação não pode ser desfeita.'),
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
      ),
    );
    if (confirmed == true) {
      await _handleRemove(document);
    }
  }

  Future<void> _handleRemove(AssetDocumentModel document) async {
    setState(() => _documentBusy.add(document.id));
    try {
      await widget.controller.removeProof(document);
      if (!mounted) return;
      setState(() {
        _documents =
            _documents.where((entry) => entry.id != document.id).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comprovante removido.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível remover: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _documentBusy.remove(document.id));
      }
    }
  }
}

class AssetProofsEntryScreen extends StatefulWidget {
  const AssetProofsEntryScreen({super.key});

  @override
  State<AssetProofsEntryScreen> createState() => _AssetProofsEntryScreenState();
}

class _AssetProofsEntryScreenState extends State<AssetProofsEntryScreen> {
  bool _hasOpened = false;
  AssetProofsEntryArgs? _args;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasOpened) return;
    _hasOpened = true;
    final incoming = ModalRoute.of(context)?.settings.arguments;
    if (incoming is AssetProofsEntryArgs) {
      _args = incoming;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final resolvedArgs = _args;
      if (resolvedArgs == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Fluxo inválido. Abra pela lista de bens.')),
        );
        if (mounted) Navigator.of(context).maybePop();
        return;
      }
      await showAssetProofsSheet(
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

class AssetProofsEntryArgs {
  const AssetProofsEntryArgs({required this.controller, required this.asset});

  final AssetsController controller;
  final AssetModel asset;
}
