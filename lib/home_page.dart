import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/app_router.dart';
import 'package:one_piece_battles_flutter/config/resource_permission_manager.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/repository/user_dao.dart';
import 'package:one_piece_battles_flutter/utils/base64_helper.dart';
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
  var _tabTextIndexSelected =
      I18nHelper.convertToOnepieceLocale(getIt<Locale>()).toString() ==
              (OnepieceLocale.zhCN.toString())
          ? 0
          : 1;
  UserRole selectedRole = getIt<User>().loginRole!;
  List<ResourceType> loginRoleResources = getIt<User>()
      .loginRoleResources
      .where((e) => !notShownResources.contains(e))
      .toList();
  String selectedResource = ResourceType.CHARACTER.toString();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _getSideMenu(context),
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
    );
  }

  // the first one route is fixed in this case, and the latter routes are clickable
  Row _getHeader(BuildContext context) {
    List<String> routes = GoRouterState.of(context)
        .matchedLocation
        .split("/")
        .where((element) => element != '')
        .toList();
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
                  selectedRole = value!;
                  UpdateLoginRoleRequest request =
                      UpdateLoginRoleRequest(role: selectedRole);
                  getIt<UserDao>().updateLoginRole(request).then((value) {
                    var currentUser = getIt<User>();
                    currentUser.loginRole = value!.currentRole;
                    currentUser.loginRoleResources = value.resources;
                    ResourcePermissionManager.updateUserCache(currentUser);
                  });
                  setState(() {
                    //todo(yichi): will be fixed by fix routing refresh
                    context.go(AppRouter.homePath);
                  });
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
          ),
        )
      ];
    }
  }

  Widget _getSideMenu(BuildContext context) {
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
          ],),


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
      color: OnepieceColors.secondaryThemeColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: Image.memory(
                Base64Helper.decode(getIt<User>().profileImage!),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: RichText(
              text: TextSpan(children: [
                const WidgetSpan(
                    child: Icon(
                  Icons.email,
                  color: Colors.grey,
                  size: 17,
                )),
                TextSpan(
                    text: " ${getIt<User>().email!}",
                    style: OnepieceFonts.emailFont)
              ]),
            ),
          )
        ],
      ),
    );
  }

  Widget _getSideMenuList(BuildContext context) {
    Map<String, Widget> resourceToIconMap = {
      ResourceType.FRUIT.toString(): ImageHelper.getSvgIcon(
        'images/svgs/fruit.svg',
        20,
        20,
      ),
      ResourceType.USER.toString(): const Icon(Icons.manage_accounts,
          color: OnepieceColors.menuIconColor, size: 20),
      ResourceType.BATTLE.toString(): const Icon(Icons.sports_mma_outlined,
          color: OnepieceColors.menuIconColor, size: 20),
      ResourceType.CHARACTER.toString():
          const Icon(Icons.face, color: OnepieceColors.menuIconColor, size: 20),
      ResourceType.ISSUE.toString(): const Icon(Icons.report_problem,
          color: OnepieceColors.menuIconColor, size: 20),
      "setting": const Icon(Icons.settings,
          color: OnepieceColors.menuIconColor, size: 20)
    };

    Map<String, String> resourceToLocationMap = {
      ResourceType.FRUIT.toString(): AppRouter.fruitPath,
      ResourceType.USER.toString(): AppRouter.userPath,
      ResourceType.BATTLE.toString(): AppRouter.battlePath,
      ResourceType.CHARACTER.toString(): AppRouter.characterPath,
      ResourceType.ISSUE.toString(): AppRouter.issuePath,
      "setting": AppRouter.settingPath
    };
    Map<String, String> resourceToDisplayTextMap = {
      ResourceType.FRUIT.toString(): AppLocalizations.of(context)!.devilFruit,
      ResourceType.USER.toString():
          AppLocalizations.of(context)!.userManagement,
      ResourceType.BATTLE.toString(): AppLocalizations.of(context)!.battle,
      ResourceType.CHARACTER.toString():
          AppLocalizations.of(context)!.character,
      ResourceType.ISSUE.toString(): AppLocalizations.of(context)!.issue,
      "setting": AppLocalizations.of(context)!.settings
    };
    var currentLoginRoleResources =
        loginRoleResources.map((e) => e.toString()).toList();
    currentLoginRoleResources.add("setting");
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
                selectedTileColor: OnepieceColors.menuSelectedTileColor,
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
                hoverColor: OnepieceColors.menuHoverColor,
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
        });
  }

  Widget _getMiddleArrow() {
    return const Text(
      ">",
      style: OnepieceFonts.navigationTopBarStyle,
    );
  }
}
