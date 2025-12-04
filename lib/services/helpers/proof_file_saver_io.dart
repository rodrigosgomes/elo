import 'dart:typed_data';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'proof_file_saver_stub.dart';

export 'proof_file_saver_contract.dart';

class IoProofFileSaver implements ProofFileSaver {
  @override
  Future<String> save(String fileName, Uint8List bytes) async {
    final directory = await getTemporaryDirectory();
    final sanitized = _sanitize(fileName);
    final file = File(p.join(directory.path, sanitized));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  String _sanitize(String input) {
    return input.replaceAll(RegExp(r'[\\/:]'), '_');
  }
}

ProofFileSaver createProofFileSaver() => IoProofFileSaver();
