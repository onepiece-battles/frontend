import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:one_piece_battles_flutter/components/side_menu.dart';
import 'package:one_piece_battles_flutter/responsive/base_view.dart';
import 'package:openapi/api.dart';
import '../constants/device_type.dart';
import '../constants/onepiece_colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../route/navigation_cubit.dart';
import '../utils/image_helper.dart';

class DesktopScaffold extends StatefulWidget {
  final Widget mainScreen;
  const DesktopScaffold({super.key, required this.mainScreen});

  @override
  State<DesktopScaffold> createState() => _DesktopScaffoldState();
}

class _DesktopScaffoldState extends BaseView<DesktopScaffold> with TickerProviderStateMixin{
  // Map<ResourceType, Widget> resourceNameToViewMap = {
  //   ResourceType.BATTLE: const BattleView(),
  //   ResourceType.USER: const UserView(),
  //   ResourceType.CHARACTER: const CharacterView(),
  //   ResourceType.FRUIT: const FruitView()
  // };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const SizedBox(
            width: 200,
            child: SideMenu(
              deviceType: DeviceType.desktop,
            ),
          ),
          Expanded(
            child: widget.mainScreen,
          ),
        ],
      ),
    );
  }


}
