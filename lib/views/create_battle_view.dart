import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:one_piece_battles_flutter/repository/battle_dao.dart';
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
      if (receiverToEnd) {
        return;
      }
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
      receiverToEnd =
          (value!.totalSize! / pageSize).ceil() == receiverSelectedPageIndex;
      setState(() {
        if (isRefresh) {
          receiverCharacters = value.characters;
        } else {
          receiverCharacters = List.from(receiverCharacters)
            ..addAll(value.characters);
        }
        receiverIsLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Center(
        child: Text(
          AppLocalizations.of(context)!.createBattle,
          style: OnepieceFonts.headerStyle,
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          children: [
            Container(
              height: 800,
              decoration: const BoxDecoration(
                  color: OnepieceColors.menuBackgroundColor,
                  borderRadius: BorderRadius.all(Radius.circular(15))),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      AppLocalizations.of(context)!.initiator,
                      style: OnepieceFonts.tableHeaderStyle,
                    ),
                  ),
                  starterSelectedItem == null
                      ? const SizedBox(
                          height: 30,
                          child: Text(
                            "?",
                            style: OnepieceFonts.contentStyleBold,
                          ),
                        )
                      : SizedBox(
                          height: 30, child: Text(starterSelectedItem!.name)),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 350,
                      height: 60,
                      child: TextFormField(
                        controller: starterTextController,
                        decoration: InputDecoration(
                          label: Text(
                            AppLocalizations.of(context)!.characterName,
                            style: OnepieceFonts.hintFont,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          starterCharacterFilter.name = value;
                          _searchStarter(true);
                        },
                      ),
                    ),
                  ),
                  Container(
                    width: 350,
                    height: 350,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    child: getStarter(context),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 30,
            ),
            Container(
              height: 800,
              decoration: const BoxDecoration(
                  color: OnepieceColors.menuBackgroundColor,
                  borderRadius: BorderRadius.all(Radius.circular(15))),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      AppLocalizations.of(context)!.receiver,
                      style: OnepieceFonts.tableHeaderStyle,
                    ),
                  ),
                  receiverSelectedItem == null
                      ? const SizedBox(
                          height: 30,
                          child: Text(
                            "?",
                            style: OnepieceFonts.contentStyleBold,
                          ),
                        )
                      : SizedBox(
                          height: 30, child: Text(receiverSelectedItem!.name)),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 350,
                      height: 60,
                      child: TextFormField(
                        controller: rightTextController,
                        decoration: InputDecoration(
                          label: Text(
                            AppLocalizations.of(context)!.characterName,
                            style: OnepieceFonts.hintFont,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          receiverCharacterFilter.name = value;
                          _searchReceiver(true);
                        },
                      ),
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    height: 350,
                    width: 350,
                    child: getReceiver(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          child: Text(AppLocalizations.of(context)!.cancelPopUp),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        ElevatedButton(
          onPressed:
              (starterSelectedItem == null && receiverSelectedItem == null)
                  ? null
                  : () {
                      setState(() {
                        starterSelectedItem = null;
                        starterSelectedId = "";
                        receiverSelectedItem = null;
                        receiverSelectedId = "";
                      });
                    },
          child: Text(AppLocalizations.of(context)!.clearForm),
        ),
        ElevatedButton(
          onPressed:
              (starterSelectedItem == null || receiverSelectedItem == null)
                  ? null
                  : () {
                      AddBattleRequest request = AddBattleRequest(
                          userId: getIt<User>().id,
                          starterId: starterSelectedId,
                          receiverId: receiverSelectedId);
                      getIt<BattleDao>().addBattle(request);
                      Navigator.pop(context);
                    },
          child: Text(AppLocalizations.of(context)!.submitForm),
        ),
      ],
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
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      controller: _starterScrollController,
      itemCount: starterCharacters.length,
      itemBuilder: (context, index) {
        final character = starterCharacters[index];
        if (starterCharacters.length == index) {
          return const Padding(
            padding: EdgeInsets.only(top: 10, bottom: 10),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (starterCharacters.length == index && starterToEnd == true) {
          return Text(AppLocalizations.of(context)!.endOfList);
        }
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
        if (receiverCharacters.length == index) {
          return const Padding(
            padding: EdgeInsets.only(top: 10, bottom: 10),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (receiverCharacters.length == index && receiverToEnd) {
          return Text(AppLocalizations.of(context)!.endOfList);
        }
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
