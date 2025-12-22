import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logging/logging.dart';
import 'package:one_piece_battles_flutter/components/image_lazy_loader.dart';
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
  final TextEditingController pageNumberController =
      TextEditingController(text: "0");
  final ScrollController scrollController = ScrollController();
  final ScrollController controlPanelController = ScrollController();
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
  bool preButtonEnabled = false;
  bool nextButtonEnabled = false;
  bool confirmButtonEnabled = false;
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
    CharacterSortableFieldsEnum.fruitLimit: null,
    CharacterSortableFieldsEnum.groupGain: null,
    CharacterSortableFieldsEnum.attack: null,
    CharacterSortableFieldsEnum.defense: null,
    CharacterSortableFieldsEnum.intelligence: null,
    CharacterSortableFieldsEnum.blood: null,
    CharacterSortableFieldsEnum.speed: null,
  };

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
        pageNumberController.text =
            currentCharacterList.isEmpty ? "0" : selectedPageNum.toString();
        totalItemCount = value.totalSize!;
        totalPageNum = (totalItemCount / itemCountPerPage).ceil();
        preButtonEnabled = selectedPageNum > 1;
        nextButtonEnabled = selectedPageNum < totalPageNum;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _createHeader(),
                  // Wrap control panel in simpler scroll container
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: controlPanelController,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: _createControlPanel(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Data Table Area
                  Scrollbar(
                    trackVisibility: true,
                    thickness: 5,
                    controller: tableController,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: tableController,
                      child: _createCharacterTable(),
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
          if (totalPageNum > 1)
            Padding(
              padding: const EdgeInsets.only(top: 15.0),
              child: _getPageFoot(),
            ),
        ],
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
            SizedBox(
              width: 200,
              height: 35,
              child: TextFormField(
                controller: searchNameController,
                onChanged: (value) {
                  characterFilter.name = value;
                  _search(true);
                },
                decoration: InputDecoration(
                  labelStyle: OnepieceFonts.dropDownItemStyle,
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  border: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: OnepieceColors.menuHoverColor)),
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                          color: OnepieceColors.fancyGreen, width: 1.5)),
                  prefixIcon: const Icon(Icons.search),
                  labelText: AppLocalizations.of(context)!.name,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
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
      _createSingleColumn(
        AppLocalizations.of(context)!.characterAttack,
        CharacterSortableFieldsEnum.attack,
        iconPath: 'images/character_digits_icon/attack.svg',
      ),
      _createSingleColumn(
        AppLocalizations.of(context)!.characterDefense,
        CharacterSortableFieldsEnum.defense,
        iconPath: 'images/character_digits_icon/defense.svg',
      ),
      _createSingleColumn(
        AppLocalizations.of(context)!.characterIntelligence,
        CharacterSortableFieldsEnum.intelligence,
        iconPath: 'images/character_digits_icon/intelligence.svg',
      ),
      _createSingleColumn(
        AppLocalizations.of(context)!.characterBlood,
        CharacterSortableFieldsEnum.blood,
        iconPath: 'images/character_digits_icon/blood.svg',
      ),
      _createSingleColumn(
        AppLocalizations.of(context)!.characterSpeed,
        CharacterSortableFieldsEnum.speed,
        iconPath: 'images/character_digits_icon/speed.svg',
      ),
      _createSingleColumn(
        AppLocalizations.of(context)!.groupGain,
        CharacterSortableFieldsEnum.groupGain,
        iconPath: 'images/character_digits_icon/group_gain.svg',
      ),
      _createSingleColumn(AppLocalizations.of(context)!.fruitLimit,
          CharacterSortableFieldsEnum.fruitLimit),
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
    return currentCharacterList.asMap().entries.map((entry) {
      final character = entry.value;
      final isEven = entry.key.isEven;

      return DataRow(
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
          DataCell(
            Padding(
              padding: const EdgeInsets.all(3.0),
              child: ImageLazyLoader(
                  key: UniqueKey(),
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
          DataCell(Text(character.attack.toString())),
          DataCell(Text(character.defense.toString())),
          DataCell(Text(character.intelligence.toString())),
          DataCell(Text(character.blood.toString())),
          DataCell(Text(character.speed.toString())),
          DataCell(Text(character.groupGain.toString())),
          DataCell(Text(character.maximumFruitCount.toString())),
        ],
      );
    }).toList();
  }

  Widget _getPageFoot() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
            style: OnepieceButtonStyle.getDefaultStyle(),
            onPressed: preButtonEnabled
                ? () {
                    selectedPageNum--;
                    _search(false);
                  }
                : null,
            child: const Icon(Icons.arrow_back)),
        const SizedBox(width: 8),
        SizedBox(
          width: 35,
          child: TextFormField(
              style: OnepieceFonts.pageInputStyle,
              textAlign: TextAlign.center,
              controller: pageNumberController,
              decoration: const InputDecoration(
                contentPadding:
                    EdgeInsets.only(bottom: 10), // Adjust for alignment
                enabledBorder: UnderlineInputBorder(),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: OnepieceColors.themeColor)),
              ),
              onChanged: (value) {
                setState(() {
                  final page = int.tryParse(value);
                  confirmButtonEnabled = page != null &&
                      page > 0 &&
                      page <= totalPageNum &&
                      page != selectedPageNum;
                });
              }),
        ),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
                color: OnepieceColors.menuBackgroundColor,
                borderRadius: BorderRadius.circular(3)),
            child: Text("/$totalPageNum", style: OnepieceFonts.contentStyle)),
        const SizedBox(width: 8),
        ElevatedButton(
            style: OnepieceButtonStyle.getDefaultStyle(),
            onPressed: confirmButtonEnabled
                ? () {
                    selectedPageNum = int.parse(pageNumberController.text);
                    _search(false);
                  }
                : null,
            child: Text(AppLocalizations.of(context)!.jumpToPage)),
        const SizedBox(width: 8),
        ElevatedButton(
            style: OnepieceButtonStyle.getDefaultStyle(),
            onPressed: nextButtonEnabled
                ? () {
                    selectedPageNum++;
                    _search(false);
                  }
                : null,
            child: const Icon(Icons.arrow_forward)),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
