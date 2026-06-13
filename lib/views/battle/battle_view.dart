import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/components/image_lazy_loader.dart';
import 'package:one_piece_battles_flutter/components/page_foot.dart';
import 'package:one_piece_battles_flutter/constants/button_style.dart';
import 'package:one_piece_battles_flutter/repository/battle_dao.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:openapi/api.dart';
import 'package:logging/logging.dart';
import 'package:toggle_switch/toggle_switch.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../utils/responsive_breakpoints.dart';
import '../../utils/image_helper.dart';
import '../../utils/permission_check.dart';

GetIt getIt = GetIt.instance;

class BattleView extends StatefulWidget {
  const BattleView({super.key});

  @override
  State<BattleView> createState() => _BattleViewState();
}

class _BattleViewState extends State<BattleView> {
  Logger logger = Logger('BattleView');
  TextEditingController starterNameController = TextEditingController();
  TextEditingController receiverNameController = TextEditingController();

  // base full data
  List<BattleListView> currentBattleList = [];

  // battle filters
  BattleFilter battleFilter = BattleFilter();
  List<BattleType> selectedBattleTypes = [];
  List<BattleStatus> selectedBattleStatus = [];

  ScrollController mainController = ScrollController();
  ScrollController tableController = ScrollController();

  // first all columns will be sorted by creation id desc.
  Map<BattleSortableFieldsEnum, SortOrder?> sortableEnumToSortOrderMap = {
    BattleSortableFieldsEnum.winnerName: null,
  };

  // sorting icon map
  Map<SortOrder?, String> sortOrderToPath = const {
    null: 'images/svgs/sort-solid.svg',
    SortOrder.ASC: 'images/svgs/sort-up-solid.svg',
    SortOrder.DESC: 'images/svgs/sort-down-solid.svg'
  };

  List<BattleSortableField> sortKeys = [];
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
    battleFilter.languageCode = I18nHelper.getLanguageCode();
    battleFilter.starterName = starterNameController.text;
    battleFilter.receiverName = receiverNameController.text;
    if (filterChange) {
      selectedPageNum = 1;
    }
    ListBattleRequest request = ListBattleRequest(
        pageSize: itemCountPerPage,
        pageIndex: selectedPageNum,
        sortKeys: sortKeys,
        battleFilter: battleFilter);
    Future<ListBattleResponse?> response =
        getIt<BattleDao>().listBattles(request);
    response.then((value) {
      if (!mounted) return;
      setState(() {
        currentBattleList = value!.battles;
        totalItemCount = value.totalSize!;
        totalPageNum = (totalItemCount / itemCountPerPage).ceil();
      });
    });
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
                BoxConstraints(maxWidth: isNarrow ? double.infinity : 800),
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
                  child: Scrollbar(
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
                          child: _getBattlesTable(context),
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
                  )
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
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 20),
      child: Text(
        AppLocalizations.of(context)!.battle,
        style: OnepieceFonts.headerStyle,
      ),
    );
  }

  Widget _getControlRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (PermissionCheck.checkPermission(
                  getIt<User>().loginRoleResourcesPermissionMap,
                  ResourceType.BATTLE,
                  Permission.CREATE))
                SizedBox(
                  height: 35,
                  width: 120,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        context.goNamed("createBattle");
                      },
                      style: OnepieceButtonStyle.getDefaultStyle(),
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
                    controller: starterNameController,
                    onChanged: (value) {
                      battleFilter.starterName = value.trim();
                      _search(true);
                    },
                    decoration: InputDecoration(
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        disabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                                color: OnepieceColors.menuHoverColor)),
                        enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                          color: OnepieceColors.menuHoverColor,
                        )),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                              color: OnepieceColors.fancyGreen, width: 1.5),
                        ),
                        prefixIcon: const Icon(Icons.search),
                        labelText: AppLocalizations.of(context)!.starterName,
                        labelStyle: OnepieceFonts.dropDownItemStyle),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 6, 0),
                child: SizedBox(
                  width: 200,
                  height: 35,
                  child: TextFormField(
                    controller: receiverNameController,
                    onChanged: (value) {
                      battleFilter.receiverName = value.trim();
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
                      prefixIcon: const Icon(Icons.search),
                      labelText: AppLocalizations.of(context)!.receiverName,
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
                  customWidths: const [140, 130, 150, 180],
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
                      battleFilter.systemResource = null;
                      battleFilter.userId = null;
                    }
                    // show my resource
                    if (index == 1) {
                      battleFilter.systemResource = null;
                      battleFilter.userId = getIt<User>().id;
                    }
                    // only show system resource
                    if (index == 2) {
                      battleFilter.systemResource = true;
                      battleFilter.userId = null;
                    }
                    // do not show system resource
                    if (index == 3) {
                      battleFilter.systemResource = false;
                      battleFilter.userId = null;
                    }
                    _search(true);
                  },
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              // will be displayed later
              // _getBattleTypeFilter(context),
              _getBattleStatusFilter(context),
            ],
          )
        ],
      ),
    );
  }

  Widget _getBattleStatusFilter(BuildContext context) {
    Map<BattleStatus, String> battleStatusToDisplayName = {
      BattleStatus.CREATED: AppLocalizations.of(context)!.battleStatusCreated,
      BattleStatus.IN_PROGRESS:
          AppLocalizations.of(context)!.battleStatusStarted,
      BattleStatus.FINISHED: AppLocalizations.of(context)!.battleStatusFinished,
      BattleStatus.FAILED: AppLocalizations.of(context)!.battleStatusFailed,
    };
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2(
          isExpanded: true,
          value:
              selectedBattleStatus.isEmpty ? null : selectedBattleStatus.last,
          hint: Text(
            AppLocalizations.of(context)!.battleStatusHint,
            style: OnepieceFonts.dropDownItemStyle,
          ),
          onChanged: (value) {},
          selectedItemBuilder: (context) {
            return BattleStatus.values.map(
              (item) {
                return Container(
                  alignment: AlignmentDirectional.center,
                  child: Text(
                    selectedBattleStatus
                        .map((selectedType) {
                          return battleStatusToDisplayName[selectedType];
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
              width: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: OnepieceColors.liteFancyGreen,
              )),
          menuItemStyleData: const MenuItemStyleData(
            height: 35,
          ),
          items: BattleStatus.values.map((BattleStatus battleStatus) {
            return DropdownMenuItem<BattleStatus>(
              value: battleStatus,
              enabled: false,
              child: StatefulBuilder(
                builder: (context, menuSetState) {
                  final isSelected =
                      selectedBattleStatus.contains(battleStatus);
                  return InkWell(
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    onTap: () {
                      isSelected
                          ? selectedBattleStatus.remove(battleStatus)
                          : selectedBattleStatus.add(battleStatus);
                      battleFilter.battleStatuses = selectedBattleStatus;

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
                              battleStatusToDisplayName[battleStatus]!,
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

  Widget _getBattlesTable(BuildContext context) {
    return DataTable(
      showCheckboxColumn: false,
      showBottomBorder: true,
      headingRowHeight: 50,
      border: const TableBorder(
          top: BorderSide(color: OnepieceColors.themeColor),
          bottom: BorderSide(color: OnepieceColors.themeColor)),
      columns: _createColumns(),
      rows: _createRows(context),
      columnSpacing: 20,
    );
  }

  List<DataColumn> _createColumns() {
    return [
      DataColumn(
        label: Tooltip(
          message: AppLocalizations.of(context)!.resetSort,
          preferBelow: true,
          child: ImageHelper.getIconButtonFromSvg(
            'images/svgs/reset.svg',
            OnepieceColors.fancyBlue,
            25,
            25,
            () {
              // filter will not be cleared
              sortKeys = [];
              sortableEnumToSortOrderMap = {
                BattleSortableFieldsEnum.winnerName: null,
              };
              _search(false);
            },
          ),
        ),
      ),
      _createSingleColumn(AppLocalizations.of(context)!.initiator, null, 150),
      _createSingleColumn(AppLocalizations.of(context)!.receiver, null, 150),
      _createSingleColumn(AppLocalizations.of(context)!.winner, null, 60),
      _createSingleColumn(AppLocalizations.of(context)!.status, null, 70),
      _createSingleColumn(AppLocalizations.of(context)!.creator, null, 150),
    ];
  }

  DataColumn _createSingleColumn(String displayText,
      BattleSortableFieldsEnum? sortableFieldsEnum, double? width) {
    return DataColumn(
        label: InkWell(
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      onTap: sortableFieldsEnum == null
          ? null
          : () {
              setState(() {
                var sortOrder = sortableEnumToSortOrderMap[sortableFieldsEnum];
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
                      BattleSortableField(
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
    ));
  }

  List<DataRow> _createRows(BuildContext context) {
    Map<BattleStatus, String> battleStatusToDisplayName = {
      BattleStatus.CREATED: AppLocalizations.of(context)!.battleStatusCreated,
      BattleStatus.IN_PROGRESS:
          AppLocalizations.of(context)!.battleStatusStarted,
      BattleStatus.FINISHED: AppLocalizations.of(context)!.battleStatusFinished,
      BattleStatus.FAILED: AppLocalizations.of(context)!.battleStatusFailed,
    };
    return currentBattleList
        .asMap()
        .entries
        .map(
          (entry) => DataRow(
            color: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
              if (entry.key.isEven) {
                return OnepieceColors
                    .liteFancyGreen; // Use whatever color you need for even rows
              }
              return null; // Use default (transparent) color for odd rows
            }),
            onSelectChanged: (value) {
              context.goNamed('battleDetails',
                  extra: entry.value.id,
                  pathParameters: {'id': entry.value.id});
            },
            cells: [
              _getDataCell("${entry.key + 1}"),
              DataCell(
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                      child: ImageLazyLoader(
                          key: UniqueKey(),
                          uriProvider: () => entry.value.starter!.imageUri!,
                          width: 40,
                          borderWidth: 1.5,
                          borderRadios: 40),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                          child: Text(I18nHelper.getDisplayNameFromI18n(
                              entry.value.starter!.name)),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 5.0),
                          child: Text(
                              entry.value.battleExecution!.starterScoreBefore!
                                  .toString(),
                              style: OnepieceFonts.boldFancySmallFont),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              DataCell(
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                      child: ImageLazyLoader(
                          key: UniqueKey(),
                          uriProvider: () => entry.value.receiver!.imageUri!,
                          width: 40,
                          borderWidth: 1.5,
                          borderRadios: 40),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                          child: Text(I18nHelper.getDisplayNameFromI18n(
                              entry.value.receiver!.name)),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 5.0),
                          child: Text(
                              entry.value.battleExecution!.receiverScoreBefore!
                                  .toString(),
                              style: OnepieceFonts.boldFancySmallFont),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              DataCell(
                Padding(
                  padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      entry.value.battleExecution!.winnerId == null
                          ? Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(2.0)),
                              ),
                              child: FittedBox(
                                fit: BoxFit.fill,
                                child: ImageHelper.getSvgIconWithColor(
                                    'images/svgs/question.svg',
                                    100,
                                    100,
                                    OnepieceColors.liteFancyBlue),
                              ),
                            )
                          : ImageLazyLoader(
                              key: UniqueKey(),
                              uriProvider: () =>
                                  entry.value.battleExecution!.winnerId ==
                                          entry.value.starterId
                                      ? entry.value.starter!.imageUri!
                                      : entry.value.receiver!.imageUri!,
                              width: 40,
                              borderWidth: 1.5,
                              borderRadios: 40),
                    ],
                  ),
                ),
              ),
              _getDataCell(battleStatusToDisplayName[
                  entry.value.battleExecution!.battleStatus]!),
              _getDataCell(entry.value.creationRecord!.nickname.toString()),
            ],
          ),
        )
        .toList();
  }

  DataCell _getDataCell(String value) {
    return DataCell(Padding(
      padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
      child: Text(value),
    ));
  }
}
