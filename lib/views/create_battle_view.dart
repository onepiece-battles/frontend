import 'dart:io';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:openapi/api.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../constants/onepiece_colors.dart';
import '../repository/character_dao.dart';

GetIt getIt = GetIt.instance;

class CreateBattleView extends StatefulWidget {
  const CreateBattleView({super.key});

  @override
  State<CreateBattleView> createState() => _CreateBattleViewState();
}

class _CreateBattleViewState extends State<CreateBattleView> {
  List<Character> leftCharacters = [];
  List<Character> rightCharacters = [];
  List<Character> searchResults = [];
  ScrollController _leftScrollController = ScrollController();
  Character? leftSelectedItem;
  int _leftCurrentMax = 10;
  TextEditingController leftTextController = TextEditingController();
  TextEditingController rightTextController = TextEditingController();
  ScrollController _rightScrollController = ScrollController();
  Character? rightSelectedItem;
  int _rightCurrentMax = 10;
  CharacterFilter leftCharacterFilter = CharacterFilter();
  CharacterFilter rightCharacterFilter = CharacterFilter();
  bool _isLoading = false;
  // these two indexes are used when loading more data
  int selectedLeftPageIndex = 1;
  int selectedRightPageIndex = 1;

  @override
  void initState() {
    super.initState();
    _searchLeft();
    _searchRight();
    _leftScrollController.addListener(() {
      if (_leftScrollController.position.pixels ==
          _leftScrollController.position.maxScrollExtent) {
        _loadLeftMoreData();
      }
    });
    _rightScrollController.addListener(() {
      if (_rightScrollController.position.pixels ==
          _rightScrollController.position.maxScrollExtent) {
        _loadRightMoreData();
      }
    });
  }

  @override
  void dispose() {
    leftTextController.dispose();
    _leftScrollController.dispose();
    _rightScrollController.dispose();
    super.dispose();
  }

  void _searchLeft() {
    ListCharacterRequest listCharacterRequest = ListCharacterRequest(
        pageSize: 10,
        pageIndex: 1,
        // do not need to sort in this case.
        sortKeys: [],
        characterFilter: leftCharacterFilter);
    Future<ListCharacterResponse?> listCharacterResponse =
        getIt<CharacterDao>().listCharacter(listCharacterRequest);
    listCharacterResponse.then((value) {
      debugPrint(
          'The selected character names are:${value?.characters.map((e) => e.name).toList().toString()}');
      setState(() {
        leftCharacters = value!.characters;
      });
    });
  }

  void _searchRight() {
    ListCharacterRequest listCharacterRequest = ListCharacterRequest(
        pageSize: 10,
        pageIndex: 1,
        // do not need to sort in this case.
        sortKeys: [],
        characterFilter: rightCharacterFilter);
    Future<ListCharacterResponse?> listCharacterResponse =
        getIt<CharacterDao>().listCharacter(listCharacterRequest);
    listCharacterResponse.then((value) {
      setState(() {
        rightCharacters = value!.characters;
      });
    });
  }

  void _loadLeftMoreData() {
    selectedLeftPageIndex++;
    ListCharacterRequest listCharacterRequest = ListCharacterRequest(
        pageSize: 10,
        pageIndex: selectedLeftPageIndex,
        // do not need to sort in this case.
        sortKeys: [],
        characterFilter: leftCharacterFilter);
    Future<ListCharacterResponse?> listCharacterResponse =
        getIt<CharacterDao>().listCharacter(listCharacterRequest);
    listCharacterResponse.then((value) {
      setState(() {
        var newCharacters = value!.characters;
        leftCharacters.addAll(newCharacters);
      });
    });
  }

  void _loadRightMoreData() {
    selectedRightPageIndex++;
    ListCharacterRequest listCharacterRequest = ListCharacterRequest(
        pageSize: 10,
        pageIndex: selectedRightPageIndex,
        // do not need to sort in this case.
        sortKeys: [],
        characterFilter: rightCharacterFilter);
    Future<ListCharacterResponse?> listCharacterResponse =
        getIt<CharacterDao>().listCharacter(listCharacterRequest);
    listCharacterResponse.then((value) {
      setState(() {
        var newCharacters = value!.characters;
        rightCharacters.addAll(newCharacters);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("create battle"),
      content: Row(
        children: [
          // _getStarterList(context),
          // _getReceiverList(context)
        ],
      ),
    );
  }

  // Widget _getStarterList(BuildContext context) {
  //
  // }
  //
  // Widget _getReceiverList(BuildContext context) {
  //
  // }
}
