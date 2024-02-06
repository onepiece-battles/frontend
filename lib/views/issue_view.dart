import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/repository/issue_dao.dart';
import 'package:openapi/api.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../constants/button_style.dart';
import '../constants/onepiece_colors.dart';
import '../constants/onepiece_fonts.dart';
import '../utils/data_validator.dart';
import '../utils/date_helper.dart';
import '../utils/image_helper.dart';

GetIt getIt = GetIt.instance;

class IssueView extends StatefulWidget {
  const IssueView({super.key});

  @override
  State<IssueView> createState() => _IssueViewState();
}

class _IssueViewState extends State<IssueView> {
  TextEditingController searchHeaderController = TextEditingController();
  TextEditingController pageNumberController = TextEditingController(text: "1");
  IssueFilter issueFilter = IssueFilter();
  List<Issue> currentIssueList = [];
  List<IssueSortableField> sortKeys = [];

  // sorting related fields
  Map<SortOrder?, String> sortOrderToPath = const {
    null: 'images/svgs/sort-solid.svg',
    SortOrder.ASC: 'images/svgs/sort-up-solid.svg',
    SortOrder.DESC: 'images/svgs/sort-down-solid.svg'
  };
  Map<IssueSortableFieldEnum, SortOrder?> sortableEnumToSortOrderMap = {
    IssueSortableFieldEnum.issueStatus: null,
    IssueSortableFieldEnum.issueType: null,
    IssueSortableFieldEnum.creationTimestamp: null,
    IssueSortableFieldEnum.modificationTimestamp: null,
  };
  List<IssueType> selectedIssueTypes = [];
  List<IssueStatus> selectedIssueStatuses = [];
  ScrollController scrollController = ScrollController();
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
    ListIssueRequest listIssueRequest = ListIssueRequest(
        pageSize: pageSize,
        pageIndex: selectedPageIndex,
        sortKeys: sortKeys,
        issueFilter: issueFilter);
    Future<ListIssueResponse?> listIssueResponse =
        getIt<IssueDao>().listIssue(listIssueRequest);
    listIssueResponse.then((value) {
      setState(() {
        currentIssueList = value!.issues;
        if (currentIssueList.isEmpty) {
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
                  child: _createIssueTable(context),
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
        AppLocalizations.of(context)!.issue,
        style: OnepieceFonts.headerStyle,
      ),
    );
  }

  Widget _createControlPanel(BuildContext context) {
    Map<IssueType, String> issueTypeToDisplayValue = <IssueType, String>{
      IssueType.OTHER: AppLocalizations.of(context)!.otherType,
      IssueType.FEATURE_SUGGESTION:
          AppLocalizations.of(context)!.featureSuggestion,
      IssueType.BUG_REPORT: AppLocalizations.of(context)!.bugReport,
    };
    Map<IssueStatus, String> issueStatusToDisplayValue = <IssueStatus, String>{
      IssueStatus.CREATED: AppLocalizations.of(context)!.statusCreated,
      IssueStatus.IN_PROGRESS: AppLocalizations.of(context)!.statusInProgress,
      IssueStatus.RESOLVED: AppLocalizations.of(context)!.statusResolved,
      IssueStatus.REVOKED: AppLocalizations.of(context)!.statusRevoked,
      IssueStatus.BACKLOGGED: AppLocalizations.of(context)!.statusBackLogged,
    };
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 6, 0),
            child: SizedBox(
              width: 200,
              height: 35,
              child: TextFormField(
                controller: searchHeaderController,
                onChanged: (value) {
                  issueFilter.issueHeader = value;
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
                  prefixIcon: IconButton(
                      onPressed: () {
                        issueFilter.issueHeader = searchHeaderController.text;
                        _search();
                      },
                      icon: const Icon(Icons.search)),
                  labelText: AppLocalizations.of(context)!.title,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 6, 0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton2(
                isExpanded: true,
                value:
                    selectedIssueTypes.isEmpty ? null : selectedIssueTypes.last,
                hint: Text(
                  AppLocalizations.of(context)!.issueType,
                  style: OnepieceFonts.dropDownItemStyle,
                ),
                onChanged: (value) {},
                selectedItemBuilder: (context) {
                  return IssueType.values.map(
                    (item) {
                      return Container(
                        alignment: AlignmentDirectional.center,
                        child: Text(
                          selectedIssueTypes
                              .map((selectedType) {
                                return issueTypeToDisplayValue[selectedType];
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
                items: IssueType.values.map((IssueType issueType) {
                  return DropdownMenuItem<IssueType>(
                    value: issueType,
                    enabled: false,
                    child: StatefulBuilder(
                      builder: (context, menuSetState) {
                        final isSelected =
                            selectedIssueTypes.contains(issueType);
                        return InkWell(
                          onTap: () {
                            isSelected
                                ? selectedIssueTypes.remove(issueType)
                                : selectedIssueTypes.add(issueType);
                            issueFilter.issueTypes = selectedIssueTypes;
                            // //This rebuilds the StatefulWidget to update the button's text
                            setState(() {});
                            //This rebuilds the dropdownMenu Widget to update the check mark
                            menuSetState(() {});
                            _search();
                          },
                          child: Container(
                            height: double.infinity,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6.0),
                            child: Row(
                              children: [
                                if (isSelected)
                                  const Icon(Icons.check_box_outlined)
                                else
                                  const Icon(Icons.check_box_outline_blank),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    issueTypeToDisplayValue[issueType]!,
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
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton2(
              isExpanded: true,
              value: selectedIssueStatuses.isEmpty
                  ? null
                  : selectedIssueStatuses.last,
              hint: Text(
                AppLocalizations.of(context)!.status,
                style: OnepieceFonts.dropDownItemStyle,
              ),
              onChanged: (value) {},
              selectedItemBuilder: (context) {
                return IssueStatus.values.map(
                  (item) {
                    return Container(
                      alignment: AlignmentDirectional.center,
                      child: Text(
                        selectedIssueStatuses
                            .map((selectedType) {
                              return issueStatusToDisplayValue[selectedType];
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
              items: IssueStatus.values.map((IssueStatus issueStatus) {
                return DropdownMenuItem<IssueStatus>(
                  value: issueStatus,
                  enabled: false,
                  child: StatefulBuilder(
                    builder: (context, menuSetState) {
                      final isSelected =
                          selectedIssueStatuses.contains(issueStatus);
                      return InkWell(
                        onTap: () {
                          isSelected
                              ? selectedIssueStatuses.remove(issueStatus)
                              : selectedIssueStatuses.add(issueStatus);
                          issueFilter.issueStatuses = selectedIssueStatuses;
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
                                  issueStatusToDisplayValue[issueStatus]!,
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
    ]);
  }

  DataTable _createIssueTable(BuildContext context) {
    return DataTable(
      showCheckboxColumn: false,
      showBottomBorder: true,
      headingRowHeight: 50,
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
            style: OnepieceButtonStyle.getDefaultStyle(),
            onPressed: () {
              sortKeys = [];
              sortableEnumToSortOrderMap = {
                IssueSortableFieldEnum.issueStatus: null,
                IssueSortableFieldEnum.issueType: null,
                IssueSortableFieldEnum.creationTimestamp: null,
                IssueSortableFieldEnum.modificationTimestamp: null,
              };
              _search();
            },
            child: Text(AppLocalizations.of(context)!.resetSort)),
      ),
      _createSingleColumn(
          AppLocalizations.of(context)!.userNameLabel, null, 180),
      _createSingleColumn(
          AppLocalizations.of(context)!.feedbackTitle, null, 220),
      _createSingleColumn(AppLocalizations.of(context)!.issueType,
          IssueSortableFieldEnum.issueType, null),
      _createSingleColumn(AppLocalizations.of(context)!.status,
          IssueSortableFieldEnum.issueStatus, null),
      _createSingleColumn(AppLocalizations.of(context)!.creationTime,
          IssueSortableFieldEnum.creationTimestamp, 200),
      _createSingleColumn(AppLocalizations.of(context)!.modificationTime,
          IssueSortableFieldEnum.modificationTimestamp, 200),
    ];
  }

  DataColumn _createSingleColumn(String displayText,
      IssueSortableFieldEnum? issueSortableFieldsEnum, double? width) {
    return DataColumn(
      label: InkWell(
        onTap: issueSortableFieldsEnum == null
            ? null
            : () {
                setState(() {
                  var sortOrder =
                      sortableEnumToSortOrderMap[issueSortableFieldsEnum];
                  var sortKey = issueSortableFieldsEnum;
                  if (sortOrder == null) {
                    sortOrder = SortOrder.ASC;
                  } else if (sortOrder == SortOrder.ASC) {
                    sortOrder = SortOrder.DESC;
                  } else {
                    sortOrder = null;
                  }
                  sortableEnumToSortOrderMap[issueSortableFieldsEnum] =
                      sortOrder;
                  sortKeys.removeWhere((element) => element.sortKey == sortKey);
                  if (sortOrder != null) {
                    sortKeys.insert(
                        0,
                        IssueSortableField(
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
                  style: sortableEnumToSortOrderMap[issueSortableFieldsEnum] ==
                          null
                      ? OnepieceFonts.tableHeaderStyle
                      : OnepieceFonts.selectedTableHeaderStyle,
                ),
                if (issueSortableFieldsEnum != null)
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: ImageHelper.getSvgIconWithColor(
                      sortOrderToPath[
                          sortableEnumToSortOrderMap[issueSortableFieldsEnum]]!,
                      15,
                      15,
                      sortableEnumToSortOrderMap[issueSortableFieldsEnum] ==
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
    Map<IssueType, String> issueTypeToDisplayValue = <IssueType, String>{
      IssueType.OTHER: AppLocalizations.of(context)!.otherType,
      IssueType.FEATURE_SUGGESTION:
          AppLocalizations.of(context)!.featureSuggestion,
      IssueType.BUG_REPORT: AppLocalizations.of(context)!.bugReport,
    };
    Map<IssueStatus, String> issueStatusToDisplayValue = <IssueStatus, String>{
      IssueStatus.CREATED: AppLocalizations.of(context)!.statusCreated,
      IssueStatus.IN_PROGRESS: AppLocalizations.of(context)!.statusInProgress,
      IssueStatus.RESOLVED: AppLocalizations.of(context)!.statusResolved,
      IssueStatus.REVOKED: AppLocalizations.of(context)!.statusRevoked,
      IssueStatus.BACKLOGGED: AppLocalizations.of(context)!.statusBackLogged,
    };

    return currentIssueList
        .asMap()
        .entries
        .map(
          (entry) => DataRow(
            onSelectChanged: (value) {
              context.goNamed('issueDetails');
            },
            cells: [
              _getDataCell("${entry.key + 1}", null),
              // todo(yichi): need to add username to issue api
              _getDataCell("created user", null),
              _getDataCell(entry.value.issueHeader.toString(), 200),
              _getDataCell(
                  issueTypeToDisplayValue[entry.value.issueType]!, null),
              _getDataCell(
                  issueStatusToDisplayValue[entry.value.issueStatus]!, null),
              _getDataCell(
                  DateHelper.getFormattedDatetimeFromTimestamp(
                      entry.value.creationTimestamp!, context),
                  null),
              _getDataCell(
                  DateHelper.getFormattedDatetimeFromTimestamp(
                      entry.value.modificationTimestamp!, context),
                  null),
            ],
          ),
        )
        .toList();
  }

  DataCell _getDataCell(String value, double? customizeWidth) {
    if (customizeWidth != null) {
      return DataCell(
        Padding(
          padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
          child: SizedBox(
            width: customizeWidth,
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }
    return DataCell(Padding(
      padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
      child: Text(value),
    ));
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
