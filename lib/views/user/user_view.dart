import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import '../../components/desktop_card_layout.dart';
import '../../components/page_foot.dart';
import 'package:openapi/api.dart';
import '../../l10n/app_localizations.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../utils/responsive_breakpoints.dart';
import 'user_list_controller.dart';
import 'widgets/user_roster.dart';

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
  UserFilter userFilter = UserFilter();
  List<User> currentUserList = [];
  List<UserSortableField> sortKeys = [];
  final UserListController _controller = UserListController();

  Map<UserSortableFieldsEnum, SortOrder?> sortableEnumToSortOrderMap = {
    UserSortableFieldsEnum.username: null,
    UserSortableFieldsEnum.loginRole: null,
    UserSortableFieldsEnum.nickname: null,
  };
  List<UserRole> selectedUserRoles = [];
  ScrollController scrollController = ScrollController();

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
    searchNameController.dispose();
    scrollController.dispose();
    _controller.dispose();
    super.dispose();
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

    _controller.listUser(listUserRequest).then((value) {
      if (!mounted) return;
      setState(() {
        currentUserList = value?.users ?? [];
        totalItemCount = value?.totalSize ?? 0;
        totalPageNum = (totalItemCount / itemCountPerPage).ceil();
      });
    }).catchError((error, stackTrace) {
      logger.severe('Failed to fetch user list', error, stackTrace);
      if (!mounted) return;
      setState(() {
        currentUserList = [];
        totalItemCount = 0;
        totalPageNum = 0;
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
                  children: [
                    _createHeader(context),
                    isNarrow
                        ? CompactFilterPanel(
                            child: _createControlPanel(context, isNarrow: true))
                        : DesktopFilterPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _createControlPanel(context, isNarrow: false),
                                const SizedBox(height: 10),
                                _buildUserSortControls(context),
                              ],
                            ),
                          ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: UserRoster(
                        users: currentUserList,
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

  Widget _createControlPanel(BuildContext context, {required bool isNarrow}) {
    Map<UserRole, String> enumValueToDisplayValue = <UserRole, String>{
      UserRole.NIKA: AppLocalizations.of(context)!.roleNika,
      UserRole.ADMIN: AppLocalizations.of(context)!.roleAdmin,
      UserRole.NORMAL: AppLocalizations.of(context)!.roleNormal,
      UserRole.VISITOR: AppLocalizations.of(context)!.roleVisitor,
    };

    if (isNarrow) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: SizedBox(
              height: 35,
              child: TextFormField(
                controller: searchNameController,
                onChanged: (v) {
                  userFilter.nickname = v;
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
                    labelText: AppLocalizations.of(context)!.name),
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
                userFilter.username = v;
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
                  labelText: AppLocalizations.of(context)!.email),
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonHideUnderline(
              child: DropdownButton2(
            isExpanded: true,
            value: selectedUserRoles.isEmpty ? null : selectedUserRoles.last,
            hint: Text(AppLocalizations.of(context)!.loginRole,
                style: OnepieceFonts.dropDownItemStyle),
            onChanged: (value) {},
            selectedItemBuilder: (context) => UserRole.values
                .map((item) => Container(
                    alignment: AlignmentDirectional.center,
                    child: Text(
                        selectedUserRoles
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
            items: UserRole.values
                .map((role) => DropdownMenuItem<UserRole>(
                    value: role,
                    enabled: false,
                    child: StatefulBuilder(builder: (ctx, ms) {
                      final sel = selectedUserRoles.contains(role);
                      return InkWell(
                          hoverColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          onTap: () {
                            sel
                                ? selectedUserRoles.remove(role)
                                : selectedUserRoles.add(role);
                            userFilter.userRoles = selectedUserRoles;
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
                                    child: Text(enumValueToDisplayValue[role]!,
                                        style: const TextStyle(fontSize: 16))),
                              ])));
                    })))
                .toList(),
          )),
        ],
      ]);
    }

    // Desktop
    return Wrap(
      spacing: 6,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.zero,
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
                        BorderSide(color: OnepieceColors.separator)),
                enabledBorder: const OutlineInputBorder(
                    borderSide:
                        BorderSide(color: OnepieceColors.separator)),
                focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: OnepieceColors.fancyGreen)),
                prefixIcon: const Icon(Icons.search),
                labelText: AppLocalizations.of(context)!.name,
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.zero,
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
                        BorderSide(color: OnepieceColors.separator)),
                enabledBorder: const OutlineInputBorder(
                    borderSide:
                        BorderSide(color: OnepieceColors.separator)),
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
                borderRadius: BorderRadius.circular(10),
                color: OnepieceColors.surface,
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
    );
  }

  Widget _buildUserSortControls(BuildContext context) {
    final order = sortableEnumToSortOrderMap[UserSortableFieldsEnum.username];
    return Row(children: [
      Text('$totalItemCount ${AppLocalizations.of(context)!.user}',
          style: OnepieceFonts.smallContentStyle),
      const Spacer(),
      DesktopSortChip(
        label: AppLocalizations.of(context)!.email,
        ascending: order == null ? null : order == SortOrder.ASC,
        onTap: () => _toggleUserSort(UserSortableFieldsEnum.username),
      ),
    ]);
  }

  void _toggleUserSort(UserSortableFieldsEnum field) {
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
        sortKeys.insert(0, UserSortableField(sortKey: field, sortOrder: next));
      }
      _search(false);
    });
  }
}
