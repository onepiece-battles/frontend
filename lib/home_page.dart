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
import '../../l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/popup/search_popup.dart';
import 'package:one_piece_battles_flutter/popup/user_navigation.dart';
import 'package:one_piece_battles_flutter/repository/user_dao.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:one_piece_battles_flutter/utils/image_helper.dart';
import 'package:one_piece_battles_flutter/popup/create_feedback_popup.dart';
import 'package:openapi/api.dart';
import 'components/web_socket_service.dart';
import 'constants/onepiece_colors.dart';
import 'main.dart';

GetIt getIt = GetIt.instance;
const locales = [Locale('zh', 'CN'), Locale('en', 'US')];
const List<ResourceType> notShownResources = [ResourceType.ROLE];

// Define a ValueNotifier to track the navigation state changes
final ValueNotifier<String> routeNotifier = ValueNotifier<String>('/home/abc');

class HomePage extends StatefulWidget {
  final Widget mainScreen;

  const HomePage({super.key, required this.mainScreen});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final String profile = "profile";
  var _tabTextIndexSelected =
  I18nHelper.convertToOnepieceLocale(getIt<Locale>()).toString() ==
      (OnepieceLocale.zhCN.toString())
      ? 0
      : 1;
  UserRole selectedRole = getIt<User>().loginRole!;
  late List<ResourceType> loginRoleResources;
  List<Notification> notifications = [];

  double _drawerWidth = 300;
  bool _isHovering = false;
  final double _shrinkLimitWidth = 120;

  // Caching variables to prevent flickering
  Widget? _cachedUserNavigation;
  BoxConstraints? _cachedConstraints;

  @override
  void initState() {
    super.initState();
    _initResources();
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

  void _initResources() {
    loginRoleResources = getIt<User>()
        .loginRoleResourcesPermissionMap
        .map((e) => e.resourceType!)
        .where((e) => !notShownResources.contains(e))
        .toList();
  }

  void _search() async {
    ListNotificationRequest request =
    ListNotificationRequest(userId: getIt<User>().id, onlyNew: true);
    final response = await getIt<NotificationDao>().list(request);
    if (mounted && response != null) {
      setState(() {
        notifications = response.notifications;
      });
    }
  }

  // Optimized method to cache UserNavigation
  Widget _getUserNavigation(BuildContext context, BoxConstraints constraints) {
    // If we have a cached widget and constraints match (value equality), reuse it.
    // This stops reconstruction on setState (popups) and simple layout passes.
    if (_cachedUserNavigation != null && _cachedConstraints == constraints) {
      return _cachedUserNavigation!;
    }
    _cachedConstraints = constraints;
    // We assume UserNavigation might depend on constraints, so we recreate if they change.
    _cachedUserNavigation =
        UserNavigation(context: context, constraints: constraints);
    return _cachedUserNavigation!;
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
            body: SelectionArea(
                child: Row(
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
                )),
          );
        },
      ),
    );
  }

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
                const SizedBox(width: 100),
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

    // Moved map inside but could be static/const if context dependency removed
    final Map<String, String> routePathToDisplayName = {
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

    var detailList = routes.asMap().entries.map((entry) {
      String? text;
      if (routePathToDisplayName.containsKey(entry.value)) {
        text = routePathToDisplayName[entry.value];
      } else if (isUUID(entry.value)) {
        text = AppLocalizations.of(context)!.detailInformation;
      } else {
        text = Uri.decodeFull(entry.value);
      }

      final isLast = routeLength == (entry.key + 1);

      if (!isLast) {
        return [
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
        ];
      } else {
        return [
          _getMiddleArrow(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Text(
              text!,
              style: OnepieceFonts.navigationTopBarStyleBold,
            ),
          )
        ];
      }
    }).expand((element) => element);

    var home = Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
      child: IconButton(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.all(Colors.transparent),
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
          const SizedBox(width: 30),
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
              onChanged: (b) {
                setState(() {
                  _tabTextIndexSelected = _tabTextIndexSelected == 0 ? 1 : 0;
                  Locale locale = _tabTextIndexSelected == 0
                      ? locales.first
                      : locales.last;

                  getIt<UserDao>().updateUser(UpdateUserRequest(
                      id: getIt<User>().id,
                      nickname: getIt<User>().nickname,
                      locale: I18nHelper.convertToOnepieceLocale(locale)));
                  MyApp.setLocale(context, locale);
                });
              },
              styleBuilder: (b) => const ToggleStyle(
                  indicatorColor: OnepieceColors.fancyBlue),
              iconBuilder: (value) => value
                  ? const Text("En", style: _toggleTextStyle)
                  : const Text("文", style: _toggleTextStyle),
              textBuilder: (value) => value
                  ? const Center(child: Text('文', style: _toggleTextDarkStyle))
                  : const Center(child: Text('En', style: _toggleTextDarkStyle)),
            ),
          ),
          const SizedBox(width: 30),
          SizedBox(
            width: 140,
            child: DropdownButtonHideUnderline(
              child: DropdownButton2(
                isExpanded: true,
                value: selectedRole,
                onChanged: (UserRole? value) {
                  if (value == null) return;
                  selectedRole = value;
                  UpdateLoginRoleRequest request =
                  UpdateLoginRoleRequest(role: selectedRole);
                  getIt<UserDao>().updateLoginRole(request).then((res) {
                    var currentUser = getIt<User>();
                    currentUser.loginRoleId = res!.currentRoleId;
                    currentUser.loginRole = res.currentRole;
                    currentUser.loginRoleResourcesPermissionMap =
                        res.resourcePermissionMap;
                    ResourcePermissionManager.updateUserCache(currentUser);
                    setState(() {
                      _initResources();
                    });
                    context.goNamed('characters');
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
                menuItemStyleData: const MenuItemStyleData(height: 30),
                items: getItems(context),
              ),
            ),
          )
        ],
      ),
    );
  }

  // Extracted constants for styles to be const
  static const TextStyle _toggleTextStyle = TextStyle(
      color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600);
  static const TextStyle _toggleTextDarkStyle = TextStyle(
      color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600);

  Widget getNotification(BuildContext context) {
    return NotificationList(
      notifications: notifications,
      context: context,
    );
  }

  List<DropdownMenuItem<UserRole>> getItems(BuildContext context) {
    final Map<UserRole, String> userRoleToDisplayNameMap = {
      UserRole.NIKA: AppLocalizations.of(context)!.roleNika,
      UserRole.NORMAL: AppLocalizations.of(context)!.roleNormal,
      UserRole.VISITOR: AppLocalizations.of(context)!.roleVisitor,
      UserRole.ADMIN: AppLocalizations.of(context)!.roleAdmin
    };
    return getIt<User>().userRoles.map((UserRole userRole) {
      return DropdownMenuItem<UserRole>(
        value: userRole,
        child: Text(
          userRoleToDisplayNameMap[userRole]!,
          style: _toggleTextDarkStyle,
        ),
      );
    }).toList();
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
                                var parts = routeNotifier.value.split("/");
                                var resource = parts.where((e) => e != '' && e != "home").lastOrNull ?? "";

                                return Material(
                                  type: MaterialType.transparency,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
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
                                        const EdgeInsets.fromLTRB(20, 0, 15, 0),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        leading: SizedBox(
                                          width: 20,
                                          child: ImageHelper.getSvgIcon(
                                            'images/svgs/profile.svg',
                                            18,
                                            18,
                                          ),
                                        ),
                                        selected: profile == resource,
                                        selectedTileColor: OnepieceColors.fancyBlue,
                                        onTap: () {
                                          if (getIt<User>().loginRole == UserRole.VISITOR) {
                                            context.go(AppRouter.registerPath);
                                          } else {
                                            context.goNamed('userProfile',
                                                extra: getIt<User>().id,
                                                pathParameters: {
                                                  'name': getIt<User>().nickname
                                                });
                                          }
                                        },
                                        hoverColor: OnepieceColors.liteFancyBlue,
                                        title: Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                _drawerWidth > _shrinkLimitWidth
                                                    ? AppLocalizations.of(context)!.myAccount
                                                    : "",
                                                textAlign: TextAlign.left,
                                                maxLines: 1,
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: OnepieceFonts.weightRegular,
                                                    color: resource == "profile"
                                                        ? Colors.white
                                                        : Colors.black),
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
                                padding: const EdgeInsets.all(3),
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
                                    const EdgeInsets.fromLTRB(20, 0, 15, 0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    leading: ImageHelper.getSvgIcon(
                                      'images/svgs/logout.svg',
                                      20,
                                      20,
                                    ),
                                    onTap: () {
                                      getIt<UserDao>()
                                          .logout(LogoutRequest(userId: getIt<User>().id))
                                          .then((value) {
                                        getIt<WebSocketService>().disconnect();
                                        getIt.registerLazySingleton<User>(() =>
                                            User(id: "", username: "", nickname: ""));
                                      });
                                      context.replace(AppRouter.loginPath);
                                    },
                                    selectedColor: OnepieceColors.fancyBlue,
                                    hoverColor: OnepieceColors.liteFancyBlue,
                                    title: _drawerWidth > _shrinkLimitWidth
                                        ? Text(
                                      AppLocalizations.of(context)!.logout,
                                      maxLines: 1,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: OnepieceFonts.weightRegular,
                                          color: Colors.black),
                                    )
                                        : const Text(""),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
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
                      padding: const EdgeInsets.symmetric(vertical: 5),
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
          left: _drawerWidth - 10,
          top: 0,
          bottom: 0,
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeLeftRight,
            onEnter: (_) => setState(() => _isHovering = true),
            onExit: (_) => setState(() => _isHovering = false),
            child: GestureDetector(
              onTapDown: (_) => setState(() => _isHovering = true),
              onTapUp: (_) => setState(() => _isHovering = false),
              onTapCancel: () => setState(() => _isHovering = false),
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _drawerWidth += details.delta.dx;
                  _drawerWidth = _drawerWidth.clamp(75.0, 350.0);
                });
              },
              child: Container(
                width: 8,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(8),
                      right: Radius.circular(8)),
                  color: _isHovering
                      ? OnepieceColors.liteFancyBlue
                      : Colors.transparent,
                  boxShadow: _isHovering
                      ? const [
                    BoxShadow(
                      color: OnepieceColors.liteFancyBlue,
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: Offset(0, 4),
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
                          : Colors.transparent,
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
                // USING THE CACHED WIDGET HERE
                _getUserNavigation(context, constraints),

                if (_drawerWidth > _shrinkLimitWidth)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            getIt<User>().nickname,
                            style: OnepieceFonts.headerStyleWhite,
                            maxLines: 1,
                          ),
                        ),
                        Tooltip(
                          message: getIt<User>().username,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
          if (_drawerWidth > _shrinkLimitWidth) const SizedBox(height: 20),
          const SizedBox(height: 10),
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
                    padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                      EdgeInsets.symmetric(
                          horizontal: _drawerWidth <= _shrinkLimitWidth ? 2.0 : 6.0),
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
                            AppLocalizations.of(context)!.searchResourceShortcut,
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
          'images/svgs/devil_fruit.svg', 20, 20, Colors.orange),
      ResourceType.GROUP.toString(): ImageHelper.getSvgIcon(
          'images/svgs/flag.svg', 20, 20),
      ResourceType.USER.toString(): ImageHelper.getSvgIcon(
          'images/svgs/users.svg', 20, 20),
      ResourceType.BATTLE.toString(): ImageHelper.getSvgIcon(
          'images/svgs/cannon.svg', 20, 20),
      ResourceType.CHARACTER.toString(): ImageHelper.getSvgIcon(
          'images/svgs/hat.svg', 20, 20),
      ResourceType.CHATTING.toString(): ImageHelper.getSvgIcon(
          'images/svgs/message1.svg', 20, 20),
      ResourceType.ISSUE.toString(): ImageHelper.getSvgIcon(
          'images/svgs/feedback.svg', 20, 20),
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
      ResourceType.USER.toString(): AppLocalizations.of(context)!.userManagement,
      ResourceType.BATTLE.toString(): AppLocalizations.of(context)!.battle,
      ResourceType.CHARACTER.toString(): AppLocalizations.of(context)!.character,
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
        var firstPath = value.split("/").where((e) => e != '' && e != "home").firstOrNull;

        return ListView.builder(
          shrinkWrap: true,
          itemCount: currentLoginRoleResources.length,
          itemBuilder: (context, index) {
            String resourceType = currentLoginRoleResources[index];
            bool isSelected = firstPath == resourceType.toLowerCase();

            return Material(
              type: MaterialType.transparency,
              child: Container(
                padding: const EdgeInsets.fromLTRB(3, 3, 4, 3),
                decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(5))),
                child: Tooltip(
                  message: _drawerWidth > _shrinkLimitWidth
                      ? ""
                      : resourceToDisplayTextMap[resourceType]!,
                  child: ListTile(
                    dense: true,
                    minLeadingWidth: 10,
                    contentPadding: const EdgeInsets.fromLTRB(20, 0, 15, 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    leading: resourceToIconMap[resourceType],
                    selected: isSelected,
                    selectedTileColor: OnepieceColors.fancyBlue,
                    onTap: () {
                      GoRouter.of(context)
                          .go(resourceToLocationMap[resourceType]!);
                    },
                    hoverColor: OnepieceColors.liteFancyBlue,
                    title: _drawerWidth > _shrinkLimitWidth
                        ? Text(resourceToDisplayTextMap[resourceType]!,
                        maxLines: 1,
                        textAlign: TextAlign.left,
                        overflow: TextOverflow.clip,
                        style: OnepieceFonts.contentStyle.copyWith(
                            fontSize: 16,
                            color: isSelected ? Colors.white : Colors.black)
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
