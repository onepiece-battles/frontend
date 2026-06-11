import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:openapi/api.dart';

import '../../l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/components/image_lazy_loader.dart';
import 'package:one_piece_battles_flutter/repository/battle_dao.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:one_piece_battles_flutter/repository/file_dao.dart';
import 'package:one_piece_battles_flutter/repository/group_dao.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:one_piece_battles_flutter/utils/pdf_downloader_stub.dart'
    if (dart.library.html) 'package:one_piece_battles_flutter/utils/pdf_downloader_web.dart';
import 'constants/onepiece_colors.dart';
import 'constants/onepiece_fonts.dart';

GetIt getIt = GetIt.instance;

class UserHome extends StatefulWidget {
  final String userId;

  const UserHome({super.key, required this.userId});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  late Future myFuture;
  bool currentRoleOnly = true;
  List<CharacterListView> characters = [];
  List<GroupListView> groups = [];
  List<BattleListView> battles = [];

  // ... [Keep your API call methods: listCharacters, listGroups, listBattles, _updateData, initState unchanged] ...

  Future<ListCharacterResponse?> listCharacters() async {
    ListCharacterRequest listCharacterRequest = ListCharacterRequest(
        pageSize: 100,
        pageIndex: 1,
        sortKeys: [],
        characterFilter: CharacterFilter(
            languageCode: I18nHelper.getLanguageCode(),
            userId: widget.userId,
            roleId: currentRoleOnly ? getIt<User>().loginRoleId : null));
    return await getIt<CharacterDao>().listCharacter(listCharacterRequest);
  }

  Future<ListGroupResponse?> listGroups() async {
    ListGroupRequest listGroupRequest = ListGroupRequest(
        pageSize: 100,
        pageIndex: 1,
        sortKeys: [],
        groupFilter: GroupFilter(
            languageCode: I18nHelper.getLanguageCode(),
            userId: widget.userId,
            roleId: currentRoleOnly ? getIt<User>().loginRoleId : null));
    return await getIt<GroupDao>().listGroups(listGroupRequest);
  }

  Future<ListBattleResponse?> listBattles() async {
    ListBattleRequest request = ListBattleRequest(
        pageSize: 100,
        pageIndex: 1,
        sortKeys: [],
        battleFilter: BattleFilter(
            userId: widget.userId,
            roleId: currentRoleOnly ? getIt<User>().loginRoleId : null));
    return await getIt<BattleDao>().listBattles(request);
  }

  _updateData(List<dynamic> widgets) {
    final r0 = widgets[0];
    final r1 = widgets[1];
    final r2 = widgets[2];
    characters = (r0 is ListCharacterResponse) ? (r0.characters) : [];
    groups = (r1 is ListGroupResponse) ? (r1.groups) : [];
    battles = (r2 is ListBattleResponse) ? (r2.battles) : [];
  }

  @override
  void initState() {
    super.initState();
    myFuture = Future.wait([listCharacters(), listGroups(), listBattles()],
        eagerError: false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: myFuture as Future<List<dynamic>>,
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.loading,
                style: OnepieceFonts.loadingFont,
              ),
            );
          }
          _updateData(snapshot.data!);

          // REFACTORED: Use CustomScrollView with Slivers
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _getHeader(context),
                    // Show only if this user has more than one role
                    if (getIt<User>().userRoles.length > 1) _getRoleToggle(),

                    // Section Title: Characters
                    _getSectionTitle(AppLocalizations.of(context)!.myCharacters),
                  ]),
                ),
              ),

              // Character Grid
              _getCharacterSliverGrid(context),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Section Title: Groups
                    _getSectionTitle(AppLocalizations.of(context)!.myGroups),
                  ]),
                ),
              ),

              // Group Grid
              _getGroupSliverGrid(context),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Section Title: Battles
                    _getSectionTitle(AppLocalizations.of(context)!.myBattles),
                  ]),
                ),
              ),

              // Battle Grid
              _getBattleSliverGrid(context),

              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          );
        } else {
          return Center(
            child: Text(
              AppLocalizations.of(context)!.loading,
              style: OnepieceFonts.loadingFont,
            ),
          );
        }
      },
    );
  }

  Widget _getRoleToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        height: 35,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.showAllRoleResources,
              style: OnepieceFonts.smallContentStyle,
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  currentRoleOnly = !currentRoleOnly;
                  myFuture = Future.wait(
                      [listCharacters(), listGroups(), listBattles()],
                      eagerError: false);
                });
              },
              hoverColor: Colors.transparent,
              splashRadius: 1,
              icon: Icon(
                !currentRoleOnly ? Icons.check_box : Icons.check_box_outline_blank,
                color: OnepieceColors.fancyBlue,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
      child: Text(
        title,
        style: OnepieceFonts.contentStyleBoldFancyBlue,
      ),
    );
  }

  Widget _getHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18.0),
      child: Text(
        AppLocalizations.of(context)!.homePage,
        style: OnepieceFonts.headerStyle,
      ),
    );
  }

  // --- REFACTORED SLIVER METHODS ---

  Widget _getCharacterSliverGrid(BuildContext context) {
    if (characters.isEmpty) return _getEmptySliver(context, "createCharacter");

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 110,
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
          childAspectRatio: 1.0, // Adjust this ratio based on your lazy loader aspect
        ),
        delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
            return Tooltip(
              preferBelow: true,
              message: I18nHelper.getDisplayNameFromI18n(characters[index].name),
              child: InkWell(
                splashColor: Colors.transparent,
                hoverColor: Colors.transparent,
                onTap: () {
                  context.goNamed('characterDetails',
                      extra: characters[index].id,
                      pathParameters: {
                        'name': I18nHelper.getDisplayNameFromI18n(
                            characters[index].name)
                      });
                },
                child: ImageLazyLoader(
                    uriProvider: () => characters[index].imageUri ?? '',
                    width: 100,
                    borderWidth: 2,
                    borderRadios: 100),
              ),
            );
          },
          childCount: characters.length,
        ),
      ),
    );
  }

  Widget _getGroupSliverGrid(BuildContext context) {
    if (groups.isEmpty) return _getEmptySliver(context, "createGroup");

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 110,
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
          childAspectRatio: 1.0,
        ),
        delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
            return Tooltip(
              message: I18nHelper.getDisplayNameFromI18n(groups[index].name),
              preferBelow: true,
              child: InkWell(
                  splashColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  onTap: () {
                    context.goNamed('groupDetails',
                        extra: groups[index].id,
                        pathParameters: {
                          'name': I18nHelper.getDisplayNameFromI18n(
                              groups[index].name)
                        });
                  },
                  child: ImageLazyLoader(
                      uriProvider: () => groups[index].imageUri ?? '',
                      width: 100,
                      borderWidth: 2,
                      borderRadios: 10)),
            );
          },
          childCount: groups.length,
        ),
      ),
    );
  }

  Widget _getBattleSliverGrid(BuildContext context) {
    Map<BattleStatus, String> battleStatusToDisplayName = {
      BattleStatus.CREATED: AppLocalizations.of(context)!.battleStatusCreated,
      BattleStatus.IN_PROGRESS: AppLocalizations.of(context)!.battleStatusStarted,
      BattleStatus.FAILED: AppLocalizations.of(context)!.battleStatusFailed,
      BattleStatus.FINISHED: AppLocalizations.of(context)!.battleStatusFinished
    };

    if (battles.isEmpty) return _getEmptySliver(context, "createBattle");

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 350, // Slightly increased to fit content
          mainAxisExtent: 250, // Fixed height for battle card
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, int index) => _buildBattleCard(
              context, battles[index], battleStatusToDisplayName),
          childCount: battles.length,
        ),
      ),
    );
  }

  Widget _getEmptySliver(BuildContext context, String routeName) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0, bottom: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(AppLocalizations.of(context)!.notCreated),
            ),
            TextButton(
                onPressed: () {
                  context.goNamed(routeName);
                },
                child: Text(AppLocalizations.of(context)!.goToCreationPage))
          ],
        ),
      ),
    );
  }

  Widget _buildBattleCard(BuildContext context, BattleListView battle, Map<BattleStatus, String> statusMap) {
    final execution = battle.battleExecution;
    final starter = battle.starter;
    final receiver = battle.receiver;
    if (execution == null || starter == null || receiver == null) {
      return const SizedBox.shrink();
    }

    return InkWell(
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      onTap: () {
        context.goNamed('battleDetails',
            extra: battle.id,
            pathParameters: {'id': battle.id});
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: OnepieceColors.menuBackgroundColor,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ImageLazyLoader(
                          uriProvider: () => starter.imageUri ?? '',
                          width: 40,
                          borderWidth: 1.5,
                          borderRadios: 40),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(5, 5, 0, 0),
                        child: Text(
                          I18nHelper.getDisplayNameFromI18n(starter.name),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(execution.starterScoreBefore?.toString() ?? '',
                          style: OnepieceFonts.boldFancySmallFont)
                    ],
                  ),
                ),
                Center(
                  child: Text(
                    "vs",
                    style: OnepieceFonts.boldFancyBlueHintFont,
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ImageLazyLoader(
                          uriProvider: () => receiver.imageUri ?? '',
                          width: 40,
                          borderWidth: 1.5,
                          borderRadios: 40),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(5, 5, 0, 0),
                        child: Text(
                          I18nHelper.getDisplayNameFromI18n(receiver.name),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(execution.receiverScoreBefore?.toString() ?? '',
                          style: OnepieceFonts.boldFancySmallFont)
                    ],
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5.0),
                  color: OnepieceColors.fancyBlue,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(statusMap[execution.battleStatus] ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: OnepieceFonts.boldFancyWhiteSmallFont),
                      ),
                      if (execution.battleReportStage == BattleReportStage.FINISHED)
                        _buildPdfButton(battle),
                      if (execution.battleReportStage != BattleReportStage.FINISHED)
                        SvgPicture.asset(
                          'asset/images/svgs/pdf_black.svg',
                          width: 20,
                          height: 20,
                          colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                        )
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPdfButton(BattleListView battle) {
    final reportFileId = battle.battleExecution?.reportFileId;
    if (reportFileId == null) return const SizedBox.shrink();

    return Tooltip(
      message: AppLocalizations.of(context)!.downloadReport,
      child: InkWell(
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
        onTap: () {
          getIt<FileDao>()
              .downloadFile(DownloadFileRequest(id: reportFileId))
              .then((response) async {
            if (response?.fileData == null) return;
            var pdf = base64Decode(response!.fileData!);
            downloadPdf(pdf, "${response.fileName}.pdf",
                response.httpMimeType);
          });
        },
        child: SvgPicture.asset(
          'asset/images/svgs/pdf.svg',
          width: 20,
          height: 20,
        ),
      ),
    );
  }
}
