import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';
import 'package:one_piece_battles_flutter/ai/import_api.dart';
import 'package:one_piece_battles_flutter/ai/import_avatars.dart';
import 'package:one_piece_battles_flutter/ai/import_session.dart';
import 'package:one_piece_battles_flutter/ai/import_fields.dart';
import 'package:one_piece_battles_flutter/ai/json_events.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/repository/image_dao.dart';
import 'package:one_piece_battles_flutter/views/assistant/import_view.dart';

/// Stands in for the server: [events] feeds the draft stream, [onCommit]
/// answers the import.
class _FakeImportApi extends ImportApi {
  _FakeImportApi() : super(ApiClient());

  /// One stream per draft or revision; [events] / [revisions] is the latest.
  final _drafts = <StreamController<ImportEvent>>[];
  final _revisions = <StreamController<ImportEvent>>[];
  StreamController<ImportEvent> get events => _drafts.last;
  StreamController<ImportEvent> get revisions => _revisions.last;
  final scopes = <String>[];
  List<ImportItem>? committed;
  Future<ImportResult> Function(List<ImportItem> items) onCommit =
      (_) async => const ImportResult([], 0, 0, 0);

  @override
  Stream<ImportEvent> draft(String scope, {String? language}) {
    scopes.add(scope);
    _drafts.add(StreamController<ImportEvent>());
    return events.stream;
  }

  final revised = <(List<ImportItem>, List<ImportTurn>, String)>[];

  @override
  Stream<ImportEvent> revise(
      List<ImportItem> items, List<ImportTurn> conversation, String instruction,
      {String? language}) {
    revised.add((items, conversation, instruction));
    _revisions.add(StreamController<ImportEvent>());
    return revisions.stream;
  }

  @override
  Future<ImportResult> commit(List<ImportItem> items, {String? language}) {
    committed = items
        .map((i) => ImportItem.fromJson(jsonDecode(jsonEncode(i.toJson()))))
        .toList();
    return onCommit(items);
  }
}

Map<String, dynamic> _character(String zh, String en) => {
      'name': {'zh_CN': zh, 'en_US': en},
      'race': 'HUMAN',
      'battle_style': 'KATANA',
      'hakis': ['Busoshoku'],
      'bounty': 1111000000,
      'maximum_fruit_count': 1,
      'group_gain': 130,
      'attack': 1100,
      'defense': 700,
      'blood': 6000,
      'speed': 120,
      'intelligence': 110,
      'energy': 150,
    };

ImportDraft _strawHats() => ImportDraft.fromJson({
      'items': [
        {
          'key': 'g1',
          'type': 'group',
          'data': {
            'name': {'zh_CN': '草帽一伙', 'en_US': 'Straw Hat Pirates'},
            'group_category': 'pirate'
          },
        },
        {
          'key': 'f1',
          'type': 'fruit',
          'existingId': 'fruit-gomu',
          'data': {
            'name': {'zh_CN': '橡胶果实', 'en_US': 'Gomu Gomu no Mi'}
          },
        },
        {
          'key': 'f2',
          'type': 'fruit',
          'data': {
            'name': {'zh_CN': '花花果实', 'en_US': 'Hana Hana no Mi'},
            'fruit_type': 'Paramecia',
            'energy_consume': 4,
            for (final stat in [
              'attack',
              'defense',
              'blood',
              'group_gain',
              'speed',
              'intelligence'
            ]) ...{'${stat}_slope': 1.1, '${stat}_intercept': 5},
          },
        },
        {
          'key': 'c1',
          'type': 'character',
          'data': _character('罗罗诺亚·索隆', 'Roronoa Zoro'),
          'group': 'g1',
          'position': 'combatant',
          'uncertain': ['bounty'],
        },
        {
          'key': 'c2',
          'type': 'character',
          'data': {..._character('妮可·罗宾', 'Nico Robin')}..remove('race'),
          'fruits': ['f2'],
          'group': 'g1',
          'position': 'scholar',
          'problems': ['缺少必填项：race'],
        },
        {
          'key': 'c3',
          'type': 'character',
          'existingId': 'character-luffy',
          'data': {
            'name': {'zh_CN': '蒙奇·D·路飞', 'en_US': 'Monkey D. Luffy'}
          },
          'fruits': ['f1'],
          'group': 'g1',
          'position': 'captain',
        },
      ],
      'notes': ['只包含当前成员'],
    });

/// Answers the wiki lookup with [found] and "crops" without decoding.
class _FakeAvatars extends ImportAvatars {
  Map<String, String> found = {};
  final prepared = <String>[];

  @override
  Future<Map<String, String>> find(List<ImportItem> items) async => found;

  @override
  Future<Uint8List> prepare(String url) async {
    prepared.add(url);
    return Uint8List.fromList([137, 80, 78, 71]);
  }
}

class _FakeImageDao extends ImageDao {
  _FakeImageDao() : super.empty();

  final uploads = <UploadImageRequest>[];

  @override
  Future<UploadImageResponse?> addImage(UploadImageRequest request) async {
    uploads.add(request);
    return null;
  }
}

Future<_FakeImportApi> _pump(WidgetTester tester,
    {String language = 'zh',
    UserRole role = UserRole.NIKA,
    _FakeAvatars? avatars,
    ImageDao? images}) async {
  tester.view.physicalSize = const Size(1100, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final api = _FakeImportApi();
  GetIt.instance
    ..registerSingleton<ImportApi>(api)
    ..registerSingleton<ImportSession>(ImportSession())
    ..registerSingleton<ImportAvatars>(avatars ?? _FakeAvatars())
    ..registerSingleton<ImageDao>(images ?? _FakeImageDao())
    ..registerSingleton<User>(
        User(id: 'nika', username: 'nika', nickname: 'Nika', loginRole: role));
  addTearDown(() => GetIt.instance.reset());
  await tester.pumpWidget(MaterialApp(
    locale: Locale(language),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: const Scaffold(body: ImportView()),
  ));
  await tester.pump();
  return api;
}

/// Types [text] into the conversation's composer and sends it.
Future<void> _say(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const ValueKey('import_input')), text);
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('import_send')));
}

Future<void> _draftStrawHats(WidgetTester tester, _FakeImportApi api) async {
  await _say(tester, '草帽一伙全员');
  await tester.pump();
  api.events.add(const ImportProgress('正在梳理名单…'));
  await tester.pump();
  expect(find.text('正在梳理名单…'), findsOneWidget);
  api.events.add(ImportDraftReady(_strawHats()));
  await tester.pump();
}

Finder _in(String key, Finder finder) =>
    find.descendant(of: find.byKey(Key('import-item-$key')), matching: finder);

bool? _checked(WidgetTester tester, String key) =>
    tester.widget<Checkbox>(_in(key, find.byType(Checkbox))).value;

FilledButton _commitButton(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byKey(const Key('import-commit-button')));

void main() {
  test('parses draft events and checks fields against the create ranges',
      () async {
    final body =
        utf8.encode('event:status\ndata:{"tool":"import","label":"起草中"}\n\n'
            'event:draft\ndata:{"items":[],"notes":["n"]}\n\n');
    final events = await parseJsonEvents(Stream.value(body)).toList();
    expect(events.map((e) => e.name), ['status', 'draft']);

    final robin = _strawHats().items.firstWhere((i) => i.key == 'c2');
    expect(importFieldErrors(robin, true).keys, ['race']);
    robin.data['attack'] = 99999;
    robin.fruits.add('f9');
    expect(importFieldErrors(robin, true).keys,
        containsAll(['race', 'attack', 'fruits']));
    final luffy = _strawHats().items.firstWhere((i) => i.key == 'c3');
    expect(importFieldErrors(luffy, true), isEmpty); // existing: reused as is
  });

  test('field ranges are those of the create forms', () {
    String? check(String type, String key, num value) =>
        importFields(type).firstWhere((f) => f.key == key).check(value, true);
    expect(check(ImportType.character, 'energy', 300), isNull);
    expect(check(ImportType.character, 'energy', 50), isNotNull);
    expect(check(ImportType.character, 'bounty', 50000000000), isNull);
    expect(check(ImportType.fruit, 'energy_consume', 10), isNull);
    expect(check(ImportType.fruit, 'energy_consume', 11), isNotNull);
    // A new character holds one fruit.
    expect(check(ImportType.character, 'maximum_fruit_count', 1), isNull);
    expect(check(ImportType.character, 'maximum_fruit_count', 2), isNotNull);
  });

  testWidgets('drafts, leaves out what needs fixing and imports the rest',
      (tester) async {
    final api = await _pump(tester);
    await _draftStrawHats(tester, api);

    expect(api.scopes, ['草帽一伙全员']);
    // The same composer as the assistant page.
    expect(find.byKey(const ValueKey('import_composer')), findsOneWidget);
    expect(find.byKey(const ValueKey('import_input_surface')), findsOneWidget);
    expect(find.text('只包含当前成员'), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('import-item-g1')),
            matching: find.text('草帽一伙')),
        findsOneWidget);
    expect(find.text('已存在 · 复用'), findsNWidgets(2));
    expect(find.text('1 项待核对'), findsOneWidget);
    expect(find.text('需修改'), findsOneWidget);
    expect(find.textContaining('草帽一伙 · 船长'), findsOneWidget);
    expect(_commitButton(tester).onPressed, isNull);
    expect(find.text('还有 1 项需要修改'), findsOneWidget);

    // Leave Robin out, and the crew too: its relations are dropped. Robin's
    // fruit goes with her, since nobody else eats it.
    await tester.tap(find.descendant(
        of: find.byKey(const Key('import-item-c2')),
        matching: find.byType(Checkbox)));
    await tester.tap(find.descendant(
        of: find.byKey(const Key('import-item-g1')),
        matching: find.byType(Checkbox)));
    await tester.pump();
    expect(
        tester
            .widget<Checkbox>(find.descendant(
                of: find.byKey(const Key('import-item-f2')),
                matching: find.byType(Checkbox)))
            .value,
        isFalse);
    expect(_commitButton(tester).onPressed, isNotNull);
    expect(find.text('导入 3 项'), findsOneWidget);

    api.onCommit = (_) async => const ImportResult(
        [ImportCreated('c1', 'character', 'id-c1', '罗罗诺亚·索隆')], 2, 1, 0);
    await tester.tap(find.byKey(const Key('import-commit-button')));
    await tester.pump();
    await tester.pump();

    final sent = {for (final item in api.committed!) item.key: item};
    expect(sent.keys, ['f1', 'c1', 'c3']);
    expect(sent['c1']!.group, isNull);
    expect(sent['c3']!.fruits, ['f1']);
    expect(sent['c3']!.existingId, 'character-luffy');
    expect(sent['c1']!.data['attack'], 1100);
    expect(find.byKey(const Key('import-result')), findsOneWidget);
    expect(find.text('罗罗诺亚·索隆'), findsOneWidget);
    expect(find.byKey(const Key('import-commit-button')), findsNothing);
  });

  Future<(_FakeImportApi, _FakeAvatars, _FakeImageDao)> pumpWithAvatars(
      WidgetTester tester) async {
    final avatars = _FakeAvatars()
      ..found = {
        'c1': 'https://lain.bgm.test/zoro.jpg',
        'c2': 'https://lain.bgm.test/robin.jpg',
      };
    final images = _FakeImageDao();
    final api = await _pump(tester, avatars: avatars, images: images);
    await _draftStrawHats(tester, api);
    await tester.pump();
    api.onCommit = (_) async => const ImportResult([
          ImportCreated('g1', 'group', 'id-g1', '草帽一伙'),
          ImportCreated('f2', 'fruit', 'id-f2', '花花果实'),
          ImportCreated('c1', 'character', 'id-c1', '罗罗诺亚·索隆'),
        ], 2, 1, 2);
    // Leave Robin out so the import can go ahead.
    await tester.tap(find.descendant(
        of: find.byKey(const Key('import-item-c2')),
        matching: find.byType(Checkbox)));
    await tester.pump();
    return (api, avatars, images);
  }

  Future<void> importNow(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('import-commit-button')));
    for (var i = 0; i < 3; i++) {
      await tester.pump();
    }
  }

  testWidgets('uploads the character avatars the reviewer kept after importing',
      (tester) async {
    final (api, avatars, images) = await pumpWithAvatars(tester);
    // Two new characters; Luffy is reused, fruits and groups get none.
    expect(
        find.descendant(
            of: find.byKey(const Key('import-avatar-status')),
            matching: find.textContaining('找到 2/2 个角色头像')),
        findsOneWidget);
    expect(find.byKey(const Key('import-avatar-g1')), findsNothing);
    expect(find.byKey(const Key('import-avatar-f2')), findsNothing);

    // Skipping and bringing back an avatar keeps it.
    await tester.tap(find.byKey(const Key('import-avatar-c1')));
    await tester.pump();
    expect(find.byTooltip('使用这个头像'), findsOneWidget);
    await tester.tap(find.byKey(const Key('import-avatar-c1')));
    await tester.pump();
    await importNow(tester);

    // Robin was left out, so only Zoro's avatar is uploaded.
    expect(avatars.prepared, ['https://lain.bgm.test/zoro.jpg']);
    expect(images.uploads.map((u) => (u.resourceId, u.type, u.image)), [
      ('id-c1', ResourceType.CHARACTER, 'iVBORw=='),
    ]);
    expect(api.committed!.every((i) => !i.toJson().containsKey('avatarUrl')),
        isTrue);
    expect(find.text('已上传 1 个头像。'), findsOneWidget);
  });

  testWidgets('a skipped avatar is not uploaded', (tester) async {
    final (_, avatars, images) = await pumpWithAvatars(tester);
    await tester.tap(find.byKey(const Key('import-avatar-c1')));
    await tester.pump();
    await importNow(tester);
    expect(avatars.prepared, isEmpty);
    expect(images.uploads, isEmpty);
    expect(find.byKey(const Key('import-avatar-status')), findsNothing);
  });

  testWidgets('talks with the AI to revise the draft', (tester) async {
    final api = await _pump(tester);
    await _draftStrawHats(tester, api);
    expect(find.textContaining('起草了 1 个团体、2 个果实、3 个角色'), findsOneWidget);
    // Leave the crew out first: the revision keeps that choice.
    await tester.tap(_in('g1', find.byType(Checkbox)));
    await tester.pump();

    await _say(tester, '去掉索隆，加上乌索普');
    await tester.pump();
    final (items, history, instruction) = api.revised.single;
    expect(instruction, '去掉索隆，加上乌索普');
    expect(history.map((t) => (t.user, t.text)).first, (true, '草帽一伙全员'));
    expect(history, hasLength(2));
    expect(items.map((i) => i.key), ['g1', 'f1', 'f2', 'c1', 'c2', 'c3']);

    api.revisions.add(const ImportProgress('正在理解你的修改…'));
    await tester.pump();
    expect(find.text('正在理解你的修改…'), findsOneWidget);
    // The list waits for the revision.
    await tester.tap(_in('c3', find.byType(Checkbox)), warnIfMissed: false);
    await tester.pump();
    expect(_checked(tester, 'c3'), isTrue);

    final revised = _strawHats().items
      ..removeWhere((i) => i.key == 'c1')
      ..add(ImportItem(
          key: 'c4',
          type: 'character',
          data: _character('乌索普', 'Usopp'),
          group: 'g1',
          position: 'combatant'));
    api.revisions.add(ImportDraftReady(ImportDraft(revised, const [],
        reply: '去掉了索隆，加上了乌索普。', changed: ['c4'])));
    await tester.pump();
    await tester.pump();

    expect(find.text('去掉索隆，加上乌索普'), findsOneWidget); // the request
    expect(find.text('去掉了索隆，加上了乌索普。'), findsOneWidget); // the reply
    expect(find.byKey(const Key('import-item-c1')), findsNothing);
    expect(_in('c4', find.text('刚修改')), findsOneWidget);
    expect(_in('c3', find.text('刚修改')), findsNothing);
    expect(_checked(tester, 'g1'), isFalse);
    expect(_checked(tester, 'c4'), isTrue);
    await tester.ensureVisible(find.byKey(const Key('import-review-revision')));
    await tester.tap(find.byKey(const Key('import-review-revision')));
    await tester.pumpAndSettle();
    expect(find.text('罗罗诺亚·索隆 · 移除'), findsOneWidget);
    expect(find.text('乌索普 · 新增'), findsOneWidget);
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('import-undo-revision')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('import-item-c1')), findsOneWidget);
    expect(find.byKey(const Key('import-item-c4')), findsNothing);
    expect(_checked(tester, 'g1'), isFalse); // reviewer choices survive undo
    expect(find.byKey(const Key('import-undo-revision')), findsNothing);
  });

  testWidgets('keeps every request, across a new draft and leaving the page',
      (tester) async {
    final api = await _pump(tester);
    await _draftStrawHats(tester, api);
    await _say(tester, '去掉索隆');
    await tester.pump();
    api.revisions.add(ImportDraftReady(ImportDraft(_strawHats().items, const [],
        reply: '去掉了索隆。', changed: const [])));
    await tester.pump();

    // Leave the page and come back: the conversation and the draft are kept.
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('zh'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: ImportView()),
    ));
    await tester.pump();
    for (final text in ['草帽一伙全员', '去掉索隆', '去掉了索隆。']) {
      expect(find.text(text), findsOneWidget);
    }
    expect(find.byKey(const Key('import-item-c2')), findsOneWidget);

    // A new draft keeps what was said, and its revisions only see their own.
    await tester.tap(find.byKey(const Key('import-new-draft')));
    await tester.pump();
    expect(find.byKey(const Key('import-item-c2')), findsNothing);
    await _say(tester, '唐吉诃德家族');
    await tester.pump();
    expect(api.scopes, ['草帽一伙全员', '唐吉诃德家族']);
    api.events.add(ImportDraftReady(_strawHats()));
    await tester.pump();
    for (final text in ['草帽一伙全员', '去掉索隆', '开始新草稿', '唐吉诃德家族']) {
      expect(find.text(text), findsOneWidget);
    }
    await _say(tester, '加上多弗朗明哥');
    await tester.pump();
    final history = api.revised.last.$2;
    expect(history.first.text, '唐吉诃德家族');
    expect(history.map((t) => t.text), isNot(contains('去掉索隆')));
  });

  testWidgets('a new fruit needs a holder before it can be imported',
      (tester) async {
    final api = await _pump(tester);
    await _draftStrawHats(tester, api);
    // Leaving Robin out takes her fruit with her; taking the fruit back alone
    // leaves it without a holder.
    await tester.tap(_in('c2', find.byType(Checkbox)));
    await tester.pump();
    expect(_checked(tester, 'f2'), isFalse);
    await tester.tap(_in('f2', find.byType(Checkbox)));
    await tester.pump();
    expect(_in('f2', find.text('还没有')), findsOneWidget);
    expect(_in('f2', find.text('需修改')), findsOneWidget);
    expect(_commitButton(tester).onPressed, isNull);
    expect(find.byKey(const Key('import-revise-holders')), findsOneWidget);

    // Give it to Zoro instead.
    await tester.tap(find.byKey(const Key('import-assign-f2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('罗罗诺亚·索隆').last);
    await tester.pumpAndSettle();
    expect(_in('f2', find.text('罗罗诺亚·索隆')), findsOneWidget);
    expect(_in('c1', find.textContaining('花花果实')), findsOneWidget);
    expect(find.byKey(const Key('import-revise-holders')), findsNothing);
    expect(_commitButton(tester).onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('import-commit-button')));
    await tester.pump();
    final sent = {for (final item in api.committed!) item.key: item};
    expect(sent['c1']!.fruits, ['f2']);
  });

  testWidgets('the editor groups fields and moves a fruit between holders',
      (tester) async {
    final api = await _pump(tester);
    await _draftStrawHats(tester, api);

    await tester.tap(_in('c1', find.byIcon(Icons.edit_outlined)));
    await tester.pumpAndSettle();
    for (final section in ['名称', '身份', '资料', '战斗属性', '关系']) {
      expect(find.text(section), findsOneWidget);
    }
    expect(find.text('10 – 1500'), findsOneWidget); // attack's range
    expect(find.text('AI 不确定'), findsOneWidget); // the bounty
    await tester.tap(find.byTooltip('关闭'));
    await tester.pumpAndSettle();

    // Picking another fruit for Robin replaces hers: a character holds one.
    await tester.tap(_in('c2', find.byIcon(Icons.edit_outlined)));
    await tester.pumpAndSettle();
    expect(find.text('吃下的果实（只能 1 个）'), findsOneWidget);
    await tester.tap(find.byKey(const Key('import-link-f1')));
    await tester.tap(find.byKey(const Key('import-editor-save')));
    await tester.pumpAndSettle();
    expect(_in('c2', find.textContaining('橡胶果实')), findsOneWidget);
    expect(_in('c2', find.textContaining('花花果实')), findsNothing);
    await tester.tap(find.descendant(
        of: find.byKey(const Key('import-item-c2')),
        matching: find.byIcon(Icons.edit_outlined)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('import-link-f2')));
    await tester.tap(find.byKey(const Key('import-editor-save')));
    await tester.pumpAndSettle();

    // Robin's fruit goes to Zoro.
    await tester.tap(_in('f2', find.byIcon(Icons.edit_outlined)));
    await tester.pumpAndSettle();
    expect(find.text('效果'), findsOneWidget);
    await tester.tap(find.byKey(const Key('import-link-c1')));
    await tester.tap(find.byKey(const Key('import-link-c2')));
    await tester.tap(find.byKey(const Key('import-editor-save')));
    await tester.pumpAndSettle();
    expect(_in('f2', find.text('罗罗诺亚·索隆')), findsOneWidget);
    expect(_in('f2', find.text('妮可·罗宾')), findsNothing);
    expect(_in('c2', find.textContaining('花花果实')), findsNothing);
  });

  testWidgets('editing a drafted item fixes it', (tester) async {
    final api = await _pump(tester, language: 'en');
    await _draftStrawHats(tester, api);
    expect(_commitButton(tester).onPressed, isNull);
    final edited =
        GetIt.instance<ImportSession>().items.firstWhere((i) => i.key == 'c2');
    edited.uncertain.add('attack');

    await tester.tap(find.descendant(
        of: find.byKey(const Key('import-item-c2')),
        matching: find.byIcon(Icons.edit_outlined)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('import-field-race')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Human').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('import-field-attack')), '1,050');
    await tester.tap(find.byKey(const Key('import-editor-save')));
    await tester.pumpAndSettle();

    expect(find.text('Needs fixing'), findsNothing);
    expect(_commitButton(tester).onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('import-commit-button')));
    await tester.pump();
    final sent = api.committed!.firstWhere((i) => i.key == 'c2');
    expect(sent.data['race'], 'HUMAN');
    expect(sent.data['attack'], 1050);
    expect(sent.uncertain, isNot(contains('attack')));
    expect(sent.fruits, ['f2']);
  });

  testWidgets('a rejected import shows every problem and keeps the draft',
      (tester) async {
    final api = await _pump(tester);
    await _draftStrawHats(tester, api);
    await tester.tap(find.descendant(
        of: find.byKey(const Key('import-item-c2')),
        matching: find.byType(Checkbox)));
    await tester.pump();

    api.onCommit = (_) async => throw const ImportRejected('有内容需要修改,未导入任何数据。', [
          ImportProblem('c1', '已经存在同名资源，请重新起草以复用它。'),
          ImportProblem(null, '一次最多导入 60 项。'),
        ]);
    await tester.tap(find.byKey(const Key('import-commit-button')));
    await tester.pump();
    await tester.pump();

    expect(find.text('已经存在同名资源，请重新起草以复用它。'), findsOneWidget);
    expect(find.text('一次最多导入 60 项。'), findsOneWidget);
    expect(find.byKey(const Key('import-result')), findsNothing);
    expect(_commitButton(tester).onPressed, isNull); // Zoro must be fixed first
  });

  testWidgets('a failed draft shows the server message', (tester) async {
    final api = await _pump(tester);
    await _say(tester, '不存在的范围');
    await tester.pump();
    api.events.add(
        const ImportFailure('invalid_request', '没有找到这个范围里的角色、果实或团体，换个说法试试。'));
    await tester.pump();
    expect(find.text('没有找到这个范围里的角色、果实或团体，换个说法试试。'), findsOneWidget);
    expect(find.text('不存在的范围'), findsOneWidget); // the request stays too
    expect(find.byKey(const Key('import-commit-button')), findsNothing);
  });

  testWidgets('only NIKA can use the page', (tester) async {
    await _pump(tester, role: UserRole.ADMIN);
    expect(find.text('只有 NIKA 可以使用批量录入。'), findsOneWidget);
    expect(find.byKey(const ValueKey('import_input')), findsNothing);
  });
}
