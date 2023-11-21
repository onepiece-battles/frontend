import 'package:flutter/material.dart';

class BattleDetailView extends StatefulWidget {
  final String battleId;
  const BattleDetailView({super.key, required this.battleId});

  @override
  State<BattleDetailView> createState() => _BattleDetailViewState();
}

class _BattleDetailViewState extends State<BattleDetailView> {
  @override
  Widget build(BuildContext context) {
    return  Container(color: Colors.yellow,child: const Text("this is battle detail"),);
  }
}
