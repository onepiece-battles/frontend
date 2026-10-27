import 'package:flutter/material.dart';
import '../../components/resource_loading.dart';
import '../../l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:one_piece_battles_flutter/components/resource_list_load_more.dart';
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
    scrollController.addListener(_maybeLoadMore);
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
  bool _loadingMore = false;
  bool _loadMoreFailed = false;
  int _requestId = 0;

  Future<void> _search(bool filterChange) async {
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _loadFailed = false;
      _loadingMore = false;
      _loadMoreFailed = false;
      selectedPageNum = 1;
    });
    if (scrollController.hasClients) scrollController.jumpTo(0);
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
      _checkForShortViewport();
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  void _maybeLoadMore() {
    if (!scrollController.hasClients ||
        _loading ||
        _loadingMore ||
        _loadMoreFailed ||
        selectedPageNum >= totalPageNum) {
      return;
    }
    final position = scrollController.position;
    final threshold = (position.viewportDimension * 0.5).clamp(120.0, 400.0);
    if (position.extentAfter < threshold) {
      _loadMore();
    }
  }

  void _checkForShortViewport() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !scrollController.hasClients ||
          _loading ||
          _loadingMore ||
          _loadMoreFailed ||
          selectedPageNum >= totalPageNum) {
        return;
      }
      // Fill a viewport that has no scroll range. Otherwise wait for scrolling.
      if (scrollController.position.maxScrollExtent <= 0) {
        _loadMore();
      }
    });
  }

  Future<void> _loadMore() async {
    final requestId = _requestId;
    final nextPage = selectedPageNum + 1;
    setState(() {
      _loadingMore = true;
      _loadMoreFailed = false;
    });
    final request = ListCharacterRequest(
        pageSize: itemCountPerPage,
        pageIndex: nextPage,
        sortKeys: sortKeys,
        characterFilter: characterFilter);
    try {
      final value = await _controller.listCharacter(request);
      if (!mounted || requestId != _requestId) return;
      if (value == null) {
        throw StateError('Resource request returned no response');
      }
      setState(() {
        final seen = currentCharacterList.map((item) => item.id).toSet();
        currentCharacterList = [
          ...currentCharacterList,
          ...value.characters.where((item) => seen.add(item.id)),
        ];
        selectedPageNum = nextPage;
        totalItemCount = value.totalSize ?? totalItemCount;
        totalPageNum = value.characters.isEmpty
            ? nextPage
            : (totalItemCount / itemCountPerPage).ceil();
        _loadingMore = false;
      });
      _checkForShortViewport();
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loadingMore = false;
        _loadMoreFailed = true;
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
                                footer: selectedPageNum < totalPageNum
                                    ? ResourceListLoadMore(
                                        loading: _loadingMore,
                                        failed: _loadMoreFailed,
                                        onRetry: _loadMore)
                                    : null,
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
                                footer: selectedPageNum < totalPageNum
                                    ? ResourceListLoadMore(
                                        loading: _loadingMore,
                                        failed: _loadMoreFailed,
                                        onRetry: _loadMore)
                                    : null,
                              ),
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
