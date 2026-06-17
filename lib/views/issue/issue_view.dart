import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/repository/issue_dao.dart';
import 'package:openapi/api.dart';
import '../../l10n/app_localizations.dart';
import '../../components/page_foot.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../utils/date_helper.dart';
import '../../utils/image_helper.dart';
import '../../utils/nested_scroll_helper.dart';
import '../../utils/responsive_breakpoints.dart';

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
  ScrollController horizontalController = ScrollController();

  int selectedPageNum = 1;
  bool _showFilters = false;
  int totalPageNum = 0;
  int itemCountPerPage = 10;
  int totalItemCount = 0;

  @override
  void initState() {
    super.initState();
    _search(false);
  }

  @override
  void dispose() {
    searchHeaderController.dispose();
    searchEmailController.dispose();
    searchNicknameController.dispose();
    scrollController.dispose();
    horizontalController.dispose();
    super.dispose();
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
        getIt<IssueDao>().listIssue(listIssueRequest);
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
            constraints:
                BoxConstraints(maxWidth: isNarrow ? double.infinity : 1400),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    _createHeader(context),
                    _createControlPanel(context, isNarrow: isNarrow),
                    const SizedBox(height: 10),
                    Expanded(
                      child: isNarrow
                          ? _buildMobileIssueCards(context)
                          : SingleChildScrollView(
                              controller: scrollController,
                              scrollDirection: Axis.vertical,
                              child: Scrollbar(
                                thumbVisibility: true,
                                controller: horizontalController,
                                child: NestedHorizontalScrollView(
                                  controller: horizontalController,
                                  verticalParentController: scrollController,
                                  child: _createIssueTable(context),
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
                            BorderSide(color: OnepieceColors.menuHoverColor)),
                    enabledBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: OnepieceColors.menuHoverColor)),
                    focusedBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: OnepieceColors.fancyGreen)),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    labelText: AppLocalizations.of(context)!.title),
              ),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () => setState(() => _showFilters = !_showFilters),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 35,
              width: 35,
              decoration: BoxDecoration(
                  border: Border.all(color: OnepieceColors.menuHoverColor),
                  borderRadius: BorderRadius.circular(4),
                  color: _showFilters
                      ? OnepieceColors.fancyBlue.withValues(alpha: 0.1)
                      : null),
              child: Icon(Icons.filter_list,
                  size: 20,
                  color: _showFilters
                      ? OnepieceColors.fancyBlue
                      : Colors.grey[700]),
            ),
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
                          BorderSide(color: OnepieceColors.menuHoverColor)),
                  enabledBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: OnepieceColors.menuHoverColor)),
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
                          BorderSide(color: OnepieceColors.menuHoverColor)),
                  enabledBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: OnepieceColors.menuHoverColor)),
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
                    borderRadius: BorderRadius.circular(3),
                    color: OnepieceColors.liteFancyGreen)),
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
                          BorderSide(color: OnepieceColors.menuHoverColor)),
                  enabledBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: OnepieceColors.menuHoverColor)),
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
                          BorderSide(color: OnepieceColors.menuHoverColor)),
                  enabledBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: OnepieceColors.menuHoverColor)),
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
                          BorderSide(color: OnepieceColors.menuHoverColor)),
                  enabledBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: OnepieceColors.menuHoverColor)),
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

  // ── Mobile: card-based issue list ────────────────────────────────────

  Widget _buildMobileIssueCards(BuildContext context) {
    final typeMap = <IssueType, String>{
      IssueType.OTHER: AppLocalizations.of(context)!.otherType,
      IssueType.FEATURE_SUGGESTION:
          AppLocalizations.of(context)!.featureSuggestion,
      IssueType.BUG_REPORT: AppLocalizations.of(context)!.bugReport,
    };
    final statusMap = <IssueStatus, String>{
      IssueStatus.CREATED: AppLocalizations.of(context)!.statusCreated,
      IssueStatus.IN_PROGRESS: AppLocalizations.of(context)!.statusInProgress,
      IssueStatus.RESOLVED: AppLocalizations.of(context)!.statusResolved,
      IssueStatus.REVOKED: AppLocalizations.of(context)!.statusRevoked,
      IssueStatus.BACKLOGGED: AppLocalizations.of(context)!.statusBackLogged,
    };

    if (currentIssueList.isEmpty) {
      return Center(
          child: Text(AppLocalizations.of(context)!.empty,
              style: OnepieceFonts.contentStyle));
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: currentIssueList.length,
      itemBuilder: (context, index) {
        final issue = currentIssueList[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => context.goNamed('issueDetails',
                extra: issue.id, pathParameters: {'id': issue.id!}),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(issue.issueHeader.toString(),
                        style: OnepieceFonts.headerStyle.copyWith(fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: OnepieceColors.fancyBlue
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(typeMap[issue.issueType] ?? '',
                                style: OnepieceFonts.smallContentStyle.copyWith(
                                    color: OnepieceColors.fancyBlue,
                                    fontSize: 11)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: OnepieceColors.liteFancyGreen
                                    .withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(statusMap[issue.issueStatus] ?? '',
                                style: OnepieceFonts.smallContentStyle
                                    .copyWith(fontSize: 11)),
                          ),
                        ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      Text('${AppLocalizations.of(context)!.creatorEmail}: ',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      Expanded(
                          child: Text(issue.creationRecord!.nickname ?? '',
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)),
                    ]),
                    const SizedBox(height: 2),
                    Text(
                        DateHelper.getFormattedDatetimeFromTimestamp(
                            issue.creationRecord!.actionTimestamp!, context),
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey)),
                  ]),
            ),
          ),
        );
      },
    );
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
        label: Tooltip(
          message: AppLocalizations.of(context)!.resetSort,
          child: ImageHelper.getIconButtonFromSvg(
            'images/svgs/reset.svg',
            OnepieceColors.fancyBlue,
            25,
            25,
            () {
              sortKeys = [];
              sortableEnumToSortOrderMap = {
                IssueSortableFieldEnum.issueStatus: null,
                IssueSortableFieldEnum.issueType: null,
                IssueSortableFieldEnum.creationTimestamp: null,
                IssueSortableFieldEnum.modificationTimestamp: null,
              };
              _search(false);
            },
          ),
        ),
      ),
      _createSingleColumn(
          AppLocalizations.of(context)!.feedbackTitle, null, 200),
      _createSingleColumn(AppLocalizations.of(context)!.issueType,
          IssueSortableFieldEnum.issueType, 170),
      _createSingleColumn(AppLocalizations.of(context)!.status,
          IssueSortableFieldEnum.issueStatus, 150),
      _createSingleColumn(
          AppLocalizations.of(context)!.creatorEmail, null, 150),
      _createSingleColumn(
          AppLocalizations.of(context)!.creatorNickname, null, 150),
      _createSingleColumn(AppLocalizations.of(context)!.creationTime,
          IssueSortableFieldEnum.creationTimestamp, 160),
      _createSingleColumn(AppLocalizations.of(context)!.modificationTime,
          IssueSortableFieldEnum.modificationTimestamp, 160),
    ];
  }

  DataColumn _createSingleColumn(String displayText,
      IssueSortableFieldEnum? issueSortableFieldsEnum, double? width) {
    return DataColumn(
      label: InkWell(
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
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
                  style: sortableEnumToSortOrderMap[issueSortableFieldsEnum] ==
                          null
                      ? OnepieceFonts.tableHeaderStyle
                      : OnepieceFonts.selectedTableHeaderStyle,
                ),
                const SizedBox(
                  width: 10,
                ),
                if (issueSortableFieldsEnum != null)
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: ImageHelper.getSvgIconWithColor(
                      sortOrderToPath[
                          sortableEnumToSortOrderMap[issueSortableFieldsEnum]]!,
                      12,
                      12,
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
              context.goNamed('issueDetails',
                  extra: entry.value.id,
                  pathParameters: {'id': entry.value.id!});
            },
            cells: [
              _getDataCell("${entry.key + 1}", null),
              _getDataCell(entry.value.issueHeader.toString(), null),
              _getDataCell(
                  issueTypeToDisplayValue[entry.value.issueType]!, null),
              _getDataCell(
                  issueStatusToDisplayValue[entry.value.issueStatus]!, null),
              _getDataCell(entry.value.creationRecord!.username!, null),
              _getDataCell(entry.value.creationRecord!.nickname!, null),
              _getDataCell(
                  DateHelper.getFormattedDatetimeFromTimestamp(
                      entry.value.creationRecord!.actionTimestamp!, context),
                  null),
              _getDataCell(
                  DateHelper.getFormattedDatetimeFromTimestamp(
                      entry.value.modificationRecord!.actionTimestamp!,
                      context),
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
}
