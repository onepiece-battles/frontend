import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:one_piece_battles_flutter/config/app_router.dart';
import 'package:one_piece_battles_flutter/utils/image_helper.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/views/create_feedback_view.dart';
import 'package:openapi/api.dart';
import '../constants/device_type.dart';
import '../utils/base64_helper.dart';

GetIt getIt = GetIt.instance;
List<ResourceType> notShownResources = [ResourceType.ROLE];

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
      child: Stack(
        children: [
          ListView(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              children: _getSideMenuList(
                  context,
                  getIt<User>()
                      .loginRoleResources
                      .where((element) => !notShownResources.contains(element))
                      .toSet())),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: SizedBox(
                width: 110,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: OnepieceColors.menuBackgroundColor,
                        foregroundColor: OnepieceColors.menuIconColor,
                        elevation: 0.0,
                        shadowColor: Colors.transparent,
                        textStyle: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w400)),
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
                            OnepieceColors.menuIconColor,
                            25,
                            25,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppLocalizations.of(context)!.feedback,
                            style: const TextStyle(
                              color: OnepieceColors.menuTextColor,
                            ),
                          )
                        ],
                      ),
                    )),
              ),
            ),
          )
        ],
      ),
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
        ));
  }

  List<Widget> _getSideMenuList(
      BuildContext context, Set<ResourceType> resourceTypes) {
    List<Widget> sideMenuList = [];
    sideMenuList.add(_getDrawerHeader(context));
    sideMenuList.add(Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 0, 10),
      child: Text(AppLocalizations.of(context)!.route,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
    ));
    for (ResourceType resourceType in resourceTypes) {
      sideMenuList.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 1, 8, 1),
          child: Material(
              type: MaterialType.transparency,
              child: _getListTile(context, resourceType)),
        ),
      );
    }
    sideMenuList.add(
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 1, 8, 1),
        child: Material(
            type: MaterialType.transparency,
            child: _getListTile(context, null)),
      ),
    );
    return sideMenuList;
  }

  Widget _getListTile(BuildContext context, ResourceType? resourceType) {
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
          const Icon(Icons.face, color: OnepieceColors.menuIconColor, size: 20),
      ResourceType.ISSUE: const Icon(Icons.report_problem,
          color: OnepieceColors.menuIconColor, size: 20)
    };

    Map<ResourceType, String> resourceToLocationMap = {
      ResourceType.FRUIT: AppRouter.fruitPath,
      ResourceType.USER: AppRouter.userPath,
      ResourceType.BATTLE: AppRouter.battlePath,
      ResourceType.CHARACTER: AppRouter.characterPath,
      ResourceType.ISSUE: AppRouter.issuePath
    };
    Map<ResourceType, String> resourceToDisplayTextMap = {
      ResourceType.FRUIT: AppLocalizations.of(context)!.devilFruit,
      ResourceType.USER: AppLocalizations.of(context)!.userManagement,
      ResourceType.BATTLE: AppLocalizations.of(context)!.battle,
      ResourceType.CHARACTER: AppLocalizations.of(context)!.character,
      ResourceType.ISSUE: AppLocalizations.of(context)!.issue,
    };
    return ListTile(
      minLeadingWidth: 10,
      contentPadding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      leading: resourceToIconMap[resourceType] ?? const Icon(Icons.settings),
      selected:
          GoRouterState.of(context).fullPath!.split("/")[2].toUpperCase() ==
              (resourceType ?? "setting"),
      selectedTileColor: OnepieceColors.menuSelectedTileColor,
      onTap: () {
        setState(
          () {
            GoRouter.of(context).go(
                resourceToLocationMap[resourceType] ?? AppRouter.settingPath);
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
        resourceToDisplayTextMap[resourceType] ??
            AppLocalizations.of(context)!.settings,
        textAlign: TextAlign.left,
        style: const TextStyle(
            fontSize: 18,
            fontWeight: OnepieceFonts.sideMenuFontWeight,
            color: OnepieceColors.menuTextColor),
      ),
    );
  }
}
