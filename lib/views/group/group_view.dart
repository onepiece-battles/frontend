import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/repository/group_dao.dart';
import 'package:openapi/api.dart';
import '../../l10n/app_localizations.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../../components/image_lazy_loader.dart';
import '../../components/page_foot.dart';
import '../../constants/button_style.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../utils/i18n_helper.dart';
import '../../utils/image_helper.dart';
import '../../utils/permission_check.dart';

GetIt getIt = GetIt.instance;

class GroupView extends StatefulWidget {
  const GroupView({Key? key}) : super(key: key);

  @override
  State<GroupView> createState() => _GroupViewState();
}

class _GroupViewState extends State<GroupView> {
  ScrollController scrollController = ScrollController();
  ScrollController horizontalController = ScrollController();
  TextEditingController searchNameController = TextEditingController();
  GroupFilter groupFilter = GroupFilter();
  List<GroupListView> currentGroupList = [];
  List<GroupSortableField> sortKeys = [];

  // group sorting options
  Map<SortOrder?, String> sortOrderToPath = const {
    null: 'images/svgs/sort-solid.svg',
    SortOrder.ASC: 'images/svgs/sort-up-solid.svg',
    SortOrder.DESC: 'images/svgs/sort-down-solid.svg'
  };
  Map<GroupSortableFieldsEnum, SortOrder?> sortableEnumToSortOrderMap = {
    GroupSortableFieldsEnum.name: null,
    GroupSortableFieldsEnum.category: null,
  };
  ScrollController mainController = ScrollController();
  ScrollController tableController = ScrollController();
  int initialLabelIndex = 0;
  // group filter options

  List<GroupCategory> selectedGroupCategories = [];

  bool onlyShowSystemResource = false;
  bool donNotShowSystemResource = false;

  int selectedPageNum = 1;
  int totalPageNum = 0;
  int itemCountPerPage = 10;
  int totalItemCount = 0;

  @override
  void initState() {
    super.initState();
    _search(false);
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
        getIt<GroupDao>().listGroups(listGroupRequest);

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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _createHeader(context),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    height: 90,
                    child: _createControlPanel(context),
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
                          child: _createGroupTable(context),
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
    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
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
                padding: const EdgeInsets.fromLTRB(0, 0, 6, 0),
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
                              BorderSide(color: OnepieceColors.menuHoverColor)),
                      enabledBorder: const OutlineInputBorder(
                          borderSide:
                              BorderSide(color: OnepieceColors.menuHoverColor)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
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
              const SizedBox(
                width: 10,
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
                      borderRadius: BorderRadius.circular(3),
                      color: OnepieceColors.liteFancyGreen,
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

  DataTable _createGroupTable(BuildContext context) {
    return DataTable(
      showCheckboxColumn: false,
      showBottomBorder: true,
      headingRowHeight: 50,
      border: const TableBorder(
          top: BorderSide(color: OnepieceColors.themeColor),
          bottom: BorderSide(color: OnepieceColors.themeColor)),
      columns: _createColumns(),
      rows: _createRows(context),
      columnSpacing: 15,
    );
  }

  List<DataColumn> _createColumns() {
    return [
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
              // filter will not be cleared
              sortKeys = [];
              sortableEnumToSortOrderMap = {
                GroupSortableFieldsEnum.name: null,
                GroupSortableFieldsEnum.category: null,
              };
              _search(true);
            },
          ),
        ),
      ),
      _createSingleColumn(AppLocalizations.of(context)!.name, null, 120),
      _createSingleColumn(AppLocalizations.of(context)!.category, null, 120),
      _createSingleColumn(AppLocalizations.of(context)!.creator, null, 100),
      _createSingleColumn(AppLocalizations.of(context)!.member, null, 600),
    ];
  }

  DataColumn _createSingleColumn(String displayText,
      GroupSortableFieldsEnum? groupSortableFieldsEnum, double? width) {
    return DataColumn(
      label: InkWell(
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        onTap: groupSortableFieldsEnum == null
            ? null
            : () {
                setState(() {
                  var sortOrder =
                      sortableEnumToSortOrderMap[groupSortableFieldsEnum];
                  var sortKey = groupSortableFieldsEnum;
                  if (sortOrder == null) {
                    sortOrder = SortOrder.ASC;
                  } else if (sortOrder == SortOrder.ASC) {
                    sortOrder = SortOrder.DESC;
                  } else {
                    sortOrder = null;
                  }
                  sortableEnumToSortOrderMap[groupSortableFieldsEnum] =
                      sortOrder;
                  sortKeys.removeWhere((element) => element.sortKey == sortKey);
                  if (sortOrder != null) {
                    sortKeys.insert(
                        0,
                        GroupSortableField(
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
                  style: sortableEnumToSortOrderMap[groupSortableFieldsEnum] ==
                          null
                      ? OnepieceFonts.tableHeaderStyle
                      : OnepieceFonts.selectedTableHeaderStyle,
                ),
                const SizedBox(
                  width: 10,
                ),
                if (groupSortableFieldsEnum != null)
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: ImageHelper.getSvgIconWithColor(
                      sortOrderToPath[
                          sortableEnumToSortOrderMap[groupSortableFieldsEnum]]!,
                      12,
                      12,
                      sortableEnumToSortOrderMap[groupSortableFieldsEnum] ==
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
    return currentGroupList
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
              context.goNamed('groupDetails',
                  extra: entry.value.id,
                  pathParameters: {
                    'name': I18nHelper.getDisplayNameFromI18n(entry.value.name)
                  });
            },
            cells: [
              DataCell(
                Padding(
                    padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                    child: RepaintBoundary(
                      child: ImageLazyLoader(
                          key: ValueKey(entry.value.imageUri),
                          uriProvider: () => entry.value.imageUri!,
                          width: 40,
                          borderWidth: 1.5,
                          borderRadios: 5,
                          lazy: true),
                    )),
              ),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child:
                    Text(I18nHelper.getDisplayNameFromI18n(entry.value.name)),
              )),
              DataCell(Padding(
                  padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                  child: Text(
                      enumValueToDisplayValue[entry.value.groupCategory!]!))),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Text(entry.value.creationRecord!.nickname!),
              )),
              DataCell(
                Padding(
                  padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                  child: SizedBox(
                    width: 700,
                    child: entry.value.groupCategory == GroupCategory.group
                        ? _createGroupList(entry.value.subGroups)
                        : _createCharacterList(entry.value.characterInGroup),
                  ),
                ),
              ),
            ],
          ),
        )
        .toList();
  }

  Widget _createCharacterList(List<CharacterInGroupLite> characters) {
    if (characters.isEmpty) {
      return const Text("");
    }
    // 使用 ListView.builder 替代 SingleChildScrollView + Row
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: characters.length,
      // 提升滑动性能
      physics: const ClampingScrollPhysics(),
      itemBuilder: (context, index) {
        final character = characters[index];
        return InkWell(
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          onTap: () {
            context.goNamed('characterDetails',
                extra: character.id,
                pathParameters: {
                  'name': I18nHelper.getDisplayNameFromI18n(character.name!)
                });
          },
          child: Tooltip(
            message: I18nHelper.getDisplayNameFromI18n(character.name),
            preferBelow: false,
            showDuration: const Duration(seconds: 1),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
              child: RepaintBoundary(
                child: ImageLazyLoader(
                    key: ValueKey(character.imageUri),
                    uriProvider: () => character.imageUri!,
                    width: 40,
                    borderWidth: 1.5,
                    borderRadios: 40,
                    lazy: true),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _createGroupList(List<Group> groups) {
    if (groups.isEmpty) {
      return const Text("");
    }
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: groups.length,
      physics: const ClampingScrollPhysics(),
      itemBuilder: (context, index) {
        final group = groups[index];
        return InkWell(
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          onTap: () {
            context.goNamed('groupDetails', extra: group.id, pathParameters: {
              'name': I18nHelper.getDisplayNameFromI18n(group.name!)
            });
          },
          child: Tooltip(
            message: I18nHelper.getDisplayNameFromI18n(group.name),
            preferBelow: false,
            showDuration: const Duration(seconds: 1),
            child: Padding(
                padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                child: RepaintBoundary(
                  child: ImageLazyLoader(
                      key: ValueKey(group.imageUri),
                      uriProvider: () => group.imageUri!,
                      width: 40,
                      borderWidth: 1.5,
                      borderRadios: 3,
                      lazy: true),
                )),
          ),
        );
      },
    );
  }
}
