import 'package:flutter/material.dart';

class BattleDetailView extends StatefulWidget {
  const BattleDetailView({super.key});

  @override
  State<BattleDetailView> createState() => _BattleDetailViewState();
}

class _BattleDetailViewState extends State<BattleDetailView> {
  @override
  Widget build(BuildContext context) {
    return  Container(color: Colors.yellow,child: const Text("this is battle detail"),);
  }
}
