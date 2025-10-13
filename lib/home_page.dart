import 'dart:ui';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart' hide Notification;
import 'package:flutter/material.dart' hide Notification;
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/popup/notification_list.dart';
import 'package:one_piece_battles_flutter/repository/notification_dao.dart';
import 'package:string_validator/string_validator.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/app_router.dart';
import 'package:one_piece_battles_flutter/config/resource_permission_manager.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/popup/search_popup.dart';
import 'package:one_piece_battles_flutter/popup/user_navigation.dart';
import 'package:one_piece_battles_flutter/repository/user_dao.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:one_piece_battles_flutter/utils/image_helper.dart';
import 'package:one_piece_battles_flutter/popup/create_feedback_popup.dart';
import 'package:openapi/api.dart';
import 'constants/onepiece_colors.dart';
import 'main.dart';

GetIt getIt = GetIt.instance;
const locales = [Locale('zh', 'CN'), Locale('en', 'US')];
List<ResourceType> notShownResources = [ResourceType.ROLE];
// Define a ValueNotifier to track the navigation state changes
final ValueNotifier<String> routeNotifier = ValueNotifier<String>('/home/abc');

class HomePage extends StatefulWidget {
  final Widget mainScreen;

  const HomePage({super.key, required this.mainScreen});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final String setting = "setting";
  final String profile = "profile";
  var _tabTextIndexSelected =
      I18nHelper.convertToOnepieceLocale(getIt<Locale>()).toString() ==
              (OnepieceLocale.zhCN.toString())
          ? 0
          : 1;
  UserRole selectedRole = getIt<User>().loginRole!;
  List<ResourceType> loginRoleResources = getIt<User>()
      .loginRoleResourcesPermissionMap
      .map((e) => e.resourceType!)
      .toList()
      .where((e) => !notShownResources.contains(e))
      .toList();
  List<Notification> notifications = [];

  double _drawerWidth = 300;
  bool _isHovering = false;
  final double _shrinkLimitWidth = 120;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      double width = MediaQuery.of(context).size.width;
      setState(() {
        if (width < 800) {
          _drawerWidth = 75;
        } else if (width > 1000) {
          _drawerWidth = 300;
        }
      });
    });
    _search();
  }

  _search() {
    ListNotificationRequest request =
        ListNotificationRequest(userId: getIt<User>().id, onlyNew: true);
    Future<ListNotificationResponse?> notification =
        getIt<NotificationDao>().list(request);
    notification.then((value) => setState(() {
          notifications = value!.notifications;
        }));
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (HardwareKeyboard.instance
            .isLogicalKeyPressed(LogicalKeyboardKey.slash)) {
          _showDialog(context);
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Scaffold(
            backgroundColor: Colors.grey[50],
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _getNavigationMenu(context, constraints),
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 55,
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: getTopBar(context, constraints),
                        ),
                      ),
                      Expanded(
                        child: widget.mainScreen,
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // the first one route is fixed in this case, and the latter routes are clickable
  Widget getTopBar(BuildContext context, BoxConstraints constraints) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
          constraints: BoxConstraints(
              minWidth: constraints.maxWidth - _drawerWidth - 10),
          child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _getRoutingBar(context),
                const SizedBox(
                  width: 100,
                ),
                _getRightControlPanel(context)
              ])),
    );
  }

  Widget _getRoutingBar(BuildContext context) {
    List<String> routes = GoRouterState.of(context)
        .matchedLocation
        .split("/")
        .where((element) => element != '' && element != "home")
        .toList();
    Map<String, String> routePathToDisplayName = {
      ResourceType.CHARACTER.toString().toLowerCase():
          AppLocalizations.of(context)!.character,
      ResourceType.FRUIT.toString().toLowerCase():
          AppLocalizations.of(context)!.devilFruit,
      ResourceType.GROUP.toString().toLowerCase():
          AppLocalizations.of(context)!.group,
      ResourceType.USER.toString().toLowerCase():
          AppLocalizations.of(context)!.userManagement,
      ResourceType.BATTLE.toString().toLowerCase():
          AppLocalizations.of(context)!.battle,
      ResourceType.ISSUE.toString().toLowerCase():
          AppLocalizations.of(context)!.issue,
      ResourceType.CHATTING.toString().toLowerCase():
      AppLocalizations.of(context)!.chatting,
      'create': AppLocalizations.of(context)!.create,
      'profile': AppLocalizations.of(context)!.userProfile,
    };
    var list = <Widget>[];
    int routeLength = routes.length;
    var currentPath = AppRouter.homePath;
    var detailList = routes
        .asMap()
        .entries
        .map((entry) {
          String? text;
          if (routePathToDisplayName.keys.contains(entry.value)) {
            text = routePathToDisplayName[entry.value];
          } else if (isUUID(entry.value)) {
            text = AppLocalizations.of(context)!.detailInformation;
          } else {
            text = Uri.decodeFull(entry.value);
          }
          return routeLength != (entry.key + 1)
              ? [
                  _getMiddleArrow(),
                  TextButton(
                    onPressed: () {
                      var decodedUri = Uri.decodeFull(entry.value);
                      if (decodedUri == getIt<User>().nickname) {
                        context.goNamed('userHome',
                            extra: getIt<User>().id,
                            pathParameters: {'name': getIt<User>().nickname});
                      } else {
                        context.go("$currentPath/$decodedUri");
                      }
                    },
                    child: Text(
                      text!,
                      style: OnepieceFonts.navigationTopBarStyleClickable,
                    ),
                  )
                ]
              : [
                  _getMiddleArrow(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Text(
                      text!,
                      style: OnepieceFonts.navigationTopBarStyleBold,
                    ),
                  )
                ];
        })
        .toList()
        .expand((element) => element);
    var home = Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
      child: IconButton(
        style: ButtonStyle(
          overlayColor: MaterialStateProperty.all(Colors.transparent),
        ),
        onPressed: () {
          context.goNamed('userHome',
              extra: getIt<User>().id,
              pathParameters: {'name': getIt<User>().nickname});
        },
        icon: const Icon(
          shadows: [
            Shadow(
              offset: Offset(2.0, 2.0),
              blurRadius: 3.0,
              color: Colors.grey,
            ),
          ],
          Icons.home,
          color: OnepieceColors.fancyBlue,
          size: 30,
        ),
      ),
    );
    list.add(home);
    list.addAll(detailList);
    return ValueListenableBuilder<String>(
        valueListenable: routeNotifier,
        builder: (context, value, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: list,
          );
        });
  }

  Padding _getRightControlPanel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          getNotification(context),
          const SizedBox(
            width: 30,
          ),
          SizedBox(
            width: 75,
            height: 32,
            child: AnimatedToggleSwitch<bool>.dual(
              current: _tabTextIndexSelected == 1,
              first: false,
              second: true,
              spacing: 1.0,
              style: const ToggleStyle(
                borderColor: Colors.transparent,
                backgroundColor: OnepieceColors.menuSelectedTileColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: Offset(0, 1.5),
                  ),
                ],
              ),
              borderWidth: 3.0,
              height: 35,
              onChanged: (b) => setState(() {
                setState(() {
                  _tabTextIndexSelected = _tabTextIndexSelected == 0 ? 1 : 0;
                  Locale locale;
                  if (_tabTextIndexSelected == 0) {
                    locale = locales.first;
                  } else {
                    locale = locales.last;
                  }
                  getIt<UserDao>().updateUser(UpdateUserRequest(
                      id: getIt<User>().id,
                      nickname: getIt<User>().nickname,
                      locale: I18nHelper.convertToOnepieceLocale(locale)));
                  MyApp.setLocale(context, locale);
                });
              }),
              styleBuilder: (b) => ToggleStyle(
                  indicatorColor:
                      b ? OnepieceColors.fancyBlue : OnepieceColors.fancyBlue),
              iconBuilder: (value) => value
                  ? const Text(
                      "En",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    )
                  : const Text(
                      "文",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
              textBuilder: (value) => value
                  ? const Center(
                      child: Text(
                      '文',
                      style: TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ))
                  : const Center(
                      child: Text(
                      'En',
                      style: TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    )),
            ),
          ),
          const SizedBox(
            width: 30,
          ),
          SizedBox(
            width: 140,
            child: DropdownButtonHideUnderline(
              child: DropdownButton2(
                isExpanded: true,
                value: selectedRole,
                onChanged: (UserRole? value) {
                  selectedRole = value!;
                  UpdateLoginRoleRequest request =
                      UpdateLoginRoleRequest(role: selectedRole);
                  getIt<UserDao>().updateLoginRole(request).then((value) {
                    var currentUser = getIt<User>();
                    currentUser.loginRoleId = value!.currentRoleId;
                    currentUser.loginRole = value.currentRole;
                    currentUser.loginRoleResourcesPermissionMap =
                        value.resourcePermissionMap;
                    ResourcePermissionManager.updateUserCache(currentUser);
                    loginRoleResources = getIt<User>()
                        .loginRoleResourcesPermissionMap
                        .map((e) => e.resourceType!)
                        .where((e) => !notShownResources.contains(e))
                        .toList();
                    context.goNamed(
                      'characters',
                    );
                  });
                },
                buttonStyleData: ButtonStyleData(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  elevation: 2,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: OnepieceColors.menuSelectedTileColor),
                  height: 40,
                  width: 140,
                ),
                menuItemStyleData: const MenuItemStyleData(
                  height: 30,
                ),
                items: getItems(context),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget getNotification(BuildContext context) {
    return NotificationList(
      notifications: notifications,
      context: context,
    );
  }

  List<DropdownMenuItem<UserRole>> getItems(BuildContext context) {
    Map<UserRole, String> userRoleToDisplayNameMap = {
      UserRole.NIKA: AppLocalizations.of(context)!.roleNika,
      UserRole.NORMAL: AppLocalizations.of(context)!.roleNormal,
      UserRole.VISITOR: AppLocalizations.of(context)!.roleVisitor,
      UserRole.ADMIN: AppLocalizations.of(context)!.roleAdmin
    };
    return getIt<User>()
        .userRoles
        .map(
          (UserRole userRole) => DropdownMenuItem<UserRole>(
            value: userRole,
            child: Text(
              userRoleToDisplayNameMap[userRole]!,
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        )
        .toList();
  }

  Widget _getNavigationMenu(BuildContext context, BoxConstraints constraints) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Container(
          width: _drawerWidth,
          color: OnepieceColors.menuBackgroundColor,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Column(
                children: [
                  _getDrawerHeader(context, constraints),
                  Expanded(
                      child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 10, 0, 10),
                          child: Text(AppLocalizations.of(context)!.route,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w800)),
                        ),
                        _getResourceMenu(context, constraints),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 10, 0, 10),
                          child: Text(AppLocalizations.of(context)!.user,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w800)),
                        ),
                        ValueListenableBuilder<String>(
                          valueListenable: routeNotifier,
                          builder: (context, value, child) {
                            // Rebuild the HomePage when the route changes
                            var resource = routeNotifier.value
                                .split("/")
                                .where((element) =>
                                    element != '' && element != "home")
                                .toList()
                                .last;
                            return Material(
                              type: MaterialType.transparency,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                                decoration: const BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(5))),
                                child: Tooltip(
                                  message: _drawerWidth > _shrinkLimitWidth
                                      ? ""
                                      : AppLocalizations.of(context)!.myAccount,
                                  child: ListTile(
                                    minLeadingWidth: 2,
                                    dense: true,
                                    contentPadding:
                                        const EdgeInsets.fromLTRB(8, 0, 0, 0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    leading: SizedBox(
                                      width: 20,
                                      child: ImageHelper.getSvgIconWithColor(
                                          'images/svgs/profile.svg',
                                          18,
                                          18,
                                          OnepieceColors.fancyBlue),
                                    ),
                                    selected: profile == resource,
                                    selectedTileColor:
                                        OnepieceColors.liteFancyBlue,
                                    onTap: () {
                                      setState(
                                        () {
                                          if (getIt<User>().loginRole ==
                                              UserRole.VISITOR) {
                                            context.go(AppRouter.registerPath);
                                          } else {
                                            context.goNamed('userProfile',
                                                extra: getIt<User>().id,
                                                pathParameters: {
                                                  'name': getIt<User>().nickname
                                                });
                                          }
                                        },
                                      );
                                    },
                                    trailing: Padding(
                                      padding:
                                          const EdgeInsets.fromLTRB(0, 0, 3, 0),
                                      child: Container(
                                        width: 3,
                                        height: 30,
                                        decoration: BoxDecoration(
                                            color: OnepieceColors
                                                .menuBackgroundColor,
                                            borderRadius:
                                                BorderRadius.circular(3)),
                                      ),
                                    ),
                                    hoverColor: OnepieceColors.liteFancyBlue,
                                    title: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            _drawerWidth > _shrinkLimitWidth
                                                ? AppLocalizations.of(context)!
                                                    .myAccount
                                                : "",
                                            textAlign: TextAlign.left,
                                            maxLines: 1,
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: OnepieceFonts
                                                    .sideMenuFontWeight,
                                                color: resource == "profile"
                                                    ? OnepieceColors.fancyBlue
                                                    : OnepieceColors
                                                        .menuTextColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        Material(
                          type: MaterialType.transparency,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                            decoration: const BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(5))),
                            child: Tooltip(
                              message: _drawerWidth > _shrinkLimitWidth
                                  ? ""
                                  : AppLocalizations.of(context)!.logout,
                              child: ListTile(
                                minLeadingWidth: 10,
                                dense: true,
                                contentPadding:
                                    const EdgeInsets.fromLTRB(8, 0, 0, 0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                leading: ImageHelper.getSvgIconWithColor(
                                    'images/svgs/logout.svg',
                                    20,
                                    20,
                                    OnepieceColors.fancyBlue),
                                onTap: () {
                                  setState(
                                    () {
                                      getIt<UserDao>()
                                          .logout(LogoutRequest(
                                              userId: getIt<User>().id))
                                          .then((value) {
                                        getIt.registerLazySingleton<User>(() =>
                                            User(
                                                id: "",
                                                username: "",
                                                nickname: ""));
                                      });
                                      context.replace(AppRouter.loginPath);
                                    },
                                  );
                                },
                                trailing: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 0, 3, 0),
                                  child: Container(
                                    width: 3,
                                    height: 30,
                                    decoration: BoxDecoration(
                                        color:
                                            OnepieceColors.menuBackgroundColor,
                                        borderRadius: BorderRadius.circular(3)),
                                  ),
                                ),
                                selectedColor: OnepieceColors.liteFancyBlue,
                                hoverColor: OnepieceColors.liteFancyBlue,
                                title: _drawerWidth > _shrinkLimitWidth
                                    ? Text(
                                        AppLocalizations.of(context)!.logout,
                                        maxLines: 1,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: OnepieceFonts
                                                .sideMenuFontWeight,
                                            color:
                                                OnepieceColors.menuTextColor),
                                      )
                                    : const Text(""),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 40,
                        ),
                      ],
                    ),
                  )),
                ],
              ),
              Container(
                decoration: const BoxDecoration(
                  color: OnepieceColors.menuBackgroundColor,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.all(5),
                      backgroundColor: OnepieceColors.menuBackgroundColor,
                      foregroundColor: OnepieceColors.menuHoverColor,
                      elevation: 1.0,
                      // shadowColor: Colors.transparent,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: ((context) {
                          return Dialog(
                            surfaceTintColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            alignment: AlignmentDirectional.bottomStart,
                            child: const CreateFeedbackPopup(),
                          );
                        }),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ImageHelper.getSvgIcon(
                            'images/svgs/menu_question.svg',
                            21,
                            21,
                          ),
                          if (_drawerWidth > _shrinkLimitWidth)
                            const SizedBox(width: 6),
                          if (_drawerWidth > _shrinkLimitWidth)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2.0),
                              child: Text(
                                  AppLocalizations.of(context)!.feedback,
                                  style: const TextStyle(
                                      color: OnepieceColors.menuTextColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500)),
                            )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: _drawerWidth - 10, // 拖动边缘的宽度
          top: 0,
          bottom: 0,
          child: MouseRegion(
            // Change cursor and update hover state
            cursor: SystemMouseCursors.resizeLeftRight,
            onEnter: (_) => setState(() {
              _isHovering = true;
            }),
            onExit: (_) => setState(() {
              _isHovering = false;
            }),

            child: GestureDetector(
              onTapDown: (_) => setState(() => _isHovering = true),
              onTapUp: (_) => setState(() => _isHovering = false),
              onTapCancel: () => setState(() => _isHovering = false),
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _drawerWidth += details.delta.dx; // 更新宽度
                  // 确保宽度在一定范围内
                  _drawerWidth = _drawerWidth.clamp(75.0, 350.0);
                });
              },
              child: Container(
                width: 8,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(8),
                      right:
                          Radius.circular(8)), // Rounded corners on the right
                  color: _isHovering
                      ? OnepieceColors.liteFancyBlue
                      : Colors.transparent, // Background color based on hover
                  boxShadow: _isHovering
                      ? [
                          const BoxShadow(
                            color: OnepieceColors.liteFancyBlue,
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: Offset(0, 4), // changes position of shadow
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: SizedBox(
                    height: 30,
                    child: VerticalDivider(
                      width: 5,
                      color: _isHovering
                          ? OnepieceColors.fancyBlue
                          : Colors.transparent, // Indicator line
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _getDrawerHeader(BuildContext context, BoxConstraints constraints) {
    return Container(
      width: _drawerWidth,
      height: 180,
      color: OnepieceColors.deepFancyBlue,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 15, 0, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserNavigation(context: context, constraints: constraints),
                if (_drawerWidth > _shrinkLimitWidth)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                          child: Text(
                            getIt<User>().nickname,
                            style: OnepieceFonts.headerStyleWhite,
                            maxLines: 1,
                          ),
                        ),
                        Tooltip(
                          message: getIt<User>().username,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              getIt<User>().username,
                              style: OnepieceFonts.contentStyleWhite,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (_drawerWidth <= _shrinkLimitWidth)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Tooltip(
                message: getIt<User>().nickname,
                child: Text(
                  getIt<User>().nickname,
                  style: OnepieceFonts.contentStyleBoldWhite,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                ),
              ),
            ),
          if (_drawerWidth <= _shrinkLimitWidth)
            Tooltip(
              message: getIt<User>().username,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Text(
                  getIt<User>().username,
                  style: OnepieceFonts.contentStyleWhite,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                ),
              ),
            ),
          if (_drawerWidth > _shrinkLimitWidth)
            const SizedBox(
              height: 20,
            ),
          const SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                width: _drawerWidth - 20,
                height: 33,
                decoration: const BoxDecoration(
                  color: OnepieceColors.fancyGreen,
                  borderRadius: BorderRadius.all(Radius.circular(3.0)),
                ),
                child: TextButton(
                  style: ButtonStyle(
                    padding: _drawerWidth <= _shrinkLimitWidth
                        ? MaterialStateProperty.all<EdgeInsetsGeometry>(
                            const EdgeInsets.symmetric(
                                horizontal:
                                    2.0), // Adjust the value to control the padding
                          )
                        : MaterialStateProperty.all<EdgeInsetsGeometry>(
                            const EdgeInsets.symmetric(
                                horizontal:
                                    6.0), // Adjust the value to control the padding
                          ),
                  ),
                  child: Row(
                      mainAxisAlignment: _drawerWidth > _shrinkLimitWidth
                          ? MainAxisAlignment.spaceBetween
                          : MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search,
                          size: 20,
                          color: Colors.white,
                        ),
                        if (_drawerWidth > 200)
                          Text(
                            AppLocalizations.of(context)!.searchResource,
                            style: OnepieceFonts.superSmallContentStyleWhite,
                          ),
                        if (_drawerWidth > _shrinkLimitWidth)
                          Text(
                            AppLocalizations.of(context)!
                                .searchResourceShortcut,
                            style: OnepieceFonts.superSmallContentStyleWhite,
                          ),
                      ]),
                  onPressed: () {
                    _showDialog(context);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDialog(BuildContext context) {
    showCupertinoModalPopup(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      context: context,
      builder: ((context) {
        return Dialog(
          backgroundColor: OnepieceColors.liteFancyGreen,
          alignment: Alignment.topCenter,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: const SearchPopup(),
        );
      }),
    );
  }

  Widget _getResourceMenu(BuildContext context, BoxConstraints constraints) {
    Map<String, Widget> resourceToIconMap = {
      ResourceType.FRUIT.toString(): ImageHelper.getSvgIconWithColor(
          'images/svgs/fruit.svg', 20, 20, OnepieceColors.fancyBlue),
      ResourceType.GROUP.toString(): ImageHelper.getSvgIconWithColor(
          'images/svgs/flag.svg', 20, 20, OnepieceColors.fancyBlue),
      ResourceType.USER.toString(): const Icon(Icons.manage_accounts,
          color: OnepieceColors.fancyBlue, size: 20),
      ResourceType.BATTLE.toString(): ImageHelper.getSvgIconWithColor(
          'images/svgs/cannon.svg', 20, 20, OnepieceColors.fancyBlue),
      ResourceType.CHARACTER.toString(): ImageHelper.getSvgIconWithColor(
          'images/svgs/hat.svg', 20, 20, OnepieceColors.fancyBlue),
      ResourceType.ISSUE.toString(): const Icon(Icons.add_alert,
          color: OnepieceColors.fancyBlue, size: 20),
      ResourceType.CHATTING.toString():
          const Icon(Icons.message, color: OnepieceColors.fancyBlue, size: 20),
      setting:
          const Icon(Icons.settings, color: OnepieceColors.fancyBlue, size: 20)
    };

    Map<String, String> resourceToLocationMap = {
      ResourceType.FRUIT.toString(): AppRouter.fruitPath,
      ResourceType.USER.toString(): AppRouter.userManagementPath,
      ResourceType.BATTLE.toString(): AppRouter.battlePath,
      ResourceType.CHARACTER.toString(): AppRouter.characterPath,
      ResourceType.ISSUE.toString(): AppRouter.issuePath,
      ResourceType.GROUP.toString(): AppRouter.groupPath,
      ResourceType.CHATTING.toString(): AppRouter.chattingPath
    };
    Map<String, String> resourceToDisplayTextMap = {
      ResourceType.FRUIT.toString(): AppLocalizations.of(context)!.devilFruit,
      ResourceType.GROUP.toString(): AppLocalizations.of(context)!.group,
      ResourceType.USER.toString():
          AppLocalizations.of(context)!.userManagement,
      ResourceType.BATTLE.toString(): AppLocalizations.of(context)!.battle,
      ResourceType.CHARACTER.toString():
          AppLocalizations.of(context)!.character,
      ResourceType.ISSUE.toString(): AppLocalizations.of(context)!.feedback,
      ResourceType.CHATTING.toString(): AppLocalizations.of(context)!.message
    };
    var currentLoginRoleResources =
        loginRoleResources.map((e) => e.toString()).toList();
    // filter out user resource if the role is not nika/admin
    if (getIt<User>().loginRole != UserRole.NIKA &&
        getIt<User>().loginRole != UserRole.ADMIN) {
      currentLoginRoleResources.remove(ResourceType.USER.toString());
      currentLoginRoleResources.remove(ResourceType.ISSUE.toString());
    }
    return ValueListenableBuilder<String>(
      valueListenable: routeNotifier,
      builder: (context, value, child) {
        // Rebuild the HomePage when the route changes
        return ListView.builder(
          shrinkWrap: true,
          itemCount: currentLoginRoleResources.length,
          itemBuilder: (context, index) {
            String resourceType = currentLoginRoleResources[index];
            return Material(
              type: MaterialType.transparency,
              child: Container(
                padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(5))),
                child: Tooltip(
                  message: _drawerWidth > _shrinkLimitWidth
                      ? ""
                      : resourceToDisplayTextMap[resourceType]!,
                  child: ListTile(
                    dense: true,
                    minLeadingWidth: 10,
                    contentPadding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    leading: resourceToIconMap[resourceType],
                    selected: routeNotifier.value
                            .split("/")
                            .where(
                                (element) => element != '' && element != "home")
                            .toList()
                            .first ==
                        resourceType.toLowerCase(),
                    selectedTileColor: OnepieceColors.liteFancyBlue,
                    onTap: () {
                      setState(
                        () {
                          GoRouter.of(context)
                              .go(resourceToLocationMap[resourceType]!);
                        },
                      );
                    },
                    trailing: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 3, 0),
                      child: Container(
                        width: 3,
                        height: 30,
                        decoration: BoxDecoration(
                            color: OnepieceColors.menuBackgroundColor,
                            borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                    hoverColor: OnepieceColors.liteFancyBlue,
                    title: _drawerWidth > _shrinkLimitWidth
                        ? Text(
                            resourceToDisplayTextMap[resourceType]!,
                            maxLines: 1,
                            textAlign: TextAlign.left,
                            overflow: TextOverflow.clip,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: OnepieceFonts.sideMenuFontWeight,
                                color: routeNotifier.value
                                            .split("/")
                                            .where((element) =>
                                                element != '' &&
                                                element != "home")
                                            .toList()
                                            .first ==
                                        resourceType.toLowerCase()
                                    ? OnepieceColors.fancyBlue
                                    : OnepieceColors.menuTextColor),
                          )
                        : const Text(""),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _getMiddleArrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 5),
      child: Icon(
        Icons.arrow_forward_ios,
        size: 15,
      ),
    );
  }
}
