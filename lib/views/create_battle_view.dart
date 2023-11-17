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
  List<Character> leftCharacters = [];
  String leftSelectedId = "";
  List<Character> rightCharacters = [];
  String rightSelectedId = "";
  List<Character> searchResults = [];
  final ScrollController _leftScrollController = ScrollController();
  Character? leftSelectedItem;
  TextEditingController leftTextController = TextEditingController();
  TextEditingController rightTextController = TextEditingController();
  final ScrollController _rightScrollController = ScrollController();
  Character? rightSelectedItem;
  CharacterFilter leftCharacterFilter = CharacterFilter();
  CharacterFilter rightCharacterFilter = CharacterFilter();
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
    super.dispose();
  }

  void _searchLeft() {
    ListCharacterRequest listCharacterRequest = ListCharacterRequest(
        pageSize: 5,
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
        pageSize: 5,
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
        pageSize: 5,
        pageIndex: selectedLeftPageIndex,
        // do not need to sort in this case.
        sortKeys: [],
        characterFilter: leftCharacterFilter);
    Future<ListCharacterResponse?> listCharacterResponse =
        getIt<CharacterDao>().listCharacter(listCharacterRequest);
    listCharacterResponse.then((value) {
      setState(() {
        var newCharacters = value!.characters;
        leftCharacters = List.from(leftCharacters)..addAll(newCharacters);
      });
    });
  }

  void _loadRightMoreData() {
    selectedRightPageIndex++;
    ListCharacterRequest listCharacterRequest = ListCharacterRequest(
        pageSize: 5,
        pageIndex: selectedRightPageIndex,
        // do not need to sort in this case.
        sortKeys: [],
        characterFilter: rightCharacterFilter);
    Future<ListCharacterResponse?> listCharacterResponse =
        getIt<CharacterDao>().listCharacter(listCharacterRequest);
    listCharacterResponse.then((value) {
      setState(() {
        var newCharacters = value!.characters;
        rightCharacters = List.from(rightCharacters)..addAll(newCharacters);
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
              height: 600,
              decoration: const BoxDecoration(color: OnepieceColors.menuBackgroundColor,
                  borderRadius: BorderRadius.all(Radius.circular(15))),
              child: Column(
                children: [
                  // Image(
                  //   image: MemoryImage(PathConstants.loginLuffyImage),
                  // ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.initiator),
                        leftSelectedItem == null
                            ? Text(AppLocalizations.of(context)!.unselected)
                            : Text("${leftSelectedItem?.name}"),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 300,
                      child: TextFormField(
                        controller: leftTextController,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 300,
                    height: 300,
                    child: _getStarterList(context),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 100,
            ),
            Container(
              height: 600,
              decoration: const BoxDecoration(color: OnepieceColors.menuBackgroundColor,
                  borderRadius: BorderRadius.all(Radius.circular(15))),
              child: Column(
                children: [
                  // Image(
                  //   image: MemoryImage(PathConstants.loginLuffyImage),
                  // ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.receiver),
                        rightSelectedItem == null
                            ? Text(AppLocalizations.of(context)!.unselected)
                            : Text("${rightSelectedItem?.name}"),
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
                          rightCharacterFilter.name = value;
                          _searchRight();
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 300,
                    width: 300,
                    child: _getReceiverList(context),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _getStarterList(BuildContext context) {
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
      controller: _leftScrollController,
      itemCount: leftCharacters.length,
      itemBuilder: (context, index) {
        if (index < leftCharacters.length) {
          final character = leftCharacters[index];
          return Material(
              type: MaterialType.transparency,
              child: Container(
            padding: const EdgeInsets.fromLTRB(10, 3, 3, 3),
            decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(5))),
            child: ListTile(
              onTap: () {
                setState(
                  () {
                    if (leftSelectedId == character.id) {
                      leftSelectedId = "";
                      leftSelectedItem = null;
                    } else {
                      leftSelectedId = character.id;
                      leftSelectedItem = character;
                    }
                  },
                );
              },
              contentPadding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              selected: leftSelectedId == character.id,
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
                    child: leftSelectedId == character.id
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
          ),);
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  Widget _getReceiverList(BuildContext context) {
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
      controller: _rightScrollController,
      itemCount: rightCharacters.length,
      itemBuilder: (context, index) {
        if (index < rightCharacters.length) {
          final character = rightCharacters[index];
          return Material(
              type: MaterialType.transparency,
              child:Container(
            padding: const EdgeInsets.fromLTRB(10, 3, 3, 3),
            decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(5))),
            child: ListTile(
              onTap: () {
                setState(
                  () {
                    if (rightSelectedId == character.id) {
                      rightSelectedId = "";
                      rightSelectedItem = null;
                    } else {
                      rightSelectedId = character.id;
                      rightSelectedItem = character;
                    }
                  },
                );
              },
              contentPadding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              selected: rightSelectedId == character.id,
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
                    child: rightSelectedId == character.id
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
          ),);
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
