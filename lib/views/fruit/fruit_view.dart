import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_tag.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:openapi/api.dart';
import '../../constants/button_style.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../repository/fruit_dao.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../utils/data_validator.dart';
import '../../utils/image_helper.dart';

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
    FruitSortableFieldsEnum.attackStrengthen: null,
    FruitSortableFieldsEnum.defenseStrengthen: null,
    FruitSortableFieldsEnum.bloodStrengthen: null,
    FruitSortableFieldsEnum.groupGainStrengthen: null,
    FruitSortableFieldsEnum.intelligenceStrengthen: null,
    FruitSortableFieldsEnum.magicConsume: null,
    FruitSortableFieldsEnum.speedStrengthen: null,
    FruitSortableFieldsEnum.name: null,
  };

  // sorting icon map
  Map<SortOrder?, String> sortOrderToPath = const {
    null: 'images/svgs/sort-solid.svg',
    SortOrder.ASC: 'images/svgs/sort-up-solid.svg',
    SortOrder.DESC: 'images/svgs/sort-down-solid.svg'
  };
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
    _search();
  }

  void _search() {
    fruitFilter.languageCode = I18nHelper.getLanguageCode();
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
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _getHeaderText(context),
              SizedBox(
                width: 1500,
                height: 50,
                child: _getControlRow(context),
              ),
              SizedBox(
                width: 1500,
                child: FittedBox(
                  fit: BoxFit.fitWidth,
                  child: _getFruitsTable(context),
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              if (totalPageNum > 1)
                SizedBox(
                  width: 1500,
                  child: Center(child: _getPageFoot(context)),
                )
            ],
          ),
        ),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                height: 35,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: ElevatedButton(
                    style: OnepieceButtonStyle.getDefaultStyle(),
                    onPressed: () {
                      context.goNamed("createFruit");
                    },
                    child: Text(AppLocalizations.of(context)!.createDevilFruit),
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
                          borderSide:
                              BorderSide(color: OnepieceColors.fancyGreen)),
                      prefixIcon: IconButton(
                          onPressed: () {
                            fruitFilter.name = searchNameController.text;
                            _search();
                          },
                          icon: const Icon(Icons.search)),
                      labelText: AppLocalizations.of(context)!.name,
                    ),
                  ),
                ),
              ),
              _getFruitTypeFilter(context),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 20, 0),
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
                              fruitFilter.onlySystem = true;
                            } else {
                              fruitFilter.onlySystem = null;
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
                            fruitFilter.onlySystem = false;
                          } else {
                            fruitFilter.onlySystem = null;
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
              )
            ],
          ),
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
              color: OnepieceColors.menuBackgroundColor,
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
                  onTap: () {
                    isSelected
                        ? selectedFruitTypes.remove(fruitType)
                        : selectedFruitTypes.add(fruitType);
                    fruitFilter.types = selectedFruitTypes;
                    // //This rebuilds the StatefulWidget to update the button's text
                    setState(() {});
                    //This rebuilds the dropdownMenu Widget to update the check mark
                    menuSetState(() {});
                    _search();
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
                FruitSortableFieldsEnum.attackStrengthen: null,
                FruitSortableFieldsEnum.defenseStrengthen: null,
                FruitSortableFieldsEnum.bloodStrengthen: null,
                FruitSortableFieldsEnum.groupGainStrengthen: null,
                FruitSortableFieldsEnum.intelligenceStrengthen: null,
                FruitSortableFieldsEnum.magicConsume: null,
                FruitSortableFieldsEnum.speedStrengthen: null,
                FruitSortableFieldsEnum.name: null,
              };
              _search();
            },
          ),
        ),
      ),
      _createSingleColumn(AppLocalizations.of(context)!.name, null, 80),
      _createSingleColumn(AppLocalizations.of(context)!.fruitType,
          FruitSortableFieldsEnum.fruitType, 150),
      _createSingleColumn(AppLocalizations.of(context)!.attackStrengthen,
          FruitSortableFieldsEnum.attackStrengthen, 150),
      _createSingleColumn(AppLocalizations.of(context)!.defenseStrengthen,
          FruitSortableFieldsEnum.defenseStrengthen, 150),
      _createSingleColumn(AppLocalizations.of(context)!.bloodStrengthen,
          FruitSortableFieldsEnum.bloodStrengthen, 150),
      _createSingleColumn(AppLocalizations.of(context)!.intelligenceStrengthen,
          FruitSortableFieldsEnum.intelligenceStrengthen, 150),
      _createSingleColumn(AppLocalizations.of(context)!.groupStrengthen,
          FruitSortableFieldsEnum.groupGainStrengthen, 150),
      _createSingleColumn(AppLocalizations.of(context)!.speedStrengthen,
          FruitSortableFieldsEnum.speedStrengthen, 150),
    ];
  }

  DataColumn _createSingleColumn(String displayText,
      FruitSortableFieldsEnum? sortableFieldsEnum, double? width) {
    return DataColumn(
      label: InkWell(
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
                  style: sortableEnumToSortOrderMap[sortableFieldsEnum] == null
                      ? OnepieceFonts.tableHeaderStyle
                      : OnepieceFonts.selectedTableHeaderStyle,
                ),
                if (sortableFieldsEnum != null)
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: ImageHelper.getSvgIconWithColor(
                      sortOrderToPath[
                          sortableEnumToSortOrderMap[sortableFieldsEnum]]!,
                      15,
                      15,
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
              _getDataCell(entry.value.attackStrengthen.toString()),
              _getDataCell(entry.value.defenseStrengthen.toString()),
              _getDataCell(entry.value.bloodStrengthen.toString()),
              _getDataCell(entry.value.intelligenceStrengthen.toString()),
              _getDataCell(entry.value.groupGainStrengthen.toString()),
              _getDataCell(entry.value.speedStrengthen.toString()),
            ],
          ),
        )
        .toList();
    result.addAll(dataList);
    return result;
  }

  DataCell _getDataCell(String value) {
    return DataCell(Padding(
      padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
      child: Text(value),
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
