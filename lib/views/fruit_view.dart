import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:openapi/api.dart';
import '../constants/onepiece_colors.dart';
import '../constants/onepiece_fonts.dart';
import '../repository/fruit_dao.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/data_validator.dart';
import '../utils/image_helper.dart';

GetIt getIt = GetIt.instance;

class FruitView extends StatefulWidget {
  const FruitView({super.key});

  @override
  State<FruitView> createState() => _FruitViewState();
}

class _FruitViewState extends State<FruitView> {
  List<Fruit> currentFruitList = [];
  FruitFilter fruitFilter = FruitFilter();
  List<FruitType> selectedFruitTypes = [];
  List<FruitSortableField> sortKeys = [];

  TextEditingController pageNumberController = TextEditingController(text: "1");
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

  void _search() {
    ListFruitRequest request = ListFruitRequest(
        pageSize: pageSize,
        pageIndex: selectedPageIndex,
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
              _getControlRow(context),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _getFruitsTable(context),
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
    return SizedBox(
      width: 1228,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 6,8),
                child: SizedBox(
                  width: 200,
                  height: 45,
                  child: TextFormField(
                    controller: searchNameController,
                    onChanged: (value) {
                      fruitFilter.name = value;
                      _search();
                    },
                    decoration: InputDecoration(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 6, 0),
            child: SizedBox(
              height: 33,
              child: ElevatedButton(
                  onPressed: () {
                    context.goNamed("createFruit");
                  },
                  child: Text(AppLocalizations.of(context)!.createDevilFruit)),
            ),
          ),
          // battle type filter
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 6, 0),
      child: DropdownButtonHideUnderline(
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
              height: 34,
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
      ),
    );
  }

  Widget _getFruitsTable(BuildContext context) {
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
          child: Text(AppLocalizations.of(context)!.resetSort),
        ),
      ),
      _createSingleColumn(
          AppLocalizations.of(context)!.name, FruitSortableFieldsEnum.name),
      _createSingleColumn(AppLocalizations.of(context)!.attackStrengthen,
          FruitSortableFieldsEnum.attackStrengthen),
      _createSingleColumn(AppLocalizations.of(context)!.defenseStrengthen,
          FruitSortableFieldsEnum.defenseStrengthen),
      _createSingleColumn(AppLocalizations.of(context)!.bloodStrengthen,
          FruitSortableFieldsEnum.bloodStrengthen),
      _createSingleColumn(AppLocalizations.of(context)!.intelligenceStrengthen,
          FruitSortableFieldsEnum.intelligenceStrengthen),
      _createSingleColumn(AppLocalizations.of(context)!.groupStrengthen,
          FruitSortableFieldsEnum.groupGainStrengthen),
      _createSingleColumn(AppLocalizations.of(context)!.speedStrengthen,
          FruitSortableFieldsEnum.speedStrengthen),
      _createSingleColumn(AppLocalizations.of(context)!.fruitType,
          FruitSortableFieldsEnum.fruitType),
      _createSingleColumn(AppLocalizations.of(context)!.createdBySystem, null),
    ];
  }

  DataColumn _createSingleColumn(
      String displayText, FruitSortableFieldsEnum? sortableFieldsEnum) {
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
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                displayText,
                style: OnepieceFonts.tableHeaderStyle,
              ),
              sortableFieldsEnum != null
                  ? Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: ImageHelper.getSvgIcon(
                        sortOrderToPath[
                            sortableEnumToSortOrderMap[sortableFieldsEnum]]!,
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
    Map<bool, String> booleanToDisplayName = {
      true: AppLocalizations.of(context)!.yes,
      false: AppLocalizations.of(context)!.no
    };
    List<DataRow> result = [];
    var dataList = currentFruitList.asMap().entries
        .map(
          (entry) => DataRow(
            cells: [
              DataCell(Text("${entry.key + 1}")),
              DataCell(Text(entry.value.name.toString())),
              DataCell(Text(entry.value.attackStrengthen.toString())),
              DataCell(Text(entry.value.defenseStrengthen.toString())),
              DataCell(Text(entry.value.bloodStrengthen.toString())),
              DataCell(Text(entry.value.intelligenceStrengthen.toString())),
              DataCell(Text(entry.value.groupGainStrengthen.toString())),
              DataCell(Text(entry.value.speedStrengthen.toString())),
              DataCell(Text(fruitTypeToDisplayValue[entry.value.fruitType]!)),
              DataCell(Text(booleanToDisplayName[entry.value.isSystemResource]!)),
            ],
          ),
        )
        .toList();
    result.addAll(dataList);
    return result;
  }

  Widget _getPageFoot() {
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
