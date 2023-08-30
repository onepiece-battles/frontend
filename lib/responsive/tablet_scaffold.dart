import 'package:flutter/material.dart';
import 'package:one_piece_battles_flutter/constants/device_type.dart';
import 'package:one_piece_battles_flutter/responsive/base_view.dart';

import '../components/my_drawer.dart';
import '../constants/component_constants.dart';
import '../constants/onepiece_colors.dart';

class TabletScaffold extends StatefulWidget {
  const TabletScaffold({super.key});

  @override
  State<TabletScaffold> createState() => _TabletScaffoldState();
}

class _TabletScaffoldState extends BaseView<TabletScaffold> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: myAppBar,
      drawer: MyDrawer(
        deviceType: DeviceType.tablet,
        pageController: pageController,
      ),
      backgroundColor: OnepieceColors.backgroundColor,
      body: PageView(
        controller: pageController,
        children: [
          Container(
            color: Colors.black,
          ),
          Container(
            color: Colors.blue,
          ),
          Container(
            color: Colors.green,
          ),
          Container(
            color: Colors.red,
          ),
          Container(
            color: Colors.yellow,
          )
        ],
      ),
    );
  }
}
