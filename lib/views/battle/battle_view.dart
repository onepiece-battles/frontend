import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import '../../components/resource_loading.dart';
import '../../l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/components/desktop_card_layout.dart';
import 'package:one_piece_battles_flutter/components/resource_list_load_more.dart';
import 'package:one_piece_battles_flutter/constants/button_style.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:openapi/api.dart';
import 'package:toggle_switch/toggle_switch.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../utils/responsive_breakpoints.dart';
import '../../utils/permission_check.dart';
import '../../utils/route_notifier.dart';
import 'battle_list_controller.dart';
import 'widgets/battle_roster.dart';

GetIt getIt = GetIt.instance;

class BattleView extends StatefulWidget {
  const BattleView({super.key});

  @override
  State<BattleView> createState() => _BattleViewState();
}

class _BattleViewState extends State<BattleView> {
  final BattleListController _controller = BattleListController();
  TextEditingController starterNameController = TextEditingController();
  TextEditingController receiverNameController = TextEditingController();

  // base full data
  List<BattleListView> currentBattleList = [];

  // battle filters
  BattleFilter battleFilter = BattleFilter();
  List<BattleType> selectedBattleTypes = [];
  List<BattleStatus> selectedBattleStatus = [];

  ScrollController mainController = ScrollController();

  List<BattleSortableField> sortKeys = [];
  int initialLabelIndex = 0;
  bool _showFilters = false;
  int selectedPageNum = 1;
  int totalPageNum = 0;
  int itemCountPerPage = 24;
  int totalItemCount = 0;

  @override
  void initState() {
    super.initState();
    mainController.addListener(_maybeLoadMore);
    routeNotifier.addListener(_refreshWhenListRouteIsActive);
    _search(false);
  }

  @override
  void dispose() {
    routeNotifier.removeListener(_refreshWhenListRouteIsActive);
    mainController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _refreshWhenListRouteIsActive() {
    if (routeNotifier.value ==
        '/home/${ResourceType.BATTLE.toString().toLowerCase()}') {
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
    if (mainController.hasClients) mainController.jumpTo(0);
    battleFilter.languageCode = I18nHelper.getLanguageCode();
    battleFilter.starterName = starterNameController.text;
    battleFilter.receiverName = receiverNameController.text;
    final request = ListBattleRequest(
        pageSize: itemCountPerPage,
        pageIndex: selectedPageNum,
        sortKeys: sortKeys,
        battleFilter: battleFilter);
    try {
      final value = await _controller.listBattles(request);
      if (!mounted || requestId != _requestId) return;
      if (value == null) {
        throw StateError('Resource request returned no response');
      }
      setState(() {
        currentBattleList = value.battles;
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
    if (!mainController.hasClients ||
        _loading ||
        _loadingMore ||
        _loadMoreFailed ||
        selectedPageNum >= totalPageNum) {
      return;
    }
    final position = mainController.position;
    final threshold = (position.viewportDimension * 0.5).clamp(120.0, 400.0);
    if (position.extentAfter < threshold) {
      _loadMore();
    }
  }

  void _checkForShortViewport() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !mainController.hasClients ||
          _loading ||
          _loadingMore ||
          _loadMoreFailed ||
          selectedPageNum >= totalPageNum) {
        return;
      }
      // Fill a viewport that has no scroll range. Otherwise wait for scrolling.
      if (mainController.position.maxScrollExtent <= 0) {
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
    final request = ListBattleRequest(
        pageSize: itemCountPerPage,
        pageIndex: nextPage,
        sortKeys: sortKeys,
        battleFilter: battleFilter);
    try {
      final value = await _controller.listBattles(request);
      if (!mounted || requestId != _requestId) return;
      if (value == null) {
        throw StateError('Resource request returned no response');
      }
      setState(() {
        final seen = currentBattleList.map((item) => item.id).toSet();
        currentBattleList = [
          ...currentBattleList,
          ...value.battles.where((item) => seen.add(item.id)),
        ];
        selectedPageNum = nextPage;
        totalItemCount = value.totalSize ?? totalItemCount;
        totalPageNum = value.battles.isEmpty
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < ResponsiveBreakpoints.tabletMax;
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
                    _getHeaderText(context),
                    CompactFilterPanel(child: _getControlRow(context)),
                    const SizedBox(height: 6),
                    Expanded(
                      child: ResourceListBody(
                        loading: _loading,
                        failed: _loadFailed,
                        hasItems: currentBattleList.isNotEmpty,
                        onRetry: () => _search(false),
                        child: BattleRoster(
                          battles: currentBattleList,
                          controller: mainController,
                          isNarrow: isNarrow,
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

  Widget _getHeaderText(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Text(
        AppLocalizations.of(context)!.battle,
        style: OnepieceFonts.headerStyle.copyWith(fontSize: 20),
      ),
    );
  }

  Widget _getControlRow(BuildContext context) {
    final hasCreate = PermissionCheck.checkPermission(
        getIt<User>().loginRoleResourcesPermissionMap,
        ResourceType.BATTLE,
        Permission.CREATE);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (hasCreate)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: SizedBox(
                  height: 35,
                  child: ElevatedButton(
                    onPressed: () => context.goNamed("create_battle"),
                    style: OnepieceButtonStyle.getDefaultStyle(),
                    child: Text(AppLocalizations.of(context)!.create,
                        style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ),
            Expanded(
              child: SizedBox(
                height: 35,
                child: TextFormField(
                  controller: starterNameController,
                  onChanged: (v) {
                    battleFilter.starterName = v.trim();
                    _search(true);
                  },
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    disabledBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: OnepieceColors.menuHoverColor)),
                    enabledBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: OnepieceColors.menuHoverColor)),
                    focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                            color: OnepieceColors.fancyGreen, width: 1.5)),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    labelText: AppLocalizations.of(context)!.starterName,
                    labelStyle:
                        OnepieceFonts.dropDownItemStyle.copyWith(fontSize: 13),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            ListFilterButton(
              active: _showFilters ||
                  initialLabelIndex != 0 ||
                  selectedBattleStatus.isNotEmpty ||
                  receiverNameController.text.isNotEmpty,
              onPressed: () => setState(() => _showFilters = !_showFilters),
            ),
          ]),
          if (_showFilters) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 35,
              child: TextFormField(
                controller: receiverNameController,
                onChanged: (v) {
                  battleFilter.receiverName = v.trim();
                  _search(true);
                },
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  disabledBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: OnepieceColors.menuHoverColor)),
                  enabledBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: OnepieceColors.menuHoverColor)),
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                          color: OnepieceColors.fancyGreen, width: 1.5)),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  labelText: AppLocalizations.of(context)!.receiverName,
                  labelStyle:
                      OnepieceFonts.dropDownItemStyle.copyWith(fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                height: 36,
                child: ToggleSwitch(
                  customWidths: const [90, 90, 100, 120],
                  cornerRadius: 4,
                  minHeight: 35,
                  fontSize: 12,
                  dividerColor: Colors.white,
                  initialLabelIndex: initialLabelIndex,
                  activeBgColor: const [OnepieceColors.fancyBlue],
                  activeFgColor: Colors.white,
                  inactiveBgColor: OnepieceColors.liteFancyGreen,
                  inactiveFgColor: Colors.grey[600],
                  totalSwitches: 4,
                  labels: [
                    AppLocalizations.of(context)!.allResources,
                    AppLocalizations.of(context)!.myResource,
                    AppLocalizations.of(context)!.systemResource,
                    AppLocalizations.of(context)!.excludeSystem
                  ],
                  onToggle: (index) {
                    initialLabelIndex = index!;
                    if (index == 0) {
                      battleFilter.systemResource = null;
                      battleFilter.userId = null;
                    }
                    if (index == 1) {
                      battleFilter.systemResource = null;
                      battleFilter.userId = getIt<User>().id;
                    }
                    if (index == 2) {
                      battleFilter.systemResource = true;
                      battleFilter.userId = null;
                    }
                    if (index == 3) {
                      battleFilter.systemResource = false;
                      battleFilter.userId = null;
                    }
                    _search(true);
                  },
                ),
              ),
            ),
            const SizedBox(height: 6),
            _getBattleStatusFilter(context),
          ],
        ],
      ),
    );
  }

  Widget _getBattleStatusFilter(BuildContext context) {
    Map<BattleStatus, String> battleStatusToDisplayName = {
      BattleStatus.CREATED: AppLocalizations.of(context)!.battleStatusCreated,
      BattleStatus.IN_PROGRESS:
          AppLocalizations.of(context)!.battleStatusStarted,
      BattleStatus.FINISHED: AppLocalizations.of(context)!.battleStatusFinished,
      BattleStatus.FAILED: AppLocalizations.of(context)!.battleStatusFailed,
    };
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2(
          isExpanded: true,
          value:
              selectedBattleStatus.isEmpty ? null : selectedBattleStatus.last,
          hint: Text(
            AppLocalizations.of(context)!.battleStatusHint,
            style: OnepieceFonts.dropDownItemStyle,
          ),
          onChanged: (value) {},
          selectedItemBuilder: (context) {
            return BattleStatus.values.map(
              (item) {
                return Container(
                  alignment: AlignmentDirectional.center,
                  child: Text(
                    selectedBattleStatus
                        .map((selectedType) {
                          return battleStatusToDisplayName[selectedType];
                        })
                        .toSet()
                        .join(', '),
                    style: const TextStyle(
                      fontSize: 16,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ),
                );
              },
            ).toList();
          },
          buttonStyleData: ButtonStyleData(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 35,
              width: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: OnepieceColors.liteFancyGreen,
              )),
          menuItemStyleData: const MenuItemStyleData(
            height: 35,
          ),
          items: BattleStatus.values.map((BattleStatus battleStatus) {
            return DropdownMenuItem<BattleStatus>(
              value: battleStatus,
              enabled: false,
              child: StatefulBuilder(
                builder: (context, menuSetState) {
                  final isSelected =
                      selectedBattleStatus.contains(battleStatus);
                  return InkWell(
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    onTap: () {
                      isSelected
                          ? selectedBattleStatus.remove(battleStatus)
                          : selectedBattleStatus.add(battleStatus);
                      battleFilter.battleStatuses = selectedBattleStatus;

                      // //This rebuilds the StatefulWidget to update the button's text
                      setState(() {});
                      //This rebuilds the dropdownMenu Widget to update the check mark
                      menuSetState(() {});
                      _search(true);
                    },
                    child: Container(
                      height: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: Row(
                        children: [
                          if (isSelected)
                            const Icon(Icons.check_box_outlined)
                          else
                            const Icon(Icons.check_box_outline_blank),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              battleStatusToDisplayName[battleStatus]!,
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
