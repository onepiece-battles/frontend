import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:one_piece_battles_flutter/repository/group_dao.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:openapi/api.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../constants/onepiece_colors.dart';
import '../repository/character_dao.dart';
import '../repository/fruit_dao.dart';
import '../utils/base64_helper.dart';

GetIt getIt = GetIt.instance;
Timer? _timer;

class SearchPopup extends StatefulWidget {
  const SearchPopup({super.key});

  @override
  State<SearchPopup> createState() => _SearchPopupState();
}

class _SearchPopupState extends State<SearchPopup> {
  TextEditingController searchBarController = TextEditingController();
  List<CharacterListView> characters =
      <CharacterListView>[].toList(growable: true);
  CharacterFilter characterFilter = CharacterFilter();
  List<FruitListView> fruits = <FruitListView>[].toList(growable: true);
  FruitFilter fruitFilter = FruitFilter();
  List<Battle> battle = [];
  GroupFilter groupFilter = GroupFilter();
  List<GroupListView> groups = [];

  _search(String name) {
    characterFilter.languageCode = I18nHelper.getLanguageCode();
    fruitFilter.languageCode = I18nHelper.getLanguageCode();
    groupFilter.languageCode = I18nHelper.getLanguageCode();
    if (name.isEmpty) {
      setState(() {
        characters = [];
        fruits = [];
        groups = [];
      });
      return;
    }
    characterFilter.name = name;
    fruitFilter.name = name;
    ListCharacterRequest listCharacterRequest = ListCharacterRequest(
        pageSize: 6,
        pageIndex: 1,
        sortKeys: [],
        characterFilter: characterFilter);
    Future<ListCharacterResponse?> listCharacterResponse =
        getIt<CharacterDao>().listCharacter(listCharacterRequest);
    listCharacterResponse.then((value) {
      setState(() {
        characters = value!.characters;
      });
    });

    ListFruitRequest request = ListFruitRequest(
        pageSize: 6, pageIndex: 1, sortKeys: [], fruitFilter: fruitFilter);
    Future<ListFruitResponse?> listFruitResponse =
        getIt<FruitDao>().list(request);
    listFruitResponse.then((value) {
      setState(() {
        fruits = value!.fruits;
      });
    });

    groupFilter.name = name;
    ListGroupRequest listGroupRequest = ListGroupRequest(
        pageSize: 6, pageIndex: 1, sortKeys: [], groupFilter: groupFilter);
    Future<ListGroupResponse?> listGroupResponse =
        getIt<GroupDao>().listGroups(listGroupRequest);
    listGroupResponse.then((value) {
      setState(() {
        groups = value!.groups;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    ScrollController scrollController = ScrollController();
    return SingleChildScrollView(
      controller: scrollController,
      scrollDirection: Axis.vertical,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 800, child: _getSearchBar()),
          if (characters.isNotEmpty)
            SizedBox(
              width: 800,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.character,
                      style: OnepieceFonts.selectedTableHeaderStyle,
                    ),
                    const Divider(
                      height: 3,
                    )
                  ],
                ),
              ),
            ),
          SizedBox(
              width: 800,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _getCharacterList(),
              )),
          if (fruits.isNotEmpty)
            SizedBox(
              width: 800,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.devilFruit,
                      style: OnepieceFonts.selectedTableHeaderStyle,
                    ),
                    const Divider(
                      height: 3,
                    )
                  ],
                ),
              ),
            ),
          SizedBox(
              width: 800,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _getFruitList(),
              )),
          if (groups.isNotEmpty)
            SizedBox(
              width: 800,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.group,
                      style: OnepieceFonts.selectedTableHeaderStyle,
                    ),
                    const Divider(
                      height: 3,
                    )
                  ],
                ),
              ),
            ),
          SizedBox(
              width: 800,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _getGroupList(),
              )),
          if (characters.isNotEmpty || fruits.isNotEmpty || groups.isNotEmpty)
            const SizedBox(
              width: 800,
              height: 30,
            )
        ],
      ),
    );
  }

  Widget _getSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: TextFormField(
        controller: searchBarController,
        decoration: InputDecoration(
          disabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: OnepieceColors.menuHoverColor)),
          enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: OnepieceColors.menuHoverColor)),
          focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: OnepieceColors.fancyGreen)),
          prefixIcon: const Icon(Icons.search),
          labelText: AppLocalizations.of(context)!.searchResourceDetail,
        ),
        onChanged: (value) {
          if (_timer?.isActive ?? false) _timer?.cancel();
          _timer = Timer(const Duration(milliseconds: 500), () {
            _search(value);
          });
        },
      ),
    );
  }

  Widget _getCharacterList() {
    debugPrint("build new character list, length ${characters.length}");
    return ListView.builder(
        shrinkWrap: true,
        itemCount: characters.length,
        itemBuilder: (context, index) {
          var character = characters[index];
          return Material(
            type: MaterialType.transparency,
            child: Container(
              padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
              decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(5))),
              child: ListTile(
                minLeadingWidth: 10,
                contentPadding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                onTap: () {
                  setState(
                    () {
                      context.goNamed('characterDetails',
                          extra: character.id,
                          pathParameters: {
                            'name': I18nHelper.getDisplayNameFromI18n(
                                character.name)
                          });
                      Navigator.pop(context);
                    },
                  );
                },
                hoverColor: OnepieceColors.liteFancyBlue,
                title: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(2.0)),
                          border: Border.all(
                              color: Colors.grey,
                              width: 2,
                              style: BorderStyle.solid),
                        ),
                        child: FittedBox(
                          fit: BoxFit.fill,
                          child: Image.memory(
                              Base64Helper.decode(character.profileImage!)),
                        ),
                      ),
                    ),
                    Text(I18nHelper.getDisplayNameFromI18n(character.name))
                  ],
                ),
              ),
            ),
          );
        });
  }

  Widget _getFruitList() {
    return ListView.builder(
        shrinkWrap: true,
        itemCount: fruits.length,
        itemBuilder: (context, index) {
          var fruit = fruits[index];
          return Material(
            type: MaterialType.transparency,
            child: Container(
              padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
              decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(5))),
              child: ListTile(
                minLeadingWidth: 10,
                contentPadding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                onTap: () {
                  setState(
                    () {
                      context.goNamed('fruitDetails',
                          extra: fruit.id,
                          pathParameters: {
                            'name':
                                I18nHelper.getDisplayNameFromI18n(fruit.name!)
                          });
                      Navigator.pop(context);
                    },
                  );
                },
                hoverColor: OnepieceColors.liteFancyBlue,
                title: Row(
                  children: [
                    Text(I18nHelper.getDisplayNameFromI18n(fruit.name!))
                  ],
                ),
              ),
            ),
          );
        });
  }

  Widget _getGroupList() {
    return ListView.builder(
        shrinkWrap: true,
        itemCount: groups.length,
        itemBuilder: (context, index) {
          var group = groups[index];
          return Material(
            type: MaterialType.transparency,
            child: Container(
              padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
              decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(5))),
              child: ListTile(
                minLeadingWidth: 10,
                contentPadding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                onTap: () {
                  // todo(yichi): update left side menu
                  setState(
                    () {
                      context.goNamed('groupDetails',
                          extra: group.id,
                          pathParameters: {
                            'name':
                                I18nHelper.getDisplayNameFromI18n(group.name)
                          });
                      Navigator.pop(context);
                    },
                  );
                },
                hoverColor: OnepieceColors.liteFancyBlue,
                title: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(2.0)),
                          border: Border.all(
                              color: Colors.grey,
                              width: 2,
                              style: BorderStyle.solid),
                        ),
                        child: FittedBox(
                          fit: BoxFit.fill,
                          child: Image.memory(
                              Base64Helper.decode(group.profileImage!)),
                        ),
                      ),
                    ),
                    Text(I18nHelper.getDisplayNameFromI18n(group.name))
                  ],
                ),
              ),
            ),
          );
        });
  }
}
