import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/components/side_menu.dart';
import 'package:one_piece_battles_flutter/config/app_router.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'constants/device_type.dart';

class HomePage extends StatefulWidget {
  final Widget mainScreen;
  const HomePage({super.key, required this.mainScreen});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const SizedBox(
            width: 250,
            child: SideMenu(
              deviceType: DeviceType.desktop,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: 55,
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: _getHeaderRoute(
                        GoRouterState.of(context)
                            .fullPath!
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
  Row _getHeaderRoute(List<String> routes, BuildContext context) {
    Map<String, String> routePathToDisplayName = {
      'home': AppLocalizations.of(context)!.home,
      'character': AppLocalizations.of(context)!.character,
      'fruit': AppLocalizations.of(context)!.devilFruit,
      'user': AppLocalizations.of(context)!.userManagement,
      'battle': AppLocalizations.of(context)!.battle,
      'setting': AppLocalizations.of(context)!.settings,
    };
    bool isFirst = true;
    String currentRoutePath = "";
    return Row(
        children: routes.expand<Widget>((route) {
      currentRoutePath = "$currentRoutePath/$route";
      var result = _getTextButton(
          routePathToDisplayName[route]!, currentRoutePath, isFirst);
      isFirst = false;
      return result;
    }).toList());
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
    return const Text(" > ");
  }
}
