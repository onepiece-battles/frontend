import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:one_piece_battles_flutter/views/add_character_view.dart';
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
  Logger logger = Logger('_CharacterViewState');
  TextEditingController searchNameController = TextEditingController();
  TextEditingController pageNumberController = TextEditingController(text: "1");
  CharacterFilter characterFilter = CharacterFilter();
  List<Character> currentCharacterList = [];
  List<CharacterSortableField> sortKeys = [];
  Map<int, SortOrder?> columnIndexToSortOrderMap = {
    1: null,
    3: null,
    4: null,
    5: null,
    6: null,
    7: null,
    8: null,
    9: null,
  };
  Map<SortOrder?, String> sortOrderToPath = const {
    null: 'images/svgs/sort-solid.svg',
    SortOrder.ASC: 'images/svgs/sort-up-solid.svg',
    SortOrder.DESC: 'images/svgs/sort-down-solid.svg'
  };
  Map<int, CharacterSortableFieldsEnum> columnIndexToSortableFieldMap = {
    1: CharacterSortableFieldsEnum.name,
    3: CharacterSortableFieldsEnum.fruitLimit,
    4: CharacterSortableFieldsEnum.groupGain,
    5: CharacterSortableFieldsEnum.attack,
    6: CharacterSortableFieldsEnum.defense,
    7: CharacterSortableFieldsEnum.intelligence,
    8: CharacterSortableFieldsEnum.blood,
    9: CharacterSortableFieldsEnum.speed
  };
  List<String> selectedItems = [];

  int selectedPageIndex = 1;
  int pageNum = 1;
  int pageSize = 10;
  int totalSize = 0;
  bool preButtonEnabled = false;
  bool nextButtonEnabled = false;
  bool confirmButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _doSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
            padding: const EdgeInsets.all(15),
            child: Text(
              AppLocalizations.of(context)!.character,
              style: OnepieceFonts.headerStyle,
            )),
        const SizedBox(
          height: 20,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
          child: _createSearchFilterRow(context),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
          child: SizedBox(width: double.infinity, child: _createDataTable()),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
          child: _getPageFoot(),
        )
      ],
    );
  }

  DataTable _createDataTable() {
    return DataTable(
      border: const TableBorder(
          top: BorderSide(color: OnepieceColors.themeColor),
          bottom: BorderSide(color: OnepieceColors.themeColor)),
      columns: _createColumns(),
      rows: _createRows(context),
      columnSpacing: 0,
    );
  }

  List<DataColumn> _createColumns() {
    return [
      DataColumn(
        label: ElevatedButton(
            onPressed: () {
              characterFilter = CharacterFilter();
              sortKeys = [];
              columnIndexToSortOrderMap = {
                1: null,
                3: null,
                4: null,
                5: null,
                6: null,
                7: null,
                8: null,
                9: null,
              };
              _doSearch();
            },
            child: Text(AppLocalizations.of(context)!.resetSort)),
      ),
      _createSingleColumn(AppLocalizations.of(context)!.characterName, 1),
      DataColumn(
          label: Text(
        AppLocalizations.of(context)!.characterTypeLable,
        style: OnepieceFonts.tableHeaderStyle,
      )),
      _createSingleColumn(AppLocalizations.of(context)!.fruitLimit, 3),
      _createSingleColumn(AppLocalizations.of(context)!.groupGain, 4),
      _createSingleColumn(AppLocalizations.of(context)!.characterAttack, 5),
      _createSingleColumn(AppLocalizations.of(context)!.characterDefense, 6),
      _createSingleColumn(
          AppLocalizations.of(context)!.characterIntelligence, 7),
      _createSingleColumn(AppLocalizations.of(context)!.characterBlood, 8),
      _createSingleColumn(AppLocalizations.of(context)!.characterSpeed, 9),
      DataColumn(
          label: Text(
        AppLocalizations.of(context)!.characterFruits,
        style: OnepieceFonts.tableHeaderStyle,
      )),
    ];
  }

  DataColumn _createSingleColumn(String name, int index) {
    return DataColumn(
      label: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            name,
            style: OnepieceFonts.tableHeaderStyle,
          ),
          IconButton(
            splashRadius: 0.1,
            onPressed: () {
              setState(() {
                var sortOrder = columnIndexToSortOrderMap[index];
                var sortKey = columnIndexToSortableFieldMap[index]!;
                if (sortOrder == null) {
                  sortOrder = SortOrder.ASC;
                } else if (sortOrder == SortOrder.ASC) {
                  sortOrder = SortOrder.DESC;
                } else {
                  sortOrder = null;
                }
                columnIndexToSortOrderMap[index] = sortOrder;
                sortKeys.removeWhere((element) => element.sortKey == sortKey);
                if (sortOrder != null) {
                  sortKeys.insert(
                      0,
                      CharacterSortableField(
                          sortKey: sortKey, sortOrder: sortOrder));
                }
                _doSearch();
              });
            },
            icon: ImageHelper.getSvgIcon(
              sortOrderToPath[columnIndexToSortOrderMap[index]]!,
              OnepieceColors.themeColor,
              15,
              15,
            ),
          ),
        ],
      ),
    );
  }

  Row _createSearchFilterRow(BuildContext context) {
    List<String> displayCharacterTypes = [
      AppLocalizations.of(context)!.body,
      AppLocalizations.of(context)!.science,
      AppLocalizations.of(context)!.katana,
      AppLocalizations.of(context)!.shoot,
      AppLocalizations.of(context)!.fist,
      AppLocalizations.of(context)!.leg
    ];
    Map<String, CharacterType> displayValueToEnumValue =
        <String, CharacterType>{
      AppLocalizations.of(context)!.body: CharacterType.body,
      AppLocalizations.of(context)!.leg: CharacterType.foot,
      AppLocalizations.of(context)!.science: CharacterType.science,
      AppLocalizations.of(context)!.fist: CharacterType.fist,
      AppLocalizations.of(context)!.katana: CharacterType.katana,
      AppLocalizations.of(context)!.shoot: CharacterType.shooter,
    };
    return Row(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 8, 6),
        child: ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: ((context) {
                  return const AddCharacterView();
                }),
              );
            },
            child: Text(AppLocalizations.of(context)!.createCharacter)),
      ),
      Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 8, 6),
          child: SizedBox(
            width: 200,
            height: 40,
            child: TextField(
              textAlign: TextAlign.center,
              controller: searchNameController,
              onChanged: (value) {
                characterFilter.name = value;
                _doSearch();
              },
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                prefixIcon: IconButton(
                    onPressed: () {
                      characterFilter.name = searchNameController.text;
                      _doSearch();
                    },
                    icon: const Icon(Icons.search)),
                hintText: AppLocalizations.of(context)!.searchCharacterName,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchNameController.clear();
                    characterFilter.name = null;
                    _doSearch();
                  },
                ),
              ),
            ),
          )),
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 6),
        child: SizedBox(
          height: 30,
          width: 200,
          child: DropdownSearch<String>.multiSelection(
            items: displayCharacterTypes,
            selectedItems: selectedItems,
            clearButtonProps: const ClearButtonProps(isVisible: true),
            onChanged: (value) {
              selectedItems = value;
              characterFilter.characterTypes = selectedItems.map((element) {
                return displayValueToEnumValue[element]!;
              }).toList();
              _doSearch();
            },
            onSaved: (value) {
              if (value == null) {
                selectedItems = [];
              } else {
                selectedItems = value;
              }
              characterFilter.characterTypes = selectedItems.map((element) {
                return displayValueToEnumValue[element]!;
              }).toList();
              _doSearch();
            },
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                  contentPadding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                  hintText: AppLocalizations.of(context)!.characterTypeHint,
                  border: const UnderlineInputBorder(),
                  focusedBorder: const UnderlineInputBorder(),
                  enabledBorder: const UnderlineInputBorder(),
                  disabledBorder: const UnderlineInputBorder(),
                  alignLabelWithHint: true),
            ),
          ),
        ),
      ),
    ]);
  }

  List<DataRow> _createRows(BuildContext context) {
    List<DataRow> result = [];
    var dataList = currentCharacterList
        .map((character) => DataRow(cells: [
              DataCell(Padding(
                  padding: const EdgeInsets.fromLTRB(0, 3, 30, 3),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 30),
                    child: Image.memory(
                        Base64Helper.decode(character.profileImage!)),
                  ))),
              // DataCell(Text("aaa")),
              DataCell(Text(character.name.toString())),
              DataCell(Text(character.characterType.toString())),
              DataCell(Text(character.fruitLimit.toString())),
              DataCell(Text(character.groupGain.toString())),
              DataCell(Text(character.attack.toString())),
              DataCell(Text(character.defense.toString())),
              DataCell(Text(character.intelligence.toString())),
              DataCell(Text(character.blood.toString())),
              DataCell(Text(character.speed.toString())),
              DataCell(Text(
                  character.fruits.isEmpty ? "" : character.fruits.toString())),
            ]))
        .toList();
    result.addAll(dataList);
    return result;
  }

  void _doSearch() {
    ListCharacterRequest listCharacterRequest = ListCharacterRequest(
        pageSize: pageSize,
        pageIndex: selectedPageIndex,
        sortKeys: sortKeys,
        characterFilter: characterFilter);
    debugPrint(listCharacterRequest.toString());
    Future<ListCharacterResponse?> listCharacterResponse =
        getIt<CharacterDao>().listCharacter(listCharacterRequest);

    listCharacterResponse.then((value) {
      setState(() {
        currentCharacterList = value!.characters;
        totalSize = value.totalSize!;
        pageNum = (totalSize / 10).ceil();
        pageNumberController.text = selectedPageIndex.toString();
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
                _doSearch();
              },
        child: const Icon(Icons.arrow_back));
    ElevatedButton nextPage = ElevatedButton(
        onPressed: !nextButtonEnabled
            ? null
            : () {
                selectedPageIndex = selectedPageIndex + 1;
                _doSearch();
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
                _doSearch();
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
      mainAxisAlignment: MainAxisAlignment.end,
      children: widgetList,
    );
  }
}
