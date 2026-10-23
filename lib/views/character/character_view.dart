import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logging/logging.dart';
import 'package:one_piece_battles_flutter/components/image_lazy_loader.dart';
import 'package:one_piece_battles_flutter/components/desktop_card_layout.dart';
import 'package:one_piece_battles_flutter/components/page_foot.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:one_piece_battles_flutter/utils/permission_check.dart';
import 'package:openapi/api.dart';
import 'package:toggle_switch/toggle_switch.dart';
import '../../constants/button_style.dart';
import '../../constants/onepiece_tag.dart';
import '../../utils/i18n_helper.dart';
import '../../utils/image_helper.dart';
import '../../utils/responsive_breakpoints.dart';
import '../../utils/route_notifier.dart';
import 'character_list_controller.dart';
import 'widgets/character_stat_pair.dart';
import 'widgets/character_mobile_roster.dart';

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
  final GlobalKey _tableKey = GlobalKey();
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
                          : _buildDesktopCharacterRoster(),
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

  // ── Desktop: profile-card roster ────────────────────────────────────────

  Widget _buildDesktopCharacterRoster() {
    if (currentCharacterList.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.empty,
            style: OnepieceFonts.contentStyle),
      );
    }

    final scoreOrder =
        sortableEnumToSortOrderMap[CharacterSortableFieldsEnum.score];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$totalItemCount ${AppLocalizations.of(context)!.character}',
              style: OnepieceFonts.smallContentStyle,
            ),
            const Spacer(),
            _buildScoreSortButton(scoreOrder),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Scrollbar(
            controller: scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 18),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 18.0;
                  final columnCount =
                      (constraints.maxWidth / 340).floor().clamp(2, 5);
                  final cardWidth =
                      (constraints.maxWidth - gap * (columnCount - 1)) /
                          columnCount;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: currentCharacterList
                        .map((character) => SizedBox(
                              width: cardWidth,
                              child: _buildDesktopCharacterCard(character),
                            ))
                        .toList(),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreSortButton(SortOrder? scoreOrder) {
    final isActive = scoreOrder != null;
    return Tooltip(
      message: AppLocalizations.of(context)!.combatPower,
      child: InkWell(
        onTap: () {
          SortOrder? nextOrder;
          if (scoreOrder == SortOrder.DESC) {
            nextOrder = SortOrder.ASC;
          } else if (scoreOrder == SortOrder.ASC) {
            nextOrder = null;
          } else {
            nextOrder = SortOrder.DESC;
          }
          setState(() {
            sortableEnumToSortOrderMap[CharacterSortableFieldsEnum.score] =
                nextOrder;
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
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isActive
                ? OnepieceColors.fancyBlue.withValues(alpha: 0.10)
                : Colors.grey.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? OnepieceColors.fancyBlue.withValues(alpha: 0.35)
                  : Colors.grey.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt, size: 17, color: OnepieceColors.fancyBlue),
              const SizedBox(width: 5),
              Text(
                AppLocalizations.of(context)!.combatPower,
                style: OnepieceFonts.smallContentStyle.copyWith(
                  color: isActive ? OnepieceColors.fancyBlue : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                scoreOrder == SortOrder.ASC
                    ? Icons.arrow_upward
                    : scoreOrder == SortOrder.DESC
                        ? Icons.arrow_downward
                        : Icons.unfold_more,
                size: 15,
                color: isActive ? OnepieceColors.fancyBlue : Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopCharacterCard(CharacterListView character) {
    final isExpanded = _expandedRowIds.contains(character.id);
    final race = raceEnumToDisplayName[character.race] ?? '';
    final battleStyle = battleStyleToDisplayValue[character.battleStyle] ?? '';

    return DesktopSpotlightCard(
      key: ValueKey('character-card-${character.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => context.goNamed(
              'characterDetails',
              extra: character.id,
              pathParameters: {
                'name': I18nHelper.getDisplayNameFromI18n(character.name)
              },
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'character-roster-${character.id}',
                        child: ImageLazyLoader(
                          key: ValueKey(character.imageUri),
                          uriProvider: () => character.imageUri!,
                          width: 58,
                          borderWidth: 2,
                          borderRadios: 58,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              I18nHelper.getDisplayNameFromI18n(character.name),
                              style: OnepieceFonts.contentStyleBold.copyWith(
                                color: OnepieceColors.deepFancyBlue,
                                fontSize: 17,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(Icons.public,
                                    size: 14, color: Colors.black45),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '$race · $battleStyle',
                                    style: OnepieceFonts.smallContentStyle
                                        .copyWith(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              OnepieceColors.fancyBlue,
                              OnepieceColors.deepFancyBlue,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.bolt,
                                size: 14, color: Colors.white70),
                            Text(
                              character.score.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (character.hakis.isNotEmpty)
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: (character.hakis.toList()
                            ..sort(
                                (a, b) => a.toString().compareTo(b.toString())))
                          .map((haki) => OnepieceTag.getHakiTag(
                              haki, hakiEnumValueToDisplayValue[haki]!))
                          .toList(),
                    )
                  else
                    const SizedBox(height: 20),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: OnepieceColors.liteFancyGreen,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.paid_outlined,
                            size: 17, color: Colors.orange[800]),
                        const SizedBox(width: 5),
                        Text(
                          character.bounty?.toString() ?? '—',
                          style: GoogleFonts.lobster(
                            fontSize: 14,
                            color: Colors.orange[900],
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (isExpanded) {
                                _expandedRowIds.remove(character.id);
                              } else {
                                _expandedRowIds.add(character.id);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!
                                      .detailInformation,
                                  style: OnepieceFonts.boldFancySmallFont,
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  size: 18,
                                  color: OnepieceColors.fancyBlue,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox(width: double.infinity),
                    secondChild: _buildDesktopStats(character),
                    crossFadeState: isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopStats(CharacterListView character) {
    final stats = <StatPair>[
      StatPair(AppLocalizations.of(context)!.characterAttack,
          character.attack.toString(),
          icon: 'images/character_digits_icon/attack.svg'),
      StatPair(AppLocalizations.of(context)!.characterDefense,
          character.defense.toString(),
          icon: 'images/character_digits_icon/defense.svg'),
      StatPair(AppLocalizations.of(context)!.characterIntelligence,
          character.intelligence.toString(),
          icon: 'images/character_digits_icon/intelligence.svg'),
      StatPair(AppLocalizations.of(context)!.characterBlood,
          character.blood.toString(),
          icon: 'images/character_digits_icon/blood.svg'),
      StatPair(AppLocalizations.of(context)!.characterSpeed,
          character.speed.toString(),
          icon: 'images/character_digits_icon/speed.svg'),
      StatPair(AppLocalizations.of(context)!.groupGain,
          character.groupGain.toString(),
          icon: 'images/character_digits_icon/group_gain.svg'),
      StatPair(AppLocalizations.of(context)!.fruitLimit,
          character.maximumFruitCount.toString()),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: stats
            .map(
              (stat) => Container(
                width: 102,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.black.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    if (stat.icon != null) ...[
                      ImageHelper.getTextFormFieldIcon(stat.icon!, false, 14),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        stat.label,
                        style: OnepieceFonts.superSmallContentStyle
                            .copyWith(fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      stat.value,
                      style: OnepieceFonts.boldFancySmallFont,
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // Kept as a fallback while the roster layout is evaluated.
  // ignore: unused_element
  DataTable _createCharacterTable() {
    return DataTable(
      key: _tableKey,
      showCheckboxColumn: false,
      showBottomBorder: true,
      headingRowHeight: 50,
      border: const TableBorder(
          top: BorderSide(color: OnepieceColors.themeColor),
          bottom: BorderSide(color: OnepieceColors.themeColor)),
      columns: _createColumns(),
      rows: _createRows(),
      columnSpacing: 20, // Increased slightly for breathing room
      horizontalMargin: 10,
    );
  }

  List<DataColumn> _createColumns() {
    return [
      // Expand / collapse toggle
      const DataColumn(label: SizedBox(width: 36)),
      DataColumn(
        label: Tooltip(
          message: AppLocalizations.of(context)!.resetSort,
          child: ImageHelper.getIconButtonFromSvg(
              'images/svgs/reset.svg', OnepieceColors.fancyBlue, 25, 25, () {
            setState(() {
              sortKeys.clear();
              sortableEnumToSortOrderMap.updateAll((key, value) => null);
              _search(false);
            });
          }),
        ),
      ),
      _createSingleColumn(AppLocalizations.of(context)!.characterName, null),
      _createSingleColumn(AppLocalizations.of(context)!.hakis, null),
      _createSingleColumn(AppLocalizations.of(context)!.combatPower,
          CharacterSortableFieldsEnum.score),
      _createSingleColumn(AppLocalizations.of(context)!.race, null),
      _createSingleColumn(AppLocalizations.of(context)!.battleStyle, null),
      _createSingleColumn(
        AppLocalizations.of(context)!.bounty,
        null,
        iconPath: 'images/character_digits_icon/bounty.svg',
      ),
    ];
  }

  // Refactored to be flexible width
  DataColumn _createSingleColumn(
      String displayText, CharacterSortableFieldsEnum? sortEnum,
      {String? iconPath}) {
    final isSorted =
        sortEnum != null && sortableEnumToSortOrderMap[sortEnum] != null;
    final sortOrder =
        sortEnum != null ? sortableEnumToSortOrderMap[sortEnum] : null;

    return DataColumn(
      label: InkWell(
        onTap: sortEnum == null
            ? null
            : () {
                setState(() {
                  // Logic to cycle: None -> Desc -> Asc -> None (or similar)
                  // Simplified logic based on existing code:
                  SortOrder? newOrder;
                  if (sortOrder == null) {
                    newOrder = SortOrder.ASC;
                  } else if (sortOrder == SortOrder.ASC) {
                    newOrder = SortOrder.DESC;
                  } else {
                    newOrder = null;
                  }

                  sortableEnumToSortOrderMap[sortEnum] = newOrder;
                  sortKeys
                      .removeWhere((element) => element.sortKey == sortEnum);

                  if (newOrder != null) {
                    sortKeys.insert(
                        0,
                        CharacterSortableField(
                            sortKey: sortEnum, sortOrder: newOrder));
                  }
                  _search(false);
                });
              },
        child: Row(
          mainAxisSize: MainAxisSize.min, // Important for auto-width
          children: [
            if (iconPath != null)
              Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: ImageHelper.getTextFormFieldIcon(iconPath, true, 20),
              ),
            Text(
              displayText,
              style: isSorted
                  ? OnepieceFonts.selectedTableHeaderStyle
                  : OnepieceFonts.tableHeaderStyle,
            ),
            if (sortEnum != null)
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: ImageHelper.getSvgIconWithColor(
                  sortOrderToPath[sortOrder]!,
                  12,
                  12,
                  isSorted ? OnepieceColors.themeColor : Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<DataRow> _createRows() {
    final List<DataRow> rows = [];

    for (final entry in currentCharacterList.asMap().entries) {
      final character = entry.value;
      final isEven = entry.key.isEven;
      final isExpanded = _expandedRowIds.contains(character.id);

      // ── Main row ─────────────────────────────────────────────────
      rows.add(DataRow(
        color: WidgetStateProperty.all(
            isEven ? OnepieceColors.liteFancyGreen : null),
        onSelectChanged: (_) {
          context.goNamed('characterDetails',
              extra: character.id,
              pathParameters: {
                'name': I18nHelper.getDisplayNameFromI18n(character.name)
              });
        },
        cells: [
          // Expand / collapse icon — opaque hit-test so only the
          // icon area toggles; the rest of the row still navigates.
          DataCell(
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedRowIds.remove(character.id);
                  } else {
                    _expandedRowIds.add(character.id);
                  }
                });
              },
              child: Center(
                child: Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: OnepieceColors.fancyBlue,
                  size: 22,
                ),
              ),
            ),
          ),
          // Image
          DataCell(
            Padding(
              padding: const EdgeInsets.all(3.0),
              child: ImageLazyLoader(
                  key: ValueKey(character.imageUri),
                  uriProvider: () => character.imageUri!,
                  width: 40,
                  borderWidth: 1.5,
                  borderRadios: 40),
            ),
          ),
          DataCell(Text(I18nHelper.getDisplayNameFromI18n(character.name))),
          DataCell(Row(
            mainAxisSize: MainAxisSize.min,
            children: (character.hakis.toList()
                  ..sort((a, b) => a.toString().compareTo(b.toString())))
                .map((e) => Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: OnepieceTag.getHakiTag(
                          e, hakiEnumValueToDisplayValue[e]!),
                    ))
                .toList(),
          )),
          DataCell(Text(character.score.toString(),
              style: OnepieceFonts.boldFancySmallFont)),
          DataCell(Text(raceEnumToDisplayName[character.race] ?? '')),
          DataCell(
              Text(battleStyleToDisplayValue[character.battleStyle] ?? '')),
          DataCell(Text(
            character.bounty?.toString() ?? "",
            style: GoogleFonts.lobster(),
            textAlign: TextAlign.right,
          )),
        ],
      ));

      // ── Expanded stat sub-rows ───────────────────────────────────
      if (isExpanded) {
        final stats = <StatPair>[
          StatPair(AppLocalizations.of(context)!.characterAttack,
              character.attack.toString(),
              icon: 'images/character_digits_icon/attack.svg'),
          StatPair(AppLocalizations.of(context)!.characterDefense,
              character.defense.toString(),
              icon: 'images/character_digits_icon/defense.svg'),
          StatPair(AppLocalizations.of(context)!.characterIntelligence,
              character.intelligence.toString(),
              icon: 'images/character_digits_icon/intelligence.svg'),
          StatPair(AppLocalizations.of(context)!.characterBlood,
              character.blood.toString(),
              icon: 'images/character_digits_icon/blood.svg'),
          StatPair(AppLocalizations.of(context)!.characterSpeed,
              character.speed.toString(),
              icon: 'images/character_digits_icon/speed.svg'),
          StatPair(AppLocalizations.of(context)!.groupGain,
              character.groupGain.toString(),
              icon: 'images/character_digits_icon/group_gain.svg'),
          StatPair(AppLocalizations.of(context)!.fruitLimit,
              character.maximumFruitCount.toString()),
        ];

        for (final stat in stats) {
          rows.add(DataRow(
            color: WidgetStateProperty.all(
                OnepieceColors.liteFancyGreen.withValues(alpha: 0.4)),
            cells: [
              const DataCell(SizedBox.shrink()),
              const DataCell(SizedBox.shrink()),
              DataCell(Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (stat.icon != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ImageHelper.getTextFormFieldIcon(
                            stat.icon!, false, 16),
                      ),
                    Text(stat.label, style: OnepieceFonts.smallContentStyle),
                    const SizedBox(width: 8),
                    Text(stat.value, style: OnepieceFonts.boldFancySmallFont),
                  ],
                ),
              )),
              // Fill remaining columns with empty cells
              for (int i = 0; i < 5; i++) const DataCell(SizedBox.shrink()),
            ],
          ));
        }
      }
    }

    return rows;
  }

  @override
  bool get wantKeepAlive => true;
}
