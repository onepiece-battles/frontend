import 'package:flutter/material.dart';
import 'package:one_piece_battles_flutter/utils/image_helper.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../constants/device_type.dart';

int selectedIndex = 0;

class SideMenu extends StatefulWidget {
  final DeviceType deviceType;
  final PageController? pageController;
  const SideMenu({super.key, required this.deviceType, this.pageController});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[300],
      child: Column(
        children: <Widget>[
          const DrawerHeader(
              child: Icon(Icons.add_alarm, color: OnepieceColors.themeColor)),
          ListTile(
            leading: const Icon(Icons.people, color: OnepieceColors.themeColor),
            selected: selectedIndex == 0,
            selectedTileColor: Colors.white,
            onTap: () {
              setState(() {
                selectedIndex = 0;
                route(selectedIndex);
              });
            },
            title: Text(
              AppLocalizations.of(context)!.character,
              textAlign: TextAlign.left,
              style: const TextStyle(fontSize: 17, fontStyle: FontStyle.italic),
            ),
          ),
          ListTile(
            leading: ImageHelper.getSvgIcon(
              'images/svgs/fruit.svg',
              OnepieceColors.themeColor,
              25,
              25,
            ),
            selected: selectedIndex == 1,
            selectedTileColor: Colors.white,
            onTap: () {
              setState(() {
                selectedIndex = 1;
                route(selectedIndex);
              });
            },
            title: Text(
              AppLocalizations.of(context)!.devilFruit,
              textAlign: TextAlign.left,
              style: const TextStyle(fontSize: 17, fontStyle: FontStyle.italic),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.local_fire_department,
              color: OnepieceColors.themeColor,
            ),
            selected: selectedIndex == 2,
            selectedTileColor: Colors.white,
            onTap: () {
              setState(() {
                selectedIndex = 2;
                route(selectedIndex);
              });
            },
            title: Text(
              AppLocalizations.of(context)!.battle,
              textAlign: TextAlign.left,
              style: const TextStyle(fontSize: 17, fontStyle: FontStyle.italic),
            ),
          ),
          ListTile(
            leading:
                const Icon(Icons.settings, color: OnepieceColors.themeColor),
            selected: selectedIndex == 3,
            selectedTileColor: Colors.white,
            onTap: () {
              setState(() {
                selectedIndex = 3;
                route(selectedIndex);
              });
            },
            title: Text(
              AppLocalizations.of(context)!.settings,
              textAlign: TextAlign.left,
              style: const TextStyle(fontSize: 17, fontStyle: FontStyle.italic),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: OnepieceColors.themeColor),
            selected: selectedIndex == 4,
            selectedTileColor: Colors.white,
            onTap: () {
              setState(() {
                selectedIndex = 4;
                route(selectedIndex);
              });
            },
            title: Text(
              AppLocalizations.of(context)!.logout,
              textAlign: TextAlign.left,
              style: const TextStyle(fontSize: 17, fontStyle: FontStyle.italic),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: OnepieceColors.themeColor),
            selected: selectedIndex == 5,
            selectedTileColor: Colors.white,
            onTap: () {
              setState(() {
                selectedIndex = 5;
                route(selectedIndex);
              });
            },
            title: Text(
              AppLocalizations.of(context)!.settings,
              textAlign: TextAlign.left,
              style: const TextStyle(fontSize: 17, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
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
