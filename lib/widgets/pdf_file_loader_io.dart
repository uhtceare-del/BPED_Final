import 'dart:io';
import 'dart:typed_data';

Future<Uint8List> loadPdfFileBytes(String path) {
  return File(path).readAsBytes();
}
