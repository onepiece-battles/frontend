import 'dart:convert';

/// A resource an answer links to, rendered as an inline tappable link.
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

/// A battle the assistant prepared for the user to confirm and create.
class BattleProposal {
  const BattleProposal(this.starterId, this.receiverId, this.label);

  final String starterId;
  final String receiverId;
  final String label; // e.g. "Luffy vs Law"

  static BattleProposal? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final starterId = (json['starterId'] ?? '').toString();
    final receiverId = (json['receiverId'] ?? '').toString();
    if (starterId.isEmpty || receiverId.isEmpty) return null;
    return BattleProposal(
        starterId, receiverId, (json['label'] ?? '').toString());
  }
}

/// One event of the server's `/assistant/ask` answer stream.
sealed class AssistantEvent {
  const AssistantEvent();

  /// Maps an SSE event name and its JSON data. Unknown events (a newer server
  /// may add some) map to null and are skipped.
  static AssistantEvent? fromJson(String event, Map<String, dynamic> json) =>
      switch (event) {
        'status' => AssistantStatus(_text(json['tool']), _text(json['label'])),
        'delta' => AssistantDelta(_text(json['text'])),
        'done' => AssistantDone(
            messageId: _text(json['messageId']),
            content: _text(json['content']),
            resources: ((json['resources'] as List?) ?? const [])
                .whereType<Map<String, dynamic>>()
                .map(AiResourceLink.fromJson)
                .toList(),
            battleProposal: BattleProposal.fromJson(json['battleProposal']),
          ),
        'error' =>
          AssistantFailure(_text(json['code']), _text(json['message'])),
        _ => null,
      };

  static String _text(Object? value) => value?.toString() ?? '';
}

/// A tool is running. Answer text streamed before this was only a preamble.
class AssistantStatus extends AssistantEvent {
  const AssistantStatus(this.tool, this.label);

  final String tool;
  final String label; // e.g. "正在查询角色「路飞」的资料"
}

/// The next fragment of the answer.
class AssistantDelta extends AssistantEvent {
  const AssistantDelta(this.text);

  final String text;
}

/// The final answer, with links already repaired by the server. It replaces
/// the streamed text and ends the stream.
class AssistantDone extends AssistantEvent {
  const AssistantDone({
    required this.messageId,
    required this.content,
    this.resources = const [],
    this.battleProposal,
  });

  final String messageId;
  final String content;
  final List<AiResourceLink> resources;
  final BattleProposal? battleProposal;
}

/// The answer failed and the stream ends. [code] is stable; [message] is
/// already localized for display.
class AssistantFailure extends AssistantEvent {
  const AssistantFailure(this.code, this.message);

  static const notConfigured = 'not_configured';

  final String code;
  final String message;
}

/// Parses a `text/event-stream` body into [AssistantEvent]s. The bytes may be
/// split anywhere — mid-line or mid-character — so decoding is incremental.
Stream<AssistantEvent> parseAssistantEvents(Stream<List<int>> body) async* {
  String? event;
  final data = <String>[];
  await for (final line
      in body.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.isEmpty) {
      final parsed = _dispatch(event, data);
      if (parsed != null) yield parsed;
      event = null;
      data.clear();
    } else if (!line.startsWith(':')) {
      // Lines starting with ":" are comments / keep-alives.
      final colon = line.indexOf(':');
      final field = colon < 0 ? line : line.substring(0, colon);
      var value = colon < 0 ? '' : line.substring(colon + 1);
      if (value.startsWith(' ')) value = value.substring(1);
      if (field == 'event') {
        event = value;
      } else if (field == 'data') {
        data.add(value);
      }
    }
  }
  // Tolerate a last event that is not followed by a blank line.
  final parsed = _dispatch(event, data);
  if (parsed != null) yield parsed;
}

AssistantEvent? _dispatch(String? event, List<String> data) {
  if (data.isEmpty) return null;
  try {
    final json = jsonDecode(data.join('\n'));
    return json is Map<String, dynamic>
        ? AssistantEvent.fromJson(event ?? 'message', json)
        : null;
  } on FormatException {
    return null;
  }
}
