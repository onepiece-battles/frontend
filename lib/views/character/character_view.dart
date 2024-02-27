import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:one_piece_battles_flutter/utils/base64_helper.dart';
import 'package:one_piece_battles_flutter/utils/data_validator.dart';
import 'package:openapi/api.dart';
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

class _CharacterViewState extends State<CharacterView> {
  Logger logger = Logger('CharacterView');
  TextEditingController searchNameController = TextEditingController();
  TextEditingController pageNumberController = TextEditingController(text: "0");
  CharacterFilter characterFilter = CharacterFilter();
  List<CharacterListView> currentCharacterList = [];
  List<CharacterSortableField> sortKeys = [];

  // sorting related fields
  Map<SortOrder?, String> sortOrderToPath = const {
    null: 'images/svgs/sort-solid.svg',
    SortOrder.ASC: 'images/svgs/sort-up-solid.svg',
    SortOrder.DESC: 'images/svgs/sort-down-solid.svg'
  };
  Map<CharacterSortableFieldsEnum, SortOrder?> sortableEnumToSortOrderMap = {
    CharacterSortableFieldsEnum.name: null,
    CharacterSortableFieldsEnum.fruitLimit: null,
    CharacterSortableFieldsEnum.groupGain: null,
    CharacterSortableFieldsEnum.attack: null,
    CharacterSortableFieldsEnum.defense: null,
    CharacterSortableFieldsEnum.intelligence: null,
    CharacterSortableFieldsEnum.blood: null,
    CharacterSortableFieldsEnum.speed: null,
  };
  List<BattleStyle> selectedBattleStyles = [];
  List<Race> selectedRaces = [];
  List<Haki> selectedHakis = [];
  ScrollController scrollController = ScrollController();

  int selectedPageNum = 1;
  int totalPageNum = 0;
  int itemCountPerPage = 10;
  int totalItemCount = 0;
  bool preButtonEnabled = false;
  bool nextButtonEnabled = false;
  bool confirmButtonEnabled = false;

  bool onlyShowSystemResource = false;
  bool donNotShowSystemResource = false;
  bool fruitOwnersOnly = false;

  @override
  void initState() {
    super.initState();
    _search();
  }

  void _search() {
    characterFilter.languageCode = I18nHelper.getLanguageCode();
    ListCharacterRequest listCharacterRequest = ListCharacterRequest(
        pageSize: itemCountPerPage,
        pageIndex: selectedPageNum,
        sortKeys: sortKeys,
        characterFilter: characterFilter);
    Future<ListCharacterResponse?> listCharacterResponse =
        getIt<CharacterDao>().listCharacter(listCharacterRequest);

    listCharacterResponse.then((value) {
      setState(() {
        currentCharacterList = value!.characters;
        if (currentCharacterList.isEmpty) {
          pageNumberController.text = "0";
        } else {
          pageNumberController.text = selectedPageNum.toString();
        }
        totalItemCount = value.totalSize!;
        totalPageNum = (totalItemCount / itemCountPerPage).ceil();
        if (selectedPageNum <= 1) {
          preButtonEnabled = false;
        } else {
          preButtonEnabled = true;
        }
        if (selectedPageNum >= totalPageNum) {
          nextButtonEnabled = false;
        } else {
          nextButtonEnabled = true;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _createHeader(context),
              SizedBox(
                width: 2000,
                height: 50,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _createControlPanel(context),
                ),
              ),
              SizedBox(
                width: 2000,
                child: FittedBox(
                  fit: BoxFit.fitWidth,
                  child: _createCharacterTable(context),
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              if (totalPageNum > 1)
                SizedBox(
                  width: 2000,
                  child: Center(child: _getPageFoot(context)),
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget _createHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
      child: Text(
        AppLocalizations.of(context)!.character,
        style: OnepieceFonts.headerStyle,
      ),
    );
  }

  Widget _createControlPanel(BuildContext context) {
    Map<BattleStyle, String> battleStyleToDisplayValue = <BattleStyle, String>{
      BattleStyle.BODY: AppLocalizations.of(context)!.body,
      BattleStyle.SCIENCE: AppLocalizations.of(context)!.science,
      BattleStyle.KATANA: AppLocalizations.of(context)!.katana,
      BattleStyle.SHOOTER: AppLocalizations.of(context)!.shoot
    };
    Map<Race, String> raceEnumToDisplayName = {
      Race.HUMAN: AppLocalizations.of(context)!.human,
      Race.FISH_MAN: AppLocalizations.of(context)!.fishman,
      Race.MERFOLK: AppLocalizations.of(context)!.merfolk,
      Race.GIANT: AppLocalizations.of(context)!.giant,
      Race.LONG_ARM: AppLocalizations.of(context)!.longArm,
      Race.LONG_LEG: AppLocalizations.of(context)!.longLeg,
      Race.SNAKE_NECK: AppLocalizations.of(context)!.snakeNeck,
      Race.THREE_EYE: AppLocalizations.of(context)!.threeEye,
      Race.LUNARIAN: AppLocalizations.of(context)!.lunarian,
      Race.MINK: AppLocalizations.of(context)!.mink,
      Race.WORLD_NOBEL: AppLocalizations.of(context)!.worldNobel,
      Race.DWARVES: AppLocalizations.of(context)!.dwarves
    };
    Map<Haki, String> hakiEnumValueToDisplayValue = {
      Haki.busoshoku: AppLocalizations.of(context)!.busoshoku,
      Haki.haoshoku: AppLocalizations.of(context)!.haoshoku,
      Haki.kenbunshoku: AppLocalizations.of(context)!.kenbunshoku,
    };
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            height: 35,
            child: Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: ElevatedButton(
                  onPressed: () {
                    context.goNamed("createCharacter");
                  },
                  style: OnepieceButtonStyle.getDefaultStyle(),
                  child: Text(
                    AppLocalizations.of(context)!.createCharacter,
                  )),
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
                  characterFilter.name = value;
                  _search();
                },
                decoration: InputDecoration(
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  disabledBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: OnepieceColors.menuHoverColor)),
                  enabledBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: OnepieceColors.menuHoverColor)),
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: OnepieceColors.fancyGreen)),
                  prefixIcon: const Icon(Icons.search),
                  labelText: AppLocalizations.of(context)!.name,
                ),
              ),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton2(
              isExpanded: true,
              value: selectedBattleStyles.isEmpty
                  ? null
                  : selectedBattleStyles.last,
              hint: Text(
                AppLocalizations.of(context)!.battleStyle,
                style: OnepieceFonts.dropDownItemStyle,
              ),
              onChanged: (value) {},
              selectedItemBuilder: (context) {
                return BattleStyle.values.map(
                  (item) {
                    return Container(
                      alignment: AlignmentDirectional.center,
                      child: Text(
                        selectedBattleStyles
                            .map((selectedType) {
                              return battleStyleToDisplayValue[selectedType];
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
                width: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: OnepieceColors.liteFancyGreen,
                ),
              ),
              menuItemStyleData: const MenuItemStyleData(
                height: 35,
              ),
              items: BattleStyle.values.map((BattleStyle battleStyle) {
                return DropdownMenuItem<BattleStyle>(
                  value: battleStyle,
                  enabled: false,
                  child: StatefulBuilder(
                    builder: (context, menuSetState) {
                      final isSelected =
                          selectedBattleStyles.contains(battleStyle);
                      return InkWell(
                        onTap: () {
                          isSelected
                              ? selectedBattleStyles.remove(battleStyle)
                              : selectedBattleStyles.add(battleStyle);
                          characterFilter.battleStyles = selectedBattleStyles;
                          // //This rebuilds the StatefulWidget to update the button's text
                          setState(() {});
                          //This rebuilds the dropdownMenu Widget to update the check mark
                          menuSetState(() {});
                          _search();
                        },
                        child: Container(
                          height: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 3.0),
                          child: Row(
                            children: [
                              if (isSelected)
                                const Icon(Icons.check_box_outlined)
                              else
                                const Icon(Icons.check_box_outline_blank),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  battleStyleToDisplayValue[battleStyle]!,
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
          const SizedBox(
            width: 6,
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton2(
              isExpanded: true,
              value: selectedHakis.isEmpty ? null : selectedHakis.last,
              hint: Text(
                AppLocalizations.of(context)!.hakis,
                style: OnepieceFonts.dropDownItemStyle,
              ),
              onChanged: (value) {},
              selectedItemBuilder: (context) {
                return BattleStyle.values.map(
                  (item) {
                    return Container(
                      alignment: AlignmentDirectional.center,
                      child: Text(
                        selectedHakis
                            .map((selectedType) {
                              return hakiEnumValueToDisplayValue[selectedType];
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
                width: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: OnepieceColors.liteFancyGreen,
                ),
              ),
              menuItemStyleData: const MenuItemStyleData(
                height: 35,
              ),
              items: Haki.values.map((Haki haki) {
                return DropdownMenuItem<Haki>(
                  value: haki,
                  enabled: false,
                  child: StatefulBuilder(
                    builder: (context, menuSetState) {
                      final isSelected = selectedHakis.contains(haki);
                      return InkWell(
                        onTap: () {
                          isSelected
                              ? selectedHakis.remove(haki)
                              : selectedHakis.add(haki);
                          characterFilter.hakis = selectedHakis;
                          debugPrint('$selectedHakis');
                          // //This rebuilds the StatefulWidget to update the button's text
                          setState(() {});
                          //This rebuilds the dropdownMenu Widget to update the check mark
                          menuSetState(() {});
                          _search();
                        },
                        child: Container(
                          height: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 3.0),
                          child: Row(
                            children: [
                              if (isSelected)
                                const Icon(Icons.check_box_outlined)
                              else
                                const Icon(Icons.check_box_outline_blank),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  hakiEnumValueToDisplayValue[haki]!,
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
          const SizedBox(
            width: 6,
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton2(
              isExpanded: true,
              value: selectedRaces.isEmpty ? null : selectedRaces.last,
              hint: Text(
                AppLocalizations.of(context)!.race,
                style: OnepieceFonts.dropDownItemStyle,
              ),
              onChanged: (value) {},
              selectedItemBuilder: (context) {
                return Race.values.map(
                  (item) {
                    return Container(
                      alignment: AlignmentDirectional.center,
                      child: Text(
                        selectedRaces
                            .map((selectedRace) {
                              return raceEnumToDisplayName[selectedRace];
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
                width: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: OnepieceColors.liteFancyGreen,
                ),
              ),
              menuItemStyleData: const MenuItemStyleData(
                height: 35,
              ),
              items: Race.values.map((Race race) {
                return DropdownMenuItem<Race>(
                  value: race,
                  enabled: false,
                  child: StatefulBuilder(
                    builder: (context, menuSetState) {
                      final isSelected = selectedRaces.contains(race);
                      return InkWell(
                        onTap: () {
                          isSelected
                              ? selectedRaces.remove(race)
                              : selectedRaces.add(race);
                          characterFilter.races = selectedRaces;
                          // //This rebuilds the StatefulWidget to update the button's text
                          setState(() {});
                          //This rebuilds the dropdownMenu Widget to update the check mark
                          menuSetState(() {});
                          _search();
                        },
                        child: Container(
                          height: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 3.0),
                          child: Row(
                            children: [
                              if (isSelected)
                                const Icon(Icons.check_box_outlined)
                              else
                                const Icon(Icons.check_box_outline_blank),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  raceEnumToDisplayName[race]!,
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
        ],
      ),
      const SizedBox(
        width: 60,
      ),
      Row(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
            child: SizedBox(
              height: 35,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)!.systemResource,
                    style: OnepieceFonts.smallContentStyle,
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        onlyShowSystemResource = !onlyShowSystemResource;
                        if (donNotShowSystemResource) {
                          donNotShowSystemResource = false;
                        }
                        if (onlyShowSystemResource) {
                          characterFilter.onlySystem = true;
                        } else {
                          characterFilter.onlySystem = null;
                        }
                        _search();
                      });
                    },
                    splashRadius: 1,
                    icon: onlyShowSystemResource
                        ? const Icon(
                            Icons.check_box,
                            color: OnepieceColors.fancyBlue,
                            size: 20,
                          )
                        : const Icon(
                            Icons.check_box_outline_blank,
                            color: OnepieceColors.fancyBlue,
                            size: 20,
                          ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
            child: SizedBox(
              height: 35,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)!.noSystemResource,
                    style: OnepieceFonts.smallContentStyle,
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        donNotShowSystemResource = !donNotShowSystemResource;
                        if (onlyShowSystemResource) {
                          onlyShowSystemResource = false;
                        }
                        if (donNotShowSystemResource) {
                          characterFilter.onlySystem = false;
                        } else {
                          characterFilter.onlySystem = null;
                        }
                        _search();
                      });
                    },
                    splashRadius: 1,
                    icon: donNotShowSystemResource
                        ? const Icon(
                            Icons.check_box,
                            color: OnepieceColors.fancyBlue,
                            size: 20,
                          )
                        : const Icon(
                            Icons.check_box_outline_blank,
                            color: OnepieceColors.fancyBlue,
                            size: 20,
                          ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 35,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context)!.fruitOwner,
                  style: OnepieceFonts.smallContentStyle,
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      fruitOwnersOnly = !fruitOwnersOnly;
                      if (fruitOwnersOnly) {
                        characterFilter.hasFruit = true;
                      } else {
                        characterFilter.hasFruit = null;
                      }
                      _search();
                    });
                  },
                  splashRadius: 1,
                  icon: fruitOwnersOnly
                      ? const Icon(
                          Icons.check_box,
                          color: OnepieceColors.fancyBlue,
                          size: 20,
                        )
                      : const Icon(
                          Icons.check_box_outline_blank,
                          color: OnepieceColors.fancyBlue,
                          size: 20,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    ]);
  }

  DataTable _createCharacterTable(BuildContext context) {
    return DataTable(
      showCheckboxColumn: false,
      showBottomBorder: true,
      headingRowHeight: 50,
      border: const TableBorder(
          top: BorderSide(color: OnepieceColors.themeColor),
          bottom: BorderSide(color: OnepieceColors.themeColor)),
      columns: _createColumns(context),
      rows: _createRows(context),
      columnSpacing: 10,
    );
  }

  List<DataColumn> _createColumns(BuildContext context) {
    return [
      DataColumn(
        label: Tooltip(
          message: AppLocalizations.of(context)!.resetSort,
          child: ImageHelper.getIconButtonFromSvg(
              'images/svgs/reset.svg', OnepieceColors.fancyBlue, 25, 25, () {
            sortKeys = [];
            sortableEnumToSortOrderMap = {
              CharacterSortableFieldsEnum.name: null,
              CharacterSortableFieldsEnum.fruitLimit: null,
              CharacterSortableFieldsEnum.groupGain: null,
              CharacterSortableFieldsEnum.attack: null,
              CharacterSortableFieldsEnum.defense: null,
              CharacterSortableFieldsEnum.intelligence: null,
              CharacterSortableFieldsEnum.blood: null,
              CharacterSortableFieldsEnum.speed: null,
            };
            _search();
          }),
        ),
      ),
      _createSingleColumn(
          AppLocalizations.of(context)!.characterName, null, 120, false),
      _createSingleColumn(
          AppLocalizations.of(context)!.hakis, null, 120, false),
      _createSingleColumn(AppLocalizations.of(context)!.race, null, 120, false),
      _createSingleColumn(
          AppLocalizations.of(context)!.battleStyle, null, 120, false),
      _createSingleColumn(
          AppLocalizations.of(context)!.bounty, null, 120, false),
      _createSingleColumn(AppLocalizations.of(context)!.characterAttack,
          CharacterSortableFieldsEnum.attack, null, true),
      _createSingleColumn(AppLocalizations.of(context)!.characterDefense,
          CharacterSortableFieldsEnum.defense, null, true),
      _createSingleColumn(AppLocalizations.of(context)!.characterIntelligence,
          CharacterSortableFieldsEnum.intelligence, null, true),
      _createSingleColumn(AppLocalizations.of(context)!.characterBlood,
          CharacterSortableFieldsEnum.blood, null, true),
      _createSingleColumn(AppLocalizations.of(context)!.characterSpeed,
          CharacterSortableFieldsEnum.speed, null, true),
      _createSingleColumn(AppLocalizations.of(context)!.groupGain,
          CharacterSortableFieldsEnum.groupGain, null, true),
      _createSingleColumn(AppLocalizations.of(context)!.fruitLimit,
          CharacterSortableFieldsEnum.fruitLimit, null, false),
    ];
  }

  DataColumn _createSingleColumn(
      String displayText,
      CharacterSortableFieldsEnum? characterSortableFieldsEnum,
      double? width,
      bool? isBattleDigit) {
    return DataColumn(
      label: InkWell(
        onTap: characterSortableFieldsEnum == null
            ? null
            : () {
                setState(() {
                  var sortOrder =
                      sortableEnumToSortOrderMap[characterSortableFieldsEnum];
                  var sortKey = characterSortableFieldsEnum;
                  if (sortOrder == null) {
                    sortOrder = SortOrder.ASC;
                  } else if (sortOrder == SortOrder.ASC) {
                    sortOrder = SortOrder.DESC;
                  } else {
                    sortOrder = null;
                  }
                  sortableEnumToSortOrderMap[characterSortableFieldsEnum] =
                      sortOrder;
                  sortKeys.removeWhere((element) => element.sortKey == sortKey);
                  if (sortOrder != null) {
                    sortKeys.insert(
                        0,
                        CharacterSortableField(
                            sortKey: sortKey, sortOrder: sortOrder));
                  }
                  _search();
                });
              },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5, 10, 0, 10),
          child: SizedBox(
            width: width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  displayText,
                  style:
                      sortableEnumToSortOrderMap[characterSortableFieldsEnum] ==
                              null
                          ? OnepieceFonts.tableHeaderStyle
                          : OnepieceFonts.selectedTableHeaderStyle,
                ),
                if (characterSortableFieldsEnum != null)
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: ImageHelper.getSvgIconWithColor(
                      sortOrderToPath[sortableEnumToSortOrderMap[
                          characterSortableFieldsEnum]]!,
                      15,
                      15,
                      sortableEnumToSortOrderMap[characterSortableFieldsEnum] ==
                              null
                          ? Colors.grey
                          : OnepieceColors.themeColor,
                    ),
                  ),
                if (isBattleDigit!)
                  ImageHelper.getIconButtonFromSvg('images/svgs/battle.svg',
                      OnepieceColors.fancyBlue, 30, 30, () => null)
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<DataRow> _createRows(BuildContext context) {
    Map<Haki, String> hakiEnumValueToDisplayValue = {
      Haki.busoshoku: AppLocalizations.of(context)!.busoshoku,
      Haki.haoshoku: AppLocalizations.of(context)!.haoshoku,
      Haki.kenbunshoku: AppLocalizations.of(context)!.kenbunshoku,
    };
    Map<BattleStyle, String> battleStyleToDisplayValue = <BattleStyle, String>{
      BattleStyle.BODY: AppLocalizations.of(context)!.body,
      BattleStyle.SCIENCE: AppLocalizations.of(context)!.science,
      BattleStyle.KATANA: AppLocalizations.of(context)!.katana,
      BattleStyle.SHOOTER: AppLocalizations.of(context)!.shoot
    };
    Map<Race, String> raceEnumToDisplayName = {
      Race.HUMAN: AppLocalizations.of(context)!.human,
      Race.FISH_MAN: AppLocalizations.of(context)!.fishman,
      Race.MERFOLK: AppLocalizations.of(context)!.merfolk,
      Race.GIANT: AppLocalizations.of(context)!.giant,
      Race.LONG_ARM: AppLocalizations.of(context)!.longArm,
      Race.LONG_LEG: AppLocalizations.of(context)!.longLeg,
      Race.SNAKE_NECK: AppLocalizations.of(context)!.snakeNeck,
      Race.THREE_EYE: AppLocalizations.of(context)!.threeEye,
      Race.LUNARIAN: AppLocalizations.of(context)!.lunarian,
      Race.MINK: AppLocalizations.of(context)!.mink,
      Race.WORLD_NOBEL: AppLocalizations.of(context)!.worldNobel,
      Race.DWARVES: AppLocalizations.of(context)!.dwarves
    };
    return currentCharacterList
        .asMap()
        .entries
        .map(
          (entry) => DataRow(
            color: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
              if (entry.key.isEven) {
                return OnepieceColors
                    .liteFancyGreen; // Use whatever color you need for even rows
              }
              return null; // Use default (transparent) color for odd rows
            }),
            onSelectChanged: (value) {
              context.goNamed('characterDetails',
                  extra: entry.value.id,
                  pathParameters: {
                    'name': I18nHelper.getDisplayNameFromI18n(entry.value.name)
                  });
            },
            cells: [
              DataCell(
                Padding(
                  padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.all(Radius.circular(2.0)),
                      border: Border.all(
                          color: OnepieceColors.fancyBlue,
                          width: 2,
                          style: BorderStyle.solid),
                    ),
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: entry.value.profileImage == null
                          ? Container()
                          : Image.memory(
                              Base64Helper.decode(entry.value.profileImage!)),
                    ),
                  ),
                ),
              ),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child:
                    Text(I18nHelper.getDisplayNameFromI18n(entry.value.name)),
              )),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Row(
                  children: entry.value.hakis
                      .map((e) => Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: OnepieceTag.getHakiTag(
                                e, hakiEnumValueToDisplayValue[e]!),
                          ))
                      .toList(),
                ),
              )),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Text(raceEnumToDisplayName[entry.value.race]!),
              )),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child:
                    Text(battleStyleToDisplayValue[entry.value.battleStyle]!),
              )),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Text("\$${entry.value.bounty.toString()}"),
              )),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Text(entry.value.attack.toString()),
              )),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Text(entry.value.defense.toString()),
              )),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Text(entry.value.intelligence.toString()),
              )),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Text(entry.value.blood.toString()),
              )),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Text(entry.value.speed.toString()),
              )),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Text(entry.value.groupGain.toString()),
              )),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Text(entry.value.maximumFruitCount.toString()),
              )),
            ],
          ),
        )
        .toList();
  }

  Widget _getPageFoot(BuildContext context) {
    return StatefulBuilder(
        builder: (BuildContext context, StateSetter footState) {
      List<Widget> widgetList = [];
      ElevatedButton prePage = ElevatedButton(
          style: OnepieceButtonStyle.getDefaultStyle(),
          onPressed: !preButtonEnabled
              ? null
              : () {
                  selectedPageNum = selectedPageNum - 1;
                  _search();
                },
          child: const Icon(Icons.arrow_back));
      ElevatedButton nextPage = ElevatedButton(
          style: OnepieceButtonStyle.getDefaultStyle(),
          onPressed: !nextButtonEnabled
              ? null
              : () {
                  selectedPageNum = selectedPageNum + 1;
                  _search();
                },
          child: const Icon(Icons.arrow_forward));
      Widget pageNumber = SizedBox(
        width: 35,
        height: 28,
        child: TextFormField(
            style: OnepieceFonts.pageInputStyle,
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.fromLTRB(0, 0, 0, 20),
              enabledBorder: UnderlineInputBorder(),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: OnepieceColors.themeColor)),
            ),
            controller: pageNumberController,
            onChanged: (value) {
              footState(() {
                if (!DataValidator.isInt(pageNumberController.text.trim())) {
                  confirmButtonEnabled = false;
                } else {
                  int currentTypedPage =
                      int.parse(pageNumberController.text.trim());
                  if (currentTypedPage < 1 ||
                      currentTypedPage > totalPageNum ||
                      currentTypedPage == selectedPageNum) {
                    confirmButtonEnabled = false;
                  } else {
                    confirmButtonEnabled = true;
                  }
                }
              });
            }),
      );
      ElevatedButton confirmPage = ElevatedButton(
          style: OnepieceButtonStyle.getDefaultStyle(),
          onPressed: !confirmButtonEnabled
              ? null
              : () {
                  selectedPageNum = int.parse(pageNumberController.text);
                  confirmButtonEnabled = false;
                  _search();
                },
          child: Text(
            AppLocalizations.of(context)!.jumpToPage,
            textAlign: TextAlign.left,
          ));
      widgetList.add(Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
        child: prePage,
      ));
      widgetList.add(pageNumber);
      var totalPageCount = ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Container(
            height: 28,
            color: OnepieceColors.menuBackgroundColor,
            alignment: AlignmentDirectional.center,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(3, 0, 3, 3),
              child: Text(
                "/$totalPageNum",
                style: OnepieceFonts.contentStyle,
              ),
            )),
      );
      widgetList.add(totalPageCount);
      widgetList.add(Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
        child: confirmPage,
      ));
      widgetList.add(Padding(
        padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
        child: nextPage,
      ));
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: widgetList,
      );
    });
  }
}
