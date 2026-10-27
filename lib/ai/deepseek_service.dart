import 'dart:convert';

import 'package:get_it/get_it.dart';

import 'assistant_api.dart';
import 'resource_tools.dart';

/// Thrown when the super-admin has not configured a DeepSeek key yet.
class AiNotConfigured implements Exception {}

class AiError implements Exception {
  AiError(this.message);
  final String message;
  @override
  String toString() => message;
}

/// A battle the assistant prepared for the user to confirm and create.
class BattleProposal {
  const BattleProposal(this.starterId, this.receiverId, this.label);
  final String starterId;
  final String receiverId;
  final String label; // e.g. "Luffy vs Law"
}

/// One message shown in the assistant chat.
class AiChatMessage {
  AiChatMessage(this.role, this.text,
      {this.resources = const [], this.pending = false, this.battleProposal});
  final String role; // 'user' | 'assistant'
  final String text;
  final List<ResourceRef> resources;
  final bool pending;

  /// Non-null when the reply offers to create a battle (fresh replies only).
  final BattleProposal? battleProposal;
}

const _systemPrompt = '''
You are the control room assistant for "One Piece Battles" — an app of One Piece
characters, devil fruits, crews and battle records.

Always use the provided tools to look up real data from the app before you
answer. Never invent combat stats, devil-fruit holders or battle outcomes; if a
lookup returns nothing, say you could not find it.

Answer in the SAME language the user used (Chinese or English). Be concise and
well formatted: use short paragraphs, **bold** for key figures, and "- " bullet
lists when comparing or listing. When comparing who is stronger, reason from the
combat power and the stats / battle history the tools return.

Tools available: search_characters, get_character_detail, list_top_characters,
search_fruits, get_fruit_holders, list_fruits_by_type (for "all Ancient Zoan
users" etc.), search_groups and get_group_detail (a crew's members, its child
groups and its parent group), and propose_battle.

IMPORTANT — make resources clickable inline: whenever you mention a character,
devil fruit or crew that appears in a tool result, write its name as a Markdown
link of the form [Name](onepiece://TYPE/ID), where TYPE is one of character,
fruit or group, and ID is the exact id from that tool result. NEVER write a bare
onepiece:// URL on its own and NEVER paste raw ids into the prose — always use
the [Name](...) form. Do not list the links separately at the end; weave each
one into the sentence where you name the resource. Only link resources that
actually came from a tool result.

When the user wants to simulate or create a fight ("who would win A vs B",
"create a battle between A and B"), call propose_battle with the two names.
The app then shows the user a Confirm/Cancel card, so do NOT create a link for
it — just give your short analysis and say you've prepared the battle below.
''';

/// Holds one assistant conversation and runs the DeepSeek tool-calling loop.
/// The DeepSeek call itself is proxied through the backend, which holds the
/// key — this client never sees it.
class DeepSeekAssistant {
  final List<Map<String, dynamic>> _api = [
    {'role': 'system', 'content': _systemPrompt}
  ];

  AssistantApi get _assistantApi => GetIt.instance<AssistantApi>();

  /// Seed the in-memory transcript from persisted history so the model keeps
  /// context across reloads. Only user/assistant turns are replayed.
  void seedHistory(Iterable<AiStoredMessage> history) {
    for (final m in history) {
      if (m.role == 'user' || m.role == 'assistant') {
        _api.add({'role': m.role, 'content': m.content});
      }
    }
  }

  Future<AiChatMessage> ask(String userText) async {
    _api.add({'role': 'user', 'content': userText});

    final resources = <ResourceRef>{};
    for (var i = 0; i < 5; i++) {
      final message = await _complete();
      final toolCalls = message['tool_calls'];
      if (toolCalls is List && toolCalls.isNotEmpty) {
        _api.add(message);
        for (final call in toolCalls) {
          final fn = (call as Map)['function'] as Map;
          final args = _decodeArgs(fn['arguments']);
          final result = await ResourceTools.execute('${fn['name']}', args);
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
      return AiChatMessage('assistant', _normalizeLinks(content, resources),
          resources: resources.toList(), battleProposal: _extractProposal(resources));
    }
    return AiChatMessage('assistant',
        'I looked a few things up but could not finish. Try rephrasing?',
        resources: resources.toList());
  }

  /// Guarantee that no raw `onepiece://` ever reaches the chat: fix the label
  /// of any onepiece markdown link (the model sometimes uses the URL itself as
  /// the label) and wrap any remaining bare URL into a proper
  /// `[name](onepiece://type/id)` link, resolving names from the tool results.
  String _normalizeLinks(String content, Set<ResourceRef> resources) {
    final byKey = <String, String>{};
    for (final r in resources) {
      byKey['${r.type.toLowerCase()}/${r.id}'] = r.name;
    }

    String labelFor(String type, String id, String? existing) {
      if (existing != null &&
          existing.trim().isNotEmpty &&
          !existing.contains('://') &&
          !existing.toLowerCase().contains('onepiece')) {
        return existing.trim();
      }
      final name = byKey['${type.toLowerCase()}/$id'];
      if (name != null && name.isNotEmpty) return name;
      return type.toLowerCase();
    }

    // 1) Clean the label of onepiece markdown links.
    final mdLink =
        RegExp(r'\[([^\]]*)\]\(\s*onepiece://([A-Za-z_]+)/([^)\s]+)\s*\)');
    var out = content.replaceAllMapped(mdLink, (m) {
      final type = m.group(2)!.toLowerCase();
      final id = m.group(3)!;
      return '[${labelFor(type, id, m.group(1))}](onepiece://$type/$id)';
    });

    // 2) Wrap any remaining bare onepiece URL (not already inside a link).
    final bare = RegExp(r'(?<![(\[])onepiece://([A-Za-z_]+)/([^)\s\]]+)');
    out = out.replaceAllMapped(bare, (m) {
      final type = m.group(1)!.toLowerCase();
      final id = m.group(2)!;
      return '[${labelFor(type, id, null)}](onepiece://$type/$id)';
    });

    return out;
  }

  BattleProposal? _extractProposal(Set<ResourceRef> resources) {
    for (final r in resources) {
      if (r.type == 'battle_proposal') {
        final parts = r.id.split('|');
        if (parts.length == 2) {
          return BattleProposal(parts[0], parts[1], r.name);
        }
      }
    }
    return null;
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

  Future<Map<String, dynamic>> _complete() async {
    final payload = jsonEncode({
      'model': 'deepseek-chat', // the server overrides this with the configured model
      'messages': _api,
      'tools': ResourceTools.definitions(),
      'tool_choice': 'auto',
      'temperature': 0.3,
    });

    final AiChatResult result;
    try {
      result = await _assistantApi.chat(payload);
    } catch (e) {
      throw AiError('Could not reach the assistant service: $e');
    }
    if (result.error == 'not_configured') {
      throw AiNotConfigured();
    }
    if (result.error != null) {
      throw AiError('Assistant service error: ${result.error}');
    }
    if (result.status != 200 || result.responseBody == null) {
      throw AiError('DeepSeek error ${result.status}: ${result.responseBody ?? ''}');
    }
    final body = jsonDecode(result.responseBody!) as Map<String, dynamic>;
    final choices = body['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw AiError('DeepSeek returned no choices.');
    }
    return Map<String, dynamic>.from((choices.first as Map)['message'] as Map);
  }
}
