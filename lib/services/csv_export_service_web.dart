import 'dart:convert';
import 'dart:html' as html;

Future<String?> exportCsvFile({
  required String fileName,
  required String content,
}) async {
  final bytes = utf8.encode(content);
  final blob = html.Blob(<Object>[bytes], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);

  return fileName;
}
