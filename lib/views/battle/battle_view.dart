import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/constants/button_style.dart';
import 'package:one_piece_battles_flutter/repository/battle_dao.dart';
import 'package:one_piece_battles_flutter/utils/date_helper.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:openapi/api.dart';
import 'package:logging/logging.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../utils/base64_helper.dart';
import '../../utils/data_validator.dart';
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
  TextEditingController pageNumberController = TextEditingController(text: "0");
  TextEditingController starterNameController = TextEditingController();
  TextEditingController receiverNameController = TextEditingController();
  // base full data
  List<BattleListView> currentBattleList = [];

  // battle filters
  BattleFilter battleFilter = BattleFilter();
  List<BattleType> selectedBattleTypes = [];
  List<BattleStatus> selectedBattleStatus = [];

  ScrollController horizontalController = ScrollController();

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
    battleFilter.languageCode = I18nHelper.getLanguageCode();
    battleFilter.starterName = starterNameController.text;
    battleFilter.receiverName = receiverNameController.text;

    ListBattleRequest request = ListBattleRequest(
        pageSize: itemCountPerPage,
        pageIndex: selectedPageNum,
        sortKeys: sortKeys,
        battleFilter: battleFilter);
    Future<ListBattleResponse?> response =
        getIt<BattleDao>().listBattles(request);
    response.then((value) => {
          setState(() {
            currentBattleList = value!.battles;
            if (currentBattleList.isEmpty) {
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
          })
        });
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
              child: Scrollbar(
                thumbVisibility: true,
                controller: horizontalController,
                child: SingleChildScrollView(
                  controller: horizontalController,
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _getHeaderText(context),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 1220,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: _getControlRow(context),
                              ),
                            ),
                          ),
                          _getBattlesTable(context),
                          const SizedBox(
                            height: 15,
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        context.goNamed("createBattle");
                      },
                      style: OnepieceButtonStyle.getDefaultStyle(),
                      child: Text(AppLocalizations.of(context)!.createBattle),
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
                      prefixIcon: const Icon(Icons.search),
                      labelText: AppLocalizations.of(context)!.starterName,
                    ),
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
                      prefixIcon: const Icon(Icons.search),
                      labelText: AppLocalizations.of(context)!.receiverName,
                    ),
                  ),
                ),
              ),
              // will be displayed later
              // _getBattleTypeFilter(context),
              _getBattleStatusFilter(context),
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
                              battleFilter.onlySystem = true;
                            } else {
                              battleFilter.onlySystem = null;
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
                            battleFilter.onlySystem = false;
                          } else {
                            battleFilter.onlySystem = null;
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
    );
  }

  Widget _getBattleTypeFilter(BuildContext context) {
    Map<BattleType, String> battleTypeToDisplayValue = {
      BattleType.SINGLE: AppLocalizations.of(context)!.singleBattle,
      BattleType.GROUP: AppLocalizations.of(context)!.groupBattle,
    };
    return Padding(
      padding: const EdgeInsets.only(right: 6),
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
            height: 35,
            width: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: OnepieceColors.menuBackgroundColor,
            ),
          ),
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
              width: 250,
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
                BattleSortableFieldsEnum.creationRecordId: null,
                BattleSortableFieldsEnum.modificationRecordId: null,
              };
              _search();
            },
          ),
        ),
      ),
      _createSingleColumn(AppLocalizations.of(context)!.initiator, null, 150),
      _createSingleColumn(AppLocalizations.of(context)!.receiver, null, 150),
      _createSingleColumn(AppLocalizations.of(context)!.winner,
          BattleSortableFieldsEnum.winnerName, 120),
      _createSingleColumn(AppLocalizations.of(context)!.status, null, 70),
      _createSingleColumn(AppLocalizations.of(context)!.creator, null, 150),
      _createSingleColumn(AppLocalizations.of(context)!.creationTime,
          BattleSortableFieldsEnum.creationRecordId, 160),
      _createSingleColumn(AppLocalizations.of(context)!.modificationTime,
          BattleSortableFieldsEnum.modificationRecordId, 160),
    ];
  }

  DataColumn _createSingleColumn(String displayText,
      BattleSortableFieldsEnum? sortableFieldsEnum, double? width) {
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
            color: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
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
                      child: ImageHelper.getRoundImageFrame(
                          40,
                          40,
                          1.5,
                          OnepieceColors.liteFancyBlue,
                          40,
                          Base64Helper.decode(
                              entry.value.starter!.profileImage!)),
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
                      child: ImageHelper.getRoundImageFrame(
                          40,
                          40,
                          1.5,
                          OnepieceColors.liteFancyBlue,
                          40,
                          Base64Helper.decode(
                              entry.value.receiver!.profileImage!)),
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
                  child: entry.value.battleExecution!.winnerId == null
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
                      : ImageHelper.getRoundImageFrame(
                          40,
                          40,
                          1.5,
                          OnepieceColors.liteFancyBlue,
                          40,
                          Base64Helper.decode(
                              entry.value.battleExecution!.winnerId ==
                                      entry.value.starterId
                                  ? entry.value.starter!.profileImage!
                                  : entry.value.receiver!.profileImage!)),
                ),
              ),
              _getDataCell(battleStatusToDisplayName[
                  entry.value.battleExecution!.battleStatus]!),
              _getDataCell(entry.value.creationRecord!.nickname.toString()),
              _getDataCell(DateHelper.getFormattedDatetimeFromTimestamp(
                  entry.value.creationRecord!.actionTimestamp!, context)),
              _getDataCell(DateHelper.getFormattedDatetimeFromTimestamp(
                  entry.value.modificationRecord!.actionTimestamp!, context)),
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
                  _search();
                  confirmButtonEnabled = false;
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
