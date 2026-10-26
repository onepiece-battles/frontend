import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:openapi/api.dart';
import 'package:toggle_switch/toggle_switch.dart';
import '../../components/desktop_card_layout.dart';
import '../../components/resource_loading.dart';
import '../../components/resource_list_load_more.dart';
import '../../constants/button_style.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/responsive_breakpoints.dart';
import '../../utils/permission_check.dart';
import '../../utils/route_notifier.dart';
import 'fruit_list_controller.dart';
import 'widgets/fruit_roster.dart';

GetIt getIt = GetIt.instance;

class FruitView extends StatefulWidget {
  const FruitView({super.key});

  @override
  State<FruitView> createState() => _FruitViewState();
}

class _FruitViewState extends State<FruitView> {
  List<FruitListView> currentFruitList = [];
  FruitFilter fruitFilter = FruitFilter();
  List<FruitType> selectedFruitTypes = [];
  List<FruitSortableField> sortKeys = [];

  TextEditingController searchNameController = TextEditingController();

  // first all columns will be sorted by creation id desc.
  Map<FruitSortableFieldsEnum, SortOrder?> sortableEnumToSortOrderMap = {
    FruitSortableFieldsEnum.fruitType: null,
    FruitSortableFieldsEnum.name: null,
  };

  /// Tracks which rows have their strengthen detail panel expanded.
  final Set<String> _expandedRowIds = {};

  final FruitListController _controller = FruitListController();
  ScrollController mainController = ScrollController();
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
    searchNameController.dispose();
    mainController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _refreshWhenListRouteIsActive() {
    if (routeNotifier.value ==
        '/home/${ResourceType.FRUIT.toString().toLowerCase()}') {
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
    fruitFilter.languageCode = I18nHelper.getLanguageCode();
    final request = ListFruitRequest(
        pageSize: itemCountPerPage,
        pageIndex: selectedPageNum,
        sortKeys: sortKeys,
        fruitFilter: fruitFilter);
    try {
      final value = await _controller.list(request);
      if (!mounted || requestId != _requestId) return;
      if (value == null) {
        throw StateError('Resource request returned no response');
      }
      setState(() {
        currentFruitList = value.fruits;
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
    final request = ListFruitRequest(
        pageSize: itemCountPerPage,
        pageIndex: nextPage,
        sortKeys: sortKeys,
        fruitFilter: fruitFilter);
    try {
      final value = await _controller.list(request);
      if (!mounted || requestId != _requestId) return;
      if (value == null) {
        throw StateError('Resource request returned no response');
      }
      setState(() {
        final seen = currentFruitList.map((item) => item.id).toSet();
        currentFruitList
            .addAll(value.fruits.where((item) => seen.add(item.id)));
        selectedPageNum = nextPage;
        totalItemCount = value.totalSize ?? totalItemCount;
        totalPageNum = value.fruits.isEmpty
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
                    _getHeaderText(context),
                    CompactFilterPanel(child: _getControlRow(context)),
                    const SizedBox(height: 6),
                    Expanded(
                      child: ResourceListBody(
                        loading: _loading,
                        failed: _loadFailed,
                        hasItems: currentFruitList.isNotEmpty,
                        onRetry: () => _search(false),
                        child: FruitRoster(
                          fruits: currentFruitList,
                          controller: mainController,
                          expandedRowIds: _expandedRowIds,
                          onToggleExpand: (id) => setState(() {
                            if (!_expandedRowIds.remove(id)) {
                              _expandedRowIds.add(id);
                            }
                          }),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        AppLocalizations.of(context)!.devilFruit,
        style: OnepieceFonts.headerStyle.copyWith(fontSize: 20),
      ),
    );
  }

  Widget _getControlRow(BuildContext context) {
    final hasCreate = PermissionCheck.checkPermission(
        getIt<User>().loginRoleResourcesPermissionMap,
        ResourceType.FRUIT,
        Permission.CREATE);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (hasCreate)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: SizedBox(
                height: 35,
                child: ElevatedButton(
                    onPressed: () => context.goNamed("createFruit"),
                    style: OnepieceButtonStyle.getDefaultStyle(),
                    child: Text(AppLocalizations.of(context)!.create,
                        style: const TextStyle(fontSize: 13))),
              ),
            ),
          Expanded(
            child: SizedBox(
              height: 35,
              child: TextFormField(
                controller: searchNameController,
                onChanged: (v) {
                  fruitFilter.name = v;
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
                  labelText: AppLocalizations.of(context)!.name,
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
                selectedFruitTypes.isNotEmpty,
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ]),
        if (_showFilters) ...[
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
                    fruitFilter.systemResource = null;
                    fruitFilter.userId = null;
                  }
                  if (index == 1) {
                    fruitFilter.systemResource = null;
                    fruitFilter.userId = getIt<User>().id;
                  }
                  if (index == 2) {
                    fruitFilter.systemResource = true;
                    fruitFilter.userId = null;
                  }
                  if (index == 3) {
                    fruitFilter.systemResource = false;
                    fruitFilter.userId = null;
                  }
                  _search(true);
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
          _getFruitTypeFilter(context),
          const SizedBox(height: 4),
          _buildFruitSortControls(context),
        ],
      ]),
    );
  }

  Widget _getFruitTypeFilter(BuildContext context) {
    Map<FruitType, String> fruitTypeToDisplayValue = {
      FruitType.logia: AppLocalizations.of(context)!.logiaFruit,
      FruitType.zoan: AppLocalizations.of(context)!.zoanFruit,
      FruitType.ancientZoan: AppLocalizations.of(context)!.ancientZoanFruit,
      FruitType.mythicalZoan: AppLocalizations.of(context)!.mythicalZoanFruit,
      FruitType.artificialZoan:
          AppLocalizations.of(context)!.artificialZoanFruit,
      FruitType.paramecia: AppLocalizations.of(context)!.parameciaFruit,
    };
    return DropdownButtonHideUnderline(
      child: DropdownButton2(
        isExpanded: true,
        value: selectedFruitTypes.isEmpty ? null : selectedFruitTypes.last,
        hint: Text(
          AppLocalizations.of(context)!.battleTypeHint,
          style: OnepieceFonts.dropDownItemStyle,
        ),
        onChanged: (value) {},
        selectedItemBuilder: (context) {
          return FruitType.values.map(
            (item) {
              return Container(
                alignment: AlignmentDirectional.center,
                child: Text(
                  selectedFruitTypes
                      .map((selectedType) {
                        return fruitTypeToDisplayValue[selectedType];
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
            width: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: OnepieceColors.liteFancyGreen,
            )),
        menuItemStyleData: const MenuItemStyleData(
          height: 35,
        ),
        items: FruitType.values.map((FruitType fruitType) {
          return DropdownMenuItem<FruitType>(
            value: fruitType,
            enabled: false,
            child: StatefulBuilder(
              builder: (context, menuSetState) {
                final isSelected = selectedFruitTypes.contains(fruitType);
                return InkWell(
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  onTap: () {
                    isSelected
                        ? selectedFruitTypes.remove(fruitType)
                        : selectedFruitTypes.add(fruitType);
                    fruitFilter.types = selectedFruitTypes;
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
                            fruitTypeToDisplayValue[fruitType]!,
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
    );
  }

  Widget _buildFruitSortControls(BuildContext context) {
    final order = sortableEnumToSortOrderMap[FruitSortableFieldsEnum.fruitType];
    return Row(children: [
      Expanded(
          child: Text(AppLocalizations.of(context)!.fruitCount(totalItemCount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OnepieceFonts.smallContentStyle)),
      const SizedBox(width: 8),
      DesktopSortChip(
        label: AppLocalizations.of(context)!.fruitType,
        ascending: order == null ? null : order == SortOrder.ASC,
        onTap: () => _toggleFruitSort(FruitSortableFieldsEnum.fruitType),
      ),
    ]);
  }

  void _toggleFruitSort(FruitSortableFieldsEnum field) {
    final current = sortableEnumToSortOrderMap[field];
    SortOrder? next;
    if (current == null) {
      next = SortOrder.ASC;
    } else if (current == SortOrder.ASC) {
      next = SortOrder.DESC;
    }
    setState(() {
      sortableEnumToSortOrderMap[field] = next;
      sortKeys.removeWhere((item) => item.sortKey == field);
      if (next != null) {
        sortKeys.insert(0, FruitSortableField(sortKey: field, sortOrder: next));
      }
      _search(false);
    });
  }
}
