import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_config.dart';
import 'resource_tools.dart';

class AiKeyMissing implements Exception {}

class AiError implements Exception {
  AiError(this.message);
  final String message;
  @override
  String toString() => message;
}

/// One message shown in the assistant chat.
class AiChatMessage {
  AiChatMessage(this.role, this.text, {this.resources = const [], this.pending = false});
  final String role; // 'user' | 'assistant'
  final String text;
  final List<ResourceRef> resources;
  final bool pending;
}

const _systemPrompt = '''
You are the control room assistant for "One Piece Battles" — an app of One Piece
characters, devil fruits, crews and battle records.

Always use the provided tools to look up real data from the app before you
answer. Never invent combat stats, devil-fruit holders or battle outcomes; if a
lookup returns nothing, say you could not find it.

Answer in the SAME language the user used (Chinese or English). Be concise and
direct. When comparing who is stronger, use combat power and the stats/battle
history the tools return. You do NOT need to write links: the app automatically
shows clickable chips for every character, fruit and battle the tools surfaced.
''';

/// Holds one assistant conversation and runs the DeepSeek tool-calling loop.
class DeepSeekAssistant {
  final List<Map<String, dynamic>> _api = [
    {'role': 'system', 'content': _systemPrompt}
  ];

  Future<AiChatMessage> ask(String userText) async {
    final key = await AiConfig.getKey();
    if (key == null) throw AiKeyMissing();
    _api.add({'role': 'user', 'content': userText});

    final resources = <ResourceRef>{};
    for (var i = 0; i < 5; i++) {
      final message = await _complete(key);
      final toolCalls = message['tool_calls'];
      if (toolCalls is List && toolCalls.isNotEmpty) {
        _api.add(message);
        for (final call in toolCalls) {
          final fn = (call as Map)['function'] as Map;
          final args = _decodeArgs(fn['arguments']);
          final result =
              await ResourceTools.execute('${fn['name']}', args);
          resources.addAll(result.resources);
          _api.add({
            'role': 'tool',
            'tool_call_id': call['id'],
            'content': result.content,
          });
        }
        continue;
      }
      final content = (message['content'] ?? '').toString();
      _api.add({'role': 'assistant', 'content': content});
      return AiChatMessage('assistant', content, resources: resources.toList());
    }
    return AiChatMessage('assistant',
        'I looked a few things up but could not finish. Try rephrasing?',
        resources: resources.toList());
  }

  Map<String, dynamic> _decodeArgs(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return {};
  }

  Future<Map<String, dynamic>> _complete(String key) async {
    final http.Response resp;
    try {
      resp = await http.post(
        Uri.parse(AiConfig.baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $key',
        },
        body: jsonEncode({
          'model': AiConfig.model,
          'messages': _api,
          'tools': ResourceTools.definitions(),
          'tool_choice': 'auto',
          'temperature': 0.3,
        }),
      );
    } catch (e) {
      throw AiError('Network error reaching DeepSeek: $e');
    }
    if (resp.statusCode != 200) {
      throw AiError('DeepSeek error ${resp.statusCode}: ${utf8.decode(resp.bodyBytes)}');
    }
    final body = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final choices = body['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw AiError('DeepSeek returned no choices.');
    }
    return Map<String, dynamic>.from(
        (choices.first as Map)['message'] as Map);
  }
}
