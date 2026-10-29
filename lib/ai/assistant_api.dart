import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:openapi/api.dart';

import 'assistant_events.dart';

export 'assistant_events.dart';

/// Thin client for the backend AI endpoints (`/api/onepiece/assistant/**`).
///
/// It reuses the generated [ApiClient] — so it inherits the configured base
/// URL, the JWT bearer header and the session-expiry handling — but talks to
/// endpoints that are deliberately kept out of the OpenAPI spec. The agent
/// itself (prompt, tools, DeepSeek key) runs on the server: this client only
/// asks and renders the streamed answer.
class AssistantApi {
  AssistantApi(this._client);

  final ApiClient _client;
  static const String _base = '/api/onepiece/assistant';

  Future<Map<String, dynamic>> _post(String path,
      [Map<String, dynamic>? body]) async {
    final response = await _client.invokeAPI(
      '$_base$path',
      'POST',
      <QueryParam>[],
      body ?? <String, dynamic>{},
      <String, String>{},
      <String, String>{},
      'application/json',
    );
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, response.body);
    }
    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Asks the server-side agent and streams its answer: [AssistantStatus]
  /// while tools run, [AssistantDelta] fragments, then one [AssistantDone] or
  /// [AssistantFailure]. The server stores the question and the answer.
  ///
  /// Sent through the session-aware client, so an expired token still
  /// triggers the login flow; on the web `package:http` reads the body with
  /// `fetch`, so the answer arrives incrementally there too.
  Stream<AssistantEvent> ask(String message, {String? language}) async* {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
    };
    await _client.authentication?.applyToParams(<QueryParam>[], headers);
    final request =
        http.Request('POST', Uri.parse('${_client.basePath}$_base/ask'))
          ..headers.addAll(headers)
          ..body = jsonEncode({
            'message': message,
            if (language != null) 'language': language,
          });
    final response = await _client.client.send(request);
    if (response.statusCode >= 400) {
      throw ApiException(
          response.statusCode, await response.stream.bytesToString());
    }
    yield* parseAssistantEvents(response.stream);
  }

  Future<List<AiStoredMessage>> listMessages() async {
    final json = await _post('/list_messages');
    final messages = (json['messages'] as List?) ?? const [];
    return messages
        .map((e) => AiStoredMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> clearMessages() => _post('/clear_messages');

  /// NIKA-only. Returns whether a key is configured plus the endpoint/model —
  /// never the key itself.
  Future<AiSettingView> getSetting() async {
    final json = await _post('/get_setting');
    return AiSettingView(
      json['configured'] == true,
      (json['baseUrl'] ?? '').toString(),
      (json['model'] ?? '').toString(),
    );
  }

  /// NIKA-only. A null/blank [apiKey] keeps the stored key.
  Future<void> setSetting(
      {String? apiKey, String? baseUrl, String? model}) async {
    await _post('/set_setting', {
      'apiKey': apiKey,
      'baseUrl': baseUrl,
      'model': model,
    });
  }
}

/// A persisted AI turn loaded from history.
class AiStoredMessage {
  const AiStoredMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.resources,
    this.actionProposals = const [],
  });

  final String id;
  final String role; // user | assistant
  final String content;
  final List<AiResourceLink> resources;
  final List<AiActionProposal> actionProposals;

  factory AiStoredMessage.fromJson(Map<String, dynamic> json) =>
      AiStoredMessage(
        id: (json['id'] ?? '').toString(),
        role: (json['role'] ?? '').toString(),
        content: (json['content'] ?? '').toString(),
        actionProposals: AiActionProposal.listFromJson(json['actionProposals']),
        resources: (((json['resources'] as List?) ?? const [])
            .map((e) => AiResourceLink.fromJson(e as Map<String, dynamic>))
            .toList()),
      );
}

/// The provider settings as seen by the super-admin UI (never the key).
class AiSettingView {
  const AiSettingView(this.configured, this.baseUrl, this.model);
  final bool configured;
  final String baseUrl;
  final String model;
}
