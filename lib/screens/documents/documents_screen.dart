import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/document_model.dart';
import '../../services/documents_repository.dart';
import '../common/vault_navigation_bar.dart';
import 'documents_controller.dart';
import 'upload_document_sheet.dart';
import 'document_detail_sheet.dart';
import 'document_queue_panel.dart';

/// Tela principal do Cofre de Documentos.
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  late DocumentsController _controller;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = DocumentsController(
      repository: DocumentsRepository(),
    );
    _controller.bootstrap();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _controller.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: SafeArea(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildHeroSection(context),
              _buildIndicatorsSection(),
              _buildFiltersSection(),
              _buildDocumentsList(),
              _buildQueueFooter(),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF5590A8),
          onPressed: () => _showUploadSheet(context),
          child: const Icon(Icons.add, color: Colors.white),
        ),
        bottomNavigationBar: const VaultNavigationBar(
          currentTab: VaultTab.documentos,
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1F24), Color(0xFF121212)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.lock,
                  color: Color(0xFF5590A8),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cofre de Documentos',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Seus documentos são criptografados localmente antes de sair do seu dispositivo. Apenas você pode acessá-los.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF5590A8).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF5590A8).withOpacity(0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified_user,
                    color: Color(0xFF5590A8),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Zero-Knowledge Encryption',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF5590A8),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorsSection() {
    return SliverToBoxAdapter(
      child: Consumer<DocumentsController>(
        builder: (context, controller, _) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _IndicatorCard(
                    icon: Icons.folder_copy,
                    label: 'Documentos',
                    value: controller.summary.totalDocuments.toString(),
                    color: const Color(0xFF5590A8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _IndicatorCard(
                    icon: Icons.storage,
                    label: 'Espaço',
                    value: controller.summary.formattedTotalSize,
                    color: const Color(0xFF7AB8C9),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _IndicatorCard(
                    icon: Icons.cloud_upload,
                    label: 'Pendentes',
                    value: controller.summary.pendingUploads.toString(),
                    color: controller.summary.pendingUploads > 0
                        ? const Color(0xFFFFB74D)
                        : const Color(0xFF66BB6A),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFiltersSection() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _FilterHeaderDelegate(
        child: Container(
          color: const Color(0xFF121212),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: Consumer<DocumentsController>(
            builder: (context, controller, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Campo de busca
                  TextField(
                    controller: _searchController,
                    onChanged: controller.updateSearchTerm,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Buscar documentos...',
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.5)),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Chips de tags
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final tag in DocumentTags.recommended)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(tag),
                              selected:
                                  controller.filters.selectedTags.contains(tag),
                              onSelected: (_) =>
                                  controller.toggleTagFilter(tag),
                              selectedColor:
                                  const Color(0xFF5590A8).withOpacity(0.3),
                              checkmarkColor: const Color(0xFF5590A8),
                              labelStyle: TextStyle(
                                color: controller.filters.selectedTags
                                        .contains(tag)
                                    ? const Color(0xFF5590A8)
                                    : Colors.white70,
                                fontSize: 12,
                              ),
                              backgroundColor: Colors.white.withOpacity(0.08),
                              side: BorderSide.none,
                            ),
                          ),
                        // Dropdown de ordenação
                        PopupMenuButton<DocumentSortBy>(
                          icon: Icon(
                            Icons.sort,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          onSelected: controller.setSortBy,
                          itemBuilder: (_) => DocumentSortBy.values
                              .map(
                                (sort) => PopupMenuItem(
                                  value: sort,
                                  child: Row(
                                    children: [
                                      if (controller.filters.sortBy == sort)
                                        const Icon(
                                          Icons.check,
                                          size: 18,
                                          color: Color(0xFF5590A8),
                                        )
                                      else
                                        const SizedBox(width: 18),
                                      const SizedBox(width: 8),
                                      Text(sort.label),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentsList() {
    return Consumer<DocumentsController>(
      builder: (context, controller, _) {
        if (controller.isLoading && controller.documents.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF5590A8),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Carregando documentos...',
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
          );
        }

        if (controller.error != null && controller.documents.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.withOpacity(0.7),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    controller.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: controller.refresh,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        if (controller.documents.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder_off,
                    size: 64,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum documento criptografado ainda',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use o botão + para adicionar',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              mainAxisExtent: 180,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= controller.documents.length) {
                  return controller.hasMore
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              color: Color(0xFF5590A8),
                            ),
                          ),
                        )
                      : null;
                }

                final doc = controller.documents[index];
                return _DocumentCard(
                  document: doc,
                  onTap: () => _showDocumentDetail(context, doc),
                );
              },
              childCount:
                  controller.documents.length + (controller.hasMore ? 1 : 0),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQueueFooter() {
    return SliverToBoxAdapter(
      child: Consumer<DocumentsController>(
        builder: (context, controller, _) {
          if (controller.uploadQueue.isEmpty) {
            return const SizedBox.shrink();
          }

          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB74D).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFB74D).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.cloud_upload,
                  color: Color(0xFFFFB74D),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${controller.uploadQueue.length} upload(s) pendente(s)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _showQueuePanel(context),
                  child: const Text(
                    'Ver fila',
                    style: TextStyle(color: Color(0xFFFFB74D)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showUploadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1F24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: _controller,
        child: const UploadDocumentSheet(),
      ),
    );
  }

  void _showDocumentDetail(BuildContext context, DocumentModel document) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1F24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: _controller,
        child: DocumentDetailSheet(document: document),
      ),
    );
  }

  void _showQueuePanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1F24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: _controller,
        child: const DocumentQueuePanel(),
      ),
    );
  }
}

/// Card de documento individual.
class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.document,
    required this.onTap,
  });

  final DocumentModel document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (document.description != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            document.description!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildStatusBadge(),
                ],
              ),
              const Spacer(),
              // Tags
              if (document.tags.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: document.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5590A8).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: Color(0xFF5590A8),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              // Metadados
              Row(
                children: [
                  Text(
                    document.formattedSize,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (document.expiresSoon) ...[
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: Colors.orange.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Expira em breve',
                      style: TextStyle(
                        color: Colors.orange.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon = Icons.description;
    if (document.mimeType != null) {
      if (document.mimeType!.contains('pdf')) {
        icon = Icons.picture_as_pdf;
      } else if (document.mimeType!.contains('image')) {
        icon = Icons.image;
      }
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF5590A8).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: const Color(0xFF5590A8),
        size: 24,
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String label;
    IconData icon;

    switch (document.status) {
      case DocumentStatus.pendingUpload:
      case DocumentStatus.uploading:
        color = const Color(0xFFFFB74D);
        label = document.status.label;
        icon = Icons.upload;
        break;
      case DocumentStatus.encrypted:
      case DocumentStatus.available:
        color = const Color(0xFF66BB6A);
        label = 'Encrypted';
        icon = Icons.lock;
        break;
      case DocumentStatus.failed:
        color = Colors.red;
        label = 'Falhou';
        icon = Icons.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de indicador.
class _IndicatorCard extends StatelessWidget {
  const _IndicatorCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Delegate para header de filtros fixo.
class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  _FilterHeaderDelegate({required this.child});

  final Widget child;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  double get maxExtent => 116;

  @override
  double get minExtent => 116;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
