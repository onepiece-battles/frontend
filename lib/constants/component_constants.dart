import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../utils/image_helper.dart';
import 'onepiece_colors.dart';

var myAppBar = AppBar(
  backgroundColor: Colors.grey[300],
);

var myDrawer = (context) => Drawer(
      backgroundColor: Colors.grey[300],
      width: 200,
      child: Column(
        children: [
          const DrawerHeader(
              child: Icon(Icons.add_alarm, color: OnepieceColors.themeColor)),
          ListTile(
            leading: const Icon(Icons.people, color: OnepieceColors.themeColor),
            selected: true,
            selectedColor: Colors.black,
            title: TextButton(
              child: Text(
                AppLocalizations.of(context)!.character,
                textAlign: TextAlign.left,
                style:
                    const TextStyle(fontSize: 17, fontStyle: FontStyle.italic),
              ),
              onPressed: () {},
            ),
          ),
          ListTile(
            leading: const Icon(Icons.people, color: OnepieceColors.themeColor),
            onTap: () {},
            selected: true,
            selectedTileColor: Colors.white,
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
            selected: false,
            title: TextButton(
              child: Text(
                AppLocalizations.of(context)!.devilFruit,
                textAlign: TextAlign.left,
                style:
                    const TextStyle(fontSize: 17, fontStyle: FontStyle.italic),
              ),
              onPressed: () {},
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.local_fire_department,
              color: OnepieceColors.themeColor,
            ),
            selected: false,
            title: TextButton(
              child: Text(
                AppLocalizations.of(context)!.battle,
                textAlign: TextAlign.left,
                style:
                    const TextStyle(fontSize: 17, fontStyle: FontStyle.italic),
              ),
              onPressed: () {},
            ),
          ),
          ListTile(
            leading:
                const Icon(Icons.settings, color: OnepieceColors.themeColor),
            selected: false,
            title: TextButton(
              child: Text(
                AppLocalizations.of(context)!.settings,
                textAlign: TextAlign.left,
                style:
                    const TextStyle(fontSize: 17, fontStyle: FontStyle.italic),
              ),
              onPressed: () {},
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: OnepieceColors.themeColor),
            selected: false,
            title: TextButton(
              child: Text(
                AppLocalizations.of(context)!.logout,
                textAlign: TextAlign.left,
                style:
                    const TextStyle(fontSize: 17, fontStyle: FontStyle.italic),
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
