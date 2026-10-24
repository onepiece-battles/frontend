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
import 'package:one_piece_battles_flutter/utils/responsive_breakpoints.dart';
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
  late Future<List<dynamic>> myFuture;
  bool currentRoleOnly = true;
  List<CharacterListView> myCharacters = [];
  List<CharacterListView> systemCharacters = [];
  List<GroupListView> myGroups = [];
  List<GroupListView> systemGroups = [];
  List<BattleListView> myBattles = [];
  List<BattleListView> systemBattles = [];

  bool get _isNika => getIt<User>().loginRole == UserRole.NIKA;

  // ... [Keep your API call methods: listCharacters, listGroups, listBattles, _updateData, initState unchanged] ...

  Future<ListCharacterResponse?> listCharacters({required bool system}) async {
    ListCharacterRequest listCharacterRequest = ListCharacterRequest(
        pageSize: 100,
        pageIndex: 1,
        sortKeys: [],
        characterFilter: CharacterFilter(
            languageCode: I18nHelper.getLanguageCode(),
            systemResource: system ? true : null,
            userId: system ? null : widget.userId,
            roleId:
                system || !currentRoleOnly ? null : getIt<User>().loginRoleId));
    return await getIt<CharacterDao>().listCharacter(listCharacterRequest);
  }

  Future<ListGroupResponse?> listGroups({required bool system}) async {
    ListGroupRequest listGroupRequest = ListGroupRequest(
        pageSize: 100,
        pageIndex: 1,
        sortKeys: [],
        groupFilter: GroupFilter(
            languageCode: I18nHelper.getLanguageCode(),
            systemResource: system ? true : null,
            userId: system ? null : widget.userId,
            roleId:
                system || !currentRoleOnly ? null : getIt<User>().loginRoleId));
    return await getIt<GroupDao>().listGroups(listGroupRequest);
  }

  Future<ListBattleResponse?> listBattles({required bool system}) async {
    ListBattleRequest request = ListBattleRequest(
        pageSize: 100,
        pageIndex: 1,
        sortKeys: [],
        battleFilter: BattleFilter(
            systemResource: system ? true : null,
            userId: system ? null : widget.userId,
            roleId:
                system || !currentRoleOnly ? null : getIt<User>().loginRoleId));
    return await getIt<BattleDao>().listBattles(request);
  }

  Future<List<dynamic>> _loadHomeData() {
    final futures = <Future<dynamic>>[
      listCharacters(system: false),
      listGroups(system: false),
      listBattles(system: false),
    ];
    if (!_isNika) {
      futures.addAll([
        listCharacters(system: true),
        listGroups(system: true),
        listBattles(system: true),
      ]);
    }
    return Future.wait(futures, eagerError: false);
  }

  _updateData(List<dynamic> widgets) {
    final r0 = widgets[0];
    final r1 = widgets[1];
    final r2 = widgets[2];
    myCharacters = (r0 is ListCharacterResponse) ? (r0.characters) : [];
    myGroups = (r1 is ListGroupResponse) ? (r1.groups) : [];
    myBattles = (r2 is ListBattleResponse) ? (r2.battles) : [];
    if (_isNika) {
      systemCharacters = [];
      systemGroups = [];
      systemBattles = [];
      return;
    }
    final r3 = widgets.length > 3 ? widgets[3] : null;
    final r4 = widgets.length > 4 ? widgets[4] : null;
    final r5 = widgets.length > 5 ? widgets[5] : null;
    systemCharacters = (r3 is ListCharacterResponse) ? r3.characters : [];
    systemGroups = (r4 is ListGroupResponse) ? r4.groups : [];
    systemBattles = (r5 is ListBattleResponse) ? r5.battles : [];
  }

  @override
  void initState() {
    super.initState();
    myFuture = _loadHomeData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: myFuture,
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
          final hasMyResources = myCharacters.isNotEmpty ||
              myGroups.isNotEmpty ||
              myBattles.isNotEmpty;

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
                    _getSectionHeader(
                      AppLocalizations.of(context)!.myResource,
                      initiallyExpanded: hasMyResources,
                      child: _buildResourceBundle(
                        context,
                        characterChild: _buildCharacterGrid(
                          context,
                          myCharacters,
                          showPlaceholderWhenEmpty: true,
                        ),
                        groupChild: _buildGroupGrid(
                          context,
                          myGroups,
                          showPlaceholderWhenEmpty: true,
                        ),
                        battleChild: _buildBattleGrid(
                          context,
                          myBattles,
                          showPlaceholderWhenEmpty: true,
                        ),
                      ),
                    ),
                    if (!_isNika)
                      _getSectionHeader(
                        AppLocalizations.of(context)!.systemResource,
                        initiallyExpanded: true,
                        child: _buildResourceBundle(
                          context,
                          characterChild: _buildCharacterGrid(
                            context,
                            systemCharacters,
                            showPlaceholderWhenEmpty: false,
                          ),
                          groupChild: _buildGroupGrid(
                            context,
                            systemGroups,
                            showPlaceholderWhenEmpty: false,
                          ),
                          battleChild: _buildBattleGrid(
                            context,
                            systemBattles,
                            showPlaceholderWhenEmpty: false,
                          ),
                        ),
                      ),
                  ]),
                ),
              ),

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
                  myFuture = _loadHomeData();
                });
              },
              hoverColor: Colors.transparent,
              splashRadius: 1,
              icon: Icon(
                !currentRoleOnly
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
                color: OnepieceColors.fancyBlue,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getSectionHeader(
    String title, {
    required Widget child,
    bool initiallyExpanded = false,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(0, 10, 0, 8),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: OnepieceColors.separator),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
          title: Text(
            title,
            style: const TextStyle(
              color: OnepieceColors.primaryLabel,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          iconColor: OnepieceColors.secondaryLabel,
          collapsedIconColor: OnepieceColors.secondaryLabel,
          children: [child],
        ),
      ),
    );
  }

  Widget _buildResourceBundle(
    BuildContext context, {
    required Widget characterChild,
    required Widget groupChild,
    required Widget battleChild,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResourceTypeTitle(AppLocalizations.of(context)!.character),
        characterChild,
        const SizedBox(height: 12),
        _buildResourceTypeTitle(AppLocalizations.of(context)!.group),
        groupChild,
        const SizedBox(height: 12),
        _buildResourceTypeTitle(AppLocalizations.of(context)!.battle),
        battleChild,
      ],
    );
  }

  Widget _buildResourceTypeTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: OnepieceColors.secondaryLabel,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _getHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Text(
        AppLocalizations.of(context)!.homePage,
        style: const TextStyle(
          color: OnepieceColors.primaryLabel,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildCharacterGrid(
    BuildContext context,
    List<CharacterListView> items, {
    required bool showPlaceholderWhenEmpty,
  }) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final maxExtent = isDesktop ? 150.0 : 120.0;
    final mainExtent = isDesktop ? 170.0 : 140.0;
    final imgSize = isDesktop ? 100.0 : 72.0;
    final itemCount =
        items.isEmpty && showPlaceholderWhenEmpty ? 1 : items.length;
    if (itemCount == 0) return _buildEmptyResourceStrip(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxExtent,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: mainExtent,
      ),
      itemCount: itemCount,
      itemBuilder: (_, i) {
        if (items.isEmpty) {
          return _buildPlaceholderCard(
            context,
            routeName: "createCharacter",
            imgSize: imgSize,
            borderRadius: 100,
          );
        }
        final character = items[i];
        return _buildImageCard(
          context,
          imageUri: character.imageUri ?? '',
          name: I18nHelper.getDisplayNameFromI18n(character.name),
          borderRadius: 100,
          imgSize: imgSize,
          onTap: () => context.goNamed('characterDetails',
              extra: character.id,
              pathParameters: {
                'name': I18nHelper.getDisplayNameFromI18n(character.name)
              }),
        );
      },
    );
  }

  Widget _buildGroupGrid(
    BuildContext context,
    List<GroupListView> items, {
    required bool showPlaceholderWhenEmpty,
  }) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final maxExtent = isDesktop ? 150.0 : 120.0;
    final mainExtent = isDesktop ? 170.0 : 140.0;
    final imgSize = isDesktop ? 100.0 : 72.0;
    final itemCount =
        items.isEmpty && showPlaceholderWhenEmpty ? 1 : items.length;
    if (itemCount == 0) return _buildEmptyResourceStrip(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxExtent,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: mainExtent,
      ),
      itemCount: itemCount,
      itemBuilder: (_, i) {
        if (items.isEmpty) {
          return _buildPlaceholderCard(
            context,
            routeName: "createGroup",
            imgSize: imgSize,
            borderRadius: 10,
          );
        }
        final group = items[i];
        return _buildImageCard(
          context,
          imageUri: group.imageUri ?? '',
          name: I18nHelper.getDisplayNameFromI18n(group.name),
          borderRadius: 10,
          imgSize: imgSize,
          onTap: () => context.goNamed('groupDetails',
              extra: group.id,
              pathParameters: {
                'name': I18nHelper.getDisplayNameFromI18n(group.name)
              }),
        );
      },
    );
  }

  Widget _buildBattleGrid(
    BuildContext context,
    List<BattleListView> items, {
    required bool showPlaceholderWhenEmpty,
  }) {
    final battleStatusToDisplayName = {
      BattleStatus.CREATED: AppLocalizations.of(context)!.battleStatusCreated,
      BattleStatus.IN_PROGRESS:
          AppLocalizations.of(context)!.battleStatusStarted,
      BattleStatus.FAILED: AppLocalizations.of(context)!.battleStatusFailed,
      BattleStatus.FINISHED: AppLocalizations.of(context)!.battleStatusFinished
    };
    final itemCount =
        items.isEmpty && showPlaceholderWhenEmpty ? 1 : items.length;
    if (itemCount == 0) return _buildEmptyResourceStrip(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 350,
        mainAxisExtent: 250,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (items.isEmpty) {
          return _buildPlaceholderCard(
            context,
            routeName: "createBattle",
            imgSize: 88,
            borderRadius: 10,
          );
        }
        return _buildBattleCard(
            context, items[index], battleStatusToDisplayName);
      },
    );
  }

  Widget _buildEmptyResourceStrip(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: OnepieceColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        AppLocalizations.of(context)!.empty,
        style: const TextStyle(
          color: OnepieceColors.secondaryLabel,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildPlaceholderCard(
    BuildContext context, {
    required String routeName,
    required double imgSize,
    required double borderRadius,
  }) {
    return Material(
      color: OnepieceColors.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.goNamed(routeName),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: imgSize,
                height: imgSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: OnepieceColors.separator,
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.add,
                  color: OnepieceColors.fancyBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.notCreated,
                style: const TextStyle(
                  color: OnepieceColors.secondaryLabel,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCard(BuildContext context,
      {required String imageUri,
      required String name,
      required double borderRadius,
      required double imgSize,
      required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: OnepieceColors.separator),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ImageLazyLoader(
                  uriProvider: () => imageUri,
                  width: imgSize,
                  borderWidth: 2,
                  borderRadios: borderRadius),
              const SizedBox(height: 8),
              Text(name,
                  style: const TextStyle(
                    color: OnepieceColors.primaryLabel,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBattleCard(BuildContext context, BattleListView battle,
      Map<BattleStatus, String> statusMap) {
    final execution = battle.battleExecution;
    final starter = battle.starter;
    final receiver = battle.receiver;
    if (execution == null || starter == null || receiver == null) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.goNamed('battleDetails',
            extra: battle.id, pathParameters: {'id': battle.id}),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: OnepieceColors.separator),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ImageLazyLoader(
                                uriProvider: () => starter.imageUri ?? '',
                                width: 44,
                                borderWidth: 2,
                                borderRadios: 44),
                            const SizedBox(height: 4),
                            Text(
                                I18nHelper.getDisplayNameFromI18n(starter.name),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(fontSize: 11)),
                            Text(execution.starterScoreBefore?.toString() ?? '',
                                style: OnepieceFonts.boldFancySmallFont),
                          ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(children: [
                        Text("VS",
                            style: OnepieceFonts.boldFancyBlueHintFont
                                .copyWith(fontSize: 13)),
                        const SizedBox(height: 4),
                        if (execution.winnerId != null)
                          ImageLazyLoader(
                              uriProvider: () =>
                                  execution.winnerId == battle.starterId
                                      ? starter.imageUri!
                                      : receiver.imageUri!,
                              width: 28,
                              borderWidth: 1.5,
                              borderRadios: 28)
                        else
                          Icon(Icons.help_outline,
                              size: 28, color: Colors.grey[400]),
                      ]),
                    ),
                    Expanded(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ImageLazyLoader(
                                uriProvider: () => receiver.imageUri ?? '',
                                width: 44,
                                borderWidth: 2,
                                borderRadios: 44),
                            const SizedBox(height: 4),
                            Text(
                                I18nHelper.getDisplayNameFromI18n(
                                    receiver.name),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(fontSize: 11)),
                            Text(
                                execution.receiverScoreBefore?.toString() ?? '',
                                style: OnepieceFonts.boldFancySmallFont),
                          ]),
                    ),
                  ]),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: OnepieceColors.fancyBlue),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                          child: Text(statusMap[execution.battleStatus] ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: OnepieceFonts.boldFancyWhiteSmallFont)),
                      if (execution.battleReportStage ==
                          BattleReportStage.FINISHED)
                        _buildPdfButton(battle),
                      if (execution.battleReportStage !=
                          BattleReportStage.FINISHED)
                        SvgPicture.asset('asset/images/svgs/pdf_black.svg',
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                                Colors.white70, BlendMode.srcIn)),
                    ]),
              ),
            ],
          ),
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
            downloadPdf(pdf, "${response.fileName}.pdf", response.httpMimeType);
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
