import 'csv_export_service_stub.dart'
    if (dart.library.io) 'csv_export_service_io.dart'
    if (dart.library.html) 'csv_export_service_web.dart' as impl;

Future<String?> exportCsvFile({
  required String fileName,
  required String content,
}) {
  return impl.exportCsvFile(fileName: fileName, content: content);
}
