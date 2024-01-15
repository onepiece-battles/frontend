import 'package:flutter/material.dart';

class FruitDetailView extends StatefulWidget {
  final String fruitId;
  const FruitDetailView({super.key, required this.fruitId});

  @override
  State<FruitDetailView> createState() => _FruitDetailViewState();
}

class _FruitDetailViewState extends State<FruitDetailView> {
  @override
  Widget build(BuildContext context) {
    return  Container(color: Colors.yellow,child: const Text("this is fruit detail"),);
  }
}
