import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';
import '../../l10n/app_localizations.dart';
import '../../components/page_foot.dart';
import '../../components/desktop_card_layout.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../utils/responsive_breakpoints.dart';
import '../../utils/route_notifier.dart';
import 'issue_list_controller.dart';
import 'widgets/issue_roster.dart';

GetIt getIt = GetIt.instance;

class IssueView extends StatefulWidget {
  const IssueView({super.key});

  @override
  State<IssueView> createState() => _IssueViewState();
}

class _IssueViewState extends State<IssueView> {
  final TextEditingController searchHeaderController = TextEditingController();
  final TextEditingController searchEmailController = TextEditingController();
  final TextEditingController searchNicknameController =
      TextEditingController();
  IssueFilter issueFilter = IssueFilter();
  List<IssueListView> currentIssueList = [];
  List<IssueSortableField> sortKeys = [];
  final IssueListController _controller = IssueListController();

  Map<IssueSortableFieldEnum, SortOrder?> sortableEnumToSortOrderMap = {
    IssueSortableFieldEnum.issueStatus: null,
    IssueSortableFieldEnum.issueType: null,
    IssueSortableFieldEnum.creationTimestamp: null,
    IssueSortableFieldEnum.modificationTimestamp: null,
  };
  List<IssueType> selectedIssueTypes = [];
  List<IssueStatus> selectedIssueStatuses = [];
  ScrollController scrollController = ScrollController();

  int selectedPageNum = 1;
  bool _showFilters = false;
  int totalPageNum = 0;
  int itemCountPerPage = 10;
  int totalItemCount = 0;

  @override
  void initState() {
    super.initState();
    routeNotifier.addListener(_refreshWhenListRouteIsActive);
    _search(false);
  }

  @override
  void dispose() {
    routeNotifier.removeListener(_refreshWhenListRouteIsActive);
    searchHeaderController.dispose();
    searchEmailController.dispose();
    searchNicknameController.dispose();
    scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _refreshWhenListRouteIsActive() {
    if (routeNotifier.value ==
        '/home/${ResourceType.ISSUE.toString().toLowerCase()}') {
      _search(false);
    }
  }

  void _search(bool filterChange) {
    if (filterChange) {
      selectedPageNum = 1;
    }
    ListIssueRequest listIssueRequest = ListIssueRequest(
        pageSize: itemCountPerPage,
        pageIndex: selectedPageNum,
        sortKeys: sortKeys,
        issueFilter: issueFilter);
    Future<ListIssueResponse?> listIssueResponse =
        _controller.listIssue(listIssueRequest);
    listIssueResponse.then((value) {
      if (!mounted) return;
      setState(() {
        currentIssueList = value!.issues;
        totalItemCount = value.totalSize!;
        totalPageNum = (totalItemCount / 10).ceil();
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
            constraints: const BoxConstraints(maxWidth: double.infinity),
            child: Padding(
              padding: EdgeInsets.all(isNarrow ? 15 : 24),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    _createHeader(context),
                    isNarrow
                        ? CompactFilterPanel(
                            child: _createControlPanel(context, isNarrow: true))
                        : DesktopFilterPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: _createControlPanel(context,
                                      isNarrow: false),
                                ),
                                const SizedBox(height: 10),
                                _buildIssueSortControls(context),
                              ],
                            ),
                          ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: IssueRoster(
                        issues: currentIssueList,
                        controller: scrollController,
                        isNarrow: isNarrow,
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
                              scrollController.jumpTo(0);
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

  Widget _createHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
      child: Text(
        AppLocalizations.of(context)!.issue,
        style: OnepieceFonts.headerStyle,
      ),
    );
  }

  Widget _createControlPanel(BuildContext context, {required bool isNarrow}) {
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

    if (isNarrow) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: SizedBox(
              height: 35,
              child: TextFormField(
                controller: searchHeaderController,
                onChanged: (v) {
                  issueFilter.issueHeader = v;
                  _search(true);
                },
                decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    disabledBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: OnepieceColors.separator)),
                    enabledBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: OnepieceColors.separator)),
                    focusedBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: OnepieceColors.fancyGreen)),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    labelText: AppLocalizations.of(context)!.title),
              ),
            ),
          ),
          const SizedBox(width: 6),
          ListFilterButton(
            active: _showFilters,
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ]),
        if (_showFilters) ...[
          const SizedBox(height: 6),
          SizedBox(
            height: 35,
            child: TextFormField(
              controller: searchEmailController,
              onChanged: (v) {
                issueFilter.username = v;
                _search(true);
              },
              decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  disabledBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: OnepieceColors.separator)),
                  enabledBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: OnepieceColors.separator)),
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: OnepieceColors.fancyGreen)),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  labelText: AppLocalizations.of(context)!.creatorEmail),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 35,
            child: TextFormField(
              controller: searchNicknameController,
              onChanged: (v) {
                issueFilter.nickname = v;
                _search(true);
              },
              decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  disabledBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: OnepieceColors.separator)),
                  enabledBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: OnepieceColors.separator)),
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: OnepieceColors.fancyGreen)),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  labelText: AppLocalizations.of(context)!.creatorNickname),
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonHideUnderline(
              child: DropdownButton2(
            isExpanded: true,
            value: selectedIssueTypes.isEmpty ? null : selectedIssueTypes.last,
            hint: Text(AppLocalizations.of(context)!.issueType,
                style: OnepieceFonts.dropDownItemStyle),
            onChanged: (value) {},
            selectedItemBuilder: (context) => IssueType.values
                .map((item) => Container(
                    alignment: AlignmentDirectional.center,
                    child: Text(
                        selectedIssueTypes
                            .map((t) => issueTypeToDisplayValue[t])
                            .toSet()
                            .join(', '),
                        style: const TextStyle(
                            fontSize: 16, overflow: TextOverflow.ellipsis),
                        maxLines: 1)))
                .toList(),
            buttonStyleData: ButtonStyleData(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 35,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: OnepieceColors.surface)),
            menuItemStyleData: const MenuItemStyleData(height: 35),
            items: IssueType.values
                .map((type) => DropdownMenuItem<IssueType>(
                    value: type,
                    enabled: false,
                    child: StatefulBuilder(builder: (ctx, ms) {
                      final sel = selectedIssueTypes.contains(type);
                      return InkWell(
                          hoverColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          onTap: () {
                            sel
                                ? selectedIssueTypes.remove(type)
                                : selectedIssueTypes.add(type);
                            issueFilter.issueTypes = selectedIssueTypes;
                            setState(() {});
                            ms(() {});
                            _search(true);
                          },
                          child: Container(
                              height: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              child: Row(children: [
                                Icon(sel
                                    ? Icons.check_box_outlined
                                    : Icons.check_box_outline_blank),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(issueTypeToDisplayValue[type]!,
                                        style: const TextStyle(fontSize: 16))),
                              ])));
                    })))
                .toList(),
          )),
          const SizedBox(height: 6),
          DropdownButtonHideUnderline(
              child: DropdownButton2(
            isExpanded: true,
            value: selectedIssueStatuses.isEmpty
                ? null
                : selectedIssueStatuses.last,
            hint: Text(AppLocalizations.of(context)!.status,
                style: OnepieceFonts.dropDownItemStyle),
            onChanged: (value) {},
            selectedItemBuilder: (context) => IssueStatus.values
                .map((item) => Container(
                    alignment: AlignmentDirectional.center,
                    child: Text(
                        selectedIssueStatuses
                            .map((t) => issueStatusToDisplayValue[t])
                            .toSet()
                            .join(', '),
                        style: const TextStyle(
                            fontSize: 16, overflow: TextOverflow.ellipsis),
                        maxLines: 1)))
                .toList(),
            buttonStyleData: ButtonStyleData(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 35,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: OnepieceColors.menuBackgroundColor)),
            menuItemStyleData: const MenuItemStyleData(height: 35),
            items: IssueStatus.values
                .map((status) => DropdownMenuItem<IssueStatus>(
                    value: status,
                    enabled: false,
                    child: StatefulBuilder(builder: (ctx, ms) {
                      final sel = selectedIssueStatuses.contains(status);
                      return InkWell(
                          hoverColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          onTap: () {
                            sel
                                ? selectedIssueStatuses.remove(status)
                                : selectedIssueStatuses.add(status);
                            issueFilter.issueStatuses = selectedIssueStatuses;
                            setState(() {});
                            ms(() {});
                            _search(true);
                          },
                          child: Container(
                              height: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              child: Row(children: [
                                Icon(sel
                                    ? Icons.check_box_outlined
                                    : Icons.check_box_outline_blank),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(
                                        issueStatusToDisplayValue[status]!,
                                        style: const TextStyle(fontSize: 16))),
                              ])));
                    })))
                .toList(),
          )),
        ],
      ]);
    }

    // Desktop
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
                  _search(true);
                },
                decoration: InputDecoration(
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  disabledBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: OnepieceColors.separator)),
                  enabledBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: OnepieceColors.separator)),
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: OnepieceColors.fancyGreen)),
                  prefixIcon: const Icon(Icons.search),
                  labelText: AppLocalizations.of(context)!.title,
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
                controller: searchEmailController,
                onChanged: (value) {
                  issueFilter.username = value;
                  _search(true);
                },
                decoration: InputDecoration(
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  disabledBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: OnepieceColors.separator)),
                  enabledBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: OnepieceColors.separator)),
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: OnepieceColors.fancyGreen)),
                  prefixIcon: const Icon(Icons.search),
                  labelText: AppLocalizations.of(context)!.creatorEmail,
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
                controller: searchNicknameController,
                onChanged: (value) {
                  issueFilter.nickname = value;
                  _search(true);
                },
                decoration: InputDecoration(
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  disabledBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: OnepieceColors.separator)),
                  enabledBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: OnepieceColors.separator)),
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: OnepieceColors.fancyGreen)),
                  prefixIcon: const Icon(Icons.search),
                  labelText: AppLocalizations.of(context)!.creatorNickname,
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
                          hoverColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          onTap: () {
                            isSelected
                                ? selectedIssueTypes.remove(issueType)
                                : selectedIssueTypes.add(issueType);
                            issueFilter.issueTypes = selectedIssueTypes;
                            // //This rebuilds the StatefulWidget to update the button's text
                            setState(() {});
                            //This rebuilds the dropdownMenu Widget to update the check mark
                            menuSetState(() {});
                            _search(true);
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
                        hoverColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        onTap: () {
                          isSelected
                              ? selectedIssueStatuses.remove(issueStatus)
                              : selectedIssueStatuses.add(issueStatus);
                          issueFilter.issueStatuses = selectedIssueStatuses;
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

  Widget _buildIssueSortControls(BuildContext context) {
    return Row(children: [
      Text('$totalItemCount ${AppLocalizations.of(context)!.issue}',
          style: OnepieceFonts.smallContentStyle),
      const Spacer(),
      Wrap(spacing: 6, children: [
        _issueSortChip(AppLocalizations.of(context)!.issueType,
            IssueSortableFieldEnum.issueType),
        _issueSortChip(AppLocalizations.of(context)!.status,
            IssueSortableFieldEnum.issueStatus),
        _issueSortChip(AppLocalizations.of(context)!.creationTime,
            IssueSortableFieldEnum.creationTimestamp),
        _issueSortChip(AppLocalizations.of(context)!.modificationTime,
            IssueSortableFieldEnum.modificationTimestamp),
      ]),
    ]);
  }

  Widget _issueSortChip(String label, IssueSortableFieldEnum field) {
    final order = sortableEnumToSortOrderMap[field];
    return DesktopSortChip(
      label: label,
      ascending: order == null ? null : order == SortOrder.ASC,
      onTap: () => _toggleIssueSort(field),
    );
  }

  void _toggleIssueSort(IssueSortableFieldEnum field) {
    final current = sortableEnumToSortOrderMap[field];
    SortOrder? next;
    if (current == null) {
      next = SortOrder.ASC;
    } else if (current == SortOrder.ASC) {
      next = SortOrder.DESC;
    }
    setState(() {
      sortableEnumToSortOrderMap[field] = next;
      sortKeys.removeWhere((item) => item.sortKey == field);
      if (next != null) {
        sortKeys.insert(0, IssueSortableField(sortKey: field, sortOrder: next));
      }
      _search(false);
    });
  }
}
