
/// Stub implementation for non-web platforms.
/// PDF download via Blob/AnchorElement is only supported on web.
void downloadPdf(List<int> bytes, String fileName, String? mimeType) {
  throw UnsupportedError(
      'PDF download is not supported on this platform. Please use the web version.');
}
