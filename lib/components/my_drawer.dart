import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/constants/device_type.dart';

import '../utils/image_helper.dart';
import '../utils/onepiece_colors.dart';

int seletedIndex = 0;

class MyDrawer extends StatefulWidget {
  final DeviceType deviceType;
  final PageController? pageController;
  const MyDrawer({super.key, required this.deviceType, this.pageController});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.grey[300],
      width: 200,
      child: Column(
        children: [
          const DrawerHeader(
              child: Icon(Icons.add_alarm, color: OnepieceColors.themeColor)),
          ListTile(
            leading: const Icon(Icons.people, color: OnepieceColors.themeColor),
            selected: seletedIndex == 0,
            selectedTileColor: Colors.white,
            onTap: () {
              setState(() {
                seletedIndex = 0;
                route(seletedIndex);
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
            selected: seletedIndex == 1,
            selectedTileColor: Colors.white,
            onTap: () {
              setState(() {
                seletedIndex = 1;
                route(seletedIndex);
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
            selected: seletedIndex == 2,
            selectedTileColor: Colors.white,
            onTap: () {
              setState(() {
                seletedIndex = 2;
                route(seletedIndex);
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
            selected: seletedIndex == 3,
            selectedTileColor: Colors.white,
            onTap: () {
              setState(() {
                seletedIndex = 3;
                route(seletedIndex);
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
            selected: seletedIndex == 4,
            selectedTileColor: Colors.white,
            onTap: () {
              setState(() {
                seletedIndex = 4;
                route(seletedIndex);
              });
            },
            title: Text(
              AppLocalizations.of(context)!.logout,
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
      widget.pageController!.jumpToPage(seletedIndex);
    }
  }
}
