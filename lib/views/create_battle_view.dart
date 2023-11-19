import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:openapi/api.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../constants/onepiece_colors.dart';
import '../repository/character_dao.dart';
import '../utils/base64_helper.dart';

GetIt getIt = GetIt.instance;

class CreateBattleView extends StatefulWidget {
  const CreateBattleView({super.key});

  @override
  State<CreateBattleView> createState() => _CreateBattleViewState();
}

class _CreateBattleViewState extends State<CreateBattleView> {
  List<Character> starterCharacters = [];
  String starterSelectedId = "";
  List<Character> receiverCharacters = [];
  String receiverSelectedId = "";
  final ScrollController _starterScrollController = ScrollController();
  Character? starterSelectedItem;
  TextEditingController starterTextController = TextEditingController();
  TextEditingController rightTextController = TextEditingController();
  final ScrollController _receiverScrollController = ScrollController();
  Character? receiverSelectedItem;
  CharacterFilter starterCharacterFilter = CharacterFilter();
  CharacterFilter receiverCharacterFilter = CharacterFilter();
  // these two indexes are used when loading more data
  int starterSelectedPageIndex = 1;
  int receiverSelectedPageIndex = 1;
  int pageSize = 5;

  bool starterIsLoading = false;
  bool receiverIsLoading = false;
  bool starterToEnd = false;
  bool receiverToEnd = false;

  int starterCancelFlex = 1;
  int receiverCancelFlex = 1;

  @override
  void initState() {
    super.initState();
    _searchStarter(true);
    _searchReceiver(true);
    _starterScrollController.addListener(() {
      if (_starterScrollController.position.pixels ==
          _starterScrollController.position.maxScrollExtent) {
        _searchStarter(false);
      }
    });
    _receiverScrollController.addListener(() {
      if (_receiverScrollController.position.pixels ==
          _receiverScrollController.position.maxScrollExtent) {
        _searchReceiver(false);
      }
    });
  }

  void _searchStarter(bool isRefresh) {
    if (isRefresh) {
      starterSelectedPageIndex = 1;
    } else {
      if (starterToEnd) {
        return;
      }
      starterSelectedPageIndex++;
      starterIsLoading = true;
      setState(() {});
    }
    ListCharacterRequest listCharacterRequest = ListCharacterRequest(
        pageSize: pageSize,
        pageIndex: starterSelectedPageIndex,
        // do not need to sort in this case.
        sortKeys: [],
        characterFilter: starterCharacterFilter);
    Future<ListCharacterResponse?> listCharacterResponse =
        getIt<CharacterDao>().listCharacter(listCharacterRequest);
    listCharacterResponse.then((value) {
      setState(() {
        starterToEnd =
            (value!.totalSize! / pageSize).ceil() == starterSelectedPageIndex;
        if (isRefresh) {
          starterCharacters = value.characters;
        } else {
          starterCharacters = List.from(starterCharacters)
            ..addAll(value.characters);
        }
        starterIsLoading = false;
      });
    });
  }

  void _searchReceiver(bool isRefresh) {
    if (isRefresh) {
      receiverSelectedPageIndex = 1;
    } else {
      receiverSelectedPageIndex++;
      receiverIsLoading = true;
      setState(() {});
    }
    ListCharacterRequest listCharacterRequest = ListCharacterRequest(
        pageSize: pageSize,
        pageIndex: receiverSelectedPageIndex,
        // do not need to sort in this case.
        sortKeys: [],
        characterFilter: receiverCharacterFilter);
    Future<ListCharacterResponse?> listCharacterResponse =
        getIt<CharacterDao>().listCharacter(listCharacterRequest);
    listCharacterResponse.then((value) {
      setState(() {
        if (isRefresh) {
          receiverCharacters = value!.characters;
        } else {
          receiverCharacters = List.from(receiverCharacters)
            ..addAll(value!.characters);
        }
        receiverIsLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        AppLocalizations.of(context)!.createBattle,
        style: OnepieceFonts.headerStyle,
      ),
      content: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          children: [
            Container(
              height: 900,
              decoration: const BoxDecoration(
                  color: OnepieceColors.menuBackgroundColor,
                  borderRadius: BorderRadius.all(Radius.circular(15))),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.initiator),
                        starterSelectedItem == null
                            ? Text(AppLocalizations.of(context)!.unselected)
                            : Text("${starterSelectedItem?.name}"),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 300,
                      child: Row(
                        children: [
                          Flexible(flex: 5, child: Focus(
                            child: TextFormField(
                              controller: starterTextController,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!
                                    .searchCharacterName,
                                hintText: AppLocalizations.of(context)!
                                    .searchCharacterName,
                                prefixIcon: const Icon(Icons.search),
                              ),
                              onChanged: (value) {
                                starterCharacterFilter.name = value;
                                _searchStarter(true);
                              },
                            ),
                            onFocusChange: (focused) {
                              if (focused) {
                                starterCancelFlex = 1;
                              } else {
                                starterCancelFlex = 0;
                              }
                            },
                          ),),

                          Flexible(
                              flex: starterCancelFlex,
                              child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      starterCancelFlex = 0;
                                    });
                                  },
                                  child: Text(AppLocalizations.of(context)!
                                      .cancelPopUp)))
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 300,
                    height: 300,
                    child: getStarter(context),
                  ),
                  if (starterIsLoading == true)
                    const Padding(
                      padding: EdgeInsets.only(top: 10, bottom: 40),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  if (starterToEnd == true)
                    Text(AppLocalizations.of(context)!.endOfList)
                ],
              ),
            ),
            const SizedBox(
              width: 100,
            ),
            Container(
              height: 900,
              decoration: const BoxDecoration(
                  color: OnepieceColors.menuBackgroundColor,
                  borderRadius: BorderRadius.all(Radius.circular(15))),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.receiver),
                        receiverSelectedItem == null
                            ? Text(AppLocalizations.of(context)!.unselected)
                            : Text("${receiverSelectedItem?.name}"),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 300,
                      child: TextFormField(
                        controller: rightTextController,
                        onChanged: (value) {
                          receiverCharacterFilter.name = value;
                          _searchReceiver(true);
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 300,
                    width: 300,
                    child: getReceiver(context),
                  ),
                  if (receiverIsLoading == true)
                    const Padding(
                      padding: EdgeInsets.only(top: 10, bottom: 40),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  if (receiverToEnd == true)
                    Text(AppLocalizations.of(context)!.endOfList)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getStarter(BuildContext context) {
    Map<CharacterType, String> enumValueToDisplayValue =
        <CharacterType, String>{
      CharacterType.body: AppLocalizations.of(context)!.body,
      CharacterType.foot: AppLocalizations.of(context)!.leg,
      CharacterType.science: AppLocalizations.of(context)!.science,
      CharacterType.fist: AppLocalizations.of(context)!.fist,
      CharacterType.katana: AppLocalizations.of(context)!.katana,
      CharacterType.shooter: AppLocalizations.of(context)!.shoot
    };
    return ListView.builder(
      controller: _starterScrollController,
      itemCount: starterCharacters.length,
      itemBuilder: (context, index) {
        final character = starterCharacters[index];
        return Material(
          type: MaterialType.transparency,
          child: Container(
            padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
            decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(5))),
            child: ListTile(
              onTap: () {
                setState(
                  () {
                    if (starterSelectedId == character.id) {
                      starterSelectedId = "";
                      starterSelectedItem = null;
                    } else {
                      starterSelectedId = character.id;
                      starterSelectedItem = character;
                    }
                  },
                );
              },
              contentPadding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              selected: starterSelectedId == character.id,
              hoverColor: OnepieceColors.menuHoverColor,
              selectedTileColor: OnepieceColors.menuHoverColor,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: Image.memory(
                      Base64Helper.decode(character.profileImage!),
                      width: 80,
                      height: 60,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                          "${AppLocalizations.of(context)!.name}: ${character.name}",
                          style: OnepieceFonts.smallContentStyle),
                      Text(
                          "${AppLocalizations.of(context)!.characterTypeLabel}: ${enumValueToDisplayValue[character.characterType]!}",
                          style: OnepieceFonts.smallContentStyle),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 3, 0),
                    child: starterSelectedId == character.id
                        ? const Icon(
                            Icons.check_circle,
                            size: 20,
                          )
                        : const Icon(
                            Icons.check_circle_outline,
                            size: 20,
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget getReceiver(BuildContext context) {
    Map<CharacterType, String> enumValueToDisplayValue =
        <CharacterType, String>{
      CharacterType.body: AppLocalizations.of(context)!.body,
      CharacterType.foot: AppLocalizations.of(context)!.leg,
      CharacterType.science: AppLocalizations.of(context)!.science,
      CharacterType.fist: AppLocalizations.of(context)!.fist,
      CharacterType.katana: AppLocalizations.of(context)!.katana,
      CharacterType.shooter: AppLocalizations.of(context)!.shoot
    };
    return ListView.builder(
      controller: _receiverScrollController,
      itemCount: receiverCharacters.length,
      itemBuilder: (context, index) {
        final character = receiverCharacters[index];
        return Material(
          type: MaterialType.transparency,
          child: Container(
            padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
            decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(5))),
            child: ListTile(
              onTap: () {
                setState(
                  () {
                    if (receiverSelectedId == character.id) {
                      receiverSelectedId = "";
                      receiverSelectedItem = null;
                    } else {
                      receiverSelectedId = character.id;
                      receiverSelectedItem = character;
                    }
                  },
                );
              },
              contentPadding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              selected: receiverSelectedId == character.id,
              hoverColor: OnepieceColors.menuHoverColor,
              selectedTileColor: OnepieceColors.menuHoverColor,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: Image.memory(
                      Base64Helper.decode(character.profileImage!),
                      width: 80,
                      height: 60,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                          "${AppLocalizations.of(context)!.name}: ${character.name}",
                          style: OnepieceFonts.smallContentStyle),
                      Text(
                          "${AppLocalizations.of(context)!.characterTypeLabel}: ${enumValueToDisplayValue[character.characterType]!}",
                          style: OnepieceFonts.smallContentStyle),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 3, 0),
                    child: receiverSelectedId == character.id
                        ? const Icon(
                            Icons.check_circle,
                            size: 20,
                          )
                        : const Icon(
                            Icons.check_circle_outline,
                            size: 20,
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
