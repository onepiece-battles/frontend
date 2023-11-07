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
  List<Character> characters = [];
  List<Character> searchResults = [];
  ScrollController _scrollController = ScrollController();
  CharacterFilter characterFilter = CharacterFilter();
  bool _isLoading = false;
  int pageSize = 10;
  int selectedPageIndex =0;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _search() {
    selectedPageIndex++;
    ListCharacterRequest listCharacterRequest = ListCharacterRequest(
        pageSize: pageSize,
        pageIndex: selectedPageIndex,
        // do not need to sort in this case.
        sortKeys: [],
        characterFilter: characterFilter);
    Future<ListCharacterResponse?> listCharacterResponse =
    getIt<CharacterDao>().listCharacter(listCharacterRequest);
    listCharacterResponse.then((value) {
      setState(() {
        var newCharacters = value!.characters;
        characters.addAll(newCharacters);
      });
    });
  }

  void _loadMoreData() {
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }
    _search();
    setState(() {
      _isLoading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        _getDropDownList(context),
    _getDropDownList(context)
      ],)
    ],);
  }

  Widget _getDropDownList(BuildContext context) {
    return Container();
  }
}
