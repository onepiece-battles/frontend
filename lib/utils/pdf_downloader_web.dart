import 'dart:html' as html;

/// Web implementation of PDF download using Blob and AnchorElement.
void downloadPdf(List<int> bytes, String fileName, String? mimeType) {
  final blob = html.Blob([bytes], mimeType ?? 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement()
    ..href = url
    ..setAttribute('target', '_blank')
    ..download = fileName
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
