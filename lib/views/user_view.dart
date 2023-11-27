import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:openapi/api.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../constants/button_style.dart';
import '../constants/onepiece_colors.dart';
import '../constants/onepiece_fonts.dart';
import '../repository/user_dao.dart';
import '../utils/base64_helper.dart';
import '../utils/data_validator.dart';
import '../utils/image_helper.dart';

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
  TextEditingController pageNumberController = TextEditingController(text: "1");
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
    UserSortableFieldsEnum.name: null,
    UserSortableFieldsEnum.loginRole: null,
    UserSortableFieldsEnum.email: null,
  };
  List<UserRole> selectedUserRoles = [];
  ScrollController scrollController = ScrollController();

  int selectedPageIndex = 1;
  int pageNum = 0;
  int pageSize = 10;
  int totalSize = 0;
  bool preButtonEnabled = false;
  bool nextButtonEnabled = false;
  bool confirmButtonEnabled = false;

  bool onlyShowSystemResource = false;
  bool donNotShowSystemResource = false;

  @override
  void initState() {
    super.initState();
    _search();
  }

  void _search() {
    ListUsersRequest listUserRequest = ListUsersRequest(
        pageSize: pageSize,
        pageIndex: selectedPageIndex,
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
                  child: _createCharacterTable(context),
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
        AppLocalizations.of(context)!.character,
        style: OnepieceFonts.headerStyle,
      ),
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
                  userFilter.name = value;
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
              value: selectedUserRoles.isEmpty ? null : selectedUserRoles.last,
              hint: Text(
                AppLocalizations.of(context)!.characterTypeLabel,
                style: OnepieceFonts.dropDownItemStyle,
              ),
              onChanged: (value) {},
              selectedItemBuilder: (context) {
                return CharacterType.values.map(
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
                        onTap: () {
                          isSelected
                              ? selectedUserRoles.remove(userRole)
                              : selectedUserRoles.add(userRole);
                          userFilter.userRoles = selectedUserRoles;
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

  DataTable _createCharacterTable(BuildContext context) {
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
        label: ElevatedButton(
            style: OnepieceButtonStyle.getDefaultStyle(),
            onPressed: () {
              sortKeys = [];
              sortableEnumToSortOrderMap = {
                UserSortableFieldsEnum.name: null,
                UserSortableFieldsEnum.loginRole: null,
                UserSortableFieldsEnum.email: null,
              };
              _search();
            },
            child: Text(AppLocalizations.of(context)!.resetSort)),
      ),
      _createSingleColumn(
          AppLocalizations.of(context)!.name, UserSortableFieldsEnum.name),
      _createSingleColumn(AppLocalizations.of(context)!.fruitLimit,
          UserSortableFieldsEnum.email),
      _createSingleColumn("login role", UserSortableFieldsEnum.loginRole),
      _createSingleColumn("status", null),
    ];
  }

  DataColumn _createSingleColumn(
      String displayText, UserSortableFieldsEnum? userSortableFieldsEnum) {
    return DataColumn(
      label: InkWell(
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
                  _search();
                });
              },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5, 10, 0, 10),
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
              if (userSortableFieldsEnum != null)
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: ImageHelper.getSvgIconWithColor(
                    sortOrderToPath[
                        sortableEnumToSortOrderMap[userSortableFieldsEnum]]!,
                    15,
                    15,
                    sortableEnumToSortOrderMap[userSortableFieldsEnum] == null
                        ? Colors.grey
                        : OnepieceColors.themeColor,
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }

  List<DataRow> _createRows(BuildContext context) {
    Map<CharacterType, String> enumValueToDisplayValue =
        <CharacterType, String>{
      CharacterType.body: AppLocalizations.of(context)!.body,
      CharacterType.foot: AppLocalizations.of(context)!.leg,
      CharacterType.science: AppLocalizations.of(context)!.science,
      CharacterType.fist: AppLocalizations.of(context)!.fist,
      CharacterType.katana: AppLocalizations.of(context)!.katana,
      CharacterType.shooter: AppLocalizations.of(context)!.shoot
    };
    Map<bool, String> booleanToDisplayName = {
      true: AppLocalizations.of(context)!.yes,
      false: AppLocalizations.of(context)!.no
    };
    return currentUserList
        .map(
          (user) => DataRow(
            onSelectChanged: (value) {
              context.goNamed('userDetails',
                  extra: user.id, pathParameters: {'name': user.name});
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
                      child:
                          Image.memory(Base64Helper.decode(user.profileImage!)),
                    ),
                  ),
                ),
              ),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Text(user.name.toString()),
              )),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Text(user.email.toString()),
              )),
              DataCell(Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Text(enumValueToDisplayValue[user.loginRole]!),
              )),
            ],
          ),
        )
        .toList();
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
