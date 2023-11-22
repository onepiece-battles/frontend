import 'package:flutter/material.dart';

class CreateFruitView extends StatefulWidget {
  const CreateFruitView({Key? key}) : super(key: key);

  @override
  State<CreateFruitView> createState() => _CreateFruitViewState();
}

class _CreateFruitViewState extends State<CreateFruitView> {
  @override
  Widget build(BuildContext context) {
    return Container(child: Text("this is fruit view"),);
  }
}
