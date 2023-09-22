import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
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
      color: Colors.grey[300],
      child: ListView(
          children: _getListTitle(context, getIt<User>().loginRoleResources)),
    );
  }

  Widget _getDrawerHeader(BuildContext context) {
    return const SizedBox(
      height: 100,
      child: Text("this is the header"),
    );
  }

  List<Widget> _getListTitle(
      BuildContext context, List<ResourceType> resourceTypes) {
    Map<ResourceType, Widget> resourceToIconMap = {
      ResourceType.FRUIT: ImageHelper.getSvgIcon(
        'images/svgs/fruit.svg',
        OnepieceColors.themeColor,
        25,
        25,
      ),
      ResourceType.USER:
          const Icon(Icons.manage_accounts, color: OnepieceColors.themeColor),
      ResourceType.BATTLE: const Icon(Icons.sports_mma_outlined,
          color: OnepieceColors.themeColor),
      ResourceType.CHARACTER:
          const Icon(Icons.face, color: OnepieceColors.themeColor)
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
        ListTile(
          leading: resourceToIconMap[resourceType],
          selected: selectedResource == resourceType.toString(),
          selectedTileColor: Colors.white,
          onTap: () {
            selectedResource = resourceType.toString();
            setState(
              () {
                GoRouter.of(context).go(resourceToLocationMap[resourceType]!);
              },
            );
          },
          title: Text(
            resourceToDisplayTextMap[resourceType]!,
            textAlign: TextAlign.left,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
          ),
        ),
      );
    }
    listTitles.add(
      ListTile(
        leading: const Icon(Icons.settings, color: OnepieceColors.themeColor),
        selected: selectedResource == "setting",
        selectedTileColor: Colors.white,
        onTap: () {
          selectedResource = "setting";
          setState(() {
            GoRouter.of(context).go(AppRouter.settingPath);
          });
        },
        title: Text(
          AppLocalizations.of(context)!.settings,
          textAlign: TextAlign.left,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
        ),
      ),
    );
    return listTitles;
  }
}
