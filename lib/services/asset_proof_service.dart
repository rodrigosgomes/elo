import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/asset_model.dart';
import 'assets_repository.dart';
import 'document_encryption_service.dart';
import 'helpers/proof_file_saver_stub.dart'
    if (dart.library.io) 'helpers/proof_file_saver_io.dart'
    if (dart.library.html) 'helpers/proof_file_saver_web.dart';

class AssetProofService {
  AssetProofService({
    SupabaseClient? client,
    AssetsRepository? repository,
    ProofFileSaver? fileSaver,
  })  : _client = client ?? Supabase.instance.client,
        _repository = repository ??
            AssetsRepository(client: client ?? Supabase.instance.client),
        _fileSaver = fileSaver ?? createProofFileSaver();

  final SupabaseClient _client;
  final AssetsRepository _repository;
  final ProofFileSaver _fileSaver;

  static const _bucketName = 'asset-proofs';
  static const _maxFileSizeBytes = 10 * 1024 * 1024; // 10MB

  Future<AssetDocumentModel?> pickAndUploadProof(int assetId) async {
    final userId = _requireUserId();
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;
    final Uint8List? rawBytes = file.bytes;
    if (rawBytes == null) {
      throw StateError('Não foi possível ler o arquivo selecionado.');
    }

    if (rawBytes.length > _maxFileSizeBytes) {
      throw StateError('Arquivo acima de 15MB. Escolha um arquivo menor.');
    }

    final encryption = DocumentEncryptionService(userId: userId);
    final encrypted = await encryption.encrypt(rawBytes);
    final storagePath = _buildStoragePath(userId, assetId, file.name);

    await _client.storage.from(_bucketName).uploadBinary(
          storagePath,
          encrypted.bytes,
          fileOptions: const FileOptions(
            contentType: 'application/octet-stream',
            upsert: false,
          ),
        );

    final document = await _repository.insertAssetDocument(
      assetId: assetId,
      storagePath: storagePath,
      encryptedChecksum: encrypted.checksum,
      fileType: file.extension,
    );

    await _repository.updateProofState(assetId: assetId, hasProof: true);
    await _repository.insertTrustEvent(
      userId: userId,
      eventType: 'ASSET_PROOF_UPLOADED',
      description: 'Comprovante anexado ao bem',
      metadata: {
        'asset_id': assetId,
        'storage_path': storagePath,
        'file_type': file.extension,
        'size_bytes': rawBytes.length,
      },
    );

    return document;
  }

  Future<String> downloadProof(
    AssetDocumentModel document, {
    String? factorUsed,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError(
          'Download de comprovantes ainda não está disponível no navegador.');
    }
    final userId = _requireUserId();
    final encryptedBytes =
        await _client.storage.from(_bucketName).download(document.storagePath);
    final encryption = DocumentEncryptionService(userId: userId);
    final Uint8List plainBytes = await encryption.decrypt(encryptedBytes);
    final fileName = _deriveFileName(document.storagePath);
    final savedPath = await _fileSaver.save(fileName, plainBytes);
    await _repository.insertTrustEvent(
      userId: userId,
      eventType: 'ASSET_PROOF_DOWNLOADED',
      description: 'Comprovante baixado localmente',
      metadata: {
        'asset_id': document.assetId,
        'storage_path': document.storagePath,
      },
    );
    if (factorUsed != null) {
      await _repository.insertStepUpEvent(
        userId: userId,
        eventType: 'ASSET_PROOF_DOWNLOADED',
        factorUsed: factorUsed,
        success: true,
        metadata: {
          'asset_id': document.assetId,
        },
      );
    }
    return savedPath;
  }

  Future<void> deleteProof(AssetDocumentModel document) async {
    final userId = _requireUserId();
    await _client.storage.from(_bucketName).remove([document.storagePath]);
    await _repository.deleteAssetDocument(document.id);
    final remaining = await _repository.countAssetDocuments(document.assetId);
    if (remaining == 0) {
      await _repository.updateProofState(
        assetId: document.assetId,
        hasProof: false,
      );
    }
    await _repository.insertTrustEvent(
      userId: userId,
      eventType: 'ASSET_PROOF_REMOVED',
      description: 'Comprovante removido do bem',
      metadata: {
        'asset_id': document.assetId,
        'storage_path': document.storagePath,
      },
    );
  }

  String _requireUserId() {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('Sessão expirada. Faça login novamente.');
    }
    return id;
  }

  String _buildStoragePath(String userId, int assetId, String originalName) {
    final sanitized = originalName.replaceAll(RegExp(r'\s+'), '_');
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return '$userId/$assetId/${timestamp}_$sanitized.enc';
  }

  String _deriveFileName(String storagePath) {
    final raw = storagePath.split('/').last;
    if (raw.endsWith('.enc')) {
      return raw.substring(0, raw.length - 4);
    }
    return raw;
  }
}
