import 'package:flutter/material.dart';
import 'package:one_piece_battles_flutter/components/battle_view.dart';
import 'package:one_piece_battles_flutter/components/character_view.dart';
import 'package:one_piece_battles_flutter/components/settings_view.dart';
import 'package:one_piece_battles_flutter/components/side_menu.dart';
import 'package:one_piece_battles_flutter/components/user_view.dart';
import 'package:one_piece_battles_flutter/responsive/base_view.dart';
import 'package:openapi/api.dart';
import '../components/fruit_view.dart';
import '../constants/device_type.dart';

class DesktopScaffold extends StatefulWidget {
  static const  List<ResourceType> displayedResources = [
    ResourceType.CHARACTER,
    ResourceType.BATTLE,
    ResourceType.FRUIT,
    ResourceType.USER
  ];
  const DesktopScaffold({super.key});

  @override
  State<DesktopScaffold> createState() => _DesktopScaffoldState();
}

class _DesktopScaffoldState extends BaseView<DesktopScaffold> with TickerProviderStateMixin{
  Map<ResourceType, Widget> resourceNameToViewMap = {
    ResourceType.BATTLE: const BattleView(),
    ResourceType.USER: const UserView(),
    ResourceType.CHARACTER: const CharacterView(),
    ResourceType.FRUIT: const FruitView()
  };


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
              resourceTypes: DesktopScaffold.displayedResources,
            ),
          ),
          Expanded(
            child: PageView(
              controller: pageController,
              children: _getDisplayedViews(DesktopScaffold.displayedResources),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _getDisplayedViews(List<ResourceType> displayedResources) {
    debugPrint(displayedResources.toString());
    List<Widget> views = [];
    for (ResourceType resourceType in displayedResources) {
      views.add(resourceNameToViewMap[resourceType]!);
    }
    views.add(const SettingsView());
    return views;
  }
}
