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
    return FutureBuilder<List<dynamic>>(
      future: myFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: TextButton.icon(
              onPressed: () => setState(() {
                myFuture = _loadHomeData();
              }),
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.retryLoading),
            ),
          );
        }
        _updateData(snapshot.data!);
        return ColoredBox(
          color: OnepieceColors.surface,
          child: LayoutBuilder(builder: (context, constraints) {
            final narrow = constraints.maxWidth < 650;
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                            narrow ? 14 : 28, 24, narrow ? 14 : 28, 48),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _getHeader(context),
                            if (getIt<User>().userRoles.length > 1)
                              _getRoleToggle(),
                            const SizedBox(height: 20),
                            _getSectionHeader(
                              AppLocalizations.of(context)!.myResource,
                              initiallyExpanded: true,
                              icon: Icons.person_outline,
                              child: _buildResourceBundle(
                                context,
                                characterChild: _buildCharacterGrid(
                                    context, myCharacters,
                                    showPlaceholderWhenEmpty: true),
                                groupChild: _buildGroupGrid(context, myGroups,
                                    showPlaceholderWhenEmpty: true),
                                battleChild: _buildBattleGrid(
                                    context, myBattles,
                                    showPlaceholderWhenEmpty: true),
                              ),
                            ),
                            if (!_isNika) ...[
                              const SizedBox(height: 16),
                              _getSectionHeader(
                                AppLocalizations.of(context)!.systemResource,
                                initiallyExpanded: true,
                                icon: Icons.auto_awesome_outlined,
                                child: _buildResourceBundle(
                                  context,
                                  characterChild: _buildCharacterGrid(
                                      context, systemCharacters,
                                      showPlaceholderWhenEmpty: false),
                                  groupChild: _buildGroupGrid(
                                      context, systemGroups,
                                      showPlaceholderWhenEmpty: false),
                                  battleChild: _buildBattleGrid(
                                      context, systemBattles,
                                      showPlaceholderWhenEmpty: false),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }

  Widget _getRoleToggle() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 5, 10, 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: OnepieceColors.separator),
        ),
        child: Row(children: [
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.showAllRoleResources,
              style: const TextStyle(
                  fontSize: 13, color: OnepieceColors.primaryLabel),
            ),
          ),
          Switch.adaptive(
            value: !currentRoleOnly,
            activeTrackColor: OnepieceColors.fancyBlue,
            onChanged: (value) => setState(() {
              currentRoleOnly = !value;
              myFuture = _loadHomeData();
            }),
          ),
        ]),
      ),
    );
  }

  Widget _getSectionHeader(
    String title, {
    required Widget child,
    bool initiallyExpanded = false,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: OnepieceColors.separator, width: .8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
          leading: Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
                color: OnepieceColors.surface,
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: OnepieceColors.fancyBlue, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: OnepieceColors.primaryLabel,
              fontSize: 16,
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
        const SizedBox(height: 16),
        _buildResourceTypeTitle(AppLocalizations.of(context)!.group),
        groupChild,
        const SizedBox(height: 16),
        _buildResourceTypeTitle(AppLocalizations.of(context)!.battle),
        battleChild,
      ],
    );
  }

  Widget _buildResourceTypeTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 16, 2, 10),
      child: Text(
        title,
        style: const TextStyle(
          color: OnepieceColors.primaryLabel,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _getHeader(BuildContext context) {
    final user = getIt<User>();
    final imageUri = user.imageUri ?? '';
    final loc = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: OnepieceColors.separator, width: .8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          imageUri.isEmpty
              ? const CircleAvatar(
                  radius: 35,
                  backgroundColor: OnepieceColors.surface,
                  child: Icon(Icons.person_outline,
                      size: 36, color: OnepieceColors.secondaryLabel))
              : ImageLazyLoader(
                  uriProvider: () => imageUri,
                  width: 70,
                  borderWidth: 0,
                  borderRadios: 70),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.homePage,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: OnepieceColors.secondaryLabel)),
                const SizedBox(height: 4),
                Text(user.nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.4,
                        color: OnepieceColors.primaryLabel)),
                const SizedBox(height: 3),
                Text(user.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, color: OnepieceColors.secondaryLabel)),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 20),
        const Divider(height: 1, color: OnepieceColors.separator),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _HomeStat(label: loc.character, count: myCharacters.length),
          _HomeStat(label: loc.group, count: myGroups.length),
          _HomeStat(label: loc.battle, count: myBattles.length),
        ]),
      ]),
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
            routeName: 'create_character',
            label: AppLocalizations.of(context)!.character,
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
            routeName: 'create_group',
            label: AppLocalizations.of(context)!.group,
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
        mainAxisExtent: 205,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (items.isEmpty) {
          return _buildPlaceholderCard(
            context,
            routeName: 'create_battle',
            label: AppLocalizations.of(context)!.battle,
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
    required String label,
    required double imgSize,
    required double borderRadius,
  }) {
    return Material(
      color: OnepieceColors.surface,
      borderRadius: BorderRadius.circular(16),
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
                  border: Border.all(color: OnepieceColors.separator),
                ),
                child: const Icon(
                  Icons.add,
                  color: OnepieceColors.fancyBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${AppLocalizations.of(context)!.create}'
                '${Localizations.localeOf(context).languageCode == 'zh' ? '' : ' '}'
                '$label',
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
      color: OnepieceColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ImageLazyLoader(
                  uriProvider: () => imageUri,
                  width: imgSize,
                  borderWidth: 0,
                  borderRadios: borderRadius,
                  // Defer the fetch until the card scrolls into view, so the
                  // image-heavy home grids don't fire every request at once.
                  lazy: true),
              const SizedBox(height: 8),
              Text(name,
                  style: const TextStyle(
                    color: OnepieceColors.primaryLabel,
                    fontSize: 12,
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
      color: OnepieceColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.goNamed('battleDetails',
            extra: battle.id, pathParameters: {'id': battle.id}),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
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
                                borderWidth: 0,
                                borderRadios: 44,
                                lazy: true),
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
                        Text(AppLocalizations.of(context)!.versus,
                            style: OnepieceFonts.boldFancyBlueHintFont
                                .copyWith(fontSize: 13)),
                        const SizedBox(height: 4),
                        if (execution.winnerId != null)
                          ImageLazyLoader(
                              uriProvider: () =>
                                  execution.winnerId == battle.starterId
                                      ? (starter.imageUri ?? '')
                                      : (receiver.imageUri ?? ''),
                              width: 28,
                              borderWidth: 0,
                              borderRadios: 28,
                              lazy: true)
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
                                borderWidth: 0,
                                borderRadios: 44,
                                lazy: true),
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
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                          child: Text(statusMap[execution.battleStatus] ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: OnepieceColors.fancyBlue))),
                      if (execution.battleReportStage ==
                          BattleReportStage.FINISHED)
                        _buildPdfButton(battle),
                      if (execution.battleReportStage !=
                          BattleReportStage.FINISHED)
                        SvgPicture.asset('asset/images/svgs/pdf_black.svg',
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                                OnepieceColors.secondaryLabel,
                                BlendMode.srcIn)),
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

class _HomeStat extends StatelessWidget {
  final String label;
  final int count;
  const _HomeStat({required this.label, required this.count});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: OnepieceColors.surface,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('$count',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: OnepieceColors.primaryLabel)),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: OnepieceColors.secondaryLabel)),
        ]),
      );
}
