import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/document_model.dart';

/// Repository para operações CRUD de documentos no Supabase.
class DocumentsRepository {
  DocumentsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Retorna o ID do usuário atual autenticado.
  String get currentUserId {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError(
        'DocumentsRepository requer usuário autenticado para operar.',
      );
    }
    return uid;
  }

  /// Carrega documentos com filtros, paginação e ordenação.
  Future<List<DocumentModel>> fetchDocuments({
    DocumentFilters filters = const DocumentFilters(),
    int limit = 50,
    int offset = 0,
  }) async {
    // Construir query base
    final baseQuery = _client
        .from('documents')
        .select()
        .eq('user_id', currentUserId)
        .isFilter('deleted_at', null);

    // Aplicar filtros, ordenação e paginação em uma única chain
    final order = _resolveOrder(filters.sortBy);

    // Executar query com todos os parâmetros
    final data = await baseQuery
        .order(order.column, ascending: order.ascending)
        .range(offset, offset + limit - 1);

    // Filtrar resultados em memória para casos complexos
    var results = (data as List<dynamic>)
        .map((row) => DocumentModel.fromJson(row as Map<String, dynamic>))
        .toList();

    // Aplicar filtros adicionais em memória se necessário
    if (filters.searchTerm != null && filters.searchTerm!.isNotEmpty) {
      final term = filters.searchTerm!.toLowerCase();
      results = results.where((doc) {
        return doc.title.toLowerCase().contains(term) ||
            (doc.description?.toLowerCase().contains(term) ?? false);
      }).toList();
    }

    if (filters.selectedTags.isNotEmpty) {
      results = results.where((doc) {
        return filters.selectedTags.any((tag) => doc.tags.contains(tag));
      }).toList();
    }

    if (filters.selectedStatuses.isNotEmpty) {
      results = results.where((doc) {
        return filters.selectedStatuses.contains(doc.status);
      }).toList();
    }

    if (filters.expiresWithinDays != null) {
      final threshold = DateTime.now().add(
        Duration(days: filters.expiresWithinDays!),
      );
      results = results.where((doc) {
        return doc.expiresAt != null && doc.expiresAt!.isBefore(threshold);
      }).toList();
    }

    return results;
  }

  /// Conta documentos por status para indicadores.
  Future<DocumentVaultSummary> fetchSummary() async {
    final userId = currentUserId;

    // Documentos criptografados/disponíveis
    final docsQuery = await _client
        .from('documents')
        .select('id, size_bytes')
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .inFilter('status', ['ENCRYPTED', 'AVAILABLE']);

    final docs = docsQuery as List<dynamic>;
    final totalDocs = docs.length;
    final totalSize = docs.fold<int>(
      0,
      (sum, row) => sum + ((row['size_bytes'] as int?) ?? 0),
    );

    // Uploads pendentes
    final queueQuery = await _client
        .from('document_upload_queue')
        .select('id')
        .eq('user_id', userId)
        .inFilter('status', ['PENDING_UPLOAD', 'UPLOADING', 'FAILED']);

    final pending = (queueQuery as List<dynamic>).length;

    return DocumentVaultSummary(
      totalDocuments: totalDocs,
      totalSizeBytes: totalSize,
      pendingUploads: pending,
    );
  }

  /// Carrega entradas da fila de upload.
  Future<List<DocumentQueueEntry>> fetchUploadQueue() async {
    final data = await _client
        .from('document_upload_queue')
        .select()
        .eq('user_id', currentUserId)
        .order('priority', ascending: true);

    return (data as List<dynamic>)
        .map((row) => DocumentQueueEntry.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Insere um novo documento (placeholder antes do upload).
  Future<DocumentModel> insertDocument(DocumentInput input) async {
    final userId = currentUserId;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final placeholderPath = '$userId/tmp/$timestamp';

    final row = await _client
        .from('documents')
        .insert({
          'user_id': userId,
          'title': input.title,
          'description': input.description,
          'storage_path': placeholderPath,
          'tags': input.tags.map((t) => t.toLowerCase()).toList(),
          'status': 'PENDING_UPLOAD',
          'expires_at': input.expiresAt?.toIso8601String(),
        })
        .select()
        .single();

    return DocumentModel.fromJson(row);
  }

  /// Cria entrada na fila de upload.
  Future<DocumentQueueEntry> insertQueueEntry({
    required int documentId,
    required NetworkPolicy networkPolicy,
    required int priority,
    String? offlineBlobChecksum,
  }) async {
    final row = await _client
        .from('document_upload_queue')
        .insert({
          'user_id': currentUserId,
          'document_id': documentId,
          'network_policy': networkPolicy.toDatabase(),
          'status': 'PENDING_UPLOAD',
          'priority': priority,
          'offline_blob_checksum': offlineBlobChecksum,
        })
        .select()
        .single();

    return DocumentQueueEntry.fromJson(row);
  }

  /// Atualiza documento após upload bem-sucedido.
  Future<DocumentModel> updateDocumentAfterUpload({
    required int documentId,
    required String storagePath,
    required int sizeBytes,
    required String mimeType,
    required String checksum,
  }) async {
    final row = await _client
        .from('documents')
        .update({
          'storage_path': storagePath,
          'size_bytes': sizeBytes,
          'mime_type': mimeType,
          'checksum': checksum,
          'status': 'ENCRYPTED',
          'encrypted_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', documentId)
        .eq('user_id', currentUserId)
        .select()
        .single();

    return DocumentModel.fromJson(row);
  }

  /// Atualiza status do documento.
  Future<void> updateDocumentStatus({
    required int documentId,
    required DocumentStatus status,
  }) async {
    await _client
        .from('documents')
        .update({
          'status': status.toDatabase(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', documentId)
        .eq('user_id', currentUserId);
  }

  /// Atualiza metadados do documento (título, descrição, tags, validade).
  Future<DocumentModel> updateDocument({
    required int documentId,
    required DocumentInput input,
  }) async {
    final row = await _client
        .from('documents')
        .update({
          ...input.toJson(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', documentId)
        .eq('user_id', currentUserId)
        .select()
        .single();

    return DocumentModel.fromJson(row);
  }

  /// Atualiza last_accessed_at ao baixar documento.
  Future<void> updateLastAccessed(int documentId) async {
    await _client
        .from('documents')
        .update({
          'last_accessed_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', documentId)
        .eq('user_id', currentUserId);
  }

  /// Soft delete de documento (define deleted_at).
  Future<void> softDeleteDocument(int documentId) async {
    await _client
        .from('documents')
        .update({
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', documentId)
        .eq('user_id', currentUserId);
  }

  /// Remove entrada da fila de upload.
  Future<void> deleteQueueEntry(int queueId) async {
    await _client
        .from('document_upload_queue')
        .delete()
        .eq('id', queueId)
        .eq('user_id', currentUserId);
  }

  /// Atualiza entrada da fila após tentativa de upload.
  Future<void> updateQueueEntry({
    required int queueId,
    required DocumentStatus status,
    String? retryReason,
    bool incrementRetry = false,
  }) async {
    final updates = <String, dynamic>{
      'status': status.toDatabase(),
      'last_retry_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (retryReason != null) {
      updates['retry_reason'] = retryReason;
    }

    if (incrementRetry) {
      // Supabase não suporta increment diretamente, fazemos via RPC ou busca+update
      final current = await _client
          .from('document_upload_queue')
          .select('retry_count')
          .eq('id', queueId)
          .single();
      updates['retry_count'] = (current['retry_count'] as int? ?? 0) + 1;
    }

    await _client
        .from('document_upload_queue')
        .update(updates)
        .eq('id', queueId)
        .eq('user_id', currentUserId);
  }

  /// Registra evento de confiança.
  Future<void> insertTrustEvent({
    required String eventType,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    await _client.from('trust_events').insert({
      'user_id': currentUserId,
      'event_type': eventType,
      'description': description,
      'metadata': metadata,
    });
  }

  /// Registra métrica KPI.
  Future<void> insertKpiMetric({
    required String metricType,
    double metricValue = 1,
    Map<String, dynamic>? metadata,
  }) async {
    await _client.from('kpi_metrics').insert({
      'user_id': currentUserId,
      'metric_type': metricType,
      'metric_value': metricValue,
      'metadata': metadata,
    });
  }

  /// Registra evento de step-up.
  Future<void> insertStepUpEvent({
    required String eventType,
    required String factorUsed,
    bool success = true,
    Map<String, dynamic>? metadata,
  }) async {
    await _client.from('step_up_events').insert({
      'user_id': currentUserId,
      'event_type': eventType,
      'factor_used': factorUsed,
      'success': success,
      'related_resource': 'documents',
      'metadata': metadata,
    });
  }

  /// Busca eventos de confiança relacionados a um documento.
  Future<List<Map<String, dynamic>>> fetchDocumentTrustEvents(
    int documentId, {
    int limit = 20,
  }) async {
    final data = await _client
        .from('trust_events')
        .select()
        .eq('user_id', currentUserId)
        .contains('metadata', {'document_id': documentId})
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List<dynamic>).cast<Map<String, dynamic>>();
  }

  /// Cria canal de escuta para mudanças em tempo real.
  RealtimeChannel createDocumentsChannel({
    required void Function(Map<String, dynamic> payload) onInsert,
    required void Function(Map<String, dynamic> payload) onUpdate,
    required void Function(Map<String, dynamic> payload) onDelete,
  }) {
    return _client
        .channel('public:documents')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'documents',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentUserId,
          ),
          callback: (payload) => onInsert(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'documents',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentUserId,
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'documents',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentUserId,
          ),
          callback: (payload) => onDelete(payload.oldRecord),
        )
        .subscribe();
  }

  /// Cria canal de escuta para mudanças na fila de upload.
  RealtimeChannel createQueueChannel({
    required void Function(Map<String, dynamic> payload) onChange,
  }) {
    return _client
        .channel('public:document_upload_queue')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'document_upload_queue',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentUserId,
          ),
          callback: (payload) => onChange(payload.newRecord),
        )
        .subscribe();
  }
}

/// Representa ordenação de documentos para query.
@immutable
class _DocumentOrder {
  const _DocumentOrder({required this.column, required this.ascending});
  final String column;
  final bool ascending;
}

_DocumentOrder _resolveOrder(DocumentSortBy sortBy) {
  return _DocumentOrder(
    column: sortBy.orderByColumn,
    ascending: sortBy.ascending,
  );
}
