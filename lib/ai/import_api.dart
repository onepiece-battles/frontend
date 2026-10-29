import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:openapi/api.dart';

import 'import_models.dart';
import 'json_events.dart';

export 'import_models.dart';

/// Client of the AI batch import (NIKA only). Like [AssistantApi] it goes
/// through the generated [ApiClient] for the base URL, JWT and session expiry.
class ImportApi {
  ImportApi(this._client);

  final ApiClient _client;
  static const String _base = '/api/onepiece/assistant/import';

  Future<http.StreamedResponse> _send(String path, Object body,
      {bool stream = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (stream) 'Accept': 'text/event-stream',
    };
    await _client.authentication?.applyToParams(<QueryParam>[], headers);
    final request =
        http.Request('POST', Uri.parse('${_client.basePath}$_base$path'))
          ..headers.addAll(headers)
          ..body = jsonEncode(body);
    return _client.client.send(request);
  }

  /// Drafts the resources of [scope]: [ImportProgress] while DeepSeek works,
  /// then one [ImportDraftReady] or [ImportFailure]. Nothing is written.
  Stream<ImportEvent> draft(String scope, {String? language}) async* {
    final response = await _send(
        '/draft', {'scope': scope, if (language != null) 'language': language},
        stream: true);
    if (response.statusCode >= 400) {
      throw ApiException(
          response.statusCode, await response.stream.bytesToString());
    }
    await for (final event in parseJsonEvents(response.stream)) {
      switch (event.name) {
        case 'status':
          yield ImportProgress((event.data['label'] ?? '').toString());
        case 'draft':
          yield ImportDraftReady(ImportDraft.fromJson(event.data));
        case 'error':
          yield ImportFailure((event.data['code'] ?? '').toString(),
              (event.data['message'] ?? '').toString());
      }
    }
  }

  /// Imports the reviewed [items] in one transaction. Throws [ImportRejected]
  /// (nothing written) when the server finds problems.
  Future<ImportResult> commit(List<ImportItem> items,
      {String? language}) async {
    final response = await _send('/commit', {
      'items': items.map((e) => e.toJson()).toList(),
      if (language != null) 'language': language,
    });
    final body = await response.stream.bytesToString();
    if (response.statusCode == 422) {
      throw ImportRejected.fromJson(jsonDecode(body) as Map<String, dynamic>);
    }
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, body);
    }
    return ImportResult.fromJson(jsonDecode(body) as Map<String, dynamic>);
  }
}
