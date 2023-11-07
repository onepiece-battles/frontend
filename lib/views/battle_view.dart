import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/repository/battle_dao.dart';
import 'package:one_piece_battles_flutter/views/create_battle_view.dart';
import 'package:openapi/api.dart';
import 'package:logging/logging.dart';
import '../constants/onepiece_colors.dart';
import '../constants/onepiece_fonts.dart';
import '../utils/image_helper.dart';

GetIt getIt = GetIt.instance;

class BattleView extends StatefulWidget {
  const BattleView({super.key});

  @override
  State<BattleView> createState() => _BattleViewState();
}

class _BattleViewState extends State<BattleView> {
  Logger logger = Logger('BattleView');
  TextEditingController pageNumberController = TextEditingController(text: "1");
  // base full data
  List<Battle> currentBattleList = [];

  // battle filters
  BattleFilter battleFilter = BattleFilter();
  List<BattleType> selectedBattleTypes = [];
  List<BattleStatus> selectedBattleStatus = [];

  // // battle sortable fields
  // Map<int, BattleSortableFieldsEnum> columnIndexToSortableFieldMap = {
  //   1: BattleSortableFieldsEnum.winnerName,
  //   2: BattleSortableFieldsEnum.creationRecordId,
  //   3: BattleSortableFieldsEnum.modificationRecordId,
  // };

  // first all columns will be sorted by creation id desc.
  Map<BattleSortableFieldsEnum, SortOrder?> sortableEnumToSortOrderMap = {
    BattleSortableFieldsEnum.winnerName: null,
    BattleSortableFieldsEnum.creationRecordId: null,
    BattleSortableFieldsEnum.modificationRecordId: null,
  };

  // sorting icon map
  Map<SortOrder?, String> sortOrderToPath = const {
    null: 'images/svgs/sort-solid.svg',
    SortOrder.ASC: 'images/svgs/sort-up-solid.svg',
    SortOrder.DESC: 'images/svgs/sort-down-solid.svg'
  };

  List<BattleSortableField> sortKeys = [];

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
    _search();
  }

  void _search() {
    // todo(yichi): update api name from "fruit filter" to "battle filter".
    ListBattleRequest request = ListBattleRequest(
        pageSize: pageSize,
        pageIndex: selectedPageIndex,
        sortKeys: sortKeys,
        fruitFilter: battleFilter);
    Future<ListBattleResponse?> response =
        getIt<BattleDao>().listBattles(request);
    response.then((value) => {
          setState(() {
            currentBattleList = value!.battles;
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
          })
        });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _getHeaderText(context),
        _getControlRow(context),
        _getBattlesTable(context),
        // _getPageFoot(context)
      ],
    );
  }

  Widget _getHeaderText(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      child: Text(
        AppLocalizations.of(context)!.battle,
        style: OnepieceFonts.headerStyle,
      ),
    );
  }

  Widget _getControlRow(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0,0,6,6),
            child: SizedBox(
              height: 33,
              child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: ((context) {
                        return const CreateBattleView();
                      }),
                    );
                  },
                  child: Text(AppLocalizations.of(context)!.createBattle)),
            ),
          ),
          // battle type filter
          _getBattleTypeFilter(context),
          // battle status filter
          _getBattleStatusFilter(context)
        ],
      ),
    );
  }

  Widget _getBattleTypeFilter(BuildContext context) {
    Map<BattleType, String> battleTypeToDisplayValue = {
      BattleType.single: AppLocalizations.of(context)!.singleBattle,
      BattleType.group: AppLocalizations.of(context)!.groupBattle,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 6, 6),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2(
          isExpanded: true,
          value: selectedBattleTypes.isEmpty ? null : selectedBattleTypes.last,
          hint: Text(
            AppLocalizations.of(context)!.battleTypeHint,
            style: OnepieceFonts.dropDownItemStyle,
          ),
          onChanged: (value) {},
          selectedItemBuilder: (context) {
            return BattleType.values.map(
              (item) {
                return Container(
                  alignment: AlignmentDirectional.center,
                  child: Text(
                    selectedBattleTypes
                        .map((selectedType) {
                          return battleTypeToDisplayValue[selectedType];
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
          items: BattleType.values.map((BattleType battleType) {
            return DropdownMenuItem<BattleType>(
              value: battleType,
              enabled: false,
              child: StatefulBuilder(
                builder: (context, menuSetState) {
                  final isSelected = selectedBattleTypes.contains(battleType);
                  return InkWell(
                    onTap: () {
                      isSelected
                          ? selectedBattleTypes.remove(battleType)
                          : selectedBattleTypes.add(battleType);
                      battleFilter.battleTypes = selectedBattleTypes;
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
                              battleTypeToDisplayValue[battleType]!,
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

  Widget _getBattleStatusFilter(BuildContext context) {
    Map<BattleStatus, String> battleStatusToDisplayName = {
      BattleStatus.created: AppLocalizations.of(context)!.battleStatusCreated,
      BattleStatus.started: AppLocalizations.of(context)!.battleStatusStarted,
      BattleStatus.finished: AppLocalizations.of(context)!.battleStatusFinished,
      BattleStatus.canceled: AppLocalizations.of(context)!.battleStatusCanceled,
      BattleStatus.failed: AppLocalizations.of(context)!.battleStatusFailed,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 6, 6),
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
            return CharacterType.values.map(
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
              height: 34,
              width: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: OnepieceColors.menuBackgroundColor,
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
                    onTap: () {
                      isSelected
                          ? selectedBattleStatus.remove(battleStatus)
                          : selectedBattleStatus.add(battleStatus);
                      battleFilter.battleStatuses = selectedBattleStatus;

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
          onPressed: () {
            // filter will not be cleared
            sortKeys = [];
            sortableEnumToSortOrderMap = {
              BattleSortableFieldsEnum.winnerName: null,
              BattleSortableFieldsEnum.creationRecordId: null,
              BattleSortableFieldsEnum.modificationRecordId: null,
            };
            _search();
          },
          child: Text(AppLocalizations.of(context)!.resetSort),
        ),
      ),
      _createSingleColumn(AppLocalizations.of(context)!.creator, null),
      _createSingleColumn(AppLocalizations.of(context)!.initiator, null),
      _createSingleColumn(AppLocalizations.of(context)!.receiver, null),
      _createSingleColumn(AppLocalizations.of(context)!.creationTime,
          BattleSortableFieldsEnum.creationRecordId),
      _createSingleColumn(AppLocalizations.of(context)!.modificationTime,
          BattleSortableFieldsEnum.modificationRecordId),
      _createSingleColumn(AppLocalizations.of(context)!.status, null),
      _createSingleColumn(AppLocalizations.of(context)!.winner,
          BattleSortableFieldsEnum.winnerName),
      _createSingleColumn(AppLocalizations.of(context)!.createdBySystem, null),
    ];
  }

  DataColumn _createSingleColumn(
      String displayText, BattleSortableFieldsEnum? sortableFieldsEnum) {
    return DataColumn(
        label: InkWell(
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
                _search();
              });
            },
      child: Padding(
        padding: const EdgeInsets.all(10.0),
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
    ));
  }

  List<DataRow> _createRows(BuildContext context) {
    return [];
  }
}
