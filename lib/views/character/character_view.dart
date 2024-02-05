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
  List<Haki> selectedHakis = [];
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
  bool fruitOwnersOnly = false;

  @override
  void initState() {
    super.initState();
    _search();
  }

  void _search() {
    characterFilter.languageCode = I18nHelper.getLanguageCode();
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
      CharacterType.BODY: AppLocalizations.of(context)!.body,
      CharacterType.FOOT: AppLocalizations.of(context)!.leg,
      CharacterType.SCIENCE: AppLocalizations.of(context)!.science,
      CharacterType.FIST: AppLocalizations.of(context)!.fist,
      CharacterType.KATANA: AppLocalizations.of(context)!.katana,
      CharacterType.SHOOTER: AppLocalizations.of(context)!.shoot
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
                width: 200,
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
                return CharacterType.values.map(
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
        ],
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
      columns: _createColumns(),
      rows: _createRows(context),
      columnSpacing: 10,
    );
  }

  List<DataColumn> _createColumns() {
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
    Map<CharacterType, String> enumValueToDisplayValue =
        <CharacterType, String>{
      CharacterType.BODY: AppLocalizations.of(context)!.body,
      CharacterType.FOOT: AppLocalizations.of(context)!.leg,
      CharacterType.SCIENCE: AppLocalizations.of(context)!.science,
      CharacterType.FIST: AppLocalizations.of(context)!.fist,
      CharacterType.KATANA: AppLocalizations.of(context)!.katana,
      CharacterType.SHOOTER: AppLocalizations.of(context)!.shoot
    };
    Map<Haki, String> hakiEnumValueToDisplayValue = {
      Haki.busoshoku: AppLocalizations.of(context)!.busoshoku,
      Haki.haoshoku: AppLocalizations.of(context)!.haoshoku,
      Haki.kenbunshoku: AppLocalizations.of(context)!.kenbunshoku,
    };
    return currentCharacterList
        .asMap()
        .entries
        .map(
          (entry) => DataRow(
            color: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
              if (entry.key.isEven) {
                return OnepieceColors.liteFancyGreen; // Use whatever color you need for even rows
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
