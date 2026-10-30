import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:one_piece_battles_flutter/repository/group_dao.dart';
import 'package:one_piece_battles_flutter/repository/image_dao.dart';
import 'package:one_piece_battles_flutter/views/group/group_detail_controller.dart';
import 'package:one_piece_battles_flutter/views/group/widgets/group_members_panel.dart';
import 'package:openapi/api.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Answers a character's full view and records which ids were asked for.
class _Characters extends CharacterDao {
  _Characters() : super.empty();

  final asked = <String>[];

  @override
  Future<CharacterFullView?> getCharacter(
      GetCharacterFullViewRequest request) async {
    final id = request.characterId ?? '';
    asked.add(id);
    return CharacterFullView(
      id: id,
      name: I18nText(zhCN: 'Baby-5', enUS: 'Baby-5'),
      maximumFruitCount: 1,
      score: 1000,
      baseGroupGain: 120,
      baseAttack: 640,
      baseDefense: 500,
      baseIntelligence: 110,
      baseBlood: 4200,
      baseSpeed: 90,
      attack: 641,
      defense: 501,
      intelligence: 111,
      blood: 4201,
      speed: 91,
      groupGain: 121,
      energy: 160,
      battleStyle: BattleStyle.RIFLE,
      race: Race.HUMAN,
    );
  }
}

void main() {
  testWidgets("expanding a member shows its stats, found by the member's id",
      (tester) async {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    GetIt.I.registerSingleton<Locale>(const Locale('zh'));
    addTearDown(() => GetIt.I.reset());
    final characters = _Characters();
    final controller = GroupDetailController(
      groupDao: GroupDao.empty(),
      imageDao: ImageDao.empty(),
      characterDao: characters,
    );
    addTearDown(controller.dispose);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    // As the group detail has long sent members: the character's id in `id`,
    // `character_id` empty.
    final crew = GroupFullView(
      id: 'donquixote',
      name: I18nText(zhCN: '唐吉诃德家族', enUS: 'Donquixote Family'),
      groupCategory: GroupCategory.underWorld,
      characters: [
        CharacterInGroupView(
          id: 'baby-5',
          name: I18nText(zhCN: 'Baby-5', enUS: 'Baby-5'),
          position: GroupPosition.member,
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          controller: scroll,
          child: GroupMembersPanel(
            groupFullView: crew,
            controller: controller,
            pageScrollController: scroll,
            editButtonVisible: false,
          ),
        ),
      ),
    ));
    await tester.pump();

    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();

    expect(characters.asked, ['baby-5']);
    expect(find.text('641'), findsOneWidget); // attack
    expect(tester.takeException(), isNull);
  });
}
