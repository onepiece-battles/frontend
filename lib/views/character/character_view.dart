import 'package:flutter/material.dart';
import '../../components/resource_loading.dart';
import '../../l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:one_piece_battles_flutter/components/page_foot.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:one_piece_battles_flutter/utils/permission_check.dart';
import 'package:openapi/api.dart';
import '../../utils/i18n_helper.dart';
import '../../utils/responsive_breakpoints.dart';
import '../../utils/route_notifier.dart';
import 'character_list_controller.dart';
import 'widgets/character_mobile_roster.dart';
import 'widgets/character_desktop_roster.dart';
import 'widgets/character_filter_panel.dart';

GetIt getIt = GetIt.instance;

class CharacterView extends StatefulWidget {
  const CharacterView({super.key});

  @override
  State<CharacterView> createState() => _CharacterViewState();
}

class _CharacterViewState extends State<CharacterView>
    with AutomaticKeepAliveClientMixin {
  final Logger logger = Logger('CharacterView');
  final CharacterListController _controller = CharacterListController();
  // Controllers
  final TextEditingController searchNameController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  // Data & Filter State
  CharacterFilter characterFilter = CharacterFilter();
  List<CharacterListView> currentCharacterList = [];
  List<CharacterSortableField> sortKeys = [
    CharacterSortableField(
        sortKey: CharacterSortableFieldsEnum.score, sortOrder: SortOrder.DESC)
  ];

  // Selections
  List<BattleStyle> selectedBattleStyles = [];
  List<Race> selectedRaces = [];
  List<Haki> selectedHakis = [];

  // Pagination State
  int selectedPageNum = 1;
  int totalPageNum = 0;
  int itemCountPerPage = 24;
  int totalItemCount = 0;

  // Constants / Maps
  final Map<SortOrder?, String> sortOrderToPath = {
    null: 'images/svgs/sort-solid.svg',
    SortOrder.ASC: 'images/svgs/sort-up-solid.svg',
    SortOrder.DESC: 'images/svgs/sort-down-solid.svg'
  };

  Map<CharacterSortableFieldsEnum, SortOrder?> sortableEnumToSortOrderMap = {
    CharacterSortableFieldsEnum.name: null,
    CharacterSortableFieldsEnum.score: SortOrder.DESC,
  };

  /// Tracks which rows have their stat detail panel expanded.
  final Set<String> _expandedRowIds = {};

  // Cached display maps to avoid rebuilding in build()
  late Map<BattleStyle, String> battleStyleToDisplayValue;
  late Map<Race, String> raceEnumToDisplayName;
  late Map<Haki, String> hakiEnumValueToDisplayValue;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize localized maps here as context is available
    final loc = AppLocalizations.of(context)!;
    battleStyleToDisplayValue = {
      BattleStyle.BODY: loc.body,
      BattleStyle.SCIENCE: loc.science,
      BattleStyle.KATANA: loc.katana,
      BattleStyle.SHOOTER: loc.shoot,
      BattleStyle.STICK: loc.stick,
      BattleStyle.RIFLE: loc.rifle,
      BattleStyle.SWORD: loc.sword
    };
    raceEnumToDisplayName = {
      Race.HUMAN: loc.human,
      Race.FISH_MAN: loc.fishman,
      Race.MERFOLK: loc.merfolk,
      Race.GIANT: loc.giant,
      Race.LONG_ARM: loc.longArm,
      Race.LONG_LEG: loc.longLeg,
      Race.SNAKE_NECK: loc.snakeNeck,
      Race.THREE_EYE: loc.threeEye,
      Race.LUNARIAN: loc.lunarian,
      Race.MINK: loc.mink,
      Race.WORLD_NOBEL: loc.worldNobel,
      Race.DWARVES: loc.dwarves,
      Race.NO_LIFE_OBJECT: loc.lifeless_object,
      Race.ANIMAL: loc.animal,
      Race.SOUL: loc.soul,
    };
    hakiEnumValueToDisplayValue = {
      Haki.busoshoku: loc.busoshoku,
      Haki.haoshoku: loc.haoshoku,
      Haki.kenbunshoku: loc.kenbunshoku,
    };
  }

  @override
  void initState() {
    super.initState();
    routeNotifier.addListener(_refreshWhenListRouteIsActive);
    _search(false);
  }

  @override
  void dispose() {
    routeNotifier.removeListener(_refreshWhenListRouteIsActive);
    searchNameController.dispose();
    scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _refreshWhenListRouteIsActive() {
    if (routeNotifier.value ==
        '/home/${ResourceType.CHARACTER.toString().toLowerCase()}') {
      _search(false);
    }
  }

  bool _loading = true;
  bool _loadFailed = false;
  int _requestId = 0;

  Future<void> _search(bool filterChange) async {
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _loadFailed = false;
      if (filterChange) selectedPageNum = 1;
    });
    characterFilter.languageCode = I18nHelper.getLanguageCode();
    final request = ListCharacterRequest(
        pageSize: itemCountPerPage,
        pageIndex: selectedPageNum,
        sortKeys: sortKeys,
        characterFilter: characterFilter);
    try {
      final value = await _controller.listCharacter(request);
      if (!mounted || requestId != _requestId) return;
      if (value == null) {
        throw StateError('Resource request returned no response');
      }
      setState(() {
        currentCharacterList = value.characters;
        totalItemCount = value.totalSize ?? 0;
        totalPageNum = (totalItemCount / itemCountPerPage).ceil();
        _loading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  void _onScoreSortTap() {
    final scoreOrder =
        sortableEnumToSortOrderMap[CharacterSortableFieldsEnum.score];
    SortOrder? nextOrder;
    if (scoreOrder == SortOrder.DESC) {
      nextOrder = SortOrder.ASC;
    } else if (scoreOrder == SortOrder.ASC) {
      nextOrder = null;
    } else {
      nextOrder = SortOrder.DESC;
    }
    setState(() {
      sortableEnumToSortOrderMap[CharacterSortableFieldsEnum.score] = nextOrder;
      sortKeys.removeWhere(
          (item) => item.sortKey == CharacterSortableFieldsEnum.score);
      if (nextOrder != null) {
        sortKeys.insert(
          0,
          CharacterSortableField(
            sortKey: CharacterSortableFieldsEnum.score,
            sortOrder: nextOrder,
          ),
        );
      }
      _search(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow =
            ResponsiveBreakpoints.isMobileFromConstraints(constraints);
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: double.infinity),
            child: Padding(
              padding: EdgeInsets.all(isNarrow ? 8 : 12),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _createHeader(),
                    CharacterFilterPanel(
                      isNarrow: isNarrow,
                      hasCreate: PermissionCheck.checkPermission(
                          getIt<User>().loginRoleResourcesPermissionMap,
                          ResourceType.CHARACTER,
                          Permission.CREATE),
                      myUserId: getIt<User>().id,
                      searchNameController: searchNameController,
                      characterFilter: characterFilter,
                      selectedBattleStyles: selectedBattleStyles,
                      selectedRaces: selectedRaces,
                      selectedHakis: selectedHakis,
                      battleStyleMap: battleStyleToDisplayValue,
                      raceMap: raceEnumToDisplayName,
                      hakiMap: hakiEnumValueToDisplayValue,
                      onCreate: () => context.goNamed("createCharacter"),
                      onSearch: _search,
                    ),
                    const SizedBox(height: 6),
                    // Compact cards on mobile, a richer roster on desktop.
                    Expanded(
                      child: ResourceListBody(
                        loading: _loading,
                        failed: _loadFailed,
                        hasItems: currentCharacterList.isNotEmpty,
                        onRetry: () => _search(false),
                        child: isNarrow
                            ? CharacterMobileRoster(
                                characters: currentCharacterList,
                                scrollController: scrollController,
                                battleStyleMap: battleStyleToDisplayValue,
                                raceMap: raceEnumToDisplayName,
                                hakiMap: hakiEnumValueToDisplayValue,
                                expandedRowIds: _expandedRowIds,
                                onToggleExpand: (id) => setState(() {
                                  if (_expandedRowIds.contains(id)) {
                                    _expandedRowIds.remove(id);
                                  } else {
                                    _expandedRowIds.add(id);
                                  }
                                }),
                              )
                            : CharacterDesktopRoster(
                                characters: currentCharacterList,
                                totalItemCount: totalItemCount,
                                scrollController: scrollController,
                                battleStyleMap: battleStyleToDisplayValue,
                                raceMap: raceEnumToDisplayName,
                                hakiMap: hakiEnumValueToDisplayValue,
                                expandedRowIds: _expandedRowIds,
                                onToggleExpand: (id) => setState(() {
                                  if (_expandedRowIds.contains(id)) {
                                    _expandedRowIds.remove(id);
                                  } else {
                                    _expandedRowIds.add(id);
                                  }
                                }),
                                scoreOrder: sortableEnumToSortOrderMap[
                                    CharacterSortableFieldsEnum.score],
                                onScoreSortTap: _onScoreSortTap,
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (totalPageNum > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: PageFoot(
                          currentPage: selectedPageNum,
                          totalPages: totalPageNum,
                          jumpLabel: AppLocalizations.of(context)!.jumpToPage,
                          onPageChanged: (page) {
                            selectedPageNum = page;
                              if (scrollController.hasClients) {
                              scrollController.jumpTo(0);
                              }
                            _search(false);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _createHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        AppLocalizations.of(context)!.character,
        style: OnepieceFonts.headerStyle.copyWith(fontSize: 20),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
