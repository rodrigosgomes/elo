import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:crypto/crypto.dart' as crypto;

class EncryptedDocumentPayload {
  const EncryptedDocumentPayload({required this.bytes, required this.checksum});

  final Uint8List bytes;
  final String checksum;
}

class DocumentEncryptionService {
  DocumentEncryptionService({required this.userId})
      : assert(userId.isNotEmpty, 'userId is required'),
        _algorithm = AesGcm.with256bits(),
        _random = Random.secure();

  final String userId;
  final AesGcm _algorithm;
  final Random _random;

  static const int _nonceLength = 12;
  static const int _macLength = 16;

  Future<EncryptedDocumentPayload> encrypt(Uint8List data) async {
    final secretKey = await _deriveKey();
    final nonce = _randomBytes(_nonceLength);
    final secretBox = await _algorithm.encrypt(
      data,
      secretKey: secretKey,
      nonce: nonce,
    );

    final payload =
        Uint8List(_nonceLength + secretBox.cipherText.length + _macLength);
    payload.setRange(0, _nonceLength, nonce);
    payload.setRange(
      _nonceLength,
      _nonceLength + secretBox.cipherText.length,
      secretBox.cipherText,
    );
    payload.setRange(
      payload.length - _macLength,
      payload.length,
      secretBox.mac.bytes,
    );

    final checksum = _checksum(payload);
    return EncryptedDocumentPayload(bytes: payload, checksum: checksum);
  }

  Future<Uint8List> decrypt(Uint8List encryptedBytes) async {
    if (encryptedBytes.length <= _nonceLength + _macLength) {
      throw StateError('Encrypted payload is malformed.');
    }
    final secretKey = await _deriveKey();
    final nonce = encryptedBytes.sublist(0, _nonceLength);
    final macBytes = encryptedBytes.sublist(encryptedBytes.length - _macLength);
    final cipherText = encryptedBytes.sublist(
      _nonceLength,
      encryptedBytes.length - _macLength,
    );

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    final clearBytes = await _algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );
    return Uint8List.fromList(clearBytes);
  }

  Future<SecretKey> _deriveKey() async {
    final digest =
        crypto.sha256.convert(utf8.encode('elo:$userId:asset-proof'));
    return SecretKey(digest.bytes);
  }

  Uint8List _randomBytes(int length) {
    final bytes = List<int>.generate(length, (_) => _random.nextInt(256));
    return Uint8List.fromList(bytes);
  }

  String _checksum(Uint8List data) {
    return crypto.sha256.convert(data).toString();
  }
}
