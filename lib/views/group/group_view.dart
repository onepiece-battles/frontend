import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:openapi/api.dart';
import '../../l10n/app_localizations.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../../components/desktop_card_layout.dart';
import '../../components/page_foot.dart';
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

  void _search(bool filterChange) {
    groupFilter.languageCode = I18nHelper.getLanguageCode();
    if (filterChange) {
      selectedPageNum = 1;
    }
    ListGroupRequest listGroupRequest = ListGroupRequest(
        pageSize: itemCountPerPage,
        pageIndex: selectedPageNum,
        sortKeys: sortKeys,
        groupFilter: groupFilter);
    Future<ListGroupResponse?> listGroupResponse =
        _controller.listGroups(listGroupRequest);

    listGroupResponse.then((value) {
      if (!mounted) return;
      setState(() {
        currentGroupList = value!.groups;
        totalItemCount = value.totalSize!;
        totalPageNum = (totalItemCount / itemCountPerPage).ceil();
      });
    });
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
              padding: EdgeInsets.all(isNarrow ? 15 : 24),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _createHeader(context),
                    isNarrow
                        ? CompactFilterPanel(
                            child: _createControlPanel(context, isNarrow: true))
                        : DesktopFilterPanel(
                            child:
                                _createControlPanel(context, isNarrow: false)),
                    const SizedBox(height: 10),
                    Expanded(
                      child: GroupRoster(
                        groups: currentGroupList,
                        controller: mainController,
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
                              mainController.jumpTo(0);
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

  Widget _createHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
      child: Text(
        AppLocalizations.of(context)!.group,
        style: OnepieceFonts.headerStyle,
      ),
    );
  }

  Widget _createControlPanel(BuildContext context, {required bool isNarrow}) {
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

    if (isNarrow) {
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
                            BorderSide(color: OnepieceColors.separator)),
                    enabledBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: OnepieceColors.separator)),
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
            active: _showFilters,
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
                inactiveBgColor: OnepieceColors.surface,
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
                    borderRadius: BorderRadius.circular(10),
                    color: OnepieceColors.surface)),
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
                            groupFilter.groupCategories =
                                selectedGroupCategories;
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
                                    child: Text(enumValueToDisplayValue[gc]!,
                                        style: const TextStyle(fontSize: 16))),
                              ])));
                    })))
                .toList(),
          )),
        ],
      ]);
    }

    // Desktop
    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (PermissionCheck.checkPermission(
                  getIt<User>().loginRoleResourcesPermissionMap,
                  ResourceType.GROUP,
                  Permission.CREATE))
                SizedBox(
                  height: 35,
                  width: 120,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: ElevatedButton(
                        onPressed: () {
                          context.goNamed("createGroup");
                        },
                        style: OnepieceButtonStyle.getDefaultStyle(),
                        child: Text(AppLocalizations.of(context)!.create)),
                  ),
                ),
              Padding(
                padding: EdgeInsets.zero,
                child: SizedBox(
                  width: 200,
                  height: 35,
                  child: TextFormField(
                    controller: searchNameController,
                    onChanged: (value) {
                      groupFilter.name = value;
                      _search(true);
                    },
                    decoration: InputDecoration(
                      labelStyle: OnepieceFonts.dropDownItemStyle,
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      disabledBorder: const OutlineInputBorder(
                          borderSide:
                              BorderSide(color: OnepieceColors.separator)),
                      enabledBorder: const OutlineInputBorder(
                          borderSide:
                              BorderSide(color: OnepieceColors.separator)),
                      focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                              color: OnepieceColors.fancyGreen, width: 1.5)),
                      prefixIcon: const Icon(Icons.search),
                      labelText: AppLocalizations.of(context)!.name,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
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
                  inactiveBgColor: OnepieceColors.surface,
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
                      groupFilter.systemResource = null;
                      groupFilter.userId = null;
                    }
                    // show my resource
                    if (index == 1) {
                      groupFilter.systemResource = null;
                      groupFilter.userId = getIt<User>().id;
                    }
                    // only show system resource
                    if (index == 2) {
                      groupFilter.systemResource = true;
                      groupFilter.userId = null;
                    }
                    // do not show system resource
                    if (index == 3) {
                      groupFilter.systemResource = false;
                      groupFilter.userId = null;
                    }
                    _search(true);
                  },
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton2(
                  isExpanded: true,
                  value: selectedGroupCategories.isEmpty
                      ? null
                      : selectedGroupCategories.last,
                  hint: Text(
                    AppLocalizations.of(context)!.groupCategory,
                    style: OnepieceFonts.dropDownItemStyle,
                  ),
                  onChanged: (value) {},
                  selectedItemBuilder: (context) {
                    return GroupCategory.values.map(
                      (item) {
                        return Container(
                          alignment: AlignmentDirectional.center,
                          child: Text(
                            selectedGroupCategories
                                .map((selectedType) {
                                  return enumValueToDisplayValue[selectedType];
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
                    width: 240,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: OnepieceColors.surface,
                    ),
                  ),
                  menuItemStyleData: const MenuItemStyleData(
                    height: 35,
                  ),
                  items:
                      GroupCategory.values.map((GroupCategory groupCategory) {
                    return DropdownMenuItem<GroupCategory>(
                      value: groupCategory,
                      enabled: false,
                      child: StatefulBuilder(
                        builder: (context, menuSetState) {
                          final isSelected =
                              selectedGroupCategories.contains(groupCategory);
                          return InkWell(
                            hoverColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            onTap: () {
                              isSelected
                                  ? selectedGroupCategories
                                      .remove(groupCategory)
                                  : selectedGroupCategories.add(groupCategory);
                              groupFilter.groupCategories =
                                  selectedGroupCategories;
                              // //This rebuilds the StatefulWidget to update the button's text
                              setState(() {});
                              //This rebuilds the dropdownMenu Widget to update the check mark
                              menuSetState(() {});
                              _search(true);
                            },
                            child: Container(
                              height: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 3.0),
                              child: Row(
                                children: [
                                  if (isSelected)
                                    const Icon(Icons.check_box_outlined)
                                  else
                                    const Icon(Icons.check_box_outline_blank),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      enumValueToDisplayValue[groupCategory]!,
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
          )
        ]);
  }
}
