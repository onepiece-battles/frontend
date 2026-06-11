import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logging/logging.dart';
import 'package:one_piece_battles_flutter/components/image_lazy_loader.dart';
import 'package:one_piece_battles_flutter/components/page_foot.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:one_piece_battles_flutter/utils/permission_check.dart';
import 'package:openapi/api.dart';
import 'package:toggle_switch/toggle_switch.dart';
import '../../constants/button_style.dart';
import '../../constants/onepiece_tag.dart';
import '../../utils/i18n_helper.dart';
import '../../utils/image_helper.dart';

GetIt getIt = GetIt.instance;

class CharacterView extends StatefulWidget {
  const CharacterView({super.key});

  @override
  State<CharacterView> createState() => _CharacterViewState();
}

class _CharacterViewState extends State<CharacterView>
    with AutomaticKeepAliveClientMixin {
  final Logger logger = Logger('CharacterView');
  final GlobalKey _tableKey = GlobalKey();

  // Controllers
  final TextEditingController searchNameController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final ScrollController tableController = ScrollController();

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
    _search(false);
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

    getIt<CharacterDao>().listCharacter(listCharacterRequest).then((value) {
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _createHeader(),
                // Control panel — horizontally scrollable if needed
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: _createControlPanel(),
                  ),
                ),
                const SizedBox(height: 10),
                // Data Table — fills remaining space, scrolls both ways
                Expanded(
                  child: Scrollbar(
                    controller: scrollController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Scrollbar(
                        controller: tableController,
                        thumbVisibility: true,
                        trackVisibility: true,
                        notificationPredicate: (notification) =>
                            notification.depth == 0,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          controller: tableController,
                          child: _createCharacterTable(),
                        ),
                      ),
                    ),
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

  Widget _createControlPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (PermissionCheck.checkPermission(
                getIt<User>().loginRoleResourcesPermissionMap,
                ResourceType.CHARACTER,
                Permission.CREATE))
              Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: SizedBox(
                  height: 35,
                  width: 120,
                  child: ElevatedButton(
                    onPressed: () => context.goNamed("createCharacter"),
                    style: OnepieceButtonStyle.getDefaultStyle(),
                    child: Text(AppLocalizations.of(context)!.create),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 6, 0),
              child: SizedBox(
                width: 200,
                height: 35,
                child: TextFormField(
                  controller: searchNameController,
                  onChanged: (value) {
                    characterFilter.name = value.trim();
                    _search(true);
                  },
                  decoration: InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      disabledBorder: const OutlineInputBorder(
                          borderSide:
                              BorderSide(color: OnepieceColors.menuHoverColor)),
                      enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                        color: OnepieceColors.menuHoverColor,
                      )),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                            color: OnepieceColors.fancyGreen, width: 1.5),
                      ),
                      prefixIcon: const Icon(Icons.search),
                      labelText: AppLocalizations.of(context)!.starterName,
                      labelStyle: OnepieceFonts.dropDownItemStyle),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ToggleSwitch(
            customWidths: const [150, 150, 150, 180],
            cornerRadius: 4,
            minHeight: 35.0,
            fontSize: 14.0,
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
              characterFilter.userId = (index == 1) ? getIt<User>().id : null;
              _search(true);
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          _buildDropdown<BattleStyle>(
            items: BattleStyle.values,
            selectedItems: selectedBattleStyles,
            displayMap: battleStyleToDisplayValue,
            hint: AppLocalizations.of(context)!.battleStyle,
            onChanged: (list) {
              characterFilter.battleStyles = list;
              _search(true);
            },
          ),
          const SizedBox(width: 6),
          _buildDropdown<Haki>(
            items: Haki.values,
            selectedItems: selectedHakis,
            displayMap: hakiEnumValueToDisplayValue,
            hint: AppLocalizations.of(context)!.hakis,
            onChanged: (list) {
              characterFilter.hakis = list;
              _search(true);
            },
          ),
          const SizedBox(width: 6),
          _buildDropdown<Race>(
            items: Race.values,
            selectedItems: selectedRaces,
            displayMap: raceEnumToDisplayName,
            hint: AppLocalizations.of(context)!.race,
            width: 250,
            onChanged: (list) {
              characterFilter.races = list;
              _search(true);
            },
          ),
        ])
      ],
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
          height: 35,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: OnepieceColors.liteFancyGreen,
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
        final stats = <_StatPair>[
          _StatPair(AppLocalizations.of(context)!.characterAttack,
              character.attack.toString(),
              icon: 'images/character_digits_icon/attack.svg'),
          _StatPair(AppLocalizations.of(context)!.characterDefense,
              character.defense.toString(),
              icon: 'images/character_digits_icon/defense.svg'),
          _StatPair(AppLocalizations.of(context)!.characterIntelligence,
              character.intelligence.toString(),
              icon: 'images/character_digits_icon/intelligence.svg'),
          _StatPair(AppLocalizations.of(context)!.characterBlood,
              character.blood.toString(),
              icon: 'images/character_digits_icon/blood.svg'),
          _StatPair(AppLocalizations.of(context)!.characterSpeed,
              character.speed.toString(),
              icon: 'images/character_digits_icon/speed.svg'),
          _StatPair(AppLocalizations.of(context)!.groupGain,
              character.groupGain.toString(),
              icon: 'images/character_digits_icon/group_gain.svg'),
          _StatPair(AppLocalizations.of(context)!.fruitLimit,
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

/// Lightweight value object for the expandable stat rows.
class _StatPair {
  final String label;
  final String value;
  final String? icon;
  const _StatPair(this.label, this.value, {this.icon});
}
