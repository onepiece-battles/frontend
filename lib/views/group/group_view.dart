import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/repository/group_dao.dart';
import 'package:openapi/api.dart';
import '../../l10n/app_localizations.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../../components/image_lazy_loader.dart';
import '../../constants/button_style.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../utils/data_validator.dart';
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
  TextEditingController pageNumberController = TextEditingController(text: "0");
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
  ScrollController controlBarController = ScrollController();
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
  bool preButtonEnabled = false;
  bool nextButtonEnabled = false;
  bool confirmButtonEnabled = false;

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
      setState(() {
        currentGroupList = value!.groups;
        if (currentGroupList.isEmpty) {
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
      });
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
            controller: mainController,
            scrollDirection: Axis.vertical,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _createHeader(context),
                SizedBox(
                    width: 1400,
                    height: 90,
                    child: Scrollbar(
                      controller: controlBarController,
                      trackVisibility: true,
                      thickness: 5,
                      child: SingleChildScrollView(
                        controller: controlBarController,
                        scrollDirection: Axis.horizontal,
                        child: _createControlPanel(context),
                      ),
                    )),
                Scrollbar(
                  controller: tableController,
                  trackVisibility: true,
                  thickness: 5,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _createGroupTable(context),
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
              ],
            ),
          )),
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
            color: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
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
                    child: ImageLazyLoader(
                        key: UniqueKey(),
                        uriProvider: () => entry.value.imageUri!,
                        width: 40,
                        borderWidth: 1.5,
                        borderRadios: 5)),
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
                              I18nHelper.getDisplayNameFromI18n(character.name!)
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

  Widget _createGroupList(List<Group> groups) {
    if (groups.isEmpty) {
      return const Text("");
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: groups
            .map((group) => InkWell(
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  onTap: () {
                    context.goNamed('groupDetails',
                        extra: group.id,
                        pathParameters: {
                          'name': I18nHelper.getDisplayNameFromI18n(group.name!)
                        });
                  },
                  child: Tooltip(
                    message: I18nHelper.getDisplayNameFromI18n(group.name),
                    preferBelow: false,
                    showDuration: const Duration(seconds: 1),
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                        child: ImageLazyLoader(
                            key: UniqueKey(),
                            uriProvider: () => group.imageUri!,
                            width: 40,
                            borderWidth: 1.5,
                            borderRadios: 3)),
                  ),
                ))
            .toList(),
      ),
    );
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
                  _search(false);
                },
          child: const Icon(Icons.arrow_back));
      ElevatedButton nextPage = ElevatedButton(
          style: OnepieceButtonStyle.getDefaultStyle(),
          onPressed: !nextButtonEnabled
              ? null
              : () {
                  selectedPageNum = selectedPageNum + 1;
                  _search(false);
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
                _search(false);
              },
        child: Text(
          AppLocalizations.of(context)!.jumpToPage,
          textAlign: TextAlign.left,
        ),
      );
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
