import 'dart:io';

import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

Future<String?> exportCsvFile({
  required String fileName,
  required String content,
}) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$fileName');
  await file.writeAsString(content);
  await OpenFile.open(file.path);
  return file.path;
}
