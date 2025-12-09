import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/document_model.dart';
import 'documents_controller.dart';

/// Painel para visualizar e gerenciar a fila de upload.
class DocumentQueuePanel extends StatelessWidget {
  const DocumentQueuePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Consumer<DocumentsController>(
                builder: (context, controller, _) {
                  if (controller.uploadQueue.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: controller.uploadQueue.length,
                    itemBuilder: (context, index) {
                      final entry = controller.uploadQueue[index];
                      return _QueueEntryCard(entry: entry);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_upload,
            color: Color(0xFFFFB74D),
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'Fila de Upload',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.green.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Fila vazia',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Todos os uploads foram concluídos',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueEntryCard extends StatelessWidget {
  const _QueueEntryCard({required this.entry});

  final DocumentQueueEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _borderColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatusIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Documento #${entry.documentId}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _statusText,
                      style: TextStyle(
                        color: _borderColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _buildActions(context),
            ],
          ),
          if (entry.retryReason != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.retryReason!,
                      style: TextStyle(
                        color: Colors.red.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildMetadata(),
        ],
      ),
    );
  }

  Color get _borderColor {
    switch (entry.status) {
      case DocumentStatus.pendingUpload:
        return const Color(0xFFFFB74D);
      case DocumentStatus.uploading:
        return const Color(0xFF5590A8);
      case DocumentStatus.failed:
        return Colors.red;
      default:
        return const Color(0xFF66BB6A);
    }
  }

  String get _statusText {
    switch (entry.status) {
      case DocumentStatus.pendingUpload:
        if (entry.isWaitingForWifi) {
          return 'Aguardando Wi-Fi...';
        }
        return 'Na fila (${entry.retryCount}/${entry.maxRetries} tentativas)';
      case DocumentStatus.uploading:
        return 'Enviando...';
      case DocumentStatus.failed:
        return 'Falhou (${entry.retryCount}/${entry.maxRetries} tentativas)';
      default:
        return entry.status.label;
    }
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;

    switch (entry.status) {
      case DocumentStatus.pendingUpload:
        icon = entry.isWaitingForWifi ? Icons.wifi : Icons.schedule;
        color = const Color(0xFFFFB74D);
        break;
      case DocumentStatus.uploading:
        icon = Icons.cloud_upload;
        color = const Color(0xFF5590A8);
        break;
      case DocumentStatus.failed:
        icon = Icons.error;
        color = Colors.red;
        break;
      default:
        icon = Icons.check_circle;
        color = const Color(0xFF66BB6A);
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildActions(BuildContext context) {
    final controller = context.read<DocumentsController>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (entry.status == DocumentStatus.failed ||
            entry.status == DocumentStatus.pendingUpload)
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF5590A8)),
            tooltip: 'Reenviar',
            onPressed: () => controller.retryQueueEntry(entry.id),
          ),
        IconButton(
          icon: Icon(
            Icons.cancel,
            color: Colors.red.withOpacity(0.7),
          ),
          tooltip: 'Cancelar',
          onPressed: () => _confirmCancel(context, controller),
        ),
      ],
    );
  }

  Widget _buildMetadata() {
    return Row(
      children: [
        Icon(
          entry.isWaitingForWifi ? Icons.wifi : Icons.signal_cellular_alt,
          size: 14,
          color: Colors.white.withOpacity(0.5),
        ),
        const SizedBox(width: 4),
        Text(
          entry.networkPolicy == NetworkPolicy.wifiOnly
              ? 'Apenas Wi-Fi'
              : 'Qualquer rede',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 16),
        Icon(
          Icons.loop,
          size: 14,
          color: Colors.white.withOpacity(0.5),
        ),
        const SizedBox(width: 4),
        Text(
          'Prioridade: ${entry.priority}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 11,
          ),
        ),
        if (entry.lastRetryAt != null) ...[
          const SizedBox(width: 16),
          Icon(
            Icons.access_time,
            size: 14,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(width: 4),
          Text(
            _formatTime(entry.lastRetryAt!),
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    DocumentsController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F24),
        title: const Text(
          'Cancelar upload?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'O documento será marcado como falho e removido da fila.',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancelar upload'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.cancelQueueEntry(entry.id, entry.documentId);
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
