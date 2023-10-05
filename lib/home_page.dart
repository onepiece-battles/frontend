import 'package:flutter/material.dart';
import 'package:one_piece_battles_flutter/components/side_menu.dart';
import 'constants/device_type.dart';

class HomePage extends StatefulWidget {
  final Widget mainScreen;
  const HomePage({super.key, required this.mainScreen});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const SizedBox(
            width: 250,
            child: SideMenu(
              deviceType: DeviceType.desktop,
            ),
          ),
          Expanded(
            child: widget.mainScreen,
          )
        ],
      ),
    );
  }
}
