import 'package:flutter/foundation.dart';

/// Status de um documento no cofre.
enum DocumentStatus {
  pendingUpload,
  uploading,
  encrypted,
  available,
  failed;

  /// Converte do valor armazenado no Supabase.
  static DocumentStatus fromDatabase(String value) {
    switch (value) {
      case 'PENDING_UPLOAD':
        return DocumentStatus.pendingUpload;
      case 'UPLOADING':
        return DocumentStatus.uploading;
      case 'ENCRYPTED':
        return DocumentStatus.encrypted;
      case 'AVAILABLE':
        return DocumentStatus.available;
      case 'FAILED':
        return DocumentStatus.failed;
      default:
        throw ArgumentError('Unknown document status: $value');
    }
  }

  /// Converte para o valor do banco de dados.
  String toDatabase() {
    switch (this) {
      case DocumentStatus.pendingUpload:
        return 'PENDING_UPLOAD';
      case DocumentStatus.uploading:
        return 'UPLOADING';
      case DocumentStatus.encrypted:
        return 'ENCRYPTED';
      case DocumentStatus.available:
        return 'AVAILABLE';
      case DocumentStatus.failed:
        return 'FAILED';
    }
  }

  /// Rótulo para exibição na UI.
  String get label {
    switch (this) {
      case DocumentStatus.pendingUpload:
        return 'Aguardando';
      case DocumentStatus.uploading:
        return 'Enviando';
      case DocumentStatus.encrypted:
        return 'Criptografado';
      case DocumentStatus.available:
        return 'Disponível';
      case DocumentStatus.failed:
        return 'Falhou';
    }
  }

  /// Indica se o documento está em processo de upload.
  bool get isProcessing =>
      this == DocumentStatus.pendingUpload || this == DocumentStatus.uploading;

  /// Indica se o documento está pronto para uso.
  bool get isReady =>
      this == DocumentStatus.encrypted || this == DocumentStatus.available;
}

/// Política de rede para upload.
enum NetworkPolicy {
  any,
  wifiOnly;

  static NetworkPolicy fromDatabase(String? value) {
    if (value == 'WIFI_ONLY') return NetworkPolicy.wifiOnly;
    return NetworkPolicy.any;
  }

  String toDatabase() {
    switch (this) {
      case NetworkPolicy.any:
        return 'ANY';
      case NetworkPolicy.wifiOnly:
        return 'WIFI_ONLY';
    }
  }
}

/// Modelo de documento do cofre.
@immutable
class DocumentModel {
  const DocumentModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.storagePath,
    this.sizeBytes,
    this.mimeType,
    required this.tags,
    required this.status,
    this.expiresAt,
    this.encryptedAt,
    this.checksum,
    this.lastAccessedAt,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String userId;
  final String title;
  final String? description;
  final String storagePath;
  final int? sizeBytes;
  final String? mimeType;
  final List<String> tags;
  final DocumentStatus status;
  final DateTime? expiresAt;
  final DateTime? encryptedAt;
  final String? checksum;
  final DateTime? lastAccessedAt;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Tag principal (primeira da lista) usada como "coleção".
  String? get primaryTag => tags.isNotEmpty ? tags.first : null;

  /// Verifica se o documento expira em breve (30 dias).
  bool get expiresSoon {
    if (expiresAt == null) return false;
    final threshold = DateTime.now().add(const Duration(days: 30));
    return expiresAt!.isBefore(threshold);
  }

  /// Verifica se o documento já expirou.
  bool get isExpired {
    if (expiresAt == null) return false;
    return expiresAt!.isBefore(DateTime.now());
  }

  /// Tamanho formatado para exibição (KB, MB, etc).
  String get formattedSize {
    if (sizeBytes == null) return '—';
    if (sizeBytes! < 1024) return '$sizeBytes B';
    if (sizeBytes! < 1024 * 1024) {
      return '${(sizeBytes! / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes! / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      storagePath: json['storage_path'] as String,
      sizeBytes: json['size_bytes'] as int?,
      mimeType: json['mime_type'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      status: DocumentStatus.fromDatabase(json['status'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      encryptedAt: json['encrypted_at'] != null
          ? DateTime.parse(json['encrypted_at'] as String)
          : null,
      checksum: json['checksum'] as String?,
      lastAccessedAt: json['last_accessed_at'] != null
          ? DateTime.parse(json['last_accessed_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  DocumentModel copyWith({
    int? id,
    String? userId,
    String? title,
    String? description,
    String? storagePath,
    int? sizeBytes,
    String? mimeType,
    List<String>? tags,
    DocumentStatus? status,
    DateTime? expiresAt,
    DateTime? encryptedAt,
    String? checksum,
    DateTime? lastAccessedAt,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      storagePath: storagePath ?? this.storagePath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      mimeType: mimeType ?? this.mimeType,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      encryptedAt: encryptedAt ?? this.encryptedAt,
      checksum: checksum ?? this.checksum,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Entrada na fila de upload de documentos.
@immutable
class DocumentQueueEntry {
  const DocumentQueueEntry({
    required this.id,
    required this.userId,
    required this.documentId,
    required this.retryCount,
    this.lastRetryAt,
    required this.networkPolicy,
    required this.status,
    required this.maxRetries,
    this.retryReason,
    this.offlineBlobChecksum,
    required this.priority,
  });

  final int id;
  final String userId;
  final int documentId;
  final int retryCount;
  final DateTime? lastRetryAt;
  final NetworkPolicy networkPolicy;
  final DocumentStatus status;
  final int maxRetries;
  final String? retryReason;
  final String? offlineBlobChecksum;
  final int priority;

  /// Verifica se atingiu o limite de tentativas.
  bool get hasExceededRetries => retryCount >= maxRetries;

  /// Verifica se está aguardando Wi-Fi.
  bool get isWaitingForWifi => networkPolicy == NetworkPolicy.wifiOnly;

  factory DocumentQueueEntry.fromJson(Map<String, dynamic> json) {
    return DocumentQueueEntry(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      documentId: json['document_id'] as int,
      retryCount: json['retry_count'] as int? ?? 0,
      lastRetryAt: json['last_retry_at'] != null
          ? DateTime.parse(json['last_retry_at'] as String)
          : null,
      networkPolicy:
          NetworkPolicy.fromDatabase(json['network_policy'] as String?),
      status: DocumentStatus.fromDatabase(json['status'] as String),
      maxRetries: json['max_retries'] as int? ?? 3,
      retryReason: json['retry_reason'] as String?,
      offlineBlobChecksum: json['offline_blob_checksum'] as String?,
      priority: json['priority'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentQueueEntry &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Input para criação/edição de documento.
@immutable
class DocumentInput {
  const DocumentInput({
    required this.title,
    this.description,
    required this.tags,
    this.expiresAt,
    this.networkPolicy = NetworkPolicy.any,
    this.allowSharing = false,
  });

  final String title;
  final String? description;
  final List<String> tags;
  final DateTime? expiresAt;
  final NetworkPolicy networkPolicy;
  final bool allowSharing;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'tags': tags.map((t) => t.toLowerCase()).toList(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }
}

/// Estado de filtros para documentos.
@immutable
class DocumentFilters {
  const DocumentFilters({
    this.searchTerm,
    this.selectedTags = const [],
    this.selectedStatuses = const [],
    this.expiresWithinDays,
    this.sortBy = DocumentSortBy.updatedAtDesc,
  });

  final String? searchTerm;
  final List<String> selectedTags;
  final List<DocumentStatus> selectedStatuses;
  final int? expiresWithinDays;
  final DocumentSortBy sortBy;

  bool get hasActiveFilters =>
      (searchTerm?.isNotEmpty ?? false) ||
      selectedTags.isNotEmpty ||
      selectedStatuses.isNotEmpty ||
      expiresWithinDays != null;

  DocumentFilters copyWith({
    String? searchTerm,
    List<String>? selectedTags,
    List<DocumentStatus>? selectedStatuses,
    int? expiresWithinDays,
    DocumentSortBy? sortBy,
  }) {
    return DocumentFilters(
      searchTerm: searchTerm ?? this.searchTerm,
      selectedTags: selectedTags ?? this.selectedTags,
      selectedStatuses: selectedStatuses ?? this.selectedStatuses,
      expiresWithinDays: expiresWithinDays ?? this.expiresWithinDays,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

/// Ordenação de documentos.
enum DocumentSortBy {
  updatedAtDesc,
  titleAsc,
  sizeBytesDesc,
  expiresAtAsc;

  String get label {
    switch (this) {
      case DocumentSortBy.updatedAtDesc:
        return 'Mais recentes';
      case DocumentSortBy.titleAsc:
        return 'Nome A-Z';
      case DocumentSortBy.sizeBytesDesc:
        return 'Tamanho';
      case DocumentSortBy.expiresAtAsc:
        return 'Expira antes';
    }
  }

  String get orderByColumn {
    switch (this) {
      case DocumentSortBy.updatedAtDesc:
        return 'updated_at';
      case DocumentSortBy.titleAsc:
        return 'title';
      case DocumentSortBy.sizeBytesDesc:
        return 'size_bytes';
      case DocumentSortBy.expiresAtAsc:
        return 'expires_at';
    }
  }

  bool get ascending =>
      this == DocumentSortBy.titleAsc || this == DocumentSortBy.expiresAtAsc;
}

/// Tags pré-definidas recomendadas.
class DocumentTags {
  DocumentTags._();

  static const List<String> recommended = [
    'Seguro de Vida',
    'Escritura',
    'Certidão',
    'Contrato',
    'Comprovantes Fiscais',
    'Documentos Pessoais',
  ];

  /// Tags que exigem step-up para operações sensíveis.
  static const List<String> sensitive = [
    'Escritura',
    'Seguro de Vida',
    'Documentos Pessoais',
  ];

  static bool isSensitive(String tag) =>
      sensitive.any((s) => s.toLowerCase() == tag.toLowerCase());
}

/// Resumo de indicadores do cofre.
@immutable
class DocumentVaultSummary {
  const DocumentVaultSummary({
    required this.totalDocuments,
    required this.totalSizeBytes,
    required this.pendingUploads,
  });

  final int totalDocuments;
  final int totalSizeBytes;
  final int pendingUploads;

  /// Tamanho total formatado.
  String get formattedTotalSize {
    if (totalSizeBytes < 1024) return '$totalSizeBytes B';
    if (totalSizeBytes < 1024 * 1024) {
      return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (totalSizeBytes < 1024 * 1024 * 1024) {
      return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(totalSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static const empty = DocumentVaultSummary(
    totalDocuments: 0,
    totalSizeBytes: 0,
    pendingUploads: 0,
  );
}
