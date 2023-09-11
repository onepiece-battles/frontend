import 'package:flutter/material.dart';
import 'package:one_piece_battles_flutter/components/character_view.dart';
import 'package:one_piece_battles_flutter/components/settings_view.dart';
import 'package:one_piece_battles_flutter/components/side_menu.dart';
import 'package:one_piece_battles_flutter/responsive/base_view.dart';
import '../constants/device_type.dart';

class DesktopScaffold extends StatefulWidget {
  const DesktopScaffold({super.key});

  @override
  State<DesktopScaffold> createState() => _DesktopScaffoldState();
}

class _DesktopScaffoldState extends BaseView<DesktopScaffold> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 200,
            child: SideMenu(
              deviceType: DeviceType.desktop,
              pageController: pageController,
            ),
          ),
          Expanded(
            child: PageView(
              controller: pageController,
              children: [
                const CharacterView(),
                Container(
                  color: Colors.blue,
                ),
                Container(
                  color: Colors.green,
                ),
                Container(
                  color: Colors.red,
                ),
                const SettingsView()
              ],
            ),
          ),
        ],
      ),
    );
  }
}
