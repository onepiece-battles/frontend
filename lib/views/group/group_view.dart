import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:openapi/api.dart';
import '../../l10n/app_localizations.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../../components/desktop_card_layout.dart';
import '../../components/resource_loading.dart';
import '../../components/resource_list_load_more.dart';
import '../../constants/button_style.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../utils/i18n_helper.dart';
import '../../utils/responsive_breakpoints.dart';
import '../../utils/permission_check.dart';
import '../../utils/route_notifier.dart';
import 'group_list_controller.dart';
import 'widgets/group_roster.dart';

GetIt getIt = GetIt.instance;

class GroupView extends StatefulWidget {
  const GroupView({Key? key}) : super(key: key);

  @override
  State<GroupView> createState() => _GroupViewState();
}

class _GroupViewState extends State<GroupView> {
  final GroupListController _controller = GroupListController();
  TextEditingController searchNameController = TextEditingController();
  GroupFilter groupFilter = GroupFilter();
  List<GroupListView> currentGroupList = [];
  List<GroupSortableField> sortKeys = [];

  ScrollController mainController = ScrollController();
  int initialLabelIndex = 0;
  bool _showFilters = false;
  // group filter options

  List<GroupCategory> selectedGroupCategories = [];

  int selectedPageNum = 1;
  int totalPageNum = 0;
  int itemCountPerPage = 24;
  int totalItemCount = 0;

  @override
  void initState() {
    super.initState();
    mainController.addListener(_maybeLoadMore);
    routeNotifier.addListener(_refreshWhenListRouteIsActive);
    _search(false);
  }

  @override
  void dispose() {
    routeNotifier.removeListener(_refreshWhenListRouteIsActive);
    mainController.dispose();
    searchNameController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _refreshWhenListRouteIsActive() {
    if (routeNotifier.value ==
        '/home/${ResourceType.GROUP.toString().toLowerCase()}') {
      _search(false);
    }
  }

  bool _loading = true;
  bool _loadFailed = false;
  bool _loadingMore = false;
  bool _loadMoreFailed = false;
  int _requestId = 0;

  Future<void> _search(bool filterChange) async {
    final requestId = ++_requestId;
    if (mainController.hasClients) mainController.jumpTo(0);
    setState(() {
      _loading = true;
      _loadFailed = false;
      _loadingMore = false;
      _loadMoreFailed = false;
      selectedPageNum = 1;
      currentGroupList = [];
    });
    groupFilter.languageCode = I18nHelper.getLanguageCode();
    final request = ListGroupRequest(
        pageSize: itemCountPerPage,
        pageIndex: selectedPageNum,
        sortKeys: sortKeys,
        groupFilter: groupFilter);
    try {
      final value = await _controller.listGroups(request);
      if (!mounted || requestId != _requestId) return;
      if (value == null) {
        throw StateError('Resource request returned no response');
      }
      setState(() {
        currentGroupList = value.groups;
        totalItemCount = value.totalSize ?? 0;
        totalPageNum = (totalItemCount / itemCountPerPage).ceil();
        _loading = false;
      });
      _checkForShortViewport();
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  void _maybeLoadMore() {
    if (!mainController.hasClients ||
        _loading ||
        _loadingMore ||
        _loadMoreFailed ||
        selectedPageNum >= totalPageNum) {
      return;
    }
    if (mainController.position.extentAfter < 500) {
      _loadMore();
    }
  }

  void _checkForShortViewport() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeLoadMore();
    });
  }

  Future<void> _loadMore() async {
    final requestId = _requestId;
    final nextPage = selectedPageNum + 1;
    setState(() {
      _loadingMore = true;
      _loadMoreFailed = false;
    });
    final request = ListGroupRequest(
        pageSize: itemCountPerPage,
        pageIndex: nextPage,
        sortKeys: sortKeys,
        groupFilter: groupFilter);
    try {
      final value = await _controller.listGroups(request);
      if (!mounted || requestId != _requestId) return;
      if (value == null) {
        throw StateError('Resource request returned no response');
      }
      setState(() {
        final seen = currentGroupList.map((item) => item.id).toSet();
        currentGroupList
            .addAll(value.groups.where((item) => seen.add(item.id)));
        selectedPageNum = nextPage;
        totalItemCount = value.totalSize ?? totalItemCount;
        totalPageNum = value.groups.isEmpty
            ? nextPage
            : (totalItemCount / itemCountPerPage).ceil();
        _loadingMore = false;
      });
      _checkForShortViewport();
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loadingMore = false;
        _loadMoreFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < ResponsiveBreakpoints.tabletMax;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: double.infinity),
            child: Padding(
              padding: EdgeInsets.all(isNarrow ? 8 : 12),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _createHeader(context),
                    CompactFilterPanel(child: _createControlPanel(context)),
                    const SizedBox(height: 6),
                    Expanded(
                      child: ResourceListBody(
                        loading: _loading,
                        failed: _loadFailed,
                        hasItems: currentGroupList.isNotEmpty,
                        onRetry: () => _search(false),
                        child: GroupRoster(
                          groups: currentGroupList,
                          controller: mainController,
                          isNarrow: isNarrow,
                          footer: selectedPageNum < totalPageNum
                              ? ResourceListLoadMore(
                                  loading: _loadingMore,
                                  failed: _loadMoreFailed,
                                  onRetry: _loadMore)
                              : null,
                        ),
                      ),
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

  Widget _createHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        AppLocalizations.of(context)!.group,
        style: OnepieceFonts.headerStyle.copyWith(fontSize: 20),
      ),
    );
  }

  Widget _createControlPanel(BuildContext context) {
    Map<GroupCategory, String> enumValueToDisplayValue =
        <GroupCategory, String>{
      GroupCategory.marine: AppLocalizations.of(context)!.marine,
      GroupCategory.pirate: AppLocalizations.of(context)!.pirate,
      GroupCategory.underWorld: AppLocalizations.of(context)!.underworld,
      GroupCategory.government: AppLocalizations.of(context)!.worldGovernment,
      GroupCategory.group: AppLocalizations.of(context)!.group,
      GroupCategory.other: AppLocalizations.of(context)!.otherType,
      GroupCategory.revolutionArmy:
          AppLocalizations.of(context)!.revolutionaryArmy,
    };
    final hasCreate = PermissionCheck.checkPermission(
        getIt<User>().loginRoleResourcesPermissionMap,
        ResourceType.GROUP,
        Permission.CREATE);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        if (hasCreate)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: SizedBox(
              height: 35,
              child: ElevatedButton(
                  onPressed: () => context.goNamed("createGroup"),
                  style: OnepieceButtonStyle.getDefaultStyle(),
                  child: Text(AppLocalizations.of(context)!.create,
                      style: const TextStyle(fontSize: 13))),
            ),
          ),
        Expanded(
          child: SizedBox(
            height: 35,
            child: TextFormField(
              controller: searchNameController,
              onChanged: (v) {
                groupFilter.name = v;
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
                      borderSide: BorderSide(
                          color: OnepieceColors.fancyGreen, width: 1.5)),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  labelText: AppLocalizations.of(context)!.name,
                  labelStyle: OnepieceFonts.dropDownItemStyle),
            ),
          ),
        ),
        const SizedBox(width: 6),
        ListFilterButton(
          active: _showFilters ||
              initialLabelIndex != 0 ||
              selectedGroupCategories.isNotEmpty,
          onPressed: () => setState(() => _showFilters = !_showFilters),
        ),
      ]),
      if (_showFilters) ...[
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            height: 36,
            child: ToggleSwitch(
              customWidths: const [90, 90, 100, 120],
              cornerRadius: 4,
              minHeight: 35,
              fontSize: 12,
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
                if (index == 0) {
                  groupFilter.systemResource = null;
                  groupFilter.userId = null;
                }
                if (index == 1) {
                  groupFilter.systemResource = null;
                  groupFilter.userId = getIt<User>().id;
                }
                if (index == 2) {
                  groupFilter.systemResource = true;
                  groupFilter.userId = null;
                }
                if (index == 3) {
                  groupFilter.systemResource = false;
                  groupFilter.userId = null;
                }
                _search(true);
              },
            ),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonHideUnderline(
            child: DropdownButton2(
          isExpanded: true,
          value: selectedGroupCategories.isEmpty
              ? null
              : selectedGroupCategories.last,
          hint: Text(AppLocalizations.of(context)!.groupCategory,
              style: OnepieceFonts.dropDownItemStyle),
          onChanged: (value) {},
          selectedItemBuilder: (context) => GroupCategory.values
              .map((item) => Container(
                  alignment: AlignmentDirectional.center,
                  child: Text(
                      selectedGroupCategories
                          .map((t) => enumValueToDisplayValue[t])
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
          items: GroupCategory.values
              .map((gc) => DropdownMenuItem<GroupCategory>(
                  value: gc,
                  enabled: false,
                  child: StatefulBuilder(builder: (ctx, ms) {
                    final sel = selectedGroupCategories.contains(gc);
                    return InkWell(
                        hoverColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        onTap: () {
                          sel
                              ? selectedGroupCategories.remove(gc)
                              : selectedGroupCategories.add(gc);
                          groupFilter.groupCategories = selectedGroupCategories;
                          setState(() {});
                          ms(() {});
                          _search(true);
                        },
                        child: Container(
                            height: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Row(children: [
                              Icon(sel
                                  ? Icons.check_box_outlined
                                  : Icons.check_box_outline_blank),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(enumValueToDisplayValue[gc]!,
                                      style: const TextStyle(fontSize: 16))),
                            ])));
                  })))
              .toList(),
        )),
      ],
    ]);
  }
}
