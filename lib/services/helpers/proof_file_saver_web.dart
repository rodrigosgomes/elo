import 'dart:typed_data';

import 'proof_file_saver_stub.dart';

export 'proof_file_saver_contract.dart';

class WebProofFileSaver implements ProofFileSaver {
  @override
  Future<String> save(String fileName, Uint8List bytes) {
    throw UnsupportedError(
      'Download de comprovantes ainda não está disponível no navegador.',
    );
  }
}

ProofFileSaver createProofFileSaver() => WebProofFileSaver();
