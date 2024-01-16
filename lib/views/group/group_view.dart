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

GetIt getIt = GetIt.instance;

class GroupView extends StatefulWidget {
  const GroupView({Key? key}) : super(key: key);

  @override
  State<GroupView> createState() => _GroupViewState();
}

class _GroupViewState extends State<GroupView> {
  ScrollController scrollController = ScrollController();
  TextEditingController searchNameController = TextEditingController();
  TextEditingController pageNumberController = TextEditingController(text: "1");
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
    groupFilter.languageCode = I18nHelper.getLanguageCode();
    ListGroupRequest listGroupRequest = ListGroupRequest(
        pageSize: pageSize,
        pageIndex: selectedPageIndex,
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
                  child: _createGroupTable(context),
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
                return CharacterType.values.map(
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
                width: 200,
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
          SizedBox(
            height: 35,
            child: Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: ElevatedButton(
                  onPressed: () {
                    context.goNamed("createGroup");
                  },
                  style: OnepieceButtonStyle.getDefaultStyle(),
                  child: Text(AppLocalizations.of(context)!.createGroup)),
            ),
          )
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
      columnSpacing: 10,
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
                GroupSortableFieldsEnum.name: null,
                GroupSortableFieldsEnum.category: null,
              };
              _search();
            },
            child: Text(AppLocalizations.of(context)!.resetSort)),
      ),
      _createSingleColumn(AppLocalizations.of(context)!.name,
          GroupSortableFieldsEnum.name, 120),
      _createSingleColumn(AppLocalizations.of(context)!.category,
          GroupSortableFieldsEnum.category, 120),
      _createSingleColumn(AppLocalizations.of(context)!.creator, null, 100),
      _createSingleColumn(AppLocalizations.of(context)!.character, null, 600),
      _createSingleColumn(
          AppLocalizations.of(context)!.createdBySystem, null, 130),
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
    Map<bool, String> booleanToDisplayName = {
      true: AppLocalizations.of(context)!.yes,
      false: AppLocalizations.of(context)!.no
    };
    return currentGroupList
        .map(
          (group) => DataRow(
            onSelectChanged: (value) {
              context.goNamed('groupDetails', extra: group.id, pathParameters: {
                'name': I18nHelper.getDisplayNameFromI18n(group.name)
              });
            },
            cells: [
              DataCell(
                Padding(
                  padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.all(Radius.circular(2.0)),
                      border: Border.all(
                          color: Colors.grey,
                          width: 2,
                          style: BorderStyle.solid),
                    ),
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: group.profileImage == null
                          ? Container()
                          : Image.memory(
                              Base64Helper.decode(group.profileImage!)),
                    ),
                  ),
                ),
              ),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Text(I18nHelper.getDisplayNameFromI18n(group.name)),
              )),
              DataCell(Padding(
                  padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                  child: Text(enumValueToDisplayValue[group.groupCategory!]!))),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Text(group.creator!),
              )),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: _createCharacterList(group.characters),
              )),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Text(
                    booleanToDisplayName[group.roleName == UserRole.NIKA]!),
              )),
            ],
          ),
        )
        .toList();
  }

  Widget _createCharacterList(List<CharacterInGroupLite> character) {
    if (character.isEmpty) {
      return const Text("");
    }
    return ListView.builder(itemBuilder: (context, index) {
      CharacterInGroupLite currentCharacter = character[index];
      return Material(
        type: MaterialType.transparency,
        child: Container(
          padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
          decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(5))),
          child: ListTile(
            minLeadingWidth: 10,
            contentPadding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            onTap: () {
              setState(
                () {
                  GoRouter.of(context).goNamed('characterDetails',
                      extra: currentCharacter.id,
                      pathParameters: {
                        'name': I18nHelper.getDisplayNameFromI18n(
                            currentCharacter.name)
                      });
                },
              );
            },
            hoverColor: OnepieceColors.liteFancyBlue,
            title: Row(
              children: [
                SizedBox(
                  width: 200,
                  child: Text(
                    I18nHelper.getDisplayNameFromI18n(currentCharacter.name),
                  ),
                ),
                SizedBox(width: 250, child: Text(currentCharacter.position!)),
                if (currentCharacter.onceBelongedTo!)
                  Text("(${AppLocalizations.of(context)!.leaved})"),
              ],
            ),
          ),
        ),
      );
    });
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
