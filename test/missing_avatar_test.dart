import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/components/image_cache_manager.dart';
import 'package:one_piece_battles_flutter/components/image_lazy_loader.dart';
import 'package:one_piece_battles_flutter/l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:one_piece_battles_flutter/repository/group_dao.dart';
import 'package:one_piece_battles_flutter/repository/image_dao.dart';
import 'package:one_piece_battles_flutter/views/group/group_detail_controller.dart';
import 'package:one_piece_battles_flutter/views/group/widgets/group_members_panel.dart';
import 'package:openapi/api.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Records which images are requested; the downloads never finish.
class _RecordingImageDao extends ImageDao {
  _RecordingImageDao() : super.empty();

  final requested = <String>[];

  @override
  Future<Uint8List> loadImageBytes(String uri, {bool? fullImage}) {
    requested.add(uri);
    return Completer<Uint8List>().future;
  }
}

// Resources created by the AI batch import or the assistant have no avatar
// (imageUri is null) until someone uploads one.
void main() {
  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    ImageCacheManager.clear();
  });
  tearDown(() async => GetIt.I.reset());

  testWidgets('a failing avatar URI does not stall the other lazy avatars',
      (tester) async {
    final images = _RecordingImageDao();
    GetIt.I.registerSingleton<ImageDao>(images);
    await tester.pumpWidget(MaterialApp(
      home: Column(children: [
        ImageLazyLoader(
            uriProvider: () => throw StateError('no avatar'),
            width: 24,
            borderWidth: 1,
            borderRadios: 12,
            lazy: true),
        ImageLazyLoader(
            uriProvider: () => 'https://oss.example/perona.png',
            width: 24,
            borderWidth: 1,
            borderRadios: 12,
            lazy: true),
      ]),
    ));
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(images.requested, ['https://oss.example/perona.png']);
  });

  testWidgets('crew members without an avatar still render in group detail',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    GetIt.I.registerSingleton<Locale>(const Locale('en'));
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    final controller = GroupDetailController(
      groupDao: GroupDao.empty(),
      imageDao: ImageDao.empty(),
      characterDao: CharacterDao.empty(),
    );
    addTearDown(controller.dispose);
    final crew = GroupFullView(
      id: 'thriller-bark-pirates',
      name: I18nText(enUS: 'Thriller Bark Pirates', zhCN: '月光莫利亚海贼团'),
      groupCategory: GroupCategory.pirate,
      characters: [
        CharacterInGroupView(
          id: 'membership',
          groupId: 'thriller-bark-pirates',
          characterId: 'perona',
          name: I18nText(enUS: 'Perona', zhCN: '佩罗娜'),
          position: GroupPosition.member,
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
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
    expect(tester.takeException(), isNull);
    expect(find.text('Perona'), findsOneWidget);
  });
}
