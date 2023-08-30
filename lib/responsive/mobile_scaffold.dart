import 'package:flutter/material.dart';
import 'package:one_piece_battles_flutter/constants/component_constants.dart';
import 'package:one_piece_battles_flutter/constants/device_type.dart';
import 'package:one_piece_battles_flutter/responsive/base_view.dart';

import '../components/my_drawer.dart';
import '../constants/onepiece_colors.dart';

class MobileScaffold extends StatefulWidget {
  const MobileScaffold({super.key});

  @override
  State<MobileScaffold> createState() => _MobileScaffoldState();
}

class _MobileScaffoldState extends BaseView<MobileScaffold> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: myAppBar,
      drawer: MyDrawer(
        deviceType: DeviceType.mobile,
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
