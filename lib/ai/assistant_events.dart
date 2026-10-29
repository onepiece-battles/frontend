import 'json_events.dart';

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

/// A server-validated pending action or its durable result. Confirmation always
/// returns to /ask; this client never performs the resource write itself.
class AiActionProposal {
  const AiActionProposal({
    required this.code,
    required this.operation,
    required this.title,
    required this.summary,
    required this.status,
    required this.expiresAt,
    this.resources = const [],
  });

  final String code;
  final String operation;
  final String title;
  final String summary;
  final String status;
  final DateTime expiresAt;
  final List<AiResourceLink> resources;

  bool get expired =>
      status == 'expired' ||
      (status == 'pending' && !expiresAt.isAfter(DateTime.now()));
  bool get canConfirm => status == 'pending' && !expired;

  static List<AiActionProposal> listFromJson(Object? value) => value is List
      ? value
          .whereType<Map<String, dynamic>>()
          .map(fromJson)
          .whereType<AiActionProposal>()
          .toList()
      : const [];

  static AiActionProposal? fromJson(Map<String, dynamic> json) {
    final code = (json['code'] ?? '').toString();
    final expires = json['expiresAt'];
    if (!RegExp(r'^[A-Fa-f0-9]{10}$').hasMatch(code) || expires is! num) {
      return null;
    }
    return AiActionProposal(
      code: code.toUpperCase(),
      operation: (json['operation'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(expires.toInt()),
      resources: ((json['resources'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AiResourceLink.fromJson)
          .toList(),
    );
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
            actionProposals:
                AiActionProposal.listFromJson(json['actionProposals']),
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
    this.actionProposals = const [],
  });

  final String messageId;
  final String content;
  final List<AiResourceLink> resources;
  final BattleProposal? battleProposal;
  final List<AiActionProposal> actionProposals;
}

/// The answer failed and the stream ends. [code] is stable; [message] is
/// already localized for display.
class AssistantFailure extends AssistantEvent {
  const AssistantFailure(this.code, this.message);

  static const notConfigured = 'not_configured';

  final String code;
  final String message;
}

/// Parses a `text/event-stream` body into [AssistantEvent]s, skipping events
/// this client does not know.
Stream<AssistantEvent> parseAssistantEvents(Stream<List<int>> body) async* {
  await for (final event in parseJsonEvents(body)) {
    final parsed = AssistantEvent.fromJson(event.name, event.data);
    if (parsed != null) yield parsed;
  }
}
