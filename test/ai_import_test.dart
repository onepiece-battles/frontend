import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';
import 'package:one_piece_battles_flutter/ai/import_api.dart';
import 'package:one_piece_battles_flutter/ai/import_fields.dart';
import 'package:one_piece_battles_flutter/ai/json_events.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/views/assistant/import_view.dart';

/// Stands in for the server: [events] feeds the draft stream, [onCommit]
/// answers the import.
class _FakeImportApi extends ImportApi {
  _FakeImportApi() : super(ApiClient());

  final events = StreamController<ImportEvent>();
  final scopes = <String>[];
  List<ImportItem>? committed;
  Future<ImportResult> Function(List<ImportItem> items) onCommit =
      (_) async => const ImportResult([], 0, 0, 0);

  @override
  Stream<ImportEvent> draft(String scope, {String? language}) {
    scopes.add(scope);
    return events.stream;
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
      'energy': 40,
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

Future<_FakeImportApi> _pump(WidgetTester tester,
    {String language = 'zh', UserRole role = UserRole.NIKA}) async {
  tester.view.physicalSize = const Size(1100, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final api = _FakeImportApi();
  GetIt.instance
    ..registerSingleton<ImportApi>(api)
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

Future<void> _draftStrawHats(WidgetTester tester, _FakeImportApi api) async {
  await tester.enterText(find.byKey(const Key('import-scope-field')), '草帽一伙全员');
  await tester.tap(find.byKey(const Key('import-draft-button')));
  await tester.pump();
  api.events.add(const ImportProgress('正在梳理名单…'));
  await tester.pump();
  expect(find.text('正在梳理名单…'), findsOneWidget);
  api.events.add(ImportDraftReady(_strawHats()));
  await tester.pump();
}

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

  testWidgets('drafts, leaves out what needs fixing and imports the rest',
      (tester) async {
    final api = await _pump(tester);
    await _draftStrawHats(tester, api);

    expect(api.scopes, ['草帽一伙全员']);
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

    // Leave Robin out, and the crew too: its relations are dropped.
    await tester.tap(find.descendant(
        of: find.byKey(const Key('import-item-c2')),
        matching: find.byType(Checkbox)));
    await tester.tap(find.descendant(
        of: find.byKey(const Key('import-item-g1')),
        matching: find.byType(Checkbox)));
    await tester.pump();
    expect(_commitButton(tester).onPressed, isNotNull);
    expect(find.text('导入 4 项'), findsOneWidget);

    api.onCommit = (_) async => const ImportResult([
          ImportCreated('f2', 'fruit', 'id-f2', '花花果实'),
          ImportCreated('c1', 'character', 'id-c1', '罗罗诺亚·索隆')
        ], 2, 1, 0);
    await tester.tap(find.byKey(const Key('import-commit-button')));
    await tester.pump();
    await tester.pump();

    final sent = {for (final item in api.committed!) item.key: item};
    expect(sent.keys, ['f1', 'f2', 'c1', 'c3']);
    expect(sent['c1']!.group, isNull);
    expect(sent['c3']!.fruits, ['f1']);
    expect(sent['c3']!.existingId, 'character-luffy');
    expect(sent['c1']!.data['attack'], 1100);
    expect(find.byKey(const Key('import-result')), findsOneWidget);
    expect(find.text('罗罗诺亚·索隆'), findsOneWidget);
    expect(find.byKey(const Key('import-commit-button')), findsNothing);
  });

  testWidgets('editing a drafted item fixes it', (tester) async {
    final api = await _pump(tester, language: 'en');
    await _draftStrawHats(tester, api);
    expect(_commitButton(tester).onPressed, isNull);

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
    await tester.enterText(
        find.byKey(const Key('import-scope-field')), '不存在的范围');
    await tester.tap(find.byKey(const Key('import-draft-button')));
    await tester.pump();
    api.events.add(
        const ImportFailure('invalid_request', '没有找到这个范围里的角色、果实或团体，换个说法试试。'));
    await tester.pump();
    expect(find.text('没有找到这个范围里的角色、果实或团体，换个说法试试。'), findsOneWidget);
    expect(find.byKey(const Key('import-commit-button')), findsNothing);
  });

  testWidgets('only NIKA can use the page', (tester) async {
    await _pump(tester, role: UserRole.ADMIN);
    expect(find.text('只有 NIKA 可以使用批量录入。'), findsOneWidget);
    expect(find.byKey(const Key('import-scope-field')), findsNothing);
  });
}
