import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

class CharacterDetail extends StatefulWidget {
  final Character character;
  const CharacterDetail({super.key,
    required this.character
  });

  @override
  State<CharacterDetail> createState() => _CharacterDetailState();
}

class _CharacterDetailState extends State<CharacterDetail> {
  @override
  Widget build(BuildContext context) {
    return  Container(color: Colors.yellow,child: const Text("this is character detail"),);
  }
}
