import 'dart:ui';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart' hide Notification;
import 'package:flutter/material.dart' hide Notification;
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/app_router.dart';
import 'package:one_piece_battles_flutter/config/resource_permission_manager.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:one_piece_battles_flutter/popup/notification_list.dart';
import 'package:one_piece_battles_flutter/popup/search_popup.dart';
import 'package:one_piece_battles_flutter/popup/user_navigation.dart';
import 'package:one_piece_battles_flutter/repository/user_dao.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:one_piece_battles_flutter/utils/image_helper.dart';
import 'package:openapi/api.dart';
import 'package:string_validator/string_validator.dart';

import '../../l10n/app_localizations.dart';
import 'components/web_socket_service.dart';
import 'main.dart';

GetIt getIt = GetIt.instance;

// --- CONFIGURATION & CONSTANTS ---
const locales = [Locale('zh', 'CN'), Locale('en', 'US')];
const List<ResourceType> notShownResources = [ResourceType.ROLE];
final ValueNotifier<String> routeNotifier = ValueNotifier<String>('/home/abc');

class MenuConfig {
  static const double shrinkLimitWidth = 120;
  static const double minDrawerWidth = 75;
  static const double maxDrawerWidth = 350;

  static Map<String, Widget> getResourceIcons() {
    return {
      ResourceType.FRUIT.toString(): ImageHelper.getSvgIconWithColor(
          'images/svgs/devil_fruit.svg', 20, 20, Colors.orange),
      ResourceType.GROUP.toString():
      ImageHelper.getSvgIcon('images/svgs/flag.svg', 20, 20),
      ResourceType.USER.toString():
      ImageHelper.getSvgIcon('images/svgs/users.svg', 20, 20),
      ResourceType.BATTLE.toString():
      ImageHelper.getSvgIcon('images/svgs/cannon.svg', 20, 20),
      ResourceType.CHARACTER.toString():
      ImageHelper.getSvgIcon('images/svgs/hat.svg', 20, 20),
      ResourceType.CHATTING.toString():
      ImageHelper.getSvgIcon('images/svgs/message1.svg', 20, 20),
      ResourceType.ISSUE.toString():
      ImageHelper.getSvgIcon('images/svgs/feedback.svg', 20, 20),
    };
  }

  static Map<String, String> getResourceRoutes() {
    return {
      ResourceType.FRUIT.toString(): AppRouter.fruitPath,
      ResourceType.USER.toString(): AppRouter.userManagementPath,
      ResourceType.BATTLE.toString(): AppRouter.battlePath,
      ResourceType.CHARACTER.toString(): AppRouter.characterPath,
      ResourceType.ISSUE.toString(): AppRouter.issuePath,
      ResourceType.GROUP.toString(): AppRouter.groupPath,
      ResourceType.CHATTING.toString(): AppRouter.chattingPath
    };
  }

  static String getResourceDisplayName(BuildContext context, String type) {
    final map = {
      ResourceType.FRUIT.toString(): AppLocalizations.of(context)!.devilFruit,
      ResourceType.GROUP.toString(): AppLocalizations.of(context)!.group,
      ResourceType.USER.toString():
      AppLocalizations.of(context)!.userManagement,
      ResourceType.BATTLE.toString(): AppLocalizations.of(context)!.battle,
      ResourceType.CHARACTER.toString():
      AppLocalizations.of(context)!.character,
      ResourceType.ISSUE.toString(): AppLocalizations.of(context)!.feedback,
      ResourceType.CHATTING.toString(): AppLocalizations.of(context)!.message,
    };
    return map[type] ?? type;
  }
}

// --- MAIN PAGE ---

class HomePage extends StatefulWidget {
  final Widget mainScreen;
  const HomePage({super.key, required this.mainScreen});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  // Using a GlobalKey to access SideMenu state for refreshing resources if needed
  final GlobalKey<_SideMenuState> _sideMenuKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (HardwareKeyboard.instance
            .isLogicalKeyPressed(LogicalKeyboardKey.slash)) {
          _showSearchDialog(context);
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
                  SideMenu(
                    key: _sideMenuKey,
                    constraints: constraints,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 55,
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: TopNavigationBar(
                              constraints: constraints,
                              onRoleChanged: () {
                                // Trigger side menu resource refresh
                                _sideMenuKey.currentState?._initResources();
                              },
                            ),
                          ),
                        ),
                        Expanded(child: widget.mainScreen),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

void _showSearchDialog(BuildContext context) {
  showCupertinoModalPopup(
    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
    context: context,
    builder: ((context) {
      return Dialog(
        backgroundColor: OnepieceColors.liteFancyGreen,
        alignment: Alignment.topCenter,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        child: const SearchPopup(),
      );
    }),
  );
}

// --- SIDE MENU (DRAWER) ---

class SideMenu extends StatefulWidget {
  final BoxConstraints constraints;
  const SideMenu({super.key, required this.constraints});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  double _drawerWidth = 300;
  bool _isHoveringResize = false;
  late List<ResourceType> loginRoleResources;

  // Caching variables
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
          _drawerWidth = MenuConfig.minDrawerWidth;
        } else {
          _drawerWidth = 300;
        }
      });
    });
  }

  void _initResources() {
    loginRoleResources = getIt<User>()
        .loginRoleResourcesPermissionMap
        .map((e) => e.resourceType!)
        .where((e) => !notShownResources.contains(e))
        .toList();
    if (mounted) setState(() {});
  }

  Widget _getUserNavigation(BuildContext context) {
    if (_cachedUserNavigation != null &&
        _cachedConstraints == widget.constraints) {
      return _cachedUserNavigation!;
    }
    _cachedConstraints = widget.constraints;
    _cachedUserNavigation = UserNavigation(
        context: context, constraints: widget.constraints);
    return _cachedUserNavigation!;
  }

  @override
  Widget build(BuildContext context) {
    bool isExpanded = _drawerWidth > MenuConfig.shrinkLimitWidth;

    return Stack(
      children: [
        Container(
          width: _drawerWidth,
          color: OnepieceColors.menuBackgroundColor,
          child: Column(
            children: [
              // 1. Fixed Header
              _buildHeader(context, isExpanded),

              // 2. Scrollable Content (Resources + Profile/Logout)
              // Using Expanded + ListView ensures it scrolls on phones/small laptops
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    if (isExpanded)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 10, 0, 10),
                        child: Text(AppLocalizations.of(context)!.route,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                      ),
                    _buildResourceList(context, isExpanded),
                    if (isExpanded)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 20, 0, 10),
                        child: Text(AppLocalizations.of(context)!.user,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                      ),
                    _buildUserActions(context, isExpanded),
                    const SizedBox(height: 40), // Bottom padding
                  ],
                ),
              ),
            ],
          ),
        ),

        // Resize Handle
        Positioned(
          left: _drawerWidth - 10,
          top: 0,
          bottom: 0,
          child: _buildResizeHandle(),
        ),
      ],
    );
  }

  Widget _buildResizeHandle() {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      onEnter: (_) => setState(() => _isHoveringResize = true),
      onExit: (_) => setState(() => _isHoveringResize = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isHoveringResize = true),
        onTapUp: (_) => setState(() => _isHoveringResize = false),
        onTapCancel: () => setState(() => _isHoveringResize = false),
        onHorizontalDragUpdate: (details) {
          setState(() {
            _drawerWidth += details.delta.dx;
            _drawerWidth = _drawerWidth.clamp(
                MenuConfig.minDrawerWidth, MenuConfig.maxDrawerWidth);
          });
        },
        child: Container(
          width: 8,
          color: Colors.transparent, // Hit test target
          child: Center(
            child: Container(
              width: 4,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _isHoveringResize
                    ? OnepieceColors.fancyBlue
                    : Colors.transparent,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isExpanded) {
    return Container(
      width: _drawerWidth,
      height: 180,
      color: OnepieceColors.deepFancyBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 15, 0, 0),
            child: Row(
              children: [
                _getUserNavigation(context),
                if (isExpanded)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(getIt<User>().nickname,
                              style: OnepieceFonts.headerStyleWhite,
                              maxLines: 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(getIt<User>().username,
                              style: OnepieceFonts.contentStyleWhite,
                              maxLines: 1),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (!isExpanded) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(getIt<User>().nickname,
                  style: OnepieceFonts.contentStyleBoldWhite, maxLines: 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(getIt<User>().username,
                  style: OnepieceFonts.contentStyleWhite, maxLines: 1),
            ),
          ],
          const Spacer(),
          _buildSearchButton(context, isExpanded),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget _buildSearchButton(BuildContext context, bool isExpanded) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Material(
        color: OnepieceColors.fancyGreen,
        borderRadius: BorderRadius.circular(3.0),
        child: InkWell(
          onTap: () => _showSearchDialog(context),
          child: Container(
            height: 33,
            padding: EdgeInsets.symmetric(horizontal: isExpanded ? 6.0 : 2.0),
            child: Row(
              mainAxisAlignment: isExpanded
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.center,
              children: [
                const Icon(Icons.search, size: 20, color: Colors.white),
                if (isExpanded)
                  Text(AppLocalizations.of(context)!.searchResourceShortcut,
                      style: OnepieceFonts.superSmallContentStyleWhite),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResourceList(BuildContext context, bool isExpanded) {
    // Filter resources
    var displayResources = loginRoleResources.map((e) => e.toString()).toList();
    if (getIt<User>().loginRole != UserRole.NIKA &&
        getIt<User>().loginRole != UserRole.ADMIN) {
      displayResources.remove(ResourceType.USER.toString());
      displayResources.remove(ResourceType.ISSUE.toString());
    }

    final icons = MenuConfig.getResourceIcons();
    final routes = MenuConfig.getResourceRoutes();

    return ValueListenableBuilder<String>(
      valueListenable: routeNotifier,
      builder: (context, currentRoute, child) {
        var firstPath = currentRoute
            .split("/")
            .where((e) => e.isNotEmpty && e != "home")
            .firstOrNull;

        return Column(
          children: displayResources.map((resourceType) {
            bool isSelected = firstPath == resourceType.toLowerCase();
            return _buildMenuItem(
              context: context,
              icon: icons[resourceType] ?? const SizedBox(),
              text: MenuConfig.getResourceDisplayName(context, resourceType),
              isSelected: isSelected,
              isExpanded: isExpanded,
              onTap: () => context.go(routes[resourceType]!),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildUserActions(BuildContext context, bool isExpanded) {
    return ValueListenableBuilder<String>(
      valueListenable: routeNotifier,
      builder: (context, currentRoute, _) {
        var resource = currentRoute
            .split("/")
            .where((e) => e.isNotEmpty && e != "home")
            .lastOrNull ??
            "";

        return Column(
          children: [
            _buildMenuItem(
              context: context,
              icon: SizedBox(
                width: 20,
                child:
                ImageHelper.getSvgIcon('images/svgs/profile.svg', 18, 18),
              ),
              text: AppLocalizations.of(context)!.myAccount,
              isSelected: resource == "profile",
              isExpanded: isExpanded,
              onTap: () {
                if (getIt<User>().loginRole == UserRole.VISITOR) {
                  context.go(AppRouter.registerPath);
                } else {
                  context.goNamed('userProfile',
                      extra: getIt<User>().id,
                      pathParameters: {'name': getIt<User>().nickname});
                }
              },
            ),
            _buildMenuItem(
              context: context,
              icon: ImageHelper.getSvgIcon('images/svgs/logout.svg', 20, 20),
              text: AppLocalizations.of(context)!.logout,
              isSelected: false,
              isExpanded: isExpanded,
              onTap: () async {
                final router = GoRouter.of(context);
                try {
                  await getIt<UserDao>()
                      .logout(LogoutRequest(userId: getIt<User>().id));
                } catch (_) {}
                getIt<WebSocketService>().disconnect();
                if (getIt.isRegistered<User>()) {
                  getIt.unregister<User>();
                }
                getIt.registerLazySingleton<User>(
                    () => User(id: "", username: "", nickname: ""));
                if (!mounted) return;
                router.replace(AppRouter.loginPath);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required Widget icon,
    required String text,
    required bool isSelected,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(5)),
        ),
        child: Tooltip(
          message: isExpanded ? "" : text,
          child: ListTile(
            dense: true,
            minLeadingWidth: 10,
            contentPadding: const EdgeInsets.fromLTRB(20, 0, 15, 0),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            leading: icon,
            selected: isSelected,
            selectedTileColor: OnepieceColors.fancyBlue,
            onTap: onTap,
            hoverColor: OnepieceColors.liteFancyBlue,
            title: isExpanded
                ? Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: OnepieceFonts.contentStyle.copyWith(
                fontSize: 16,
                color: isSelected ? Colors.white : Colors.black,
              ),
            )
                : const SizedBox(),
          ),
        ),
      ),
    );
  }
}

// --- TOP NAVIGATION BAR ---

class TopNavigationBar extends StatefulWidget {
  final BoxConstraints constraints;
  final VoidCallback onRoleChanged;

  const TopNavigationBar({
    super.key,
    required this.constraints,
    required this.onRoleChanged,
  });

  @override
  State<TopNavigationBar> createState() => _TopNavigationBarState();
}

class _TopNavigationBarState extends State<TopNavigationBar> {
  var _tabTextIndexSelected =
  I18nHelper.convertToOnepieceLocale(getIt<Locale>()).toString() ==
      (OnepieceLocale.zhCN.toString())
      ? 0
      : 1;
  UserRole selectedRole = getIt<User>().loginRole!;

  static const TextStyle _toggleTextStyle =
  TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600);
  static const TextStyle _toggleTextDarkStyle = TextStyle(
      color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600);

  @override
  Widget build(BuildContext context) {
    // 1. Calculate available width for the top bar
    return LayoutBuilder(
      builder: (context, constraints) {
        // 2. Define the minimum width needed for the UI to not break
        const double minContentWidth = 500;
        // 3. Create the Row with spaceBetween
        Widget content = Container(
          // Ensure the container fills the width if space allows,
          // or takes the min width if screen is small
          width: constraints.maxWidth > minContentWidth
              ? constraints.maxWidth
              : minContentWidth,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.max, // Force row to take full width
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween, // Push items to edges
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Breadcrumbs on the left
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _buildBreadcrumbs(context),
                ),
              ),

              const SizedBox(width: 20), // Spacing between sections

              // Controls on the right
              _buildRightControls(context),
            ],
          ),
        );

        // 4. Wrap in ScrollView only if screen is smaller than minContentWidth
        if (constraints.maxWidth < minContentWidth) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: content,
          );
        }

        return content;
      },
    );
  }

  Widget _buildBreadcrumbs(BuildContext context) {
    // Map definitions
    final Map<String, String> routeDisplayName = {
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

    return ValueListenableBuilder<String>(
      valueListenable: routeNotifier,
      builder: (context, _, __) {
        List<String> routes = GoRouterState.of(context)
            .matchedLocation
            .split("/")
            .where((e) => e.isNotEmpty && e != "home")
            .toList();

        List<Widget> crumbs = [];

        // Home Button
        crumbs.add(
          IconButton(
            onPressed: () {
              context.goNamed('userHome',
                  extra: getIt<User>().id,
                  pathParameters: {'name': getIt<User>().nickname});
            },
            icon: const Icon(
              Icons.home,
              color: OnepieceColors.fancyBlue,
              size: 30,
              shadows: [
                Shadow(
                    offset: Offset(2.0, 2.0),
                    blurRadius: 3.0,
                    color: Colors.grey)
              ],
            ),
          ),
        );

        for (int i = 0; i < routes.length; i++) {
          String part = routes[i];
          String text;
          if (routeDisplayName.containsKey(part)) {
            text = routeDisplayName[part]!;
          } else if (isUUID(part)) {
            text = AppLocalizations.of(context)!.detailInformation;
          } else {
            text = Uri.decodeFull(part);
          }

          bool isLast = i == routes.length - 1;
          crumbs.add(const Padding(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: Icon(Icons.arrow_forward_ios, size: 15),
          ));

          if (!isLast) {
            crumbs.add(TextButton(
              onPressed: () {
                if (Uri.decodeFull(part) == getIt<User>().nickname) {
                  context.goNamed('userHome',
                      extra: getIt<User>().id,
                      pathParameters: {'name': getIt<User>().nickname});
                } else {
                  context.go("${AppRouter.homePath}/$part");
                }
              },
              child: Text(text,
                  style: OnepieceFonts.navigationTopBarStyleClickable),
            ));
          } else {
            crumbs.add(Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Text(text, style: OnepieceFonts.navigationTopBarStyleBold),
            ));
          }
        }
        return Row(children: crumbs);
      },
    );
  }

  Widget _buildRightControls(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Row(
        mainAxisSize:
        MainAxisSize.min, // Important: Don't let this row expand infinitely
        children: [
          NotificationList(context: context),
          const SizedBox(width: 20),
          _buildLocaleToggle(),
          const SizedBox(width: 20),
          _buildRoleDropdown(context),
        ],
      ),
    );
  }

  Widget _buildLocaleToggle() {
    return SizedBox(
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
                offset: Offset(0, 1.5)),
          ],
        ),
        borderWidth: 3.0,
        height: 35,
        onChanged: (b) {
          setState(() {
            _tabTextIndexSelected = _tabTextIndexSelected == 0 ? 1 : 0;
            Locale locale =
            _tabTextIndexSelected == 0 ? locales.first : locales.last;

            getIt<UserDao>().updateUser(UpdateUserRequest(
                id: getIt<User>().id,
                nickname: getIt<User>().nickname,
                locale: I18nHelper.convertToOnepieceLocale(locale)));
            MyApp.setLocale(context, locale);
          });
        },
        styleBuilder: (b) =>
        const ToggleStyle(indicatorColor: OnepieceColors.fancyBlue),
        iconBuilder: (value) => value
            ? const Text("En", style: _toggleTextStyle)
            : const Text("文", style: _toggleTextStyle),
        textBuilder: (value) => value
            ? const Center(child: Text('文', style: _toggleTextDarkStyle))
            : const Center(child: Text('En', style: _toggleTextDarkStyle)),
      ),
    );
  }

  Widget _buildRoleDropdown(BuildContext context) {
    final Map<UserRole, String> roleNames = {
      UserRole.NIKA: AppLocalizations.of(context)!.roleNika,
      UserRole.NORMAL: AppLocalizations.of(context)!.roleNormal,
      UserRole.VISITOR: AppLocalizations.of(context)!.roleVisitor,
      UserRole.ADMIN: AppLocalizations.of(context)!.roleAdmin
    };

    return SizedBox(
      width: 140,
      child: DropdownButtonHideUnderline(
        child: DropdownButton2(
          isExpanded: true,
          value: selectedRole,
          onChanged: (UserRole? value) {
            if (value == null) return;
            selectedRole = value;
            final router = GoRouter.of(context);
            getIt<UserDao>()
                .updateLoginRole(UpdateLoginRoleRequest(role: selectedRole))
                .then((res) {
              if (!mounted) return;
              var currentUser = getIt<User>();
              currentUser.loginRoleId = res!.currentRoleId;
              currentUser.loginRole = res.currentRole;
              currentUser.loginRoleResourcesPermissionMap =
                  res.resourcePermissionMap;
              ResourcePermissionManager.updateUserCache(currentUser);

              widget.onRoleChanged();
              router.goNamed('characters');
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
          items: getIt<User>().userRoles.map((UserRole role) {
            return DropdownMenuItem<UserRole>(
              value: role,
              child: Text(roleNames[role]!, style: _toggleTextDarkStyle),
            );
          }).toList(),
        ),
      ),
    );
  }
}
