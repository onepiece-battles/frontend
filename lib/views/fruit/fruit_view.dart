import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_tag.dart';
import 'package:one_piece_battles_flutter/repository/support_dao.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:openapi/api.dart';
import 'package:toggle_switch/toggle_switch.dart';
import '../../components/image_lazy_loader.dart';
import '../../constants/button_style.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../repository/fruit_dao.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../utils/data_validator.dart';
import '../../utils/image_helper.dart';
import '../../utils/permission_check.dart';

GetIt getIt = GetIt.instance;

class FruitView extends StatefulWidget {
  const FruitView({super.key});

  @override
  State<FruitView> createState() => _FruitViewState();
}

class _FruitViewState extends State<FruitView> {
  List<FruitListView> currentFruitList = [];
  FruitFilter fruitFilter = FruitFilter();
  List<FruitType> selectedFruitTypes = [];
  List<FruitSortableField> sortKeys = [];

  TextEditingController pageNumberController = TextEditingController(text: "0");
  TextEditingController searchNameController = TextEditingController();

  // first all columns will be sorted by creation id desc.
  Map<FruitSortableFieldsEnum, SortOrder?> sortableEnumToSortOrderMap = {
    FruitSortableFieldsEnum.fruitType: null,
    FruitSortableFieldsEnum.magicConsume: null,
    FruitSortableFieldsEnum.name: null,
  };

  // sorting icon map
  Map<SortOrder?, String> sortOrderToPath = const {
    null: 'images/svgs/sort-solid.svg',
    SortOrder.ASC: 'images/svgs/sort-up-solid.svg',
    SortOrder.DESC: 'images/svgs/sort-down-solid.svg'
  };
  ScrollController mainController = ScrollController();
  ScrollController controlBarController = ScrollController();
  ScrollController tableController = ScrollController();
  int initialLabelIndex = 0;
  int selectedPageNum = 1;
  int totalPageNum = 0;
  int itemCountPerPage = 10;
  int totalItemCount = 0;
  bool preButtonEnabled = false;
  bool nextButtonEnabled = false;
  bool confirmButtonEnabled = false;

  bool onlyShowSystemResource = false;
  bool donNotShowSystemResource = false;

  @override
  void initState() {
    super.initState();
    _search(false);
  }

  void _search(bool filterChange) {
    fruitFilter.languageCode = I18nHelper.getLanguageCode();
    if (filterChange) {
      selectedPageNum = 1;
    }
    ListFruitRequest request = ListFruitRequest(
        pageSize: itemCountPerPage,
        pageIndex: selectedPageNum,
        sortKeys: sortKeys,
        fruitFilter: fruitFilter);
    Future<ListFruitResponse?> response = getIt<FruitDao>().list(request);
    response.then(
      (value) => {
        setState(
          () {
            currentFruitList = value!.fruits;
            if (currentFruitList.isEmpty) {
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
          },
        )
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        children: [
          Expanded(
              child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            controller: mainController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _getHeaderText(context),
                SizedBox(
                    width: 1400,
                    height: 90,
                    child: Scrollbar(
                      controller: controlBarController,
                      trackVisibility: true,
                      thickness: 5,
                      child: SingleChildScrollView(
                        controller: controlBarController,
                        scrollDirection: Axis.horizontal,
                        child: _getControlRow(context),
                      ),
                    )),
                Scrollbar(
                  controller: tableController,
                  trackVisibility: true,
                  thickness: 5,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _getFruitsTable(context),
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
              ],
            ),
          )),
          const SizedBox(
            height: 15,
          ),
          if (totalPageNum > 1)
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Center(child: _getPageFoot(context)),
              ],
            )
        ],
      ),
    );
  }

  Widget _getHeaderText(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
      child: Text(
        AppLocalizations.of(context)!.devilFruit,
        style: OnepieceFonts.headerStyle,
      ),
    );
  }

  Widget _getControlRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (PermissionCheck.checkPermission(
                  getIt<User>().loginRoleResourcesPermissionMap,
                  ResourceType.FRUIT,
                  Permission.CREATE))
                SizedBox(
                  height: 35,
                  width: 120,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: ElevatedButton(
                      style: OnepieceButtonStyle.getDefaultStyle(),
                      onPressed: () {
                        context.goNamed("createFruit");
                      },
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
                      fruitFilter.name = value;
                      _search(true);
                    },
                    decoration: InputDecoration(
                      labelStyle: OnepieceFonts.dropDownItemStyle,
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      disabledBorder: const OutlineInputBorder(
                          borderSide:
                              BorderSide(color: OnepieceColors.menuHoverColor)),
                      enabledBorder: const OutlineInputBorder(
                          borderSide:
                              BorderSide(color: OnepieceColors.menuHoverColor)),
                      focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                              color: OnepieceColors.fancyGreen, width: 1.5)),
                      prefixIcon: IconButton(
                          onPressed: () {
                            fruitFilter.name = searchNameController.text;
                            _search(true);
                          },
                          icon: const Icon(Icons.search)),
                      labelText: AppLocalizations.of(context)!.name,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                height: 36,
                child: ToggleSwitch(
                  customWidths: const [150, 150, 150, 180],
                  cornerRadius: 4,
                  minWidth: 150.0,
                  minHeight: 35.0,
                  fontSize: 14.0,
                  dividerColor: Colors.white,
                  initialLabelIndex: initialLabelIndex,
                  activeBgColor: const [OnepieceColors.fancyBlue],
                  activeFgColor: Colors.white,
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
                    // show all resources
                    if (index == 0) {
                      fruitFilter.systemResource = null;
                      fruitFilter.userId = null;
                    }
                    // show my resource
                    if (index == 1) {
                      fruitFilter.systemResource = null;
                      fruitFilter.userId = getIt<User>().id;
                    }
                    // only show system resource
                    if (index == 2) {
                      fruitFilter.systemResource = true;
                      fruitFilter.userId = null;
                    }
                    // do not show system resource
                    if (index == 3) {
                      fruitFilter.systemResource = false;
                      fruitFilter.userId = null;
                    }
                    _search(true);
                  },
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              _getFruitTypeFilter(context)
            ],
          )
        ],
      ),
    );
  }

  Widget _getFruitTypeFilter(BuildContext context) {
    Map<FruitType, String> fruitTypeToDisplayValue = {
      FruitType.logia: AppLocalizations.of(context)!.logiaFruit,
      FruitType.zoan: AppLocalizations.of(context)!.zoanFruit,
      FruitType.ancientZoan: AppLocalizations.of(context)!.ancientZoanFruit,
      FruitType.mythicalZoan: AppLocalizations.of(context)!.mythicalZoanFruit,
      FruitType.artificialZoan:
          AppLocalizations.of(context)!.artificialZoanFruit,
      FruitType.paramecia: AppLocalizations.of(context)!.parameciaFruit,
    };
    return DropdownButtonHideUnderline(
      child: DropdownButton2(
        isExpanded: true,
        value: selectedFruitTypes.isEmpty ? null : selectedFruitTypes.last,
        hint: Text(
          AppLocalizations.of(context)!.battleTypeHint,
          style: OnepieceFonts.dropDownItemStyle,
        ),
        onChanged: (value) {},
        selectedItemBuilder: (context) {
          return FruitType.values.map(
            (item) {
              return Container(
                alignment: AlignmentDirectional.center,
                child: Text(
                  selectedFruitTypes
                      .map((selectedType) {
                        return fruitTypeToDisplayValue[selectedType];
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
            )),
        menuItemStyleData: const MenuItemStyleData(
          height: 35,
        ),
        items: FruitType.values.map((FruitType fruitType) {
          return DropdownMenuItem<FruitType>(
            value: fruitType,
            enabled: false,
            child: StatefulBuilder(
              builder: (context, menuSetState) {
                final isSelected = selectedFruitTypes.contains(fruitType);
                return InkWell(
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  onTap: () {
                    isSelected
                        ? selectedFruitTypes.remove(fruitType)
                        : selectedFruitTypes.add(fruitType);
                    fruitFilter.types = selectedFruitTypes;
                    // //This rebuilds the StatefulWidget to update the button's text
                    setState(() {});
                    //This rebuilds the dropdownMenu Widget to update the check mark
                    menuSetState(() {});
                    _search(true);
                  },
                  child: Container(
                    height: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: Row(
                      children: [
                        if (isSelected)
                          const Icon(Icons.check_box_outlined)
                        else
                          const Icon(Icons.check_box_outline_blank),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fruitTypeToDisplayValue[fruitType]!,
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
    );
  }

  Widget _getFruitsTable(BuildContext context) {
    return DataTable(
      headingRowHeight: 50,
      showCheckboxColumn: false,
      showBottomBorder: true,
      border: const TableBorder(
          top: BorderSide(color: OnepieceColors.themeColor),
          bottom: BorderSide(color: OnepieceColors.themeColor)),
      columns: _createColumns(context),
      rows: _createRows(context),
      columnSpacing: 20,
    );
  }

  List<DataColumn> _createColumns(BuildContext context) {
    return [
      DataColumn(
        label: Tooltip(
          preferBelow: true,
          message: AppLocalizations.of(context)!.resetSort,
          child: ImageHelper.getIconButtonFromSvg(
            'images/svgs/reset.svg',
            OnepieceColors.fancyBlue,
            25,
            25,
            () {
              // filter will not be cleared
              sortKeys = [];
              sortableEnumToSortOrderMap = sortableEnumToSortOrderMap = {
                FruitSortableFieldsEnum.fruitType: null,
                FruitSortableFieldsEnum.magicConsume: null,
                FruitSortableFieldsEnum.name: null,
              };
              _search(false);
            },
          ),
        ),
      ),
      _createSingleColumn(AppLocalizations.of(context)!.name, null, 80),
      _createSingleColumn(AppLocalizations.of(context)!.fruitType,
          FruitSortableFieldsEnum.fruitType, 150),
      _createSingleColumn(AppLocalizations.of(context)!.owner, null, 100),
      _createSingleColumn(
          AppLocalizations.of(context)!.attackStrengthen, null, 150),
      _createSingleColumn(
          AppLocalizations.of(context)!.defenseStrengthen, null, 150),
      _createSingleColumn(
          AppLocalizations.of(context)!.bloodStrengthen, null, 150),
      _createSingleColumn(
          AppLocalizations.of(context)!.intelligenceStrengthen, null, 150),
      _createSingleColumn(
          AppLocalizations.of(context)!.groupStrengthen, null, 150),
      _createSingleColumn(
          AppLocalizations.of(context)!.speedStrengthen, null, 150),
    ];
  }

  DataColumn _createSingleColumn(String displayText,
      FruitSortableFieldsEnum? sortableFieldsEnum, double? width) {
    return DataColumn(
      label: InkWell(
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        onTap: sortableFieldsEnum == null
            ? null
            : () {
                setState(() {
                  var sortOrder =
                      sortableEnumToSortOrderMap[sortableFieldsEnum];
                  var sortKey = sortableFieldsEnum;
                  if (sortOrder == null) {
                    sortOrder = SortOrder.ASC;
                  } else if (sortOrder == SortOrder.ASC) {
                    sortOrder = SortOrder.DESC;
                  } else {
                    sortOrder = null;
                  }
                  sortableEnumToSortOrderMap[sortableFieldsEnum] = sortOrder;
                  sortKeys.removeWhere((element) => element.sortKey == sortKey);
                  if (sortOrder != null) {
                    sortKeys.insert(
                        0,
                        FruitSortableField(
                            sortKey: sortKey, sortOrder: sortOrder));
                  }
                  _search(false);
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
                  style: sortableEnumToSortOrderMap[sortableFieldsEnum] == null
                      ? OnepieceFonts.tableHeaderStyle
                      : OnepieceFonts.selectedTableHeaderStyle,
                ),
                const SizedBox(
                  width: 10,
                ),
                if (sortableFieldsEnum != null)
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: ImageHelper.getSvgIconWithColor(
                      sortOrderToPath[
                          sortableEnumToSortOrderMap[sortableFieldsEnum]]!,
                      12,
                      12,
                      sortableEnumToSortOrderMap[sortableFieldsEnum] == null
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
    Map<FruitType, String> fruitTypeToDisplayValue = {
      FruitType.logia: AppLocalizations.of(context)!.logiaFruit,
      FruitType.zoan: AppLocalizations.of(context)!.zoanFruit,
      FruitType.ancientZoan: AppLocalizations.of(context)!.ancientZoanFruit,
      FruitType.mythicalZoan: AppLocalizations.of(context)!.mythicalZoanFruit,
      FruitType.artificialZoan:
          AppLocalizations.of(context)!.artificialZoanFruit,
      FruitType.paramecia: AppLocalizations.of(context)!.parameciaFruit,
    };
    List<DataRow> result = [];
    var dataList = currentFruitList
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
              context.goNamed('fruitDetails',
                  extra: entry.value.id,
                  pathParameters: {
                    'name': I18nHelper.getDisplayNameFromI18n(entry.value.name!)
                  });
            },
            cells: [
              _getDataCell("${entry.key + 1}"),
              _getDataCell(I18nHelper.getDisplayNameFromI18n(entry.value.name)),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: OnepieceTag.getFruitTag(entry.value.fruitType!,
                    fruitTypeToDisplayValue[entry.value.fruitType]!),
              )),
              DataCell(_createCharacterList(entry.value.characters)),
              _getWidgetDataCell(
                  entry.value.attackSlope!,
                  entry.value.attackIntercept!,
                  ImageHelper.getTextFormFieldIcon(
                      'images/character_digits_icon/attack.svg', true, 25)),
              _getWidgetDataCell(
                  entry.value.defenseSlope!,
                  entry.value.defenseIntercept!,
                  ImageHelper.getTextFormFieldIcon(
                      'images/character_digits_icon/defense.svg', true, 25)),
              _getWidgetDataCell(
                  entry.value.bloodSlope!,
                  entry.value.bloodIntercept!,
                  ImageHelper.getTextFormFieldIcon(
                      'images/character_digits_icon/blood.svg', true, 25)),
              _getWidgetDataCell(
                  entry.value.intelligenceSlope!,
                  entry.value.intelligenceIntercept!,
                  ImageHelper.getTextFormFieldIcon(
                      'images/character_digits_icon/intelligence.svg',
                      true,
                      25)),
              _getWidgetDataCell(
                  entry.value.groupGainSlope!,
                  entry.value.groupGainIntercept!,
                  ImageHelper.getTextFormFieldIcon(
                      'images/character_digits_icon/group_gain.svg', true, 25)),
              _getWidgetDataCell(
                  entry.value.speedSlope!,
                  entry.value.speedIntercept!,
                  ImageHelper.getTextFormFieldIcon(
                      'images/character_digits_icon/speed.svg', true, 25)),
            ],
          ),
        )
        .toList();
    result.addAll(dataList);
    return result;
  }

  Widget _createCharacterList(List<CharacterInFruitView> characters) {
    if (characters.isEmpty) {
      return const Text("");
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: characters
            .map((character) => InkWell(
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  onTap: () {
                    context.goNamed('characterDetails',
                        extra: character.id,
                        pathParameters: {
                          'name':
                              I18nHelper.getDisplayNameFromI18n(character.name!)
                        });
                  },
                  child: Tooltip(
                    message: I18nHelper.getDisplayNameFromI18n(character.name),
                    preferBelow: false,
                    showDuration: const Duration(seconds: 1),
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                        child: ImageLazyLoader(
                            key: UniqueKey(),
                            uriProvider: () => character.imageUri!,
                            width: 40,
                            borderWidth: 1.5,
                            borderRadios: 40)),
                  ),
                ))
            .toList(),
      ),
    );
  }

  DataCell _getDataCell(String value) {
    return DataCell(Padding(
      padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
      child: Text(value),
    ));
  }

  DataCell _getWidgetDataCell(
    double slope,
    int intercept,
    Widget icon,
  ) {
    return DataCell(SizedBox(
      width: 120,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(slope.toString()),
            const Icon(
              Icons.close,
              color: OnepieceColors.fancyGreen,
              size: 17,
            ),
            icon,
            if (intercept >= 0)
              const Icon(
                Icons.add,
                color: OnepieceColors.fancyGreen,
                size: 17,
              ),
            if (intercept < 0)
              const Icon(
                Icons.remove,
                color: OnepieceColors.fancyGreen,
                size: 17,
              ),
            Text(intercept.abs().toString()),
          ],
        ),
      ),
    ));
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
                  _search(false);
                },
          child: const Icon(Icons.arrow_back));
      ElevatedButton nextPage = ElevatedButton(
          style: OnepieceButtonStyle.getDefaultStyle(),
          onPressed: !nextButtonEnabled
              ? null
              : () {
                  selectedPageNum = selectedPageNum + 1;
                  _search(false);
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
                  _search(false);
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
