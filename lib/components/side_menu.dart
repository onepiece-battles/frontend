import 'package:flutter/material.dart';
import 'package:one_piece_battles_flutter/utils/image_helper.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:openapi/api.dart';
import '../constants/device_type.dart';

int selectedIndexGlobal = 0;

class SideMenu extends StatefulWidget {
  final DeviceType deviceType;
  final PageController? pageController;
  final List<ResourceType> resourceTypes;
  const SideMenu(
      {super.key,
      required this.deviceType,
      this.pageController,
      required this.resourceTypes});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[300],
      child: ListView(

        children: _getListTitle(context, widget.resourceTypes)
      ),
    );
  }

  Widget _getDrawerHeader(BuildContext context) {
    return Container();
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
    Map<ResourceType, String> resourceToDisplayTextMap = {
      ResourceType.FRUIT: AppLocalizations.of(context)!.devilFruit,
      ResourceType.USER: AppLocalizations.of(context)!.userManagement,
      ResourceType.BATTLE: AppLocalizations.of(context)!.battle,
      ResourceType.CHARACTER: AppLocalizations.of(context)!.character
    };
    List<Widget> listTitles = [];
    listTitles.add(_getDrawerHeader(context));
    int selectedIndex = 0;
    for (ResourceType resourceType in resourceTypes) {
      listTitles.add(
        ListTile(
          leading: resourceToIconMap[resourceType],
          selected: selectedIndexGlobal == selectedIndex ,
          selectedTileColor: Colors.white,
          onTap: () {
            int localSelectedIndex = selectedIndex;
            setState(
              () {
                selectedIndexGlobal = localSelectedIndex;
                route(selectedIndexGlobal);
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
      selectedIndex++;
    }
    listTitles.add(
      ListTile(
        leading: const Icon(Icons.settings, color: OnepieceColors.themeColor),
        selected: selectedIndexGlobal == selectedIndex,
        selectedTileColor: Colors.white,
        onTap: () {
          int localSelectedIndex = selectedIndex;
          setState(() {
            selectedIndexGlobal = localSelectedIndex;
            route(selectedIndexGlobal);
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

  void route(int selectedIndex) {
    if (DeviceType.desktop != widget.deviceType) {
      Navigator.pop(context);
    }
    if (widget.pageController != null) {
      widget.pageController!.jumpToPage(selectedIndex);
    }
  }
}
