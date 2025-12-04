enum AssetCategory {
  imoveis,
  veiculos,
  financeiro,
  cripto,
  dividas,
}

extension AssetCategoryLabel on AssetCategory {
  String get label {
    switch (this) {
      case AssetCategory.imoveis:
        return 'Imóveis';
      case AssetCategory.veiculos:
        return 'Veículos';
      case AssetCategory.financeiro:
        return 'Financeiro';
      case AssetCategory.cripto:
        return 'Cripto';
      case AssetCategory.dividas:
        return 'Dívidas';
    }
  }

  String get supabaseValue => name.toUpperCase();
}

enum AssetStatus {
  active,
  pendingReview,
  archived,
}

extension AssetStatusLabel on AssetStatus {
  String get label {
    switch (this) {
      case AssetStatus.active:
        return 'Ativo';
      case AssetStatus.pendingReview:
        return 'Revisão pendente';
      case AssetStatus.archived:
        return 'Arquivado';
    }
  }

  String get supabaseValue {
    switch (this) {
      case AssetStatus.active:
        return 'ACTIVE';
      case AssetStatus.pendingReview:
        return 'PENDING_REVIEW';
      case AssetStatus.archived:
        return 'ARCHIVED';
    }
  }
}

AssetCategory assetCategoryFromString(String? value) {
  final normalized = value?.toUpperCase() ?? 'FINANCEIRO';
  return AssetCategory.values.firstWhere(
    (category) => category.supabaseValue == normalized,
    orElse: () => AssetCategory.financeiro,
  );
}

AssetStatus assetStatusFromString(String? value) {
  switch (value?.toUpperCase()) {
    case 'ACTIVE':
      return AssetStatus.active;
    case 'ARCHIVED':
      return AssetStatus.archived;
    case 'PENDING_REVIEW':
    default:
      return AssetStatus.pendingReview;
  }
}

class AssetModel {
  const AssetModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.title,
    this.description,
    this.valueEstimated,
    this.valueCurrency = 'BRL',
    this.valueUnknown = false,
    this.ownershipPercentage = 100,
    this.hasProof = false,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AssetModel.fromMap(Map<String, dynamic> map) {
    return AssetModel(
      id: map['id'] as int,
      userId: map['user_id'] as String,
      category: assetCategoryFromString(map['category'] as String?),
      title: map['title'] as String? ?? 'Bem',
      description: map['description'] as String?,
      valueEstimated: (map['value_estimated'] as num?)?.toDouble(),
      valueCurrency: (map['value_currency'] as String?)?.toUpperCase() ?? 'BRL',
      valueUnknown: map['value_unknown'] as bool? ?? false,
      ownershipPercentage:
          (map['ownership_percentage'] as num?)?.toDouble() ?? 100,
      hasProof: map['has_proof'] as bool? ?? false,
      status: assetStatusFromString(map['status'] as String?),
      createdAt: _parseDate(map['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updated_at']) ?? DateTime.now(),
    );
  }

  final int id;
  final String userId;
  final AssetCategory category;
  final String title;
  final String? description;
  final double? valueEstimated;
  final String valueCurrency;
  final bool valueUnknown;
  final double ownershipPercentage;
  final bool hasProof;
  final AssetStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isArchived => status == AssetStatus.archived;
  bool get isDebt => category == AssetCategory.dividas;

  double? get valuePortion {
    if (valueEstimated == null || valueUnknown) return null;
    return double.parse(
      ((valueEstimated ?? 0) * ownershipPercentage / 100).toStringAsFixed(2),
    );
  }

  AssetModel copyWith({
    AssetCategory? category,
    String? title,
    String? description,
    double? valueEstimated,
    String? valueCurrency,
    bool? valueUnknown,
    double? ownershipPercentage,
    bool? hasProof,
    AssetStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AssetModel(
      id: id,
      userId: userId,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      valueEstimated: valueEstimated ?? this.valueEstimated,
      valueCurrency: valueCurrency ?? this.valueCurrency,
      valueUnknown: valueUnknown ?? this.valueUnknown,
      ownershipPercentage: ownershipPercentage ?? this.ownershipPercentage,
      hasProof: hasProof ?? this.hasProof,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AssetDocumentModel {
  const AssetDocumentModel({
    required this.id,
    required this.assetId,
    required this.storagePath,
    required this.encryptedChecksum,
    this.fileType,
    required this.uploadedAt,
  });

  factory AssetDocumentModel.fromMap(Map<String, dynamic> map) {
    return AssetDocumentModel(
      id: map['id'] as int,
      assetId: map['asset_id'] as int,
      storagePath: map['storage_path'] as String,
      encryptedChecksum: map['encrypted_checksum'] as String,
      fileType: map['file_type'] as String?,
      uploadedAt: _parseDate(map['uploaded_at']) ?? DateTime.now(),
    );
  }

  final int id;
  final int assetId;
  final String storagePath;
  final String encryptedChecksum;
  final String? fileType;
  final DateTime uploadedAt;
}

class AssetFilters {
  const AssetFilters({
    this.searchTerm,
    this.categories = const {},
    this.statuses = const {},
    this.hasProof,
    this.currency,
    this.minValue,
    this.maxValue,
    this.minOwnership,
    this.maxOwnership,
    this.sortOrder = AssetSortOrder.updatedDesc,
  });

  final String? searchTerm;
  final Set<AssetCategory> categories;
  final Set<AssetStatus> statuses;
  final bool? hasProof;
  final String? currency;
  final double? minValue;
  final double? maxValue;
  final double? minOwnership;
  final double? maxOwnership;
  final AssetSortOrder sortOrder;

  AssetFilters copyWith({
    String? searchTerm,
    Set<AssetCategory>? categories,
    Set<AssetStatus>? statuses,
    bool? hasProof,
    String? currency,
    double? minValue,
    double? maxValue,
    double? minOwnership,
    double? maxOwnership,
    AssetSortOrder? sortOrder,
  }) {
    return AssetFilters(
      searchTerm: searchTerm ?? this.searchTerm,
      categories: categories ?? this.categories,
      statuses: statuses ?? this.statuses,
      hasProof: hasProof ?? this.hasProof,
      currency: currency ?? this.currency,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      minOwnership: minOwnership ?? this.minOwnership,
      maxOwnership: maxOwnership ?? this.maxOwnership,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toStorage() {
    return {
      'searchTerm': searchTerm,
      'categories': categories.map((e) => e.supabaseValue).toList(),
      'statuses': statuses.map((e) => e.supabaseValue).toList(),
      'hasProof': hasProof,
      'currency': currency,
      'minValue': minValue,
      'maxValue': maxValue,
      'minOwnership': minOwnership,
      'maxOwnership': maxOwnership,
      'sortOrder': sortOrder.name,
    };
  }

  factory AssetFilters.fromStorage(Map<String, dynamic>? data) {
    if (data == null) return const AssetFilters();
    final categoryValues = data['categories'] as List<dynamic>?;
    final statusValues = data['statuses'] as List<dynamic>?;
    return AssetFilters(
      searchTerm: data['searchTerm'] as String?,
      categories: categoryValues == null
          ? const {}
          : categoryValues
              .map((value) => assetCategoryFromString(value as String?))
              .toSet(),
      statuses: statusValues == null
          ? const {}
          : statusValues
              .map((value) => assetStatusFromString(value as String?))
              .toSet(),
      hasProof: data['hasProof'] as bool?,
      currency: data['currency'] as String?,
      minValue: (data['minValue'] as num?)?.toDouble(),
      maxValue: (data['maxValue'] as num?)?.toDouble(),
      minOwnership: (data['minOwnership'] as num?)?.toDouble(),
      maxOwnership: (data['maxOwnership'] as num?)?.toDouble(),
      sortOrder: AssetSortOrder.values.firstWhere(
        (order) => order.name == data['sortOrder'],
        orElse: () => AssetSortOrder.updatedDesc,
      ),
    );
  }
}

enum AssetSortOrder {
  valueDesc,
  valueAsc,
  nameAz,
  category,
  updatedDesc,
}

class AssetInput {
  const AssetInput({
    required this.category,
    required this.title,
    this.description,
    this.valueEstimated,
    this.valueCurrency = 'BRL',
    this.valueUnknown = false,
    this.ownershipPercentage = 100,
    this.hasProof = false,
    this.status = AssetStatus.pendingReview,
  });

  final AssetCategory category;
  final String title;
  final String? description;
  final double? valueEstimated;
  final String valueCurrency;
  final bool valueUnknown;
  final double ownershipPercentage;
  final bool hasProof;
  final AssetStatus status;

  Map<String, dynamic> toInsertPayload(String userId) {
    return {
      'user_id': userId,
      'category': category.supabaseValue,
      'title': title,
      'description': description,
      'value_estimated': valueUnknown ? null : valueEstimated,
      'value_currency': valueCurrency,
      'value_unknown': valueUnknown,
      'ownership_percentage': ownershipPercentage,
      'has_proof': hasProof,
      'status': status.supabaseValue,
    };
  }

  Map<String, dynamic> toUpdatePayload() {
    return {
      'category': category.supabaseValue,
      'title': title,
      'description': description,
      'value_estimated': valueUnknown ? null : valueEstimated,
      'value_currency': valueCurrency,
      'value_unknown': valueUnknown,
      'ownership_percentage': ownershipPercentage,
      'has_proof': hasProof,
      'status': status.supabaseValue,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  factory AssetInput.fromModel(AssetModel model) {
    return AssetInput(
      category: model.category,
      title: model.title,
      description: model.description,
      valueEstimated: model.valueEstimated,
      valueCurrency: model.valueCurrency,
      valueUnknown: model.valueUnknown,
      ownershipPercentage: model.ownershipPercentage,
      hasProof: model.hasProof,
      status: model.status,
    );
  }
}

DateTime? _parseDate(dynamic source) {
  if (source == null) return null;
  if (source is DateTime) return source;
  return DateTime.tryParse(source.toString())?.toLocal();
}

class NetWorthBreakdown {
  const NetWorthBreakdown({
    required this.totalAssets,
    required this.totalDebts,
    required this.byCategory,
    required this.pendingValuations,
    required this.fxPending,
  });

  final double totalAssets;
  final double totalDebts;
  final Map<AssetCategory, double> byCategory;
  final int pendingValuations;
  final Map<String, double> fxPending;

  Map<String, dynamic> toJson() {
    return {
      'total_assets': totalAssets,
      'total_debts': totalDebts,
      'pending_valuations': pendingValuations,
      'fx_pending': fxPending,
      'breakdown_by_category': byCategory.map(
        (key, value) => MapEntry(key.supabaseValue, value),
      ),
    };
  }
}

class NetWorthSnapshot {
  const NetWorthSnapshot({
    required this.userId,
    required this.netWorthInBrl,
    required this.capturedAt,
    required this.breakdown,
  });

  final String userId;
  final double netWorthInBrl;
  final DateTime capturedAt;
  final NetWorthBreakdown breakdown;

  static const String metricType = 'NET_WORTH';

  Map<String, dynamic> toInsertPayload() {
    return {
      'user_id': userId,
      'metric_type': metricType,
      'metric_value': netWorthInBrl,
      'recorded_at': capturedAt.toUtc().toIso8601String(),
      'metadata': breakdown.toJson(),
    };
  }
}

class NetWorthHistoryReference {
  const NetWorthHistoryReference({
    required this.value,
    required this.recordedAt,
    required this.meetsWindowRequirement,
  });

  final double value;
  final DateTime recordedAt;
  final bool meetsWindowRequirement;

  factory NetWorthHistoryReference.fromMetricRow(
    Map<String, dynamic> row, {
    required bool meetsWindowRequirement,
  }) {
    final recordedAt = _parseDate(row['recorded_at']) ?? DateTime.now();
    final value = (row['metric_value'] as num?)?.toDouble() ?? 0;
    return NetWorthHistoryReference(
      value: double.parse(value.toStringAsFixed(2)),
      recordedAt: recordedAt,
      meetsWindowRequirement: meetsWindowRequirement,
    );
  }
}
