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
import 'package:one_piece_battles_flutter/popup/create_feedback_popup.dart';
import 'package:one_piece_battles_flutter/popup/onepiece_alert.dart';
import 'package:one_piece_battles_flutter/popup/search_popup.dart';
import 'package:one_piece_battles_flutter/popup/user_navigation.dart';
import 'package:one_piece_battles_flutter/repository/user_dao.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:one_piece_battles_flutter/utils/image_helper.dart';
import 'package:one_piece_battles_flutter/utils/responsive_breakpoints.dart';
import 'package:one_piece_battles_flutter/utils/route_notifier.dart';
import 'package:openapi/api.dart';
import 'package:string_validator/string_validator.dart';

import '../../l10n/app_localizations.dart';
import 'components/web_socket_service.dart';
import 'main.dart';

GetIt getIt = GetIt.instance;

// --- CONFIGURATION & CONSTANTS ---
const locales = [Locale('zh', 'CN'), Locale('en', 'US')];
const List<ResourceType> notShownResources = [ResourceType.ROLE];

class MenuConfig {
  static const double shrinkLimitWidth = 120;
  static const double minDrawerWidth = 75;
  static const double maxDrawerWidth = 280;

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
  final GlobalKey<_SideMenuState> _drawerSideMenuKey = GlobalKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isMobileDrawerPinned = false;

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (HardwareKeyboard.instance
            .isLogicalKeyPressed(LogicalKeyboardKey.slash)) {
          _openSearchFromHome();
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile =
              ResponsiveBreakpoints.isMobileFromConstraints(constraints);
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: Colors.grey[50],
            drawer: isMobile && !_isMobileDrawerPinned
                ? Drawer(
                    width: MenuConfig.maxDrawerWidth,
                    child: SideMenu(
                      key: _drawerSideMenuKey,
                      constraints: constraints,
                      isDrawer: true,
                      onPinDrawer: _pinMobileDrawer,
                      onSearchRequested: _openSearchFromHome,
                    ),
                  )
                : null,
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isMobile && _isMobileDrawerPinned)
                  SideMenu(
                    key: _sideMenuKey,
                    constraints: constraints,
                    isPinnedRail: true,
                    onUnpinRail: _unpinMobileDrawer,
                    onSearchRequested: _openSearchFromHome,
                  ),
                if (!isMobile)
                  SideMenu(
                    key: _sideMenuKey,
                    constraints: constraints,
                    onSearchRequested: _openSearchFromHome,
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
                            isMobile: isMobile,
                            showMenuButton: !_isMobileDrawerPinned,
                            scaffoldKey: _scaffoldKey,
                            onRoleChanged: () {
                              // Trigger side menu resource refresh
                              _sideMenuKey.currentState?._initResources();
                              _drawerSideMenuKey.currentState?._initResources();
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
          );
        },
      ),
    );
  }

  void _closeLeftMenu() {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      _scaffoldKey.currentState?.closeDrawer();
      return;
    }
    _sideMenuKey.currentState?.collapse();
  }

  Future<void> _openSearchFromHome() async {
    _closeLeftMenu();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    _showSearchDialog(context);
  }

  void _pinMobileDrawer() {
    Navigator.of(context).maybePop();
    setState(() {
      _isMobileDrawerPinned = true;
    });
  }

  void _unpinMobileDrawer() {
    setState(() {
      _isMobileDrawerPinned = false;
    });
  }
}

void _showSearchDialog(BuildContext context) {
  showCupertinoModalPopup(
    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
    context: context,
    builder: ((context) {
      return const Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        alignment: Alignment.topCenter,
        child: SearchPopup(),
      );
    }),
  );
}

// --- SIDE MENU (DRAWER) ---

class SideMenu extends StatefulWidget {
  final BoxConstraints constraints;
  final bool isDrawer;
  final bool isPinnedRail;
  final VoidCallback? onSearchRequested;
  final VoidCallback? onPinDrawer;
  final VoidCallback? onUnpinRail;
  const SideMenu({
    super.key,
    required this.constraints,
    this.isDrawer = false,
    this.isPinnedRail = false,
    this.onSearchRequested,
    this.onPinDrawer,
    this.onUnpinRail,
  });

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  double _drawerWidth = 300;
  double _expandedDrawerWidth = 300;
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

  void _onDrawerItemTap(VoidCallback action) {
    if (widget.isDrawer) {
      Navigator.of(context).pop();
    }
    action();
  }

  void collapse() {
    if (widget.isDrawer || widget.isPinnedRail) {
      Navigator.of(context).maybePop();
      return;
    }
    if (_drawerWidth <= MenuConfig.minDrawerWidth) return;
    setState(() {
      _drawerWidth = MenuConfig.minDrawerWidth;
    });
  }

  void _togglePinnedNarrow() {
    if (widget.isDrawer) {
      widget.onPinDrawer?.call();
      return;
    }
    if (widget.isPinnedRail) {
      widget.onUnpinRail?.call();
      return;
    }
    final isNarrow = _drawerWidth <= MenuConfig.minDrawerWidth + 1;
    setState(() {
      if (isNarrow) {
        _drawerWidth = _expandedDrawerWidth.clamp(
            MenuConfig.shrinkLimitWidth + 1, MenuConfig.maxDrawerWidth);
      } else {
        _expandedDrawerWidth = _drawerWidth.clamp(
            MenuConfig.shrinkLimitWidth + 1, MenuConfig.maxDrawerWidth);
        _drawerWidth = MenuConfig.minDrawerWidth;
      }
    });
  }

  Widget _getUserNavigation(BuildContext context) {
    if (_cachedUserNavigation != null &&
        _cachedConstraints == widget.constraints) {
      return _cachedUserNavigation!;
    }
    _cachedConstraints = widget.constraints;
    _cachedUserNavigation =
        UserNavigation(context: context, constraints: widget.constraints);
    return _cachedUserNavigation!;
  }

  @override
  Widget build(BuildContext context) {
    final double effectiveDrawerWidth =
        widget.isPinnedRail ? MenuConfig.minDrawerWidth : _drawerWidth;
    final bool isExpanded = widget.isDrawer ||
        (!widget.isPinnedRail &&
            effectiveDrawerWidth > MenuConfig.shrinkLimitWidth);

    // Drawer mode: full-width, no resize handle, wrapped in SafeArea
    if (widget.isDrawer) {
      return SafeArea(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              _buildHeader(context, isExpanded),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildSectionLabel(AppLocalizations.of(context)!.route),
                    _buildResourceList(context, isExpanded),
                    _buildSectionLabel(AppLocalizations.of(context)!.user,
                        top: 20),
                    _buildUserActions(context, isExpanded),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
              _buildFeedbackAction(context, isExpanded),
            ],
          ),
        ),
      );
    }

    // Desktop/pinned mode: fixed width + optional resize handle
    return Stack(
      children: [
        Container(
          width: effectiveDrawerWidth,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              right: BorderSide(color: OnepieceColors.separator, width: 0.5),
            ),
          ),
          child: Column(
            children: [
              _buildHeader(context, isExpanded),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    if (isExpanded)
                      _buildSectionLabel(AppLocalizations.of(context)!.route),
                    _buildResourceList(context, isExpanded),
                    if (isExpanded)
                      _buildSectionLabel(AppLocalizations.of(context)!.user,
                          top: 20),
                    _buildUserActions(context, isExpanded),
                    const SizedBox(height: 40), // Bottom padding
                  ],
                ),
              ),
              _buildFeedbackAction(context, isExpanded),
            ],
          ),
        ),
        if (!widget.isPinnedRail)
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
            if (_drawerWidth > MenuConfig.shrinkLimitWidth) {
              _expandedDrawerWidth = _drawerWidth;
            }
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(
              isExpanded ? 12 : 8, isExpanded ? 16 : 40, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _getUserNavigation(context),
                  if (isExpanded)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(getIt<User>().nickname,
                                style: const TextStyle(
                                  color: OnepieceColors.primaryLabel,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(getIt<User>().username,
                                style: const TextStyle(
                                  color: OnepieceColors.secondaryLabel,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSearchButton(context, isExpanded),
              const SizedBox(height: 12),
              const Divider(
                  height: 1, thickness: 0.5, color: OnepieceColors.separator),
            ],
          ),
        ),
        Positioned(
          top: isExpanded ? 8 : 7,
          right: isExpanded ? 8 : 6,
          child: _buildNarrowToggle(isExpanded),
        ),
      ],
    );
  }

  Widget _buildNarrowToggle(bool isExpanded) {
    final tooltip = widget.isDrawer
        ? 'Pin menu'
        : widget.isPinnedRail
            ? 'Back to drawer'
            : isExpanded
                ? 'Collapse menu'
                : 'Expand menu';
    final icon = widget.isDrawer
        ? Icons.push_pin_outlined
        : widget.isPinnedRail
            ? Icons.keyboard_double_arrow_left
            : isExpanded
                ? Icons.keyboard_double_arrow_left
                : Icons.keyboard_double_arrow_right;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: OnepieceColors.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          hoverColor: OnepieceColors.separator,
          onTap: _togglePinnedNarrow,
          child: SizedBox(
            width: isExpanded ? 26 : 24,
            height: isExpanded ? 26 : 24,
            child: Icon(
              icon,
              size: isExpanded ? 16 : 15,
              color: OnepieceColors.secondaryLabel,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchButton(BuildContext context, bool isExpanded) {
    return Material(
      color: OnepieceColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: widget.onSearchRequested,
        child: Container(
          height: 38,
          padding: EdgeInsets.symmetric(horizontal: isExpanded ? 12.0 : 0),
          child: Row(
            mainAxisAlignment:
                isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              const Icon(Icons.search,
                  size: 19, color: OnepieceColors.secondaryLabel),
              if (isExpanded) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.searchResourceShortcut,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: OnepieceColors.secondaryLabel, fontSize: 13),
                  ),
                ),
              ],
            ],
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
              onTap: () =>
                  _onDrawerItemTap(() => context.go(routes[resourceType]!)),
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
              onTap: () => _onDrawerItemTap(() {
                if (getIt<User>().loginRole == UserRole.VISITOR) {
                  context.go(AppRouter.registerPath);
                } else {
                  context.goNamed('userProfile',
                      extra: getIt<User>().id,
                      pathParameters: {'name': getIt<User>().nickname});
                }
              }),
            ),
            _buildMenuItem(
              context: context,
              icon: ImageHelper.getSvgIcon('images/svgs/logout.svg', 20, 20),
              text: AppLocalizations.of(context)!.logout,
              isSelected: false,
              isExpanded: isExpanded,
              onTap: () => _onDrawerItemTap(() async {
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
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeedbackAction(BuildContext context, bool isExpanded) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Tooltip(
            message: AppLocalizations.of(context)!.feedback,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                hoverColor: OnepieceColors.surface,
                onTap: () => _showFeedbackDialog(context),
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(
                    Icons.feedback_outlined,
                    color: OnepieceColors.fancyBlue,
                    size: 21,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showFeedbackDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: CreateFeedbackPopup(
            onIssueCreated: (message) {
              OnepieceAlert.createAlertShower(context)(
                AppLocalizations.of(context)!.hint,
                message,
              );
            },
          ),
        );
      },
    );
  }

  /// Muted, uppercase section label (Apple-style grouped-list subheader).
  Widget _buildSectionLabel(String text, {double top = 10}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, top, 0, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: OnepieceColors.secondaryLabel,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
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
            selectedTileColor: OnepieceColors.surface,
            onTap: onTap,
            hoverColor: OnepieceColors.surface,
            title: isExpanded
                ? Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: OnepieceFonts.contentStyle.copyWith(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? OnepieceColors.fancyBlue
                          : OnepieceColors.primaryLabel,
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
  final bool isMobile;
  final bool showMenuButton;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final VoidCallback onRoleChanged;

  const TopNavigationBar({
    super.key,
    required this.constraints,
    required this.isMobile,
    this.showMenuButton = true,
    required this.scaffoldKey,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final double minContentWidth = widget.isMobile ? 300 : 500;
        final bool isMobile = widget.isMobile;

        Widget content = Container(
          width: constraints.maxWidth > minContentWidth
              ? constraints.maxWidth
              : minContentWidth,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Hamburger menu on mobile
              if (isMobile && widget.showMenuButton)
                IconButton(
                  icon: const Icon(Icons.menu,
                      color: OnepieceColors.fancyBlue, size: 20),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints:
                      const BoxConstraints.tightFor(width: 28, height: 32),
                  onPressed: () =>
                      widget.scaffoldKey.currentState?.openDrawer(),
                ),
              if (isMobile && widget.showMenuButton) const SizedBox(width: 4),

              // Breadcrumbs on the left
              if (isMobile)
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: _buildBreadcrumbs(context),
                  ),
                )
              else
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildBreadcrumbs(context),
                  ),
                ),

              if (!isMobile) const SizedBox(width: 10),

              if (isMobile) const SizedBox(width: 8),

              // Controls on the right
              if (isMobile)
                _buildMobileRightControls(context)
              else
                _buildRightControls(context),
            ],
          ),
        );

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

  Widget _buildMobileRightControls(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NotificationList(context: context, size: 30, iconSize: 18),
        const SizedBox(width: 4),
        // Language toggle
        SizedBox(
          width: 30,
          height: 30,
          child: PopupMenuButton<String>(
            tooltip: AppLocalizations.of(context)!.language,
            padding: EdgeInsets.zero,
            iconSize: 20,
            icon: const Icon(Icons.language, color: OnepieceColors.fancyBlue),
            offset: const Offset(0, 34),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            onSelected: (value) {
              switch (value) {
                case 'locale_zh':
                  setState(() => _tabTextIndexSelected = 0);
                  MyApp.setLocale(context, const Locale('zh', 'CN'));
                  getIt<UserDao>().updateUser(UpdateUserRequest(
                      id: getIt<User>().id,
                      nickname: getIt<User>().nickname,
                      locale: I18nHelper.convertToOnepieceLocale(
                          const Locale('zh', 'CN'))));
                  break;
                case 'locale_en':
                  setState(() => _tabTextIndexSelected = 1);
                  MyApp.setLocale(context, const Locale('en', 'US'));
                  getIt<UserDao>().updateUser(UpdateUserRequest(
                      id: getIt<User>().id,
                      nickname: getIt<User>().nickname,
                      locale: I18nHelper.convertToOnepieceLocale(
                          const Locale('en', 'US'))));
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'locale_zh',
                child: Row(
                  children: [
                    const Icon(Icons.language,
                        size: 18, color: OnepieceColors.fancyBlue),
                    const SizedBox(width: 8),
                    Text(_tabTextIndexSelected == 0 ? '✓ 中文' : '  中文',
                        style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'locale_en',
                child: Row(
                  children: [
                    const Icon(Icons.language,
                        size: 18, color: OnepieceColors.fancyBlue),
                    const SizedBox(width: 8),
                    Text(_tabTextIndexSelected == 1 ? '✓ English' : '  English',
                        style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreadcrumbs(BuildContext context) {
    final bool isMobile = widget.isMobile;
    final TextStyle clickableStyle =
        OnepieceFonts.navigationTopBarStyleClickable.copyWith(
      fontSize: isMobile ? 12 : 16,
      fontWeight: FontWeight.w600,
    );
    final TextStyle currentStyle =
        OnepieceFonts.navigationTopBarStyleBold.copyWith(
      fontSize: isMobile ? 12 : 16,
      fontWeight: FontWeight.w600,
      color: OnepieceColors.primaryLabel,
    );

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
            visualDensity: isMobile ? VisualDensity.compact : null,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints.tightFor(
              width: isMobile ? 28 : 48,
              height: isMobile ? 32 : 48,
            ),
            onPressed: () {
              context.goNamed('userHome',
                  extra: getIt<User>().id,
                  pathParameters: {'name': getIt<User>().nickname});
            },
            icon: Icon(
              Icons.home,
              color: OnepieceColors.fancyBlue,
              size: isMobile ? 22 : 28,
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
          crumbs.add(Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 2 : 5),
            child: Icon(Icons.arrow_forward_ios,
                size: isMobile ? 10 : 13,
                color: OnepieceColors.secondaryLabel),
          ));

          if (!isLast) {
            crumbs.add(TextButton(
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 3 : 8,
                  vertical: isMobile ? 2 : 8,
                ),
              ),
              onPressed: () {
                if (Uri.decodeFull(part) == getIt<User>().nickname) {
                  context.goNamed('userHome',
                      extra: getIt<User>().id,
                      pathParameters: {'name': getIt<User>().nickname});
                } else {
                  context.go("${AppRouter.homePath}/$part");
                }
              },
              child: Text(text, style: clickableStyle),
            ));
          } else {
            crumbs.add(Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 3 : 5),
              child: Text(text, style: currentStyle),
            ));
          }
        }
        return Row(mainAxisSize: MainAxisSize.min, children: crumbs);
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
