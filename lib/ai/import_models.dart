/// Types of the AI batch import (`/api/onepiece/assistant/import/**`). Like the
/// rest of the assistant API they are kept out of the OpenAPI spec.
library;

/// The resource types of an import item.
class ImportType {
  static const character = 'character';
  static const fruit = 'fruit';
  static const group = 'group';
}

/// One resource of a draft. [data] holds the snake_case create fields; when
/// [existingId] is set the resource already exists and is only reused for the
/// relations of other items, so [data] carries just its name.
class ImportItem {
  ImportItem({
    required this.key,
    required this.type,
    required this.data,
    this.existingId,
    List<String>? fruits,
    this.group,
    this.position,
    Set<String>? uncertain,
    List<String>? problems,
    this.included = true,
  })  : fruits = fruits ?? [],
        uncertain = uncertain ?? {},
        problems = problems ?? [];

  final String key;
  final String type; // character | fruit | group
  Map<String, dynamic> data;
  final String? existingId;
  List<String> fruits;
  String? group;
  String? position;

  /// Fields the AI was not sure about, to double-check before importing.
  Set<String> uncertain;

  /// Why the item cannot be imported as it is (from the draft or the server).
  List<String> problems;

  /// Whether the reviewer keeps this item in the import.
  bool included;

  /// A portrait found for a new character (see `ImportAvatars`), and whether
  /// the reviewer keeps it. Uploaded after the import, never sent with it.
  String? avatarUrl;
  bool useAvatar = true;

  bool get exists => existingId != null;

  String name(bool zh) {
    final name = data['name'];
    if (name is! Map) return key;
    final primary = (zh ? name['zh_CN'] : name['en_US'])?.toString() ?? '';
    final other = (zh ? name['en_US'] : name['zh_CN'])?.toString() ?? '';
    return primary.isNotEmpty ? primary : (other.isNotEmpty ? other : key);
  }

  factory ImportItem.fromJson(Map<String, dynamic> json) => ImportItem(
        key: (json['key'] ?? '').toString(),
        type: (json['type'] ?? '').toString(),
        data: Map<String, dynamic>.from((json['data'] as Map?) ?? const {}),
        existingId: json['existingId']?.toString(),
        fruits: _strings(json['fruits']),
        group: json['group']?.toString(),
        position: json['position']?.toString(),
        uncertain: _strings(json['uncertain']).toSet(),
        problems: _strings(json['problems']),
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'type': type,
        'data': data,
        'existingId': existingId,
        'fruits': fruits,
        'group': group,
        'position': position,
        'uncertain': uncertain.toList(),
        'problems': const [],
      };
}

class ImportDraft {
  ImportDraft(this.items, this.notes,
      {this.reply, List<String>? changed, List<String>? refreshAvatars})
      : changed = changed ?? const [],
        refreshAvatars = refreshAvatars ?? const [];

  final List<ImportItem> items;
  final List<String> notes;

  /// After a revision: the AI's answer, and the keys it added or changed.
  final String? reply;
  final List<String> changed;

  /// Explicit server authorization; renaming never implies changing the portrait.
  final List<String> refreshAvatars;

  factory ImportDraft.fromJson(Map<String, dynamic> json) => ImportDraft(
        ((json['items'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(ImportItem.fromJson)
            .toList(),
        _strings(json['notes']),
        reply: json['reply']?.toString(),
        changed: _strings(json['changed']),
        refreshAvatars: _strings(json['refreshAvatars']),
      );
}

enum ImportTurnKind { user, assistant, error, note }

/// One entry of the import conversation: what the reviewer said, the AI's
/// answer, an error, or a note such as where a new draft starts.
class ImportTurn {
  const ImportTurn(this.kind, this.text);

  final ImportTurnKind kind;
  final String text;

  bool get user => kind == ImportTurnKind.user;

  /// Only what was said is context for the AI.
  bool get said =>
      kind == ImportTurnKind.user || kind == ImportTurnKind.assistant;

  Map<String, dynamic> toJson() =>
      {'role': user ? 'user' : 'assistant', 'content': text};
}

class ImportCreated {
  const ImportCreated(this.key, this.type, this.id, this.name);

  final String key;
  final String type;
  final String id;
  final String name;
}

class ImportResult {
  const ImportResult(
      this.created, this.reused, this.fruitsEaten, this.groupsJoined);

  final List<ImportCreated> created;
  final int reused;
  final int fruitsEaten;
  final int groupsJoined;

  factory ImportResult.fromJson(Map<String, dynamic> json) => ImportResult(
        ((json['created'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map((e) => ImportCreated(
                  (e['key'] ?? '').toString(),
                  (e['type'] ?? '').toString(),
                  (e['id'] ?? '').toString(),
                  (e['name'] ?? '').toString(),
                ))
            .toList(),
        (json['reused'] as num?)?.toInt() ?? 0,
        (json['fruitsEaten'] as num?)?.toInt() ?? 0,
        (json['groupsJoined'] as num?)?.toInt() ?? 0,
      );
}

/// A reason an item (or, with a null [key], the whole batch) was not imported.
class ImportProblem {
  const ImportProblem(this.key, this.message);

  final String? key;
  final String message;
}

/// The server rejected the batch; nothing was written.
class ImportRejected implements Exception {
  const ImportRejected(this.message, this.problems);

  final String message;
  final List<ImportProblem> problems;

  factory ImportRejected.fromJson(Map<String, dynamic> json) => ImportRejected(
        (json['message'] ?? '').toString(),
        ((json['problems'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map((e) => ImportProblem(
                e['key']?.toString(), (e['message'] ?? '').toString()))
            .toList(),
      );

  @override
  String toString() => message;
}

/// One event of the `/import/draft` and `/import/revise` streams.
sealed class ImportEvent {
  const ImportEvent();
}

class ImportProgress extends ImportEvent {
  const ImportProgress(this.label);
  final String label;
}

class ImportDraftReady extends ImportEvent {
  const ImportDraftReady(this.draft);
  final ImportDraft draft;
}

class ImportFailure extends ImportEvent {
  const ImportFailure(this.code, this.message);
  final String code;
  final String message;
}

List<String> _strings(Object? value) => value is List
    ? value.where((e) => e != null).map((e) => e.toString()).toList()
    : <String>[];
