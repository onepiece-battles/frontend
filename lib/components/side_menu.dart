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
import '../utils/base64_helper.dart';

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
  String selectedResource = ResourceType.CHARACTER.toString();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: OnepieceColors.menuBackgroundColor,
      child: ListView(
          children: _getListTitle(context, getIt<User>().loginRoleResources)),
    );
  }

  Widget _getDrawerHeader(BuildContext context) {
    return Container(
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
              //Text(,style: ,
              child: RichText( text: TextSpan(children: [
                 const WidgetSpan(child: Icon(Icons.email, color: Colors.grey, size: 17,)),
                TextSpan(text: " ${getIt<User>().email!}",style: OnepieceFonts.emailFont)
              ]),),
            )
          ],
        ));
  }

  List<Widget> _getListTitle(
      BuildContext context, List<ResourceType> resourceTypes) {
    Map<ResourceType, Widget> resourceToIconMap = {
      ResourceType.FRUIT: ImageHelper.getSvgIcon(
        'images/svgs/fruit.svg',
        OnepieceColors.menuIconColor,
        20,
        20,
      ),
      ResourceType.USER: const Icon(Icons.manage_accounts,
          color: OnepieceColors.menuIconColor, size: 20),
      ResourceType.BATTLE: const Icon(Icons.sports_mma_outlined,
          color: OnepieceColors.menuIconColor, size: 20),
      ResourceType.CHARACTER:
          const Icon(Icons.face, color: OnepieceColors.menuIconColor, size: 20)
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
    listTitles.add(Padding(
      padding: const EdgeInsets.fromLTRB(18, 10,0,10),
      child: Text(AppLocalizations.of(context)!.route, style: const TextStyle(fontSize: 18, fontWeight:  FontWeight.w800)),
    ));
    for (ResourceType resourceType in resourceTypes) {
      listTitles.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 1, 8, 1),
          child: Material(
            type: MaterialType.transparency,
            child: ListTile(
              minLeadingWidth: 10,
              contentPadding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              leading: resourceToIconMap[resourceType],
              selected: selectedResource == resourceType.toString(),
              selectedTileColor: OnepieceColors.menuSelectedTileColor,
              onTap: () {
                setState(
                  () {
                    selectedResource = resourceType.toString();
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            minLeadingWidth: 10,
            contentPadding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
            selected: selectedResource == "setting",
            selectedTileColor: OnepieceColors.menuSelectedTileColor,
            onTap: () {
              setState(() {
                selectedResource = "setting";
                GoRouter.of(context).go(AppRouter.settingPath);
              });
            },
            hoverColor: OnepieceColors.menuHoverColor,
            title: Text(
              AppLocalizations.of(context)!.settings,
              textAlign: TextAlign.left,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: OnepieceFonts.sideMenuFontWeight,
                  color: OnepieceColors.menuTextColor),
            ),
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
          ),
        ),
      ),
    );
    return listTitles;
  }
}
