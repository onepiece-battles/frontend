import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/components/image_lazy_loader.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_tag.dart';
import 'package:one_piece_battles_flutter/repository/group_dao.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:one_piece_battles_flutter/utils/image_helper.dart';
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
        pageSize: 10,
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
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: _getSearchBar(context),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                  child: _getCharacterList(context),
                ),
              ),
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
                  child: _getFruitList(context),
                ),
              ),
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
                  child: _getGroupList(context),
                ),
              ),
            ],
          ),
          if (characters.isNotEmpty || fruits.isNotEmpty || groups.isNotEmpty)
            const SizedBox(
              width: 800,
              height: 30,
            )
        ],
      ),
    );
  }

  Widget _getSearchBar(BuildContext context) {
    return SizedBox(
      width: 800,
      child: TextFormField(
        autofocus: true,
        controller: searchBarController,
        decoration: InputDecoration(
          floatingLabelAlignment: FloatingLabelAlignment.center,
          floatingLabelStyle: OnepieceFonts.smallHeaderStyleFancyBlue,
          labelStyle: OnepieceFonts.contentStyleBold,
          disabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: OnepieceColors.fancyGreen)),
          enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: OnepieceColors.fancyGreen)),
          focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: OnepieceColors.fancyGreen)),
          prefixIcon: const Icon(
            Icons.search,
            color: Colors.white,
          ),
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

  Widget _getCharacterList(BuildContext context) {
    Map<Haki, String> hakiEnumValueToDisplayValue = {
      Haki.busoshoku: AppLocalizations.of(context)!.busoshoku,
      Haki.haoshoku: AppLocalizations.of(context)!.haoshoku,
      Haki.kenbunshoku: AppLocalizations.of(context)!.kenbunshoku,
    };
    return ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 300.0, // Set your maximum height here
        ),
        child: ListView.builder(
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
                    Navigator.pop(context);
                    context.goNamed('characterDetails',
                        extra: character.id,
                        pathParameters: {
                          'name':
                              I18nHelper.getDisplayNameFromI18n(character.name)
                        });
                  },
                  hoverColor: OnepieceColors.liteFancyBlue,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(3, 3, 6, 3),
                            child: ImageLazyLoader(
                                key: UniqueKey(),
                                uriProvider: () => character.imageUri!,
                                width: 50,
                                borderWidth: 2,
                                borderRadios: 10),
                          ),
                          Text(
                            I18nHelper.getDisplayNameFromI18n(character.name),
                            style: OnepieceFonts.smallContentStyleWhite,
                          )
                        ],
                      ),
                      if (character.hakis.isNotEmpty)
                        Row(
                          children: character.hakis
                              .map((e) => Padding(
                                    padding: const EdgeInsets.only(right: 5),
                                    child: OnepieceTag.getHakiTag(
                                        e, hakiEnumValueToDisplayValue[e]!),
                                  ))
                              .toList(),
                        )
                    ],
                  ),
                ),
              ),
            );
          },
        ));
  }

  Widget _getFruitList(BuildContext context) {
    Map<FruitType, String> fruitTypeToDisplayValue = {
      FruitType.logia: AppLocalizations.of(context)!.logiaFruit,
      FruitType.zoan: AppLocalizations.of(context)!.zoanFruit,
      FruitType.ancientZoan: AppLocalizations.of(context)!.ancientZoanFruit,
      FruitType.mythicalZoan: AppLocalizations.of(context)!.mythicalZoanFruit,
      FruitType.artificialZoan:
          AppLocalizations.of(context)!.artificialZoanFruit,
      FruitType.paramecia: AppLocalizations.of(context)!.parameciaFruit,
    };
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 300.0, // Set your maximum height here
      ),
      child: ListView.builder(
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
                    Navigator.pop(context);
                    context.goNamed('fruitDetails',
                        extra: fruit.id,
                        pathParameters: {
                          'name': I18nHelper.getDisplayNameFromI18n(fruit.name!)
                        });
                  },
                  hoverColor: OnepieceColors.liteFancyBlue,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        I18nHelper.getDisplayNameFromI18n(fruit.name!),
                        style: OnepieceFonts.smallContentStyleWhite,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: OnepieceTag.getFruitTag(fruit.fruitType!,
                            fruitTypeToDisplayValue[fruit.fruitType]!),
                      )
                    ],
                  ),
                ),
              ),
            );
          }),
    );
  }

  Widget _getGroupList(BuildContext context) {
    Map<GroupCategory, String> groupCategoryToDisplayValue =
        <GroupCategory, String>{
      GroupCategory.marine: AppLocalizations.of(context)!.marine,
      GroupCategory.pirate: AppLocalizations.of(context)!.pirate,
      GroupCategory.group: AppLocalizations.of(context)!.group,
      GroupCategory.other: AppLocalizations.of(context)!.otherType,
      GroupCategory.underWorld: AppLocalizations.of(context)!.underworld,
      GroupCategory.government: AppLocalizations.of(context)!.worldGovernment,
      GroupCategory.revolutionArmy:
          AppLocalizations.of(context)!.revolutionaryArmy,
    };
    return ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 300.0, // Set your maximum height here
        ),
        child: ListView.builder(
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
                      Navigator.pop(context);
                      context.goNamed('groupDetails',
                          extra: group.id,
                          pathParameters: {
                            'name':
                                I18nHelper.getDisplayNameFromI18n(group.name)
                          });
                    },
                    hoverColor: OnepieceColors.liteFancyBlue,
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(3, 6, 3, 3),
                              child: ImageLazyLoader(
                                  key: UniqueKey(),
                                  uriProvider: () => group.imageUri!,
                                  width: 50,
                                  borderWidth: 2,
                                  borderRadios: 10),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 5.0),
                              child: Text(
                                I18nHelper.getDisplayNameFromI18n(group.name),
                                style: OnepieceFonts.smallContentStyleWhite,
                              ),
                            )
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: OnepieceTag.getGroupTag(
                              group.groupCategory!,
                              groupCategoryToDisplayValue[
                                  group.groupCategory]!),
                        )
                      ],
                    ),
                  ),
                ),
              );
            }));
  }
}
