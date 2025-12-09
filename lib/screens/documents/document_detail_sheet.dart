import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/document_model.dart';
import '../common/step_up_prompt.dart';
import 'documents_controller.dart';

/// Sheet modal para detalhes e operações de documento.
class DocumentDetailSheet extends StatefulWidget {
  const DocumentDetailSheet({super.key, required this.document});

  final DocumentModel document;

  @override
  State<DocumentDetailSheet> createState() => _DocumentDetailSheetState();
}

class _DocumentDetailSheetState extends State<DocumentDetailSheet> {
  late DocumentModel _document;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _document = widget.document;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildStatusBadges(),
              const SizedBox(height: 24),
              _buildMetadataSection(),
              const SizedBox(height: 24),
              _buildTagsSection(),
              const SizedBox(height: 24),
              _buildOperationsSection(context),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _buildIcon(),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _document.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (_document.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  _document.description!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white54),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildIcon() {
    IconData icon = Icons.description;
    if (_document.mimeType != null) {
      if (_document.mimeType!.contains('pdf')) {
        icon = Icons.picture_as_pdf;
      } else if (_document.mimeType!.contains('image')) {
        icon = Icons.image;
      }
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF5590A8).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: const Color(0xFF5590A8), size: 32),
    );
  }

  Widget _buildStatusBadges() {
    return Row(
      children: [
        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_statusIcon, size: 16, color: _statusColor),
              const SizedBox(width: 6),
              Text(
                _document.status.label,
                style: TextStyle(
                  color: _statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Expiry badge
        if (_document.expiresSoon || _document.isExpired)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (_document.isExpired ? Colors.red : Colors.orange)
                  .withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: _document.isExpired ? Colors.red : Colors.orange,
                ),
                const SizedBox(width: 6),
                Text(
                  _document.isExpired ? 'Expirado' : 'Expira em breve',
                  style: TextStyle(
                    color: _document.isExpired ? Colors.red : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Color get _statusColor {
    switch (_document.status) {
      case DocumentStatus.pendingUpload:
      case DocumentStatus.uploading:
        return const Color(0xFFFFB74D);
      case DocumentStatus.encrypted:
      case DocumentStatus.available:
        return const Color(0xFF66BB6A);
      case DocumentStatus.failed:
        return Colors.red;
    }
  }

  IconData get _statusIcon {
    switch (_document.status) {
      case DocumentStatus.pendingUpload:
      case DocumentStatus.uploading:
        return Icons.upload;
      case DocumentStatus.encrypted:
      case DocumentStatus.available:
        return Icons.lock;
      case DocumentStatus.failed:
        return Icons.error;
    }
  }

  Widget _buildMetadataSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Metadados',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          _metadataRow('Tamanho', _document.formattedSize),
          _metadataRow('Tipo', _document.mimeType ?? '—'),
          if (_document.checksum != null)
            _metadataRow(
              'Checksum',
              '${_document.checksum!.substring(0, 16)}...',
            ),
          _metadataRow(
            'Criado em',
            _formatDate(_document.createdAt),
          ),
          _metadataRow(
            'Atualizado em',
            _formatDate(_document.updatedAt),
          ),
          if (_document.lastAccessedAt != null)
            _metadataRow(
              'Último acesso',
              _formatDate(_document.lastAccessedAt!),
            ),
          if (_document.expiresAt != null)
            _metadataRow(
              'Expira em',
              _formatDate(_document.expiresAt!),
            ),
        ],
      ),
    );
  }

  Widget _metadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _document.tags.map((tag) {
            final isSensitive = DocumentTags.isSensitive(tag);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF5590A8).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: isSensitive
                    ? Border.all(color: Colors.orange.withOpacity(0.5))
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSensitive) ...[
                    Icon(
                      Icons.shield,
                      size: 14,
                      color: Colors.orange.withOpacity(0.8),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    tag,
                    style: const TextStyle(
                      color: Color(0xFF5590A8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOperationsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Operações',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        _operationTile(
          icon: Icons.download,
          label: 'Baixar documento',
          color: const Color(0xFF5590A8),
          onTap: () => _handleDownload(context),
          enabled: _document.status.isReady,
        ),
        _operationTile(
          icon: Icons.share,
          label: 'Compartilhar link seguro',
          color: const Color(0xFF5590A8),
          onTap: () => _handleShare(context),
          enabled: _document.status == DocumentStatus.available &&
              !_document.isExpired,
        ),
        _operationTile(
          icon: Icons.edit,
          label: 'Editar informações',
          color: const Color(0xFF7AB8C9),
          onTap: () => _handleEdit(context),
        ),
        const Divider(color: Colors.white12, height: 24),
        _operationTile(
          icon: Icons.delete_outline,
          label: 'Remover documento',
          color: Colors.red,
          onTap: () => _handleDelete(context),
        ),
      ],
    );
  }

  Widget _operationTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: enabled ? Colors.white : Colors.white54,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.white.withOpacity(0.3),
        ),
        onTap: enabled ? onTap : null,
      ),
    );
  }

  Future<void> _handleDownload(BuildContext context) async {
    final controller = context.read<DocumentsController>();
    String? factorUsed;

    // Step-up para tags sensíveis
    if (controller.requiresStepUp(_document)) {
      factorUsed = await showStepUpPrompt(
        context: context,
        actionLabel: 'Baixar documento',
      );
      if (factorUsed == null) return;
    }

    setState(() => _isLoading = true);

    try {
      await controller.recordDocumentAccess(
        _document.id,
        factorUsed: factorUsed,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download iniciado'),
            backgroundColor: Color(0xFF5590A8),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleShare(BuildContext context) async {
    // TODO: Implementar compartilhamento com signed URL
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Compartilhamento será implementado em breve'),
        backgroundColor: Color(0xFFFFB74D),
      ),
    );
  }

  Future<void> _handleEdit(BuildContext context) async {
    // TODO: Implementar edição
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edição será implementada em breve'),
        backgroundColor: Color(0xFFFFB74D),
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F24),
        title: const Text(
          'Excluir documento?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Esta ação excluirá permanentemente "${_document.title}". Deseja continuar?',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final controller = context.read<DocumentsController>();
    String? factorUsed;

    if (controller.requiresStepUp(_document)) {
      factorUsed = await showStepUpPrompt(
        context: context,
        actionLabel: 'Excluir documento',
      );
      if (factorUsed == null) return;
    }

    setState(() => _isLoading = true);

    try {
      await controller.deleteDocument(_document.id, factorUsed: factorUsed);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documento excluído'),
            backgroundColor: Color(0xFF66BB6A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
