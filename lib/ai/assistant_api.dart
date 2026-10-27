import 'dart:convert';

import 'package:openapi/api.dart';

/// Thin client for the backend AI endpoints (`/api/onepiece/assistant/**`).
///
/// It reuses the generated [ApiClient] — so it inherits the configured base
/// URL, the JWT bearer header and the session-expiry handling — but talks to
/// endpoints that are deliberately kept out of the OpenAPI spec, so the chat
/// proxy can stay schema-agnostic. The DeepSeek key lives only on the server.
class AssistantApi {
  AssistantApi(this._client);

  final ApiClient _client;
  static const String _base = '/api/onepiece/assistant';

  Future<Map<String, dynamic>> _post(String path, [Map<String, dynamic>? body]) async {
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

  /// Proxy one DeepSeek chat-completion call. [requestBody] is the full
  /// OpenAI-style payload already JSON-encoded; the server adds the key.
  Future<AiChatResult> chat(String requestBody) async {
    final json = await _post('/chat', {'requestBody': requestBody});
    return AiChatResult(
      (json['status'] as num?)?.toInt() ?? 0,
      json['responseBody'] as String?,
      json['error'] as String?,
    );
  }

  Future<List<AiStoredMessage>> listMessages() async {
    final json = await _post('/list_messages');
    final messages = (json['messages'] as List?) ?? const [];
    return messages
        .map((e) => AiStoredMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveMessage(
      String role, String content, List<AiResourceLink> resources) async {
    await _post('/save_message', {
      'role': role,
      'content': content,
      'resources': resources.map((e) => e.toJson()).toList(),
    });
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
  Future<void> setSetting({String? apiKey, String? baseUrl, String? model}) async {
    await _post('/set_setting', {
      'apiKey': apiKey,
      'baseUrl': baseUrl,
      'model': model,
    });
  }
}

/// A resource the answer links to, rendered as an inline tappable link.
class AiResourceLink {
  const AiResourceLink(this.type, this.id, this.name);

  final String type; // character | fruit | battle | group
  final String id;
  final String name;

  factory AiResourceLink.fromJson(Map<String, dynamic> json) => AiResourceLink(
        (json['type'] ?? '').toString(),
        (json['id'] ?? '').toString(),
        (json['name'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {'type': type, 'id': id, 'name': name};
}

/// A persisted AI turn loaded from history.
class AiStoredMessage {
  const AiStoredMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.resources,
  });

  final String id;
  final String role; // user | assistant
  final String content;
  final List<AiResourceLink> resources;

  factory AiStoredMessage.fromJson(Map<String, dynamic> json) => AiStoredMessage(
        id: (json['id'] ?? '').toString(),
        role: (json['role'] ?? '').toString(),
        content: (json['content'] ?? '').toString(),
        resources: (((json['resources'] as List?) ?? const [])
            .map((e) => AiResourceLink.fromJson(e as Map<String, dynamic>))
            .toList()),
      );
}

/// Result of a proxied chat call. [error] is non-null when the server could
/// not reach DeepSeek (e.g. `not_configured`, `upstream_error`).
class AiChatResult {
  const AiChatResult(this.status, this.responseBody, this.error);
  final int status;
  final String? responseBody;
  final String? error;
}

/// The provider settings as seen by the super-admin UI (never the key).
class AiSettingView {
  const AiSettingView(this.configured, this.baseUrl, this.model);
  final bool configured;
  final String baseUrl;
  final String model;
}
