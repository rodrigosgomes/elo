import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/document_model.dart';
import '../../services/documents_repository.dart';
import '../../services/document_encryption_service.dart';

/// Controller para gerenciamento de estado do Cofre de Documentos.
class DocumentsController extends ChangeNotifier {
  DocumentsController({
    required DocumentsRepository repository,
    DocumentEncryptionService? encryptionService,
  })  : _repository = repository,
        _encryptionService = encryptionService ??
            DocumentEncryptionService(userId: repository.currentUserId);

  final DocumentsRepository _repository;
  final DocumentEncryptionService _encryptionService;

  static const int pageSize = 50;

  // Estado
  List<DocumentModel> _documents = [];
  List<DocumentModel> get documents => List.unmodifiable(_documents);

  List<DocumentQueueEntry> _uploadQueue = [];
  List<DocumentQueueEntry> get uploadQueue => List.unmodifiable(_uploadQueue);

  DocumentVaultSummary _summary = DocumentVaultSummary.empty;
  DocumentVaultSummary get summary => _summary;

  DocumentFilters _filters = const DocumentFilters();
  DocumentFilters get filters => _filters;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  String? _error;
  String? get error => _error;

  // Canais de tempo real
  RealtimeChannel? _documentsChannel;
  RealtimeChannel? _queueChannel;

  /// Inicializa o controller carregando dados e configurando listeners.
  Future<void> bootstrap() async {
    await Future.wait([
      refresh(),
      _loadUploadQueue(),
    ]);
    _subscribeToChannels();
  }

  /// Recarrega documentos do início.
  Future<void> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.fetchDocuments(
            filters: _filters, limit: pageSize, offset: 0),
        _repository.fetchSummary(),
      ]);

      _documents = results[0] as List<DocumentModel>;
      _summary = results[1] as DocumentVaultSummary;
      _hasMore = _documents.length >= pageSize;
    } catch (e) {
      _error = 'Erro ao carregar documentos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega mais documentos (paginação).
  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      final nextPage = await _repository.fetchDocuments(
        filters: _filters,
        limit: pageSize,
        offset: _documents.length,
      );

      _documents = [..._documents, ...nextPage];
      _hasMore = nextPage.length >= pageSize;
    } catch (e) {
      _error = 'Erro ao carregar mais documentos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega a fila de upload.
  Future<void> _loadUploadQueue() async {
    try {
      _uploadQueue = await _repository.fetchUploadQueue();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar fila de upload: $e');
    }
  }

  /// Atualiza termo de busca com debounce.
  Timer? _searchDebounce;
  void updateSearchTerm(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _filters = _filters.copyWith(searchTerm: value.isEmpty ? null : value);
      refresh();
    });
  }

  /// Alterna seleção de tag nos filtros.
  void toggleTagFilter(String tag) {
    final current = List<String>.from(_filters.selectedTags);
    if (current.contains(tag)) {
      current.remove(tag);
    } else {
      current.add(tag);
    }
    _filters = _filters.copyWith(selectedTags: current);
    refresh();
  }

  /// Define ordenação.
  void setSortBy(DocumentSortBy sortBy) {
    if (_filters.sortBy == sortBy) return;
    _filters = _filters.copyWith(sortBy: sortBy);
    refresh();
  }

  /// Aplica filtros avançados.
  void applyFilters(DocumentFilters next) {
    _filters = next;
    refresh();
  }

  /// Limpa todos os filtros.
  void clearFilters() {
    _filters = const DocumentFilters();
    refresh();
  }

  /// Inicia upload de documentos.
  Future<void> startUpload({
    required List<DocumentUploadInput> inputs,
  }) async {
    for (var i = 0; i < inputs.length; i++) {
      final input = inputs[i];

      try {
        // 1. Criar placeholder no banco
        final doc = await _repository.insertDocument(input.documentInput);

        // 2. Criar entrada na fila
        await _repository.insertQueueEntry(
          documentId: doc.id,
          networkPolicy: input.documentInput.networkPolicy,
          priority: i,
          offlineBlobChecksum: null, // Será preenchido após criptografia
        );

        // 3. Registrar evento
        await _repository.insertTrustEvent(
          eventType: 'DOC_UPLOAD_STARTED',
          description: 'Upload iniciado: ${doc.title}',
          metadata: {
            'document_id': doc.id,
            'file_name': input.fileName,
            'tags': doc.tags,
          },
        );

        // Atualizar UI imediatamente
        _documents = [doc, ..._documents];
        notifyListeners();
      } catch (e) {
        _error = 'Erro ao iniciar upload: $e';
        notifyListeners();
      }
    }

    // Recarregar fila
    await _loadUploadQueue();
  }

  /// Atualiza documento existente.
  Future<void> updateDocument({
    required int documentId,
    required DocumentInput input,
  }) async {
    try {
      final updated = await _repository.updateDocument(
        documentId: documentId,
        input: input,
      );

      // Atualizar na lista local
      final index = _documents.indexWhere((d) => d.id == documentId);
      if (index >= 0) {
        _documents = List.from(_documents)..[index] = updated;
        notifyListeners();
      }

      await _repository.insertTrustEvent(
        eventType: 'DOC_UPDATED',
        description: 'Documento atualizado: ${updated.title}',
        metadata: {'document_id': documentId},
      );
    } catch (e) {
      _error = 'Erro ao atualizar documento: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Exclui documento (soft delete).
  Future<void> deleteDocument(int documentId, {String? factorUsed}) async {
    try {
      // Encontrar documento para metadata
      final doc = _documents.firstWhere((d) => d.id == documentId);

      await _repository.softDeleteDocument(documentId);

      // Remover da lista local
      _documents = _documents.where((d) => d.id != documentId).toList();
      notifyListeners();

      // Registrar eventos
      await _repository.insertTrustEvent(
        eventType: 'DOC_DELETED',
        description: 'Documento excluído: ${doc.title}',
        metadata: {'document_id': documentId, 'tags': doc.tags},
      );

      if (factorUsed != null) {
        await _repository.insertStepUpEvent(
          eventType: 'DOC_DELETE_STEP_UP',
          factorUsed: factorUsed,
          metadata: {'document_id': documentId},
        );
      }

      // Atualizar summary
      _summary = await _repository.fetchSummary();
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao excluir documento: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Registra acesso ao documento (download/visualização).
  Future<void> recordDocumentAccess(int documentId,
      {String? factorUsed}) async {
    try {
      await _repository.updateLastAccessed(documentId);

      final doc = _documents.firstWhere((d) => d.id == documentId);

      await _repository.insertTrustEvent(
        eventType: 'DOC_DOWNLOAD',
        description: 'Documento baixado: ${doc.title}',
        metadata: {'document_id': documentId},
      );

      await _repository.insertKpiMetric(
        metricType: 'DOC_DOWNLOAD',
        metadata: {'document_id': documentId},
      );

      if (factorUsed != null) {
        await _repository.insertStepUpEvent(
          eventType: 'DOC_DOWNLOAD_STEP_UP',
          factorUsed: factorUsed,
          metadata: {'document_id': documentId},
        );
      }
    } catch (e) {
      debugPrint('Erro ao registrar acesso: $e');
    }
  }

  /// Força reenvio de item da fila.
  Future<void> retryQueueEntry(int queueId) async {
    try {
      await _repository.updateQueueEntry(
        queueId: queueId,
        status: DocumentStatus.pendingUpload,
      );
      await _loadUploadQueue();
    } catch (e) {
      _error = 'Erro ao reenviar: $e';
      notifyListeners();
    }
  }

  /// Remove item da fila e marca documento como falho.
  Future<void> cancelQueueEntry(int queueId, int documentId) async {
    try {
      await _repository.deleteQueueEntry(queueId);
      await _repository.updateDocumentStatus(
        documentId: documentId,
        status: DocumentStatus.failed,
      );
      await _loadUploadQueue();
      await refresh();
    } catch (e) {
      _error = 'Erro ao cancelar: $e';
      notifyListeners();
    }
  }

  /// Verifica se documento requer step-up para operação.
  bool requiresStepUp(DocumentModel doc) {
    // Tags sensíveis requerem step-up
    return doc.tags.any((tag) => DocumentTags.isSensitive(tag));
  }

  // Configuração de canais de tempo real
  void _subscribeToChannels() {
    _documentsChannel = _repository.createDocumentsChannel(
      onInsert: _handleDocumentInsert,
      onUpdate: _handleDocumentUpdate,
      onDelete: _handleDocumentDelete,
    );

    _queueChannel = _repository.createQueueChannel(
      onChange: (_) => _loadUploadQueue(),
    );
  }

  void _handleDocumentInsert(Map<String, dynamic> payload) {
    try {
      final doc = DocumentModel.fromJson(payload);
      if (!_documents.any((d) => d.id == doc.id)) {
        _documents = [doc, ..._documents];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao processar insert: $e');
    }
  }

  void _handleDocumentUpdate(Map<String, dynamic> payload) {
    try {
      final doc = DocumentModel.fromJson(payload);
      final index = _documents.indexWhere((d) => d.id == doc.id);
      if (index >= 0) {
        _documents = List.from(_documents)..[index] = doc;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao processar update: $e');
    }
  }

  void _handleDocumentDelete(Map<String, dynamic> payload) {
    final id = payload['id'] as int?;
    if (id != null) {
      _documents = _documents.where((d) => d.id != id).toList();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _documentsChannel?.unsubscribe();
    _queueChannel?.unsubscribe();
    super.dispose();
  }
}

/// Input para upload de documento com arquivo.
@immutable
class DocumentUploadInput {
  const DocumentUploadInput({
    required this.documentInput,
    required this.fileName,
    required this.fileBytes,
  });

  final DocumentInput documentInput;
  final String fileName;
  final List<int> fileBytes;

  int get fileSizeBytes => fileBytes.length;

  bool get isValidSize => fileSizeBytes <= 10 * 1024 * 1024; // 10MB limit
}
