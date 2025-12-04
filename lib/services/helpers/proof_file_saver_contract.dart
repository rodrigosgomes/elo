import 'dart:typed_data';

abstract class ProofFileSaver {
  Future<String> save(String fileName, Uint8List bytes);
}
