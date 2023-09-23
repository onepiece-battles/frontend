import 'package:flutter/material.dart';
import 'package:one_piece_battles_flutter/components/side_menu.dart';
import 'package:one_piece_battles_flutter/responsive/base_view.dart';
import '../constants/device_type.dart';

class DesktopScaffold extends StatefulWidget {
  final Widget mainScreen;
  const DesktopScaffold({super.key, required this.mainScreen});

  @override
  State<DesktopScaffold> createState() => _DesktopScaffoldState();
}

class _DesktopScaffoldState extends BaseView<DesktopScaffold> with TickerProviderStateMixin{

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
          Expanded(child: widget.mainScreen,)
        ],
      ),
    );
  }


}
