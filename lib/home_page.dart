import 'dart:ui';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/app_router.dart';
import 'package:one_piece_battles_flutter/config/resource_permission_manager.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/popup/search_popup.dart';
import 'package:one_piece_battles_flutter/popup/user_navigation.dart';
import 'package:one_piece_battles_flutter/repository/user_dao.dart';
import 'package:one_piece_battles_flutter/utils/base64_helper.dart';
import 'package:one_piece_battles_flutter/utils/data_validator.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:one_piece_battles_flutter/utils/image_helper.dart';
import 'package:one_piece_battles_flutter/views/create_feedback_view.dart';
import 'package:openapi/api.dart';
import 'package:flutter_toggle_tab/flutter_toggle_tab.dart';
import 'constants/onepiece_colors.dart';
import 'main.dart';

GetIt getIt = GetIt.instance;
const locales = [Locale('zh', 'CN'), Locale('en', 'US')];
List<ResourceType> notShownResources = [ResourceType.ROLE];

class HomePage extends StatefulWidget {
  final Widget mainScreen;
  const HomePage({super.key, required this.mainScreen});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final String setting = "setting";
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
  String selectedResource = ResourceType.CHARACTER.toString();

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) {
          if (event.isKeyPressed(LogicalKeyboardKey.slash)) {
            _showDialog(context);
          }
        },
        child: Scaffold(
          body: Row(
            children: [
              _getNavigationMenu(context),
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: 55,
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: _getHeader(context),
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
        ));
  }

  // the first one route is fixed in this case, and the latter routes are clickable
  Row _getHeader(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [_getRoutingBar(), _getRightControlPanel(context)]);
  }

  Widget _getRoutingBar() {
    List<String> routes = GoRouterState.of(context)
        .matchedLocation
        .split("/")
        .where((element) => element != '' && element != "home")
        .toList();
    Map<String, String> routePathToDisplayName = {
      'home': AppLocalizations.of(context)!.home,
      'characters': AppLocalizations.of(context)!.character,
      'fruits': AppLocalizations.of(context)!.devilFruit,
      'groups': AppLocalizations.of(context)!.group,
      'users': AppLocalizations.of(context)!.userManagement,
      'battles': AppLocalizations.of(context)!.battle,
      'setting': AppLocalizations.of(context)!.settings,
      'issues': AppLocalizations.of(context)!.issue,
      'create': AppLocalizations.of(context)!.create
    };
    debugPrint(routes.toString());
    var list = <Widget>[];
    int routeLength = routes.length;
    var currentPath = "/home";
    var detailList = routes
        .asMap()
        .entries
        .map((entry) {
          String? text;
          if (routePathToDisplayName.keys.contains(entry.value)) {
            text = routePathToDisplayName[entry.value];
          } else if (DataValidator.isUuid(entry.value)) {
            text = AppLocalizations.of(context)!.detailInformation;
          } else {
            text = Uri.decodeFull(entry.value);
          }
          return routeLength != (entry.key + 1)
              ? [
                  _getMiddleArrow(),
                  TextButton(
                    onPressed: () {
                      context.go("$currentPath/${entry.value}");
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
        splashRadius: 0.1,
        onPressed: () {
          selectedResource = ResourceType.CHARACTER.toString();
          context.go(AppRouter.homePath);
        },
        icon: const Icon(
          Icons.home,
          color: OnepieceColors.fancyBlue,
          size: 30,
        ),
      ),
    );
    list.add(home);
    list.addAll(detailList);
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: list,
    );
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
                OnepieceColors.fancyBlue,
                // Colors.blueAccent
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
                  selectedRole = value!;
                  UpdateLoginRoleRequest request =
                      UpdateLoginRoleRequest(role: selectedRole);
                  getIt<UserDao>().updateLoginRole(request).then((value) {
                    var currentUser = getIt<User>();
                    currentUser.loginRole = value!.currentRole;
                    currentUser.loginRoleResourcesPermissionMap =
                        value.resourcePermissionMap;
                    ResourcePermissionManager.updateUserCache(currentUser);
                    setState(() {
                      selectedResource = ResourceType.CHARACTER.toString();
                      loginRoleResources = getIt<User>()
                          .loginRoleResourcesPermissionMap
                          .map((e) => e.resourceType!)
                          .where((e) => !notShownResources.contains(e))
                          .toList();
                      context.go(AppRouter.homePath);
                    });
                  });
                },
                buttonStyleData: ButtonStyleData(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: OnepieceColors.liteFancyGreen),
                  height: 40,
                  width: 240,
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
              style: OnepieceFonts.dropDownItemStyle,
            ),
          ),
        )
        .toList();
  }

  Widget _getNavigationMenu(BuildContext context) {
    return Container(
      width: 250,
      color: OnepieceColors.menuBackgroundColor,
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _getDrawerHeader(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 0, 10),
                child: Text(AppLocalizations.of(context)!.route,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              _getSideMenuList(context),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: OnepieceColors.menuBackgroundColor,
                  foregroundColor: OnepieceColors.menuIconColor,
                  elevation: 0.0,
                  shadowColor: Colors.transparent,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: ((context) {
                      return const AlertDialog(
                        alignment: AlignmentDirectional.bottomStart,
                        content: CreateFeedbackView(),
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
                      const SizedBox(width: 6),
                      Text(AppLocalizations.of(context)!.feedback,
                          style: const TextStyle(
                              color: OnepieceColors.menuTextColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w500))
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getDrawerHeader(BuildContext context) {
    return Container(
      width: 250,
      height: 150,
      color: OnepieceColors.fancyBlue,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 0, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const UserNavigation(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 15, 8, 8),
                      child: Text(
                        getIt<User>().nickname,
                        style: OnepieceFonts.smallHeaderStyleWhite,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: ImageHelper.getSvgIcon(
                              'images/svgs/email.svg',
                              120,
                              120,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            getIt<User>().username,
                            style: OnepieceFonts.emailFont,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                width: 230,
                height: 33,
                decoration: const BoxDecoration(
                  color: OnepieceColors.fancyGreen,
                  borderRadius: BorderRadius.all(Radius.circular(3.0)),
                ),
                child: TextButton(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search,
                        color: OnepieceColors.fancyBlue,
                      ),
                      Text(
                        AppLocalizations.of(context)!.searchResource,
                        style: OnepieceFonts.smallContentStyle,
                      )
                    ],
                  ),
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
        return const Dialog(
          backgroundColor: OnepieceColors.liteFancyBlue,
          alignment: AlignmentDirectional.topCenter,
          child: SearchPopup(),
        );
      }),
    );
  }

  Widget _getSideMenuList(BuildContext context) {
    Map<String, Widget> resourceToIconMap = {
      ResourceType.FRUIT.toString(): ImageHelper.getSvgIcon(
        'images/svgs/fruit.svg',
        20,
        20,
      ),
      ResourceType.GROUP.toString(): const Icon(Icons.group,
          color: OnepieceColors.menuIconColor, size: 20),
      ResourceType.USER.toString(): const Icon(Icons.manage_accounts,
          color: OnepieceColors.menuIconColor, size: 20),
      ResourceType.BATTLE.toString(): const Icon(Icons.sports_mma_outlined,
          color: OnepieceColors.menuIconColor, size: 20),
      ResourceType.CHARACTER.toString():
          const Icon(Icons.face, color: OnepieceColors.menuIconColor, size: 20),
      ResourceType.ISSUE.toString(): const Icon(Icons.add_alert,
          color: OnepieceColors.menuIconColor, size: 20),
      setting: const Icon(Icons.settings,
          color: OnepieceColors.menuIconColor, size: 20)
    };

    Map<String, String> resourceToLocationMap = {
      ResourceType.FRUIT.toString(): AppRouter.fruitPath,
      ResourceType.USER.toString(): AppRouter.userPath,
      ResourceType.BATTLE.toString(): AppRouter.battlePath,
      ResourceType.CHARACTER.toString(): AppRouter.characterPath,
      ResourceType.ISSUE.toString(): AppRouter.issuePath,
      ResourceType.GROUP.toString(): AppRouter.groupPath,
      setting: AppRouter.settingPath
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
      setting: AppLocalizations.of(context)!.settings
    };
    var currentLoginRoleResources =
        loginRoleResources.map((e) => e.toString()).toList();
    currentLoginRoleResources.add(setting);
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
            child: ListTile(
              minLeadingWidth: 10,
              contentPadding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              leading: resourceToIconMap[resourceType],
              selected: selectedResource == resourceType,
              selectedTileColor: OnepieceColors.liteFancyBlue,
              onTap: () {
                setState(
                  () {
                    selectedResource = resourceType;
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
              title: Text(
                resourceToDisplayTextMap[resourceType]!,
                textAlign: TextAlign.left,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: OnepieceFonts.sideMenuFontWeight,
                    color: OnepieceColors.menuTextColor),
              ),
            ),
          ),
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
