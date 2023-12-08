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
import '../constants/button_style.dart';
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
  List<CharacterType> selectedCharacterTypes = [];
  ScrollController scrollController = ScrollController();

  int selectedPageIndex = 1;
  int pageNum = 0;
  int pageSize = 10;
  int totalSize = 0;
  bool preButtonEnabled = false;
  bool nextButtonEnabled = false;
  bool confirmButtonEnabled = false;

  bool onlyShowSystemResource = false;
  bool donNotShowSystemResource = false;

  @override
  void initState() {
    super.initState();
    _search();
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
                width: 1500,
                height: 50,
                child: _createControlPanel(context),
              ),
              SizedBox(
                width: 1500,
                child: FittedBox(
                  fit: BoxFit.fitWidth,
                  child: _createCharacterTable(context),
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              SizedBox(
                width: 1500,
                child: Center(child: _getPageFoot()),
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
    Map<CharacterType, String> enumValueToDisplayValue =
        <CharacterType, String>{
      CharacterType.body: AppLocalizations.of(context)!.body,
      CharacterType.foot: AppLocalizations.of(context)!.leg,
      CharacterType.science: AppLocalizations.of(context)!.science,
      CharacterType.fist: AppLocalizations.of(context)!.fist,
      CharacterType.katana: AppLocalizations.of(context)!.katana,
      CharacterType.shooter: AppLocalizations.of(context)!.shoot
    };
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 6, 0),
            child: SizedBox(
              width: 230,
              height: 35,
              child: TextFormField(
                controller: searchNameController,
                onChanged: (value) {
                  characterFilter.name = value;
                  _search();
                },
                decoration: InputDecoration(
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
                height: 35,
                width: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: OnepieceColors.liteFancyGreen,
                ),
              ),
              menuItemStyleData: const MenuItemStyleData(
                height: 35,
              ),
              items: CharacterType.values.map((CharacterType characterType) {
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
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(40,0, 20,0),
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
              SizedBox(
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
            ],
          ),
        ],
      ),
      SizedBox(
        height: 35,
        child: ElevatedButton(
            onPressed: () {
              context.goNamed("createCharacter");
            },
            style: OnepieceButtonStyle.getDefaultStyle(),
            child: Text(AppLocalizations.of(context)!.createCharacter)),
      )
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
      columns: _createColumns(),
      rows: _createRows(context),
      columnSpacing: 10,
    );
  }

  List<DataColumn> _createColumns() {
    return [
      DataColumn(
        label: ElevatedButton(
            style: OnepieceButtonStyle.getDefaultStyle(),
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
          CharacterSortableFieldsEnum.name, 120),
      _createSingleColumn(   AppLocalizations.of(context)!.characterTypeLabel, null, 120),
      _createSingleColumn(AppLocalizations.of(context)!.fruitLimit,
          CharacterSortableFieldsEnum.fruitLimit, null),
      _createSingleColumn(AppLocalizations.of(context)!.groupGain,
          CharacterSortableFieldsEnum.groupGain, null),
      _createSingleColumn(AppLocalizations.of(context)!.characterAttack,
          CharacterSortableFieldsEnum.attack , null),
      _createSingleColumn(AppLocalizations.of(context)!.characterDefense,
          CharacterSortableFieldsEnum.defense, null),
      _createSingleColumn(AppLocalizations.of(context)!.characterIntelligence,
          CharacterSortableFieldsEnum.intelligence, null),
      _createSingleColumn(AppLocalizations.of(context)!.characterBlood,
          CharacterSortableFieldsEnum.blood, null),
      _createSingleColumn(AppLocalizations.of(context)!.characterSpeed,
          CharacterSortableFieldsEnum.speed, null),
      _createSingleColumn(AppLocalizations.of(context)!.createdBySystem, null, 130),
    ];
  }

  DataColumn _createSingleColumn(String displayText,
      CharacterSortableFieldsEnum? characterSortableFieldsEnum, double? width) {
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
                  )
              ],
            ),
          ),
        ),
      ),
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
                  padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.all(Radius.circular(2.0)),
                      border: Border.all(
                          color: Colors.grey,
                          width: 2,
                          style: BorderStyle.solid),
                    ),
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: Image.memory(
                          Base64Helper.decode(character.profileImage!)),
                    ),
                  ),
                ),
              ),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Text(character.name.toString()),
              )),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Text(character.characterTypes.map((e) => enumValueToDisplayValue[e]).join(", ")),
              )),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Text(character.maximumFruitCount.toString()),
              )),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Text(character.groupGain.toString()),
              )),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Text(character.attack.toString()),
              )),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Text(character.defense.toString()),
              )),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Text(character.intelligence.toString()),
              )),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Text(character.blood.toString()),
              )),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Text(character.speed.toString()),
              )),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Text(booleanToDisplayName[character.roleName==UserRole.NIKA]!),
              )),
            ],
          ),
        )
        .toList();
  }

  Row _getPageFoot() {
    List<Widget> widgetList = [];
    ElevatedButton prePage = ElevatedButton(
        style: OnepieceButtonStyle.getDefaultStyle(),
        onPressed: !preButtonEnabled
            ? null
            : () {
                selectedPageIndex = selectedPageIndex - 1;
                _search();
              },
        child: const Icon(Icons.arrow_back));
    ElevatedButton nextPage = ElevatedButton(
        style: OnepieceButtonStyle.getDefaultStyle(),
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
        style: OnepieceButtonStyle.getDefaultStyle(),
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: widgetList,
    );
  }
}
