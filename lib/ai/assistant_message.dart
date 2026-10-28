import 'assistant_events.dart';

/// A system resource an answer referenced. The chat renders these as links
/// that deep-link into the resource's detail page.
class ResourceRef {
  const ResourceRef(this.type, this.id, this.name);

  final String type; // character | fruit | battle | group
  final String id;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is ResourceRef && other.type == type && other.id == id;

  @override
  int get hashCode => Object.hash(type, id);
}

/// One message shown in the assistant chat.
class AiChatMessage {
  AiChatMessage(this.role, this.text,
      {this.resources = const [],
      this.pending = false,
      this.status,
      this.battleProposal});
  final String role; // 'user' | 'assistant'
  final String text;
  final List<ResourceRef> resources;

  /// The answer is still streaming in.
  final bool pending;

  /// While pending: what the assistant is doing, e.g. "正在查询角色「路飞」的资料".
  final String? status;

  /// Non-null when the reply offers to create a battle (fresh replies only).
  final BattleProposal? battleProposal;
}

/// Repair resource references in an assistant reply. The server repairs every
/// new answer; this keeps replies restored from older history consistent.
String normalizeResourceLinks(String content, Iterable<ResourceRef> resources) {
  final known = resources
      .where((r) =>
          const {'character', 'fruit', 'group', 'battle'}.contains(r.type) &&
          r.id.isNotEmpty)
      .toList();
  String link(String type, String id, String? label) {
    ResourceRef? reference;
    for (final r in known) {
      if (r.type == type && r.id == id) reference = r;
    }
    // Repair a mistaken ID only when the visible name identifies one known
    // resource unambiguously. Never make an invented ID navigable.
    if (reference == null && label != null) {
      final matches = known
          .where((r) =>
              r.type == type &&
              r.name.trim().toLowerCase() == label.trim().toLowerCase())
          .toList();
      if (matches.length == 1) reference = matches.single;
    }
    final display = label != null &&
            label.trim().isNotEmpty &&
            !label.toLowerCase().contains('onepiece:')
        ? label.trim()
        : reference?.name ?? type;
    if (reference == null) return display;
    return '[$display](onepiece://${reference.type}/${reference.id})';
  }

  // Process Markdown links and bare references in one pass so a URL inside
  // a repaired Markdown link cannot be wrapped a second time.
  final tokens = RegExp(
      r'\[([^\]]*)\]\(\s*onepiece://([A-Za-z_]+)/([^\s)]+)\s*\)|onepiece://([A-Za-z_]+)/([^\s)\]，。！？；：,.;!?`*]+)',
      caseSensitive: false);
  return content.replaceAllMapped(tokens, (m) {
    final type = (m.group(2) ?? m.group(4))!.toLowerCase();
    final id = (m.group(3) ?? m.group(5))!;
    return link(type, id, m.group(1));
  });
}
