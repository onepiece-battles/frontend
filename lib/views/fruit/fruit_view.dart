import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_tag.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:openapi/api.dart';
import 'package:toggle_switch/toggle_switch.dart';
import '../../components/image_lazy_loader.dart';
import '../../components/page_foot.dart';
import '../../constants/button_style.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../repository/fruit_dao.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/responsive_breakpoints.dart';
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

  TextEditingController searchNameController = TextEditingController();

  // first all columns will be sorted by creation id desc.
  Map<FruitSortableFieldsEnum, SortOrder?> sortableEnumToSortOrderMap = {
    FruitSortableFieldsEnum.fruitType: null,
    FruitSortableFieldsEnum.name: null,
  };

  /// Tracks which rows have their strengthen detail panel expanded.
  final Set<String> _expandedRowIds = {};

  // sorting icon map
  Map<SortOrder?, String> sortOrderToPath = const {
    null: 'images/svgs/sort-solid.svg',
    SortOrder.ASC: 'images/svgs/sort-up-solid.svg',
    SortOrder.DESC: 'images/svgs/sort-down-solid.svg'
  };
  ScrollController mainController = ScrollController();
  ScrollController tableController = ScrollController();
  int initialLabelIndex = 0;
  int selectedPageNum = 1;
  int totalPageNum = 0;
  int itemCountPerPage = 10;
  int totalItemCount = 0;

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
      (value) {
        if (!mounted) return;
        setState(
          () {
            currentFruitList = value!.fruits;
            totalItemCount = value.totalSize!;
            totalPageNum = (totalItemCount / itemCountPerPage).ceil();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow =
            ResponsiveBreakpoints.isMobileFromConstraints(constraints);
        return Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: isNarrow ? double.infinity : 700),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _getHeaderText(context),
                    if (isNarrow)
                      _getControlRow(context)
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          height: 90,
                          child: _getControlRow(context),
                        ),
                      ),
                const SizedBox(height: 10),
                Expanded(
                  child: isNarrow
                      ? _buildMobileFruitCards(context)
                      : Scrollbar(
                          controller: mainController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          child: SingleChildScrollView(
                            controller: mainController,
                            child: Scrollbar(
                              controller: tableController,
                              thumbVisibility: true,
                              trackVisibility: true,
                              notificationPredicate: (notification) =>
                                  notification.depth == 0,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                controller: tableController,
                                child: _getFruitsTable(context),
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 15),
                if (totalPageNum > 1)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Center(
                          child: PageFoot(
                        currentPage: selectedPageNum,
                        totalPages: totalPageNum,
                        jumpLabel: AppLocalizations.of(context)!.jumpToPage,
                        onPageChanged: (page) {
                          selectedPageNum = page;
                          _search(false);
                        },
                      )),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
        );
      },
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
              _getFruitTypeFilter(context)
            ],
          ),
          const SizedBox(
            height: 10,
          ),
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
            width: 250,
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

  // ── Mobile: card-based fruit list ─────────────────────────────────────

  Widget _buildMobileFruitCards(BuildContext context) {
    final fruitTypeMap = <FruitType, String>{
      FruitType.logia: AppLocalizations.of(context)!.logiaFruit,
      FruitType.zoan: AppLocalizations.of(context)!.zoanFruit,
      FruitType.ancientZoan: AppLocalizations.of(context)!.ancientZoanFruit,
      FruitType.mythicalZoan: AppLocalizations.of(context)!.mythicalZoanFruit,
      FruitType.artificialZoan:
          AppLocalizations.of(context)!.artificialZoanFruit,
      FruitType.paramecia: AppLocalizations.of(context)!.parameciaFruit,
    };

    if (currentFruitList.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.empty,
            style: OnepieceFonts.contentStyle),
      );
    }

    return ListView.builder(
      controller: mainController,
      itemCount: currentFruitList.length,
      itemBuilder: (context, index) {
        final fruit = currentFruitList[index];
        final isExpanded = _expandedRowIds.contains(fruit.id);
        final isEven = index.isEven;

        return Card(
          color: isEven ? OnepieceColors.liteFancyGreen : Colors.white,
          margin: const EdgeInsets.only(bottom: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => context.goNamed('fruitDetails',
                extra: fruit.id,
                pathParameters: {
                  'name': I18nHelper.getDisplayNameFromI18n(fruit.name!)
                }),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: name + type tag
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          I18nHelper.getDisplayNameFromI18n(fruit.name),
                          style: OnepieceFonts.headerStyle.copyWith(
                              fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OnepieceTag.getFruitTag(
                        fruit.fruitType!,
                        fruitTypeMap[fruit.fruitType]!,
                      ),
                    ],
                  ),
                  // Character list
                  if (fruit.characters.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _createCharacterList(fruit.characters),
                  ],
                  // Expand toggle
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedRowIds.remove(fruit.id);
                          } else {
                            _expandedRowIds.add(fruit.id!);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.detailInformation,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: OnepieceColors.fancyBlue),
                            ),
                            Icon(
                              isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 18,
                              color: OnepieceColors.fancyBlue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Expanded stats
                  if (isExpanded)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: OnepieceColors.liteFancyGreen
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: <_FruitStat>[
                          _FruitStat(
                              AppLocalizations.of(context)!.attackStrengthen,
                              fruit.attackSlope!,
                              fruit.attackIntercept!,
                              'images/character_digits_icon/attack.svg'),
                          _FruitStat(
                              AppLocalizations.of(context)!.defenseStrengthen,
                              fruit.defenseSlope!,
                              fruit.defenseIntercept!,
                              'images/character_digits_icon/defense.svg'),
                          _FruitStat(
                              AppLocalizations.of(context)!.bloodStrengthen,
                              fruit.bloodSlope!,
                              fruit.bloodIntercept!,
                              'images/character_digits_icon/blood.svg'),
                          _FruitStat(
                              AppLocalizations.of(context)!
                                  .intelligenceStrengthen,
                              fruit.intelligenceSlope!,
                              fruit.intelligenceIntercept!,
                              'images/character_digits_icon/intelligence.svg'),
                          _FruitStat(
                              AppLocalizations.of(context)!.groupStrengthen,
                              fruit.groupGainSlope!,
                              fruit.groupGainIntercept!,
                              'images/character_digits_icon/group_gain.svg'),
                          _FruitStat(
                              AppLocalizations.of(context)!.speedStrengthen,
                              fruit.speedSlope!,
                              fruit.speedIntercept!,
                              'images/character_digits_icon/speed.svg'),
                        ].map((stat) {
                          return SizedBox(
                            width:
                                (MediaQuery.of(context).size.width - 80) / 2,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: ImageHelper.getTextFormFieldIcon(
                                      stat.icon, true, 14),
                                ),
                                Text(stat.label,
                                    style: OnepieceFonts.smallContentStyle
                                        .copyWith(fontSize: 12)),
                                const SizedBox(width: 4),
                                Text('${stat.slope}x + ${stat.intercept}',
                                    style: OnepieceFonts.boldFancySmallFont
                                        .copyWith(fontSize: 13)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
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
      // Expand / collapse toggle
      const DataColumn(label: SizedBox(width: 36)),
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
              sortKeys = [];
              sortableEnumToSortOrderMap = {
                FruitSortableFieldsEnum.fruitType: null,
                FruitSortableFieldsEnum.name: null,
              };
              _search(false);
            },
          ),
        ),
      ),
      _createSingleColumn(AppLocalizations.of(context)!.name, null, 180),
      _createSingleColumn(AppLocalizations.of(context)!.fruitType,
          FruitSortableFieldsEnum.fruitType, 150),
      _createSingleColumn(AppLocalizations.of(context)!.owner, null, 180),
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
    final List<DataRow> rows = [];

    for (final entry in currentFruitList.asMap().entries) {
      final fruit = entry.value;
      final isExpanded = _expandedRowIds.contains(fruit.id);

      // ── Main row ──────────────────────────────────────────────
      rows.add(DataRow(
        color:
            WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
          if (entry.key.isEven) return OnepieceColors.liteFancyGreen;
          return null;
        }),
        onSelectChanged: (value) {
          context.goNamed('fruitDetails', extra: fruit.id, pathParameters: {
            'name': I18nHelper.getDisplayNameFromI18n(fruit.name!)
          });
        },
        cells: [
          // Expand icon
          DataCell(
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  isExpanded
                      ? _expandedRowIds.remove(fruit.id)
                      : _expandedRowIds.add(fruit.id!);
                });
              },
              child: Center(
                child: Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: OnepieceColors.fancyBlue,
                  size: 22,
                ),
              ),
            ),
          ),
          _getDataCell("${entry.key + 1}"),
          _getDataCell(I18nHelper.getDisplayNameFromI18n(fruit.name)),
          DataCell(Padding(
            padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
            child: OnepieceTag.getFruitTag(
                fruit.fruitType!, fruitTypeToDisplayValue[fruit.fruitType]!),
          )),
          DataCell(_createCharacterList(fruit.characters)),
        ],
      ));

      // ── Expanded strengthen sub-rows ──────────────────────────
      if (isExpanded) {
        final stats = <_FruitStat>[
          _FruitStat(
              AppLocalizations.of(context)!.attackStrengthen,
              fruit.attackSlope!,
              fruit.attackIntercept!,
              'images/character_digits_icon/attack.svg'),
          _FruitStat(
              AppLocalizations.of(context)!.defenseStrengthen,
              fruit.defenseSlope!,
              fruit.defenseIntercept!,
              'images/character_digits_icon/defense.svg'),
          _FruitStat(
              AppLocalizations.of(context)!.bloodStrengthen,
              fruit.bloodSlope!,
              fruit.bloodIntercept!,
              'images/character_digits_icon/blood.svg'),
          _FruitStat(
              AppLocalizations.of(context)!.intelligenceStrengthen,
              fruit.intelligenceSlope!,
              fruit.intelligenceIntercept!,
              'images/character_digits_icon/intelligence.svg'),
          _FruitStat(
              AppLocalizations.of(context)!.groupStrengthen,
              fruit.groupGainSlope!,
              fruit.groupGainIntercept!,
              'images/character_digits_icon/group_gain.svg'),
          _FruitStat(
              AppLocalizations.of(context)!.speedStrengthen,
              fruit.speedSlope!,
              fruit.speedIntercept!,
              'images/character_digits_icon/speed.svg'),
        ];

        for (final stat in stats) {
          rows.add(DataRow(
            color: WidgetStateProperty.all(
                OnepieceColors.liteFancyGreen.withValues(alpha: 0.4)),
            cells: [
              const DataCell(SizedBox.shrink()),
              const DataCell(SizedBox.shrink()),
              DataCell(Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child:
                          ImageHelper.getTextFormFieldIcon(stat.icon, true, 18),
                    ),
                    Text(stat.label, style: OnepieceFonts.smallContentStyle),
                    const SizedBox(width: 8),
                    Text('${stat.slope}x + ${stat.intercept}',
                        style: OnepieceFonts.boldFancySmallFont),
                  ],
                ),
              )),
              const DataCell(SizedBox.shrink()),
              const DataCell(SizedBox.shrink()),
            ],
          ));
        }
      }
    }

    return rows;
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
                              I18nHelper.getDisplayNameFromI18n(character.name)
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
}

class _FruitStat {
  final String label;
  final double slope;
  final int intercept;
  final String icon;
  const _FruitStat(this.label, this.slope, this.intercept, this.icon);
}
