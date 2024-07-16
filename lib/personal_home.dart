import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/components/image_lazy_loader.dart';
import 'package:one_piece_battles_flutter/repository/battle_dao.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:one_piece_battles_flutter/repository/file_dao.dart';
import 'package:one_piece_battles_flutter/repository/group_dao.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:openapi/api.dart';
import 'constants/onepiece_colors.dart';
import 'constants/onepiece_fonts.dart';
import 'dart:html' as html;

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
  Future<ListCharacterResponse?> listCharacters() async {
    ListCharacterRequest listCharacterRequest = ListCharacterRequest(
        pageSize: 1,
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
        pageSize: 1,
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
        pageSize: 1,
        pageIndex: 1,
        sortKeys: [],
        battleFilter: BattleFilter(
            userId: widget.userId,
            roleId: currentRoleOnly ? getIt<User>().loginRoleId : null));
    return await getIt<BattleDao>().listBattles(request);
  }

  _updateData(List<dynamic> widgets) {
    characters = (widgets[0] as ListCharacterResponse).characters;
    groups = (widgets[1] as ListGroupResponse).groups;
    battles = (widgets[2] as ListBattleResponse).battles;
  }

  @override
  void initState() {
    super.initState();
    myFuture = Future.wait([listCharacters(), listGroups(), listBattles()]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: myFuture as Future<List<dynamic>>,
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            _updateData(snapshot.data!);
            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _getHeader(context),
                      // show only if this user has more than one role
                      if (getIt<User>().userRoles.length > 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: SizedBox(
                            height: 35,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!
                                      .showAllRoleResources,
                                  style: OnepieceFonts.smallContentStyle,
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      currentRoleOnly = !currentRoleOnly;
                                      myFuture = Future.wait([
                                        listCharacters(),
                                        listGroups(),
                                        listBattles()
                                      ]);
                                    });
                                  },
                                  hoverColor: Colors.transparent,
                                  splashRadius: 1,
                                  icon: !currentRoleOnly
                                      ? const Icon(
                                          Icons.check_box,
                                          color: OnepieceColors.fancyBlue,
                                          size: 20,
                                        )
                                      : const Icon(
                                          Icons.check_box_outline_blank,
                                          color: OnepieceColors.fancyBlue,
                                          size: 20,
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
                        child: Text(
                          AppLocalizations.of(context)!.myCharacters,
                          style: OnepieceFonts.contentStyleBoldFancyBlue,
                        ),
                      ),
                      _getCharacterWall(context),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
                        child: Text(
                          AppLocalizations.of(context)!.myGroups,
                          style: OnepieceFonts.contentStyleBoldFancyBlue,
                        ),
                      ),
                      _getGroupWall(context),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
                        child: Text(
                          AppLocalizations.of(context)!.myBattles,
                          style: OnepieceFonts.contentStyleBoldFancyBlue,
                        ),
                      ),
                      _getBattleWall(context),
                      const SizedBox(
                        height: 100,
                      )
                    ],
                  )),
            );
          } else {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.loading,
                style: OnepieceFonts.loadingFont,
              ),
            );
          }
        });
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

  Widget _getCharacterWall(BuildContext context) {
    if (characters.isEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(AppLocalizations.of(context)!.notCreated),
          ),
          TextButton(
              onPressed: () {
                context.goNamed("createCharacter");
              },
              child: Text(AppLocalizations.of(context)!.goToCreationPage))
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraint) {
        int crossAxisCount = (constraint.maxWidth / 110).ceil().clamp(2, 8);
        return SizedBox(
          width: 880,
          height: ((characters.length / crossAxisCount).ceil() * 110.0)
              .clamp(110, 440),
          child: GridView.builder(
            itemCount: characters.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
            ),
            itemBuilder: (context, int index) => Tooltip(
              preferBelow: true,
              message:
                  I18nHelper.getDisplayNameFromI18n(characters[index].name),
              child: InkWell(
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
                    // key: UniqueKey(),
                    uriProvider:() =>  characters[index].imageUri!,
                    width: 100,
                    borderWidth: 2,
                    borderRadios: 100),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _getGroupWall(BuildContext context) {
    if (groups.isEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(AppLocalizations.of(context)!.notCreated),
          ),
          TextButton(
              onPressed: () {
                context.goNamed("createGroup");
              },
              child: Text(AppLocalizations.of(context)!.goToCreationPage))
        ],
      );
    }
    return LayoutBuilder(builder: (context, constraint) {
      int crossAxisCount = (constraint.maxWidth / 110).ceil().clamp(2, 8);
      return SizedBox(
        width: 880,
        height:
            ((groups.length / crossAxisCount).ceil() * 110.0).clamp(110, 400),
        child: GridView.builder(
          itemCount: groups.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
          ),
          itemBuilder: (BuildContext context, int index) => Tooltip(
            message: I18nHelper.getDisplayNameFromI18n(groups[index].name),
            preferBelow: true,
            child: InkWell(
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
                    // key: UniqueKey(),
                    uriProvider: () => groups[index].imageUri!,
                    width: 100,
                    borderWidth: 2,
                    borderRadios: 10)),
          ),
        ),
      );
    });
  }

  Widget _getBattleWall(BuildContext context) {
    Map<BattleStatus, String> battleStatusToDisplayName = {
      BattleStatus.CREATED: AppLocalizations.of(context)!.battleStatusCreated,
      BattleStatus.IN_PROGRESS:
          AppLocalizations.of(context)!.battleStatusStarted,
      BattleStatus.FAILED: AppLocalizations.of(context)!.battleStatusFailed,
      BattleStatus.FINISHED: AppLocalizations.of(context)!.battleStatusFinished
    };
    if (battles.isEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(AppLocalizations.of(context)!.notCreated),
          ),
          TextButton(
              onPressed: () {
                context.goNamed("createBattle");
              },
              child: Text(AppLocalizations.of(context)!.goToCreationPage))
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraint) {
        int crossAxisCount = (constraint.maxWidth / 250).ceil().clamp(2, 4);
        return SizedBox(
          width: 1000,
          height: ((battles.length / crossAxisCount).ceil() * 250.0)
              .clamp(250, 800),
          child: GridView.builder(
            itemCount: battles.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemBuilder: (context, int index) => InkWell(
              hoverColor: Colors.transparent,
              onTap: () {
                context.goNamed('battleDetails',
                    extra: battles[index].id,
                    pathParameters: {'id': battles[index].id});
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
                        const SizedBox(
                          width: 10,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ImageLazyLoader(
                                // key: UniqueKey(),
                                uriProvider: () => battles[index].starter!.imageUri!,
                                width: 40,
                                borderWidth: 1.5,
                                borderRadios: 40),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                              child: Text(I18nHelper.getDisplayNameFromI18n(
                                  battles[index].starter!.name)),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 5.0),
                              child: Text(
                                  battles[index]
                                      .battleExecution!
                                      .starterScoreBefore!
                                      .toString(),
                                  style: OnepieceFonts.boldFancySmallFont),
                            )
                          ],
                        ),
                        const Center(
                          child: Text(
                            "vs",
                            style: OnepieceFonts.contentStyleBoldFancyBlue,
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ImageLazyLoader(
                                // key: UniqueKey(),
                                uriProvider: () => battles[index].receiver!.imageUri!,
                                width: 40,
                                borderWidth: 1.5,
                                borderRadios: 40),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                              child: Text(I18nHelper.getDisplayNameFromI18n(
                                  battles[index].receiver!.name)),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 5.0),
                              child: Text(
                                  battles[index]
                                      .battleExecution!
                                      .receiverScoreBefore!
                                      .toString(),
                                  style: OnepieceFonts.boldFancySmallFont),
                            )
                          ],
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                              Text(
                                  battleStatusToDisplayName[battles[index]
                                      .battleExecution!
                                      .battleStatus!]!,
                                  style: OnepieceFonts.boldFancyWhiteSmallFont),
                              const SizedBox(
                                width: 30,
                              ),
                              Tooltip(
                                message: battles[index]
                                            .battleExecution!
                                            .battleReportStage ==
                                        BattleReportStage.FINISHED
                                    ? AppLocalizations.of(context)!
                                        .downloadReport
                                    : "",
                                child: InkWell(
                                  hoverColor: Colors.transparent,
                                  onTap: battles[index]
                                              .battleExecution!
                                              .battleReportStage ==
                                          BattleReportStage.FINISHED
                                      ? () {
                                          getIt<FileDao>()
                                              .downloadFile(DownloadFileRequest(
                                                  id: battles[index]
                                                      .battleExecution!
                                                      .reportFileId!))
                                              .then((response) async {
                                            debugPrint(
                                                'pdf downloading finish');
                                            var pdf = base64Decode(
                                                response!.fileData!);
                                            // pdfData.value = Uint8List.fromList(value!);
                                            final blob = html.Blob(
                                                [pdf], response.httpMimeType);
                                            final url = html.Url
                                                .createObjectUrlFromBlob(blob);
                                            final anchor = html.AnchorElement()
                                              ..href = url
                                              ..setAttribute('target', '_blank')
                                              ..download =
                                                  "${response.fileName}.pdf"
                                              ..style.display = 'none';
                                            // Add the anchor element to the document body.
                                            html.document.body?.append(anchor);
                                            // Programmatically click the anchor element to start the download.
                                            anchor.click();
                                            // Remove the anchor element after the download has started.
                                            anchor.remove();
                                            // Release the object URL to free up resources.
                                            html.Url.revokeObjectUrl(url);
                                          });
                                        }
                                      : null,
                                  child: battles[index]
                                              .battleExecution!
                                              .battleReportStage ==
                                          BattleReportStage.FINISHED
                                      ? SvgPicture.asset(
                                          'asset/images/svgs/pdf.svg',
                                          width: 20,
                                          height: 20,
                                        )
                                      : SvgPicture.asset(
                                          'asset/images/svgs/pdf_black.svg',
                                          width: 20,
                                          height: 20,
                                          color: Colors.grey,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
