import 'package:http/http.dart' as http;

/// Watches authenticated API responses without modifying generated OpenAPI code.
class SessionAwareClient extends http.BaseClient {
  SessionAwareClient(this._inner, this.onUnauthorized);

  final http.Client _inner;
  final void Function() onUnauthorized;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);
    if (response.statusCode == 401) onUnauthorized();
    return response;
  }

  @override
  void close() => _inner.close();
}
