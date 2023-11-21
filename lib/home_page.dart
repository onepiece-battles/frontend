import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/components/side_menu.dart';
import 'package:one_piece_battles_flutter/app_router.dart';
import 'package:one_piece_battles_flutter/config/resource_permission_manager.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/repository/user_dao.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:openapi/api.dart';
import 'constants/device_type.dart';
import 'package:flutter_toggle_tab/flutter_toggle_tab.dart';

import 'constants/onepiece_colors.dart';
import 'main.dart';

GetIt getIt = GetIt.instance;
const locales = [Locale('zh', 'CN'), Locale('en', 'US')];

class HomePage extends StatefulWidget {
  final Widget mainScreen;
  const HomePage({super.key, required this.mainScreen});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _tabTextIndexSelected =
      I18nHelper.convertToOnepieceLocale(getIt<Locale>()).toString() ==
              (OnepieceLocale.zhCN.toString())
          ? 0
          : 1;
  UserRole selectedRole = getIt<User>().loginRole!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const SizedBox(
            width: 250,
            child: SideMenu(),
          ),
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: 55,
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: _getHeader(
                        GoRouterState.of(context)
                            .matchedLocation
                            .split("/")
                            .where((element) => element != '')
                            .toList(),
                        context),
                  ),
                ),
                const Divider(
                  height: 10,
                  thickness: 1.5,
                ),
                Expanded(
                  child: widget.mainScreen,
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // the first one route is fixed in this case, and the latter routes are clickable
  Row _getHeader(List<String> routes, BuildContext context) {
    Map<String, String> routePathToDisplayName = {
      'home': AppLocalizations.of(context)!.home,
      'characters': AppLocalizations.of(context)!.character,
      'fruits': AppLocalizations.of(context)!.devilFruit,
      'users': AppLocalizations.of(context)!.userManagement,
      'battles': AppLocalizations.of(context)!.battle,
      'setting': AppLocalizations.of(context)!.settings,
      'issues': AppLocalizations.of(context)!.issue
    };
    bool isFirst = true;
    String currentRoutePath = "";
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(
          children: routes.expand<Widget>((route) {
        currentRoutePath = "$currentRoutePath/$route";
        debugPrint('current route is: $route');
        var result = _getTextButton(
            routePathToDisplayName[route] ?? route, currentRoutePath, isFirst);
        isFirst = false;
        return result;
      }).toList()),
      _getRightControlPanel(context)
    ]);
  }

  Padding _getRightControlPanel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
            child: FlutterToggleTab(
              width: 4,
              height: 50,
              borderRadius: 20,
              selectedBackgroundColors: const [
                Color.fromARGB(255, 38, 151, 243),
                Colors.blueAccent
              ],
              labels: const ["文", "EN"],
              selectedLabelIndex: (index) {
                setState(() {
                  _tabTextIndexSelected = index;
                  Locale locale;
                  if (index == 0) {
                    locale = locales.first;
                  } else {
                    locale = locales.last;
                  }
                  MyApp.setLocale(context, locale);
                });
              },
              selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700),
              unSelectedTextStyle: const TextStyle(
                  color: Colors.black87,
                  fontSize: 10,
                  fontWeight: FontWeight.w600),
              unSelectedBackgroundColors: const [
                Color.fromARGB(255, 182, 180, 180)
              ],
              selectedIndex: _tabTextIndexSelected,
              isScroll: false,
              marginSelected: const EdgeInsets.all(3),
            ),
          ),
          SizedBox(
            width: 150,
            child: DropdownButtonHideUnderline(
              child: DropdownButton2(
                isExpanded: true,
                value: selectedRole,
                onChanged: (UserRole? value) {
                  setState(() {
                    selectedRole = value!;
                    UpdateLoginRoleRequest request =
                        UpdateLoginRoleRequest(role: selectedRole);
                    getIt<UserDao>().updateLoginRole(request).then((value) {
                      var currentUser = getIt<User>();
                      currentUser.loginRole = value!.currentRole;
                      currentUser.loginRoleResources = value.resources;
                      ResourcePermissionManager.setResourceOrder(currentUser);
                    });
                  });
                  context.go(AppRouter.characterPath);
                },
                buttonStyleData: ButtonStyleData(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: OnepieceColors.menuBackgroundColor),
                  height: 40,
                  width: 240,
                ),
                menuItemStyleData: const MenuItemStyleData(
                  height: 40,
                ),
                items: getItems(context),
              ),
            ),
          )
        ],
      ),
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
        .map((UserRole userRole) => DropdownMenuItem<UserRole>(
              value: userRole,
              child: Text(
                userRoleToDisplayNameMap[userRole]!,
                style: OnepieceFonts.dropDownItemStyle,
              ),
            ))
        .toList();
  }

  List<Widget> _getTextButton(String name, String routePath, bool isFirst) {
    if (isFirst) {
      return [
        TextButton(
          onPressed: () {
            GoRouter.of(context).go(AppRouter.homePath);
          },
          child: Text(
            name,
            style: OnepieceFonts.navigationTopBarStyle,
          ),
        )
      ];
    } else {
      return [
        _getMiddleArrow(),
        TextButton(
            onPressed: () {
              debugPrint(routePath);
              GoRouter.of(context).go(routePath);
            },
            child: Text(
              name,
              style: OnepieceFonts.navigationTopBarStyle,
            ))
      ];
    }
  }

  Widget _getMiddleArrow() {
    return const Text(
      ">",
      style: OnepieceFonts.navigationTopBarStyle,
    );
  }
}
