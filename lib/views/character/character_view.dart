import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:one_piece_battles_flutter/components/page_foot.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:one_piece_battles_flutter/utils/permission_check.dart';
import 'package:openapi/api.dart';
import 'package:toggle_switch/toggle_switch.dart';
import '../../constants/button_style.dart';
import '../../utils/i18n_helper.dart';
import '../../utils/responsive_breakpoints.dart';
import '../../utils/route_notifier.dart';
import 'character_list_controller.dart';
import 'widgets/character_mobile_roster.dart';
import 'widgets/character_desktop_roster.dart';

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
  int itemCountPerPage = 10;
  int totalItemCount = 0;
  int initialLabelIndex = 0;
  bool _showFilters = false;

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

  void _search(bool filterChange) {
    characterFilter.languageCode = I18nHelper.getLanguageCode();
    if (filterChange) {
      selectedPageNum = 1;
    }
    ListCharacterRequest listCharacterRequest = ListCharacterRequest(
        pageSize: itemCountPerPage,
        pageIndex: selectedPageNum,
        sortKeys: sortKeys,
        characterFilter: characterFilter);

    _controller.listCharacter(listCharacterRequest).then((value) {
      if (!mounted) return;
      setState(() {
        currentCharacterList = value!.characters;
        totalItemCount = value.totalSize!;
        totalPageNum = (totalItemCount / itemCountPerPage).ceil();
      });
    });
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
              padding: EdgeInsets.all(isNarrow ? 15 : 24),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _createHeader(),
                    _createControlPanel(isNarrow: isNarrow),
                    const SizedBox(height: 10),
                    // Compact cards on mobile, a richer roster on desktop.
                    Expanded(
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
                    const SizedBox(height: 15),
                    if (totalPageNum > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: PageFoot(
                          currentPage: selectedPageNum,
                          totalPages: totalPageNum,
                          jumpLabel: AppLocalizations.of(context)!.jumpToPage,
                          onPageChanged: (page) {
                            selectedPageNum = page;
                            scrollController.jumpTo(0);
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
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(
        AppLocalizations.of(context)!.character,
        style: OnepieceFonts.headerStyle,
      ),
    );
  }

  Widget _createControlPanel({required bool isNarrow}) {
    final hasCreate = PermissionCheck.checkPermission(
        getIt<User>().loginRoleResourcesPermissionMap,
        ResourceType.CHARACTER,
        Permission.CREATE);

    // ── Mobile: collapsible filter panel ──────────────────────────────
    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Create button + search field + filter toggle
          Row(
            children: [
              if (hasCreate)
                Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: SizedBox(
                    height: 35,
                    child: ElevatedButton(
                      onPressed: () => context.goNamed("createCharacter"),
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
                    controller: searchNameController,
                    onChanged: (value) {
                      characterFilter.name = value.trim();
                      _search(true);
                    },
                    decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 0),
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        disabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                                color: OnepieceColors.menuHoverColor)),
                        enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                                color: OnepieceColors.menuHoverColor)),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                              color: OnepieceColors.fancyGreen, width: 1.5),
                        ),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        labelText: AppLocalizations.of(context)!.starterName,
                        labelStyle: OnepieceFonts.dropDownItemStyle),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => setState(() => _showFilters = !_showFilters),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 35,
                  width: 35,
                  decoration: BoxDecoration(
                    border: Border.all(color: OnepieceColors.menuHoverColor),
                    borderRadius: BorderRadius.circular(4),
                    color: _showFilters
                        ? OnepieceColors.fancyBlue.withValues(alpha: 0.1)
                        : null,
                  ),
                  child: Icon(
                    Icons.filter_list,
                    size: 20,
                    color: _showFilters
                        ? OnepieceColors.fancyBlue
                        : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          // Expandable filter panel
          if (_showFilters) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                height: 36,
                child: ToggleSwitch(
                  customWidths: const [90, 90, 100, 120],
                  cornerRadius: 4,
                  minHeight: 35.0,
                  fontSize: 12.0,
                  initialLabelIndex: initialLabelIndex,
                  activeBgColor: const [OnepieceColors.fancyBlue],
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
                    characterFilter.systemResource =
                        (index == 2) ? true : (index == 3 ? false : null);
                    characterFilter.userId =
                        (index == 1) ? getIt<User>().id : null;
                    _search(true);
                  },
                ),
              ),
            ),
            const SizedBox(height: 6),
            _buildDropdown<BattleStyle>(
              items: BattleStyle.values,
              selectedItems: selectedBattleStyles,
              displayMap: battleStyleToDisplayValue,
              hint: AppLocalizations.of(context)!.battleStyle,
              width: double.infinity,
              onChanged: (list) {
                characterFilter.battleStyles = list;
                _search(true);
              },
            ),
            const SizedBox(height: 6),
            _buildDropdown<Haki>(
              items: Haki.values,
              selectedItems: selectedHakis,
              displayMap: hakiEnumValueToDisplayValue,
              hint: AppLocalizations.of(context)!.hakis,
              width: double.infinity,
              onChanged: (list) {
                characterFilter.hakis = list;
                _search(true);
              },
            ),
            const SizedBox(height: 6),
            _buildDropdown<Race>(
              items: Race.values,
              selectedItems: selectedRaces,
              displayMap: raceEnumToDisplayName,
              hint: AppLocalizations.of(context)!.race,
              width: double.infinity,
              onChanged: (list) {
                characterFilter.races = list;
                _search(true);
              },
            ),
          ],
        ],
      );
    }

    // ── Desktop: card-style search and filters ────────────────────────
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: OnepieceColors.deepFancyBlue.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: OnepieceColors.fancyBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.tune,
                    size: 21, color: OnepieceColors.fancyBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: TextFormField(
                    controller: searchNameController,
                    onChanged: (value) {
                      characterFilter.name = value.trim();
                      _search(true);
                    },
                    decoration: InputDecoration(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14),
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      filled: true,
                      fillColor: Colors.grey.withValues(alpha: 0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: BorderSide(
                            color: Colors.black.withValues(alpha: 0.07)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: const BorderSide(
                            color: OnepieceColors.fancyBlue, width: 1.5),
                      ),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: searchNameController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: MaterialLocalizations.of(context)
                                  .deleteButtonTooltip,
                              onPressed: () {
                                searchNameController.clear();
                                characterFilter.name = '';
                                _search(true);
                                setState(() {});
                              },
                              icon: const Icon(Icons.close, size: 18),
                            ),
                      labelText: AppLocalizations.of(context)!.starterName,
                      labelStyle: OnepieceFonts.dropDownItemStyle,
                    ),
                  ),
                ),
              ),
              if (hasCreate) ...[
                const SizedBox(width: 12),
                SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () => context.goNamed("createCharacter"),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      backgroundColor: OnepieceColors.fancyBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11)),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(AppLocalizations.of(context)!.create),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              height: 38,
              child: ToggleSwitch(
                customWidths: const [150, 150, 150, 180],
                cornerRadius: 10,
                minHeight: 38,
                fontSize: 13,
                initialLabelIndex: initialLabelIndex,
                activeBgColor: const [OnepieceColors.fancyBlue],
                inactiveBgColor:
                    OnepieceColors.fancyBlue.withValues(alpha: 0.07),
                inactiveFgColor: Colors.grey[700],
                totalSwitches: 4,
                labels: [
                  AppLocalizations.of(context)!.allResources,
                  AppLocalizations.of(context)!.myResource,
                  AppLocalizations.of(context)!.systemResource,
                  AppLocalizations.of(context)!.excludeSystem
                ],
                onToggle: (index) {
                  initialLabelIndex = index!;
                  characterFilter.systemResource =
                      (index == 2) ? true : (index == 3 ? false : null);
                  characterFilter.userId =
                      (index == 1) ? getIt<User>().id : null;
                  _search(true);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 10.0;
              final fieldWidth = (constraints.maxWidth - gap * 2) / 3;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _buildDropdown<BattleStyle>(
                    items: BattleStyle.values,
                    selectedItems: selectedBattleStyles,
                    displayMap: battleStyleToDisplayValue,
                    hint: AppLocalizations.of(context)!.battleStyle,
                    width: fieldWidth,
                    cardStyle: true,
                    onChanged: (list) {
                      characterFilter.battleStyles = list;
                      _search(true);
                    },
                  ),
                  _buildDropdown<Haki>(
                    items: Haki.values,
                    selectedItems: selectedHakis,
                    displayMap: hakiEnumValueToDisplayValue,
                    hint: AppLocalizations.of(context)!.hakis,
                    width: fieldWidth,
                    cardStyle: true,
                    onChanged: (list) {
                      characterFilter.hakis = list;
                      _search(true);
                    },
                  ),
                  _buildDropdown<Race>(
                    items: Race.values,
                    selectedItems: selectedRaces,
                    displayMap: raceEnumToDisplayName,
                    hint: AppLocalizations.of(context)!.race,
                    width: fieldWidth,
                    cardStyle: true,
                    onChanged: (list) {
                      characterFilter.races = list;
                      _search(true);
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Generic Dropdown Builder to reduce repetition
  Widget _buildDropdown<T>({
    required List<T> items,
    required List<T> selectedItems,
    required Map<T, String> displayMap,
    required String hint,
    required Function(List<T>) onChanged,
    double width = 200,
    bool cardStyle = false,
  }) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2(
        isExpanded: true,
        value: selectedItems.isEmpty ? null : selectedItems.last,
        hint: Text(hint, style: OnepieceFonts.dropDownItemStyle),
        onChanged: (value) {}, // Handled by MenuItem onTap
        selectedItemBuilder: (context) {
          return items.map((item) {
            return Container(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                selectedItems.map((e) => displayMap[e]).join(', '),
                style: const TextStyle(
                    fontSize: 16, overflow: TextOverflow.ellipsis),
                maxLines: 1,
              ),
            );
          }).toList();
        },
        buttonStyleData: ButtonStyleData(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: cardStyle ? 42 : 35,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cardStyle ? 11 : 3),
            color: cardStyle
                ? OnepieceColors.fancyBlue.withValues(alpha: 0.06)
                : OnepieceColors.liteFancyGreen,
            border: cardStyle
                ? Border.all(color: Colors.black.withValues(alpha: 0.07))
                : null,
          ),
        ),
        menuItemStyleData: const MenuItemStyleData(height: 35),
        items: items.map((T item) {
          return DropdownMenuItem<T>(
            value: item,
            enabled:
                false, // Disable default selection to handle multi-select manually
            child: StatefulBuilder(
              builder: (context, menuSetState) {
                final isSelected = selectedItems.contains(item);
                return InkWell(
                  onTap: () {
                    isSelected
                        ? selectedItems.remove(item)
                        : selectedItems.add(item);
                    onChanged(selectedItems);
                    setState(() {});
                    menuSetState(() {});
                  },
                  child: Container(
                    height: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 3.0),
                    child: Row(
                      children: [
                        Icon(isSelected
                            ? Icons.check_box_outlined
                            : Icons.check_box_outline_blank),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(displayMap[item]!,
                                style: const TextStyle(fontSize: 16))),
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

  @override
  bool get wantKeepAlive => true;
}
