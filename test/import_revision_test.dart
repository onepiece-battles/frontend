import 'package:flutter_test/flutter_test.dart';
import 'package:one_piece_battles_flutter/ai/import_models.dart';
import 'package:one_piece_battles_flutter/ai/import_revision.dart';
import 'package:one_piece_battles_flutter/ai/import_session.dart';

void main() {
  ImportDraft sample() => ImportDraft([
        ImportItem(
            key: 'c1',
            type: ImportType.character,
            data: {
              'name': {'zh_CN': '佩罗娜', 'en_US': 'Perona'},
              'attack': 800,
              'bounty': 1000,
              'hakis': ['Busoshoku'],
            },
            uncertain: {'bounty'},
            problems: ['review'],
            included: false)
          ..avatarUrl = 'portrait'
          ..useAvatar = false,
      ], [
        'note'
      ]);

  test(
      'review uses real field differences, distinguishes translations and clearing a fact',
      () {
    final before = sample();
    final after = copyImportDraft(before);
    after.items.single.data.remove('bounty');
    (after.items.single.data['name'] as Map)['en_US'] = 'Princess Perona';
    final review = ImportRevisionReview(before, after);
    expect(review.changes.single.fields.map((f) => f.field),
        ['name.en_US', 'bounty']);
    expect(review.changes.single.fields.last.before, 1000);
    expect(review.changes.single.fields.last.after, isNull);
    // Subsequent editor/lookup mutations cannot alter either saved snapshot.
    (before.items.single.data['hakis'] as List).clear();
    after.items.single.data['attack'] = 1;
    expect(review.before.items.single.data['hakis'], ['Busoshoku']);
    expect(review.after.items.single.data['attack'], 800);
    expect(review.before.items.single.included, isFalse);
    expect(review.before.items.single.useAvatar, isFalse);
    expect(review.before.items.single.avatarUrl, 'portrait');
    expect(review.before.items.single.problems, ['review']);
  });

  test('manual edits invalidate snapshot undo rather than discarding the edits',
      () {
    final session = ImportSession();
    final before = sample();
    final after = copyImportDraft(before)..items.single.data['attack'] = 900;
    session.draft = after;
    session.lastRevision = ImportRevisionReview(before, after);
    expect(session.canUndoRevision, isTrue);
    after.items.single.data['attack'] = 950;
    session.touch();
    session.undoRevision(zh: true);
    expect(session.draft!.items.single.data['attack'], 950);
    expect(session.canUndoRevision, isFalse);
    session.dispose();
  });
}
