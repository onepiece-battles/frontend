import 'dart:convert';

import 'import_models.dart';

/// Independent copies keep a later manual edit or avatar lookup out of the undo snapshot.
ImportDraft copyImportDraft(ImportDraft draft) => ImportDraft(
      [
        for (final item in draft.items)
          ImportItem.fromJson({
            ...item.toJson(),
            'data': jsonDecode(jsonEncode(item.data)),
            'problems': [...item.problems],
          })
            ..included = item.included
            ..avatarUrl = item.avatarUrl
            ..useAvatar = item.useAvatar,
      ],
      [...draft.notes],
      reply: draft.reply,
      changed: [...draft.changed],
    );

bool importValuesEqual(Object? a, Object? b) {
  if (a is Map && b is Map) {
    return a.length == b.length &&
        a.keys.every(
            (key) => b.containsKey(key) && importValuesEqual(a[key], b[key]));
  }
  if (a is List && b is List) {
    return a.length == b.length &&
        List.generate(a.length, (i) => i)
            .every((i) => importValuesEqual(a[i], b[i]));
  }
  return a == b;
}

class ImportFieldChange {
  const ImportFieldChange(this.field, this.before, this.after);
  final String field;
  final Object? before;
  final Object? after;
}

class ImportItemChange {
  const ImportItemChange(this.before, this.after, this.fields);
  final ImportItem? before;
  final ImportItem? after;
  final List<ImportFieldChange> fields;
  ImportItem get item => after ?? before!;
  bool get added => before == null;
  bool get removed => after == null;
}

/// Derived from actual values rather than an AI-written description of its changes.
class ImportRevisionReview {
  ImportRevisionReview(ImportDraft before, ImportDraft after)
      : before = copyImportDraft(before),
        after = copyImportDraft(after) {
    final old = {for (final item in before.items) item.key: item};
    final next = {for (final item in after.items) item.key: item};
    for (final key in {...old.keys, ...next.keys}) {
      final a = old[key], b = next[key];
      final fields = <ImportFieldChange>[];
      if (a != null && b != null) {
        final av = {
          ...a.data,
          'fruits': a.fruits,
          'group': a.group,
          'position': a.position
        };
        final bv = {
          ...b.data,
          'fruits': b.fruits,
          'group': b.group,
          'position': b.position
        };
        for (final field in {...av.keys, ...bv.keys}) {
          if (!importValuesEqual(av[field], bv[field])) {
            if (field == 'name') {
              final an = av[field] is Map ? av[field] as Map : const {};
              final bn = bv[field] is Map ? bv[field] as Map : const {};
              for (final locale in {...an.keys, ...bn.keys}) {
                if (an[locale] != bn[locale]) {
                  fields.add(ImportFieldChange(
                      'name.$locale', an[locale], bn[locale]));
                }
              }
            } else {
              fields.add(ImportFieldChange(field, av[field], bv[field]));
            }
          }
        }
      }
      if (a == null || b == null || fields.isNotEmpty) {
        changes.add(ImportItemChange(a, b, fields));
      }
    }
  }
  final ImportDraft before;
  final ImportDraft after;
  final List<ImportItemChange> changes = [];
}
