import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:one_piece_battles_flutter/components/image_lazy_loader.dart';
import 'package:openapi/api.dart';
import '../../l10n/app_localizations.dart';
import '../../constants/button_style.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../constants/onepiece_tag.dart';
import '../../repository/user_dao.dart';
import '../../utils/data_validator.dart';
import '../../utils/date_helper.dart';
import '../../utils/image_helper.dart';

GetIt getIt = GetIt.instance;

class UserView extends StatefulWidget {
  const UserView({super.key});

  @override
  State<UserView> createState() => _UserViewState();
}

class _UserViewState extends State<UserView> {
  Logger logger = Logger('UserView');
  TextEditingController searchNameController = TextEditingController();
  TextEditingController searchEmailController = TextEditingController();
  TextEditingController pageNumberController = TextEditingController(text: "0");
  UserFilter userFilter = UserFilter();
  List<User> currentUserList = [];
  List<UserSortableField> sortKeys = [];

  // sorting related fields
  Map<SortOrder?, String> sortOrderToPath = const {
    null: 'images/svgs/sort-solid.svg',
    SortOrder.ASC: 'images/svgs/sort-up-solid.svg',
    SortOrder.DESC: 'images/svgs/sort-down-solid.svg'
  };
  Map<UserSortableFieldsEnum, SortOrder?> sortableEnumToSortOrderMap = {
    UserSortableFieldsEnum.username: null,
    UserSortableFieldsEnum.loginRole: null,
    UserSortableFieldsEnum.nickname: null,
  };
  List<UserRole> selectedUserRoles = [];
  ScrollController scrollController = ScrollController();
  ScrollController horizontalController = ScrollController();

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
    _search(false);
  }

  void _search(bool filterChange) {
    if (filterChange) {
      selectedPageNum = 1;
    }
    ListUsersRequest listUserRequest = ListUsersRequest(
        pageSize: itemCountPerPage,
        pageIndex: selectedPageNum,
        sortKeys: sortKeys,
        userFilter: userFilter);
    Future<ListUsersResponse?> listUserResponse =
        getIt<UserDao>().listUser(listUserRequest);

    listUserResponse.then((value) {
      setState(() {
        currentUserList = value!.users;
        if (currentUserList.isEmpty) {
          pageNumberController.text = "0";
        } else {
          pageNumberController.text = selectedPageNum.toString();
        }
        totalItemCount = value.totalSize!;
        totalPageNum = (totalItemCount / 10).ceil();
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
            controller: scrollController,
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
                    _createHeader(context),
                    SizedBox(
                      width: 1500,
                      height: 50,
                      child: _createControlPanel(context),
                    ),
                    _createUserTable(context),
                    const SizedBox(
                      height: 15,
                    ),
                  ],
                ),
              ),
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
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 10, 20),
          child: Text(
            AppLocalizations.of(context)!.user,
            style: OnepieceFonts.headerStyle,
          ),
        ),
      ],
    );
  }

  Widget _createControlPanel(BuildContext context) {
    Map<UserRole, String> enumValueToDisplayValue = <UserRole, String>{
      UserRole.NIKA: AppLocalizations.of(context)!.roleNika,
      UserRole.ADMIN: AppLocalizations.of(context)!.roleAdmin,
      UserRole.NORMAL: AppLocalizations.of(context)!.roleNormal,
      UserRole.VISITOR: AppLocalizations.of(context)!.roleVisitor,
    };
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 6, 0),
            child: SizedBox(
              width: 230,
              height: 35,
              child: TextFormField(
                controller: searchNameController,
                onChanged: (value) {
                  userFilter.nickname = value;
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
                  labelText: AppLocalizations.of(context)!.name,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 6, 0),
            child: SizedBox(
              width: 230,
              height: 35,
              child: TextFormField(
                controller: searchEmailController,
                onChanged: (value) {
                  userFilter.username = value;
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
                  labelText: AppLocalizations.of(context)!.email,
                ),
              ),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton2(
              isExpanded: true,
              value: selectedUserRoles.isEmpty ? null : selectedUserRoles.last,
              hint: Text(
                AppLocalizations.of(context)!.loginRole,
                style: OnepieceFonts.dropDownItemStyle,
              ),
              onChanged: (value) {},
              selectedItemBuilder: (context) {
                return UserRole.values.map(
                  (item) {
                    return Container(
                      alignment: AlignmentDirectional.center,
                      child: Text(
                        selectedUserRoles
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
                width: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: OnepieceColors.liteFancyGreen,
                ),
              ),
              menuItemStyleData: const MenuItemStyleData(
                height: 35,
              ),
              items: UserRole.values.map((UserRole userRole) {
                return DropdownMenuItem<UserRole>(
                  value: userRole,
                  enabled: false,
                  child: StatefulBuilder(
                    builder: (context, menuSetState) {
                      final isSelected = selectedUserRoles.contains(userRole);
                      return InkWell(
                        hoverColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        onTap: () {
                          isSelected
                              ? selectedUserRoles.remove(userRole)
                              : selectedUserRoles.add(userRole);
                          userFilter.userRoles = selectedUserRoles;
                          // //This rebuilds the StatefulWidget to update the button's text
                          setState(() {});
                          //This rebuilds the dropdownMenu Widget to update the check mark
                          menuSetState(() {});
                          _search(true);
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
                                  enumValueToDisplayValue[userRole]!,
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

  DataTable _createUserTable(BuildContext context) {
    return DataTable(
      showCheckboxColumn: false,
      showBottomBorder: true,
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
                UserSortableFieldsEnum.nickname: null,
                UserSortableFieldsEnum.username: null,
                UserSortableFieldsEnum.loginRole: null,
              };
              _search(false);
            },
          ),
        ),
      ),
      _createSingleColumn(AppLocalizations.of(context)!.name, null, 120),
      _createSingleColumn(AppLocalizations.of(context)!.email,
          UserSortableFieldsEnum.username, 130),
      _createSingleColumn(AppLocalizations.of(context)!.emailStatus, null, 120),
      _createSingleColumn(
          AppLocalizations.of(context)!.accountStatus, null, 150),
      _createSingleColumn(AppLocalizations.of(context)!.loginRole, null, null),
      _createSingleColumn(
          AppLocalizations.of(context)!.allUserRoles, null, 280),
      _createSingleColumn(
          AppLocalizations.of(context)!.creationTime, null, 150),
      _createSingleColumn(
          AppLocalizations.of(context)!.modificationTime, null, 150),
    ];
  }

  DataColumn _createSingleColumn(String displayText,
      UserSortableFieldsEnum? userSortableFieldsEnum, double? width) {
    return DataColumn(
      label: InkWell(
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        onTap: userSortableFieldsEnum == null
            ? null
            : () {
                setState(() {
                  var sortOrder =
                      sortableEnumToSortOrderMap[userSortableFieldsEnum];
                  var sortKey = userSortableFieldsEnum;
                  if (sortOrder == null) {
                    sortOrder = SortOrder.ASC;
                  } else if (sortOrder == SortOrder.ASC) {
                    sortOrder = SortOrder.DESC;
                  } else {
                    sortOrder = null;
                  }
                  sortableEnumToSortOrderMap[userSortableFieldsEnum] =
                      sortOrder;
                  sortKeys.removeWhere((element) => element.sortKey == sortKey);
                  if (sortOrder != null) {
                    sortKeys.insert(
                        0,
                        UserSortableField(
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
                  style:
                      sortableEnumToSortOrderMap[userSortableFieldsEnum] == null
                          ? OnepieceFonts.tableHeaderStyle
                          : OnepieceFonts.selectedTableHeaderStyle,
                ),
                const SizedBox(
                  width: 10,
                ),
                if (userSortableFieldsEnum != null)
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: ImageHelper.getSvgIconWithColor(
                      sortOrderToPath[
                          sortableEnumToSortOrderMap[userSortableFieldsEnum]]!,
                      12,
                      12,
                      sortableEnumToSortOrderMap[userSortableFieldsEnum] == null
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
    Map<UserRole, String> userRoleToDisplayNameMap = {
      UserRole.NIKA: AppLocalizations.of(context)!.roleNika,
      UserRole.NORMAL: AppLocalizations.of(context)!.roleNormal,
      UserRole.VISITOR: AppLocalizations.of(context)!.roleVisitor,
      UserRole.ADMIN: AppLocalizations.of(context)!.roleAdmin
    };
    Map<AccountStatus, String> accountStatusEnumToDisplayValue = {
      AccountStatus.loggedIn: AppLocalizations.of(context)!.accountLoggedIn,
      AccountStatus.loggedOut: AppLocalizations.of(context)!.accountLoggedOut,
      AccountStatus.stopped: AppLocalizations.of(context)!.accountStopped,
      AccountStatus.closed: AppLocalizations.of(context)!.accountClosed,
    };
    Map<bool, Widget> boolToEmailRowMap = {
      true: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.verified,
            style: const TextStyle(color: Colors.greenAccent),
          ),
          const Icon(
            Icons.check,
            color: Colors.greenAccent,
            size: 20,
          )
        ],
      ),
      false: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.notVerified,
            style: const TextStyle(color: Colors.redAccent),
          ),
          const Icon(
            Icons.cancel,
            color: Colors.redAccent,
            size: 20,
          )
        ],
      )
    };
    return currentUserList
        .map(
          (user) => DataRow(
            onSelectChanged: (value) {
              context.goNamed('userDetails',
                  extra: user.id, pathParameters: {'name': user.nickname});
            },
            cells: [
              DataCell(
                Padding(
                    padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                    child: ImageLazyLoader(
                        key: UniqueKey(),
                        uriProvider: () => user.imageUri!,
                        width: 40,
                        borderWidth: 1.5,
                        borderRadios: 40)),
              ),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Text(user.nickname.toString()),
              )),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Text(user.username.toString()),
              )),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: boolToEmailRowMap[user.emailVerified],
              )),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child:
                    Text(accountStatusEnumToDisplayValue[user.accountStatus]!),
              )),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: OnepieceTag.getUserRoleTag(
                    user.loginRole!, userRoleToDisplayNameMap[user.loginRole]!),
              )),
              DataCell(
                Padding(
                  padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                  child: Row(
                    children: user.userRoles
                        .map((e) => Padding(
                              padding: const EdgeInsets.only(right: 5),
                              child: OnepieceTag.getUserRoleTag(
                                  e, userRoleToDisplayNameMap[e]!),
                            ))
                        .toList(),
                  ),
                ),
              ),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Text(DateHelper.getFormattedDatetimeFromTimestamp(
                    user.modificationRecord!.actionTimestamp!, context)),
              )),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Text(DateHelper.getFormattedDatetimeFromTimestamp(
                    user.creationRecord!.actionTimestamp!, context)),
              )),
            ],
          ),
        )
        .toList();
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
