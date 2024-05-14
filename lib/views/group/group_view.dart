import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/repository/group_dao.dart';
import 'package:openapi/api.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../constants/button_style.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../utils/base64_helper.dart';
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
    _search();
  }

  void _search() {
    groupFilter.languageCode = I18nHelper.getLanguageCode();
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
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.vertical,
        child: Scrollbar(
          thumbVisibility: true,
          controller: horizontalController,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: horizontalController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _createHeader(context),
                SizedBox(
                  width: 1200,
                  height: 50,
                  child: _createControlPanel(context),
                ),
                _createGroupTable(context),
                const SizedBox(
                  height: 15,
                ),
                if (totalPageNum > 1)
                  SizedBox(
                    width: 1200,
                    child: Center(child: _getPageFoot(context)),
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
      GroupCategory.worldGovernment:
          AppLocalizations.of(context)!.worldGovernment,
    };
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (PermissionCheck.checkPermission(
              getIt<User>().loginRoleResourcesPermissionMap,
              ResourceType.GROUP,
              Permission.CREATE))
            SizedBox(
              height: 35,
              child: Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: ElevatedButton(
                    onPressed: () {
                      context.goNamed("createGroup");
                    },
                    style: OnepieceButtonStyle.getDefaultStyle(),
                    child: Text(AppLocalizations.of(context)!.createGroup)),
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
                      borderSide: BorderSide(color: OnepieceColors.fancyGreen)),
                  prefixIcon: const Icon(Icons.search),
                  labelText: AppLocalizations.of(context)!.name,
                ),
              ),
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
                  borderRadius: BorderRadius.circular(3),
                  color: OnepieceColors.liteFancyGreen,
                ),
              ),
              menuItemStyleData: const MenuItemStyleData(
                height: 35,
              ),
              items: GroupCategory.values.map((GroupCategory groupCategory) {
                return DropdownMenuItem<GroupCategory>(
                  value: groupCategory,
                  enabled: false,
                  child: StatefulBuilder(
                    builder: (context, menuSetState) {
                      final isSelected =
                          selectedGroupCategories.contains(groupCategory);
                      return InkWell(
                        onTap: () {
                          isSelected
                              ? selectedGroupCategories.remove(groupCategory)
                              : selectedGroupCategories.add(groupCategory);
                          groupFilter.groupCategories = selectedGroupCategories;
                          // //This rebuilds the StatefulWidget to update the button's text
                          setState(() {});
                          //This rebuilds the dropdownMenu Widget to update the check mark
                          menuSetState(() {});
                          _search();
                        },
                        child: Container(
                          height: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 3.0),
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
      ),
      Row(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
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
                          groupFilter.onlySystem = true;
                        } else {
                          groupFilter.onlySystem = null;
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
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
            child: SizedBox(
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
                          groupFilter.onlySystem = false;
                        } else {
                          groupFilter.onlySystem = null;
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
          ),
        ],
      ),
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
              _search();
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
                  style: sortableEnumToSortOrderMap[groupSortableFieldsEnum] ==
                          null
                      ? OnepieceFonts.tableHeaderStyle
                      : OnepieceFonts.selectedTableHeaderStyle,
                ),
                if (groupSortableFieldsEnum != null)
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: ImageHelper.getSvgIconWithColor(
                      sortOrderToPath[
                          sortableEnumToSortOrderMap[groupSortableFieldsEnum]]!,
                      15,
                      15,
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
      GroupCategory.worldGovernment:
          AppLocalizations.of(context)!.worldGovernment,
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
                    child: ImageHelper.getRoundImageFrame(
                        40,
                        40,
                        1.5,
                        OnepieceColors.liteFancyBlue,
                        40,
                        Base64Helper.decode(entry.value.profileImage!))),
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
                    child: _createCharacterList(entry.value.characterInGroup),
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
                        child: ImageHelper.getRoundImageFrame(
                            40,
                            40,
                            1.5,
                            OnepieceColors.liteFancyBlue,
                            40,
                            Base64Helper.decode(character.profileImage!))),
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
