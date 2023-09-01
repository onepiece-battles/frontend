import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:one_piece_battles_flutter/components/add_character_view.dart';
import 'package:one_piece_battles_flutter/constants/font_constants.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:one_piece_battles_flutter/utils/base64_helper.dart';
import 'package:one_piece_battles_flutter/utils/data_validator.dart';
import 'package:openapi/api.dart';

GetIt getIt = GetIt.instance;

class CharacterView extends StatefulWidget {
  const CharacterView({super.key});

  @override
  State<CharacterView> createState() => _CharacterViewState();
}

class _CharacterViewState extends State<CharacterView> {
  Logger logger = Logger('_CharacterViewState');
  List<Character> currentCharacterList = [];
  int selectedPageIndex = 1;
  int pageSize = 10;
  List<CharacterSortableField> sortKeys = [];
  CharacterFilter characterFilter = CharacterFilter();
  TextEditingController searchNameController = TextEditingController();
  TextEditingController pageNumberController = TextEditingController();
  int totalSize = 0;
  bool preButtonEnabled = false;
  bool nextButtonEnabled = false;
  bool confirmButtonEnabled = false;
  int pageNum = 1;

  @override
  void initState() {
    super.initState();
    _doSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
            padding: const EdgeInsets.all(15),
            child: Text(
              AppLocalizations.of(context)!.character,
              style: FontConstant.headerStyle,
            )),
        const SizedBox(
          height: 20,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
          child: Container(width: double.infinity, child: _createDataTable()),
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
          label: IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: ((context) {
                    return const AddCharacterView();
                  }),
                );
              },
              icon: const Icon(Icons.add))),
      DataColumn(
          label: Text(
        AppLocalizations.of(context)!.characterName,
        style: FontConstant.tableHeaderStyle,
      )),
      DataColumn(
          label: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
        child: Text(
          AppLocalizations.of(context)!.characterTypeLable,
          style: FontConstant.tableHeaderStyle,
        ),
      )),
      DataColumn(
          label: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
        child: Text(
          AppLocalizations.of(context)!.fruitLimit,
          style: FontConstant.tableHeaderStyle,
        ),
      )),
      DataColumn(
          label: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
        child: Text(
          AppLocalizations.of(context)!.groupGain,
          style: FontConstant.tableHeaderStyle,
        ),
      )),
      DataColumn(
          label: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
        child: Text(
          AppLocalizations.of(context)!.characterAttack,
          style: FontConstant.tableHeaderStyle,
        ),
      )),
      DataColumn(
          label: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
        child: Text(
          AppLocalizations.of(context)!.characterDefense,
          style: FontConstant.tableHeaderStyle,
        ),
      )),
      DataColumn(
          label: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
        child: Text(
          AppLocalizations.of(context)!.characterIntelligence,
          style: FontConstant.tableHeaderStyle,
        ),
      )),
      DataColumn(
          label: Text(
        AppLocalizations.of(context)!.characterBlood,
        style: FontConstant.tableHeaderStyle,
      )),
      DataColumn(
        label: Text(
          AppLocalizations.of(context)!.characterSpeed,
          style: FontConstant.tableHeaderStyle,
        ),
      ),
      DataColumn(
          label: Text(
        AppLocalizations.of(context)!.characterFruits,
        style: FontConstant.tableHeaderStyle,
      )),
    ];
  }

  DataRow _createSearchFilterRow(BuildContext context) {
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
    List<String> selectedItems = [];
    return DataRow(cells: [
      DataCell(Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
        child: ElevatedButton(
            onPressed: () {},
            child: Text(AppLocalizations.of(context)!.clearAll)),
      )),
      DataCell(Padding(
          padding: const EdgeInsets.fromLTRB(0, 6, 20, 6),
          child: TextField(
            textAlign: TextAlign.center,
            controller: searchNameController,
            decoration: InputDecoration(
              prefixIcon: IconButton(
                  onPressed: () {
                    characterFilter.name = searchNameController.text;
                    _doSearch();
                  },
                  icon: const Icon(Icons.search)),
              hintText: AppLocalizations.of(context)!.search,
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  searchNameController.clear();
                  characterFilter.name = null;
                  _doSearch();
                },
              ),
            ),
          ))),
      DataCell(Padding(
        padding: const EdgeInsets.fromLTRB(0, 6, 20, 6),
        child: DropdownSearch<String>.multiSelection(
          items: displayCharacterTypes,
          selectedItems: selectedItems,
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
                hintText: AppLocalizations.of(context)!.characterTypeHint,
                alignLabelWithHint: true),
          ),
        ),
      )),
      DataCell(Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
        child: ElevatedButton(
          child: const Icon(Icons.arrow_upward),
          onPressed: () {},
        ),
      )),
      DataCell(Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
        child: ElevatedButton(
          child: const Icon(Icons.arrow_upward),
          onPressed: () {},
        ),
      )),
      DataCell(Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
        child: ElevatedButton(
          child: const Icon(Icons.arrow_upward),
          onPressed: () {},
        ),
      )),
      DataCell(Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
        child: ElevatedButton(
          child: const Icon(Icons.arrow_upward),
          onPressed: () {},
        ),
      )),
      DataCell(Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
        child: ElevatedButton(
          child: const Icon(Icons.arrow_upward),
          onPressed: () {},
        ),
      )),
      DataCell(Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
        child: ElevatedButton(
          child: const Icon(Icons.arrow_upward),
          onPressed: () {},
        ),
      )),
      DataCell(Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
        child: ElevatedButton(
          child: const Icon(Icons.arrow_upward),
          onPressed: () {},
        ),
      )),
      DataCell(Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
        child: ElevatedButton(
          child: const Icon(Icons.arrow_upward),
          onPressed: () {},
        ),
      ))
    ]);
  }

  List<DataRow> _createRows(BuildContext context) {
    var searchRow = _createSearchFilterRow(context);
    List<DataRow> result = [];
    result.add(searchRow);
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
        if (selectedPageIndex <= 1) {
          preButtonEnabled = false;
        } else {
          preButtonEnabled = true;
        }
        if (selectedPageIndex >= pageNum) {
          debugPrint("selected index $selectedPageIndex");
          debugPrint("page num $pageNum");
          nextButtonEnabled = false;
        } else {
          debugPrint("selected index $selectedPageIndex");
          debugPrint("page num $pageNum");
          nextButtonEnabled = true;
        }
      });
    });
  }

  ConstrainedBox _getPageFoot() {
    List<Widget> widgetList = [];
    ElevatedButton prePage = ElevatedButton(
        onPressed: !preButtonEnabled
            ? null
            : () {
                selectedPageIndex = selectedPageIndex - 1;
                _doSearch();
              },
        child: const Text("<<"));
    ElevatedButton nextPage = ElevatedButton(
        onPressed: !nextButtonEnabled
            ? null
            : () {
                selectedPageIndex = selectedPageIndex + 1;
                _doSearch();
              },
        child: const Text(">>"));
    Widget pageNumber = SizedBox(
      width: 60,
      height: 30,
      child: TextField(
        // textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        controller: pageNumberController,
        onChanged: (value) {
          setState(() {
            if (!DataValidator.isInt(pageNumberController.text.trim())) {
              confirmButtonEnabled = false;
            } else {
              int currentTypedPage = int.parse(pageNumberController.text.trim());
              if (currentTypedPage < 1 ||
                  currentTypedPage > pageNum ||
                  currentTypedPage == selectedPageIndex) {
                confirmButtonEnabled = false;
              } else {
                confirmButtonEnabled = true;
              }
            }
          });
        },
        decoration: InputDecoration(
          hintText: "$selectedPageIndex/$pageNum",
        ),
      ),
    );
    ElevatedButton confirmPage = ElevatedButton(
        onPressed: !confirmButtonEnabled
            ? null
            : () {
                selectedPageIndex = int.parse(pageNumberController.text);
                _doSearch();
              },
        child: const Text("go"));
    widgetList.add(prePage);
    widgetList.add(pageNumber);
    widgetList.add(confirmPage);
    widgetList.add(nextPage);
    return ConstrainedBox(constraints: const BoxConstraints(maxHeight: double.infinity), child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: widgetList,
    ),);
  }
}
