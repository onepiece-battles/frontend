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

class _HierarchyDao extends GroupDao {
  _HierarchyDao() : super.empty();

  @override
  Future<ListChildGroupsResponse?> listChildGroups(
      ListChildGroupsRequest request) async {
    return ListChildGroupsResponse(childGroups: [
      Group(
        id: 'grandchild',
        name: I18nText(enUS: 'Grandchild', zhCN: '下级团体'),
        groupCategory: GroupCategory.pirate,
        imageUri: '',
      ),
    ]);
  }
}

void main() {
  testWidgets('expanding a nested branch reveals its lazy loaded child',
      (tester) async {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    GetIt.I.registerSingleton<Locale>(const Locale('en'));
    addTearDown(() => GetIt.I.reset());
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    final controller = GroupDetailController(
      groupDao: _HierarchyDao(),
      imageDao: ImageDao.empty(),
      characterDao: CharacterDao.empty(),
    );
    addTearDown(controller.dispose);
    final root = GroupFullView(
      id: 'root',
      name: I18nText(enUS: 'Root', zhCN: '根团体'),
      groupCategory: GroupCategory.group,
      imageUri: '',
      subGroups: [
        Group(
          id: 'branch',
          name: I18nText(enUS: 'Branch', zhCN: '分支团体'),
          groupCategory: GroupCategory.group,
          imageUri: '',
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
            groupFullView: root,
            controller: controller,
            pageScrollController: scroll,
            editButtonVisible: false,
          ),
        ),
      ),
    ));
    await tester.pump();
    expect(find.byType(InteractiveViewer), findsNothing);
    expect(find.text('Branch'), findsOneWidget);
    expect(find.text('Grandchild'), findsNothing);

    await tester.tap(find.byTooltip('Expand branch'));
    await tester.pumpAndSettle();
    expect(find.text('Grandchild'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
