import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:openapi/api.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../repository/character_dao.dart';

GetIt getIt = GetIt.instance;

class CreateBattleView extends StatefulWidget {
  const CreateBattleView({super.key});

  @override
  State<CreateBattleView> createState() => _CreateBattleViewState();
}

List<Character> characters = [];

class _CreateBattleViewState extends State<CreateBattleView> {
  List<Character> leftCharacters = [];
  List<Character> rightCharacters = [];
  List<Character> searchResults = [];
  ScrollController _leftScrollController = ScrollController();
  ScrollController _rightScrollController = ScrollController();
  CharacterFilter characterFilter = CharacterFilter();
  bool _isLoading = false;
  // these two indexes are used when loading more data
  int selectedLeftPageIndex = 1;
  int selectedRightPageIndex = 1;

  @override
  void initState() {
    super.initState();
    _search(leftCharacters);
    _search(rightCharacters);
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
    _leftScrollController.dispose();
    _rightScrollController.dispose();
    super.dispose();
  }

  void _search(List<Character> characters) {
    ListCharacterRequest listCharacterRequest = ListCharacterRequest(
        pageSize: 10,
        pageIndex: 1,
        // do not need to sort in this case.
        sortKeys: [],
        characterFilter: characterFilter);
    Future<ListCharacterResponse?> listCharacterResponse =
        getIt<CharacterDao>().listCharacter(listCharacterRequest);
    listCharacterResponse.then((value) {
      setState(() {
        characters = value!.characters;
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
        characterFilter: characterFilter);
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
        characterFilter: characterFilter);
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
    return Column(
      children: [
        Row(
          children: [_getDropDownList(context), _getDropDownList(context)],
        )
      ],
    );
  }

  Widget _getDropDownList(BuildContext context) {
   return Container();
  }
}
