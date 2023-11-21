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
import '../utils/image_helper.dart';

GetIt getIt = GetIt.instance;

class CharacterView extends StatefulWidget {
  const CharacterView({super.key});

  @override
  State<CharacterView> createState() => _CharacterViewState();
}

class _CharacterViewState extends State<CharacterView> {
  Logger logger = Logger('CharacterView');
  TextEditingController searchNameController = TextEditingController();
  TextEditingController pageNumberController = TextEditingController(text: "1");
  CharacterFilter characterFilter = CharacterFilter();
  List<Character> currentCharacterList = [];
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
  List<CharacterType> selectedCharacterTypes = [];
  ScrollController scrollController = ScrollController();

  int selectedPageIndex = 1;
  int pageNum = 0;
  int pageSize = 10;
  int totalSize = 0;
  bool preButtonEnabled = false;
  bool nextButtonEnabled = false;
  bool confirmButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _search();
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
              _createControlPanel(context),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _createDataTable(),
                  const SizedBox(
                    height: 15,
                  ),
                  ConstrainedBox(
                    constraints:
                        BoxConstraints.loose(const Size.fromWidth(1500)),
                    child: FittedBox(
                      fit: BoxFit.fitWidth,
                      child: Center(child: _getPageFoot()),
                    ),
                  )
                ],
              ),
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

  DataTable _createDataTable() {
    return DataTable(
      showCheckboxColumn: false,
      showBottomBorder: true,
      border: const TableBorder(
          top: BorderSide(color: OnepieceColors.themeColor),
          bottom: BorderSide(color: OnepieceColors.themeColor)),
      columns: _createColumns(),
      rows: _createRows(context),
      columnSpacing: 30,
    );
  }

  List<DataColumn> _createColumns() {
    return [
      DataColumn(
        label: ElevatedButton(
            onPressed: () {
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
            },
            child: Text(AppLocalizations.of(context)!.resetSort)),
      ),
      _createSingleColumn(AppLocalizations.of(context)!.characterName,
          CharacterSortableFieldsEnum.name),
      DataColumn(
          label: Text(
        AppLocalizations.of(context)!.characterTypeLabel,
        style: OnepieceFonts.tableHeaderStyle,
      )),
      _createSingleColumn(AppLocalizations.of(context)!.fruitLimit,
          CharacterSortableFieldsEnum.fruitLimit),
      _createSingleColumn(AppLocalizations.of(context)!.groupGain,
          CharacterSortableFieldsEnum.groupGain),
      _createSingleColumn(AppLocalizations.of(context)!.characterAttack,
          CharacterSortableFieldsEnum.attack),
      _createSingleColumn(AppLocalizations.of(context)!.characterDefense,
          CharacterSortableFieldsEnum.defense),
      _createSingleColumn(AppLocalizations.of(context)!.characterIntelligence,
          CharacterSortableFieldsEnum.intelligence),
      _createSingleColumn(AppLocalizations.of(context)!.characterBlood,
          CharacterSortableFieldsEnum.blood),
      _createSingleColumn(AppLocalizations.of(context)!.characterSpeed,
          CharacterSortableFieldsEnum.speed),
      DataColumn(
        label: Text(
          AppLocalizations.of(context)!.characterFruits,
          style: OnepieceFonts.tableHeaderStyle,
        ),
      ),
      _createSingleColumn(AppLocalizations.of(context)!.createdBySystem, null),
    ];
  }

  DataColumn _createSingleColumn(String displayText,
      CharacterSortableFieldsEnum? characterSortableFieldsEnum) {
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
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                displayText,
                style: OnepieceFonts.tableHeaderStyle,
              ),
              characterSortableFieldsEnum != null
                  ? Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: ImageHelper.getSvgIcon(
                        sortOrderToPath[sortableEnumToSortOrderMap[
                            characterSortableFieldsEnum]]!,
                        15,
                        15,
                      ),
                    )
                  : const SizedBox.shrink()
            ],
          ),
        ),
      ),
    );
  }

  Widget _createControlPanel(BuildContext context) {
    Map<CharacterType, String> enumValueToDisplayValue =
        <CharacterType, String>{
      CharacterType.body: AppLocalizations.of(context)!.body,
      CharacterType.foot: AppLocalizations.of(context)!.leg,
      CharacterType.science: AppLocalizations.of(context)!.science,
      CharacterType.fist: AppLocalizations.of(context)!.fist,
      CharacterType.katana: AppLocalizations.of(context)!.katana,
      CharacterType.shooter: AppLocalizations.of(context)!.shoot
    };
    return SizedBox(
      width: 1250,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 6, 6),
              child: SizedBox(
                width: 200,
                height: 45,
                child: TextFormField(
                  controller: searchNameController,
                  onChanged: (value) {
                    characterFilter.name = value;
                    _search();
                  },
                  decoration: InputDecoration(
                    prefixIcon: IconButton(
                        onPressed: () {
                          characterFilter.name = searchNameController.text;
                          _search();
                        },
                        icon: const Icon(Icons.search)),
                    labelText: AppLocalizations.of(context)!.name,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 2),
              child: DropdownButtonHideUnderline(
                child: DropdownButton2(
                  isExpanded: true,
                  value: selectedCharacterTypes.isEmpty
                      ? null
                      : selectedCharacterTypes.last,
                  hint: Text(
                    AppLocalizations.of(context)!.characterTypeLabel,
                    style: OnepieceFonts.dropDownItemStyle,
                  ),
                  onChanged: (value) {},
                  selectedItemBuilder: (context) {
                    return CharacterType.values.map(
                      (item) {
                        return Container(
                          alignment: AlignmentDirectional.center,
                          child: Text(
                            selectedCharacterTypes
                                .map((selectedType) {
                                  return enumValueToDisplayValue[selectedType];
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
                      height: 34,
                      width: 280,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: OnepieceColors.menuBackgroundColor,
                      )),
                  menuItemStyleData: const MenuItemStyleData(
                    height: 35,
                  ),
                  items:
                      CharacterType.values.map((CharacterType characterType) {
                    return DropdownMenuItem<CharacterType>(
                      value: characterType,
                      enabled: false,
                      child: StatefulBuilder(
                        builder: (context, menuSetState) {
                          final isSelected =
                              selectedCharacterTypes.contains(characterType);
                          return InkWell(
                            onTap: () {
                              isSelected
                                  ? selectedCharacterTypes.remove(characterType)
                                  : selectedCharacterTypes.add(characterType);
                              characterFilter.characterTypes =
                                  selectedCharacterTypes;

                              // //This rebuilds the StatefulWidget to update the button's text
                              setState(() {});
                              //This rebuilds the dropdownMenu Widget to update the check mark
                              menuSetState(() {});
                              _search();
                            },
                            child: Container(
                              height: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6.0),
                              child: Row(
                                children: [
                                  if (isSelected)
                                    const Icon(Icons.check_box_outlined)
                                  else
                                    const Icon(Icons.check_box_outline_blank),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      enumValueToDisplayValue[characterType]!,
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
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 6, 3),
              child: SizedBox(
                height: 34,
                child: ElevatedButton(
                    onPressed: () {
                      context.goNamed("createCharacter");
                    },
                    child: Text(AppLocalizations.of(context)!.createCharacter)),
              ),
            ),
          ],
        )
      ]),
    );
  }

  List<DataRow> _createRows(BuildContext context) {
    Map<CharacterType, String> enumValueToDisplayValue =
        <CharacterType, String>{
      CharacterType.body: AppLocalizations.of(context)!.body,
      CharacterType.foot: AppLocalizations.of(context)!.leg,
      CharacterType.science: AppLocalizations.of(context)!.science,
      CharacterType.fist: AppLocalizations.of(context)!.fist,
      CharacterType.katana: AppLocalizations.of(context)!.katana,
      CharacterType.shooter: AppLocalizations.of(context)!.shoot
    };
    Map<bool, String> booleanToDisplayName = {
      true: AppLocalizations.of(context)!.yes,
      false: AppLocalizations.of(context)!.no
    };
    return currentCharacterList
        .map(
          (character) => DataRow(
            onSelectChanged: (value) {
              context.goNamed('characterDetails',
                  extra: character.id,
                  pathParameters: {'name': character.name});
            },
            cells: [
              DataCell(
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 3, 3, 3),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.all(Radius.circular(2.0)),
                      border: Border.all(
                          color: OnepieceColors.themeColor,
                          width: 2,
                          style: BorderStyle.solid),
                    ),
                    child: Expanded(
                      child: Image.memory(
                          Base64Helper.decode(character.profileImage!)),
                    ),
                  ),
                ),
              ),
              DataCell(Text(character.name.toString())),
              DataCell(Text(enumValueToDisplayValue[character.characterType]!)),
              DataCell(Text(character.fruitLimit.toString())),
              DataCell(Text(character.groupGain.toString())),
              DataCell(Text(character.attack.toString())),
              DataCell(Text(character.defense.toString())),
              DataCell(Text(character.intelligence.toString())),
              DataCell(Text(character.blood.toString())),
              DataCell(Text(character.speed.toString())),
              DataCell(Text(
                  character.fruits.isEmpty ? "" : character.fruits.toString())),
              DataCell(Text(booleanToDisplayName[character.isSystemResource]!)),
            ],
          ),
        )
        .toList();
  }

  void _search() {
    ListCharacterRequest listCharacterRequest = ListCharacterRequest(
        pageSize: pageSize,
        pageIndex: selectedPageIndex,
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
          pageNumberController.text = selectedPageIndex.toString();
        }
        totalSize = value.totalSize!;
        pageNum = (totalSize / 10).ceil();
        if (selectedPageIndex <= 1) {
          preButtonEnabled = false;
        } else {
          preButtonEnabled = true;
        }
        if (selectedPageIndex >= pageNum) {
          nextButtonEnabled = false;
        } else {
          nextButtonEnabled = true;
        }
      });
    });
  }

  Row _getPageFoot() {
    List<Widget> widgetList = [];
    ElevatedButton prePage = ElevatedButton(
        onPressed: !preButtonEnabled
            ? null
            : () {
                selectedPageIndex = selectedPageIndex - 1;
                _search();
              },
        child: const Icon(Icons.arrow_back));
    ElevatedButton nextPage = ElevatedButton(
        onPressed: !nextButtonEnabled
            ? null
            : () {
                selectedPageIndex = selectedPageIndex + 1;
                _search();
              },
        child: const Icon(Icons.arrow_forward));
    Widget pageNumber = SizedBox(
      width: 35,
      height: 28,
      child: TextFormField(
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.fromLTRB(0, 17, 0, 17),
            enabledBorder: UnderlineInputBorder(),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: OnepieceColors.themeColor)),
          ),
          controller: pageNumberController,
          onChanged: (value) {
            setState(() {
              if (!DataValidator.isInt(pageNumberController.text.trim())) {
                confirmButtonEnabled = false;
              } else {
                int currentTypedPage =
                    int.parse(pageNumberController.text.trim());
                if (currentTypedPage < 1 ||
                    currentTypedPage > pageNum ||
                    currentTypedPage == selectedPageIndex) {
                  confirmButtonEnabled = false;
                } else {
                  confirmButtonEnabled = true;
                }
              }
            });
          }),
    );
    ElevatedButton confirmPage = ElevatedButton(
        onPressed: !confirmButtonEnabled
            ? null
            : () {
                selectedPageIndex = int.parse(pageNumberController.text);
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
              "$pageNum",
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
      children: widgetList,
    );
  }
}
