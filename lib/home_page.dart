import 'package:flutter/material.dart';
import 'package:one_piece_battles_flutter/components/side_menu.dart';
import 'package:one_piece_battles_flutter/utils/onepiece_colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController pageController = PageController(initialPage: 0);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: OnepieceColors.black,
        toolbarHeight: 10,
        leading: const Icon(Icons.abc_outlined),
        title: const Text(
          "Welcome to onepiece",
          style: TextStyle(
            color: Colors.white,
            fontSize: 6,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.all(15),
            child: IconButton(
              iconSize: 8,
              icon: const Icon(
                Icons.person,
              ),
              onPressed: () {},
            ),
          ),
          IconButton(
            iconSize: 10,
            icon: const Icon(
              Icons.person,
            ),
            onPressed: () {},
          ),
        ],
        // toolbarHeight: 12,
      ),
      body: SafeArea(
          child: SizedBox.expand(
        child: PageView(
          controller: pageController,
        ),
      )),
    );
  }
}
