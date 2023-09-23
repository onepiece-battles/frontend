import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:one_piece_battles_flutter/route/app_router.dart';
import 'package:one_piece_battles_flutter/utils/image_helper.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:openapi/api.dart';
import '../constants/device_type.dart';

String selectedResource = ResourceType.CHARACTER.toString();
GetIt getIt = GetIt.instance;

class SideMenu extends StatefulWidget {
  final DeviceType deviceType;
  const SideMenu({
    super.key,
    required this.deviceType,
  });

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: OnepieceColors.menuBackgroundColor,
      child: ListView(
          children: _getListTitle(context, getIt<User>().loginRoleResources)),
    );
  }

  Widget _getDrawerHeader(BuildContext context) {
    return const SizedBox(
      height: 100,
      child: Column(
        children: [Row()],
      ),
    );
  }

  List<Widget> _getListTitle(
      BuildContext context, List<ResourceType> resourceTypes) {
    Map<ResourceType, Widget> resourceToIconMap = {
      ResourceType.FRUIT: ImageHelper.getSvgIcon(
        'images/svgs/fruit.svg',
        OnepieceColors.menuIconColor,
        25,
        25,
      ),
      ResourceType.USER: const Icon(Icons.manage_accounts,
          color: OnepieceColors.menuIconColor),
      ResourceType.BATTLE: const Icon(Icons.sports_mma_outlined,
          color: OnepieceColors.menuIconColor),
      ResourceType.CHARACTER:
          const Icon(Icons.face, color: OnepieceColors.menuIconColor)
    };

    Map<ResourceType, String> resourceToLocationMap = {
      ResourceType.FRUIT: AppRouter.fruitPath,
      ResourceType.USER: AppRouter.userPath,
      ResourceType.BATTLE: AppRouter.battlePath,
      ResourceType.CHARACTER: AppRouter.characterPath
    };
    Map<ResourceType, String> resourceToDisplayTextMap = {
      ResourceType.FRUIT: AppLocalizations.of(context)!.devilFruit,
      ResourceType.USER: AppLocalizations.of(context)!.userManagement,
      ResourceType.BATTLE: AppLocalizations.of(context)!.battle,
      ResourceType.CHARACTER: AppLocalizations.of(context)!.character
    };
    List<Widget> listTitles = [];
    listTitles.add(_getDrawerHeader(context));
    for (ResourceType resourceType in resourceTypes) {
      listTitles.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 1, 8, 1),
          child: Material(
            type: MaterialType.transparency,
            child: ListTile(
              minLeadingWidth: 10,
              minVerticalPadding: 1,
              leading: resourceToIconMap[resourceType],
              selected: selectedResource == resourceType.toString(),
              selectedTileColor: OnepieceColors.menuSelectedTileColor,
              onTap: () {
                selectedResource = resourceType.toString();
                setState(
                  () {
                    GoRouter.of(context)
                        .go(resourceToLocationMap[resourceType]!);
                  },
                );
              },
              hoverColor: OnepieceColors.menuHoverColor,
              title: Text(
                resourceToDisplayTextMap[resourceType]!,
                textAlign: TextAlign.left,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: OnepieceFonts.sideMenuFontWeight,
                    color: OnepieceColors.menuTextColor),
              ),
            ),
          ),
        ),
      );
    }
    listTitles.add(
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 1, 8, 1),
        child: Material(
          type: MaterialType.transparency,
          child: ListTile(
            leading: const Icon(Icons.settings,
                color: OnepieceColors.menuIconColor, size: 20),
            minLeadingWidth: 10,
            selected: selectedResource == "setting",
            selectedTileColor: OnepieceColors.menuSelectedTileColor,
            onTap: () {
              selectedResource = "setting";
              setState(() {
                GoRouter.of(context).go(AppRouter.settingPath);
              });
            },
            hoverColor: OnepieceColors.menuHoverColor,
            title: Text(
              AppLocalizations.of(context)!.settings,
              textAlign: TextAlign.left,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: OnepieceFonts.sideMenuFontWeight,
                  color: OnepieceColors.menuTextColor),
            ),
          ),
        ),
      ),
    );
    return listTitles;
  }
}
