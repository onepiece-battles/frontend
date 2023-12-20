import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:openapi/api.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../constants/button_style.dart';
import '../constants/onepiece_colors.dart';
import '../constants/path_constants.dart';
import '../repository/battle_dao.dart';
import '../repository/character_dao.dart';
import '../utils/base64_helper.dart';
import '../utils/i18n_helper.dart';

GetIt getIt = GetIt.instance;

class CreateBattleView extends StatefulWidget {
  const CreateBattleView({super.key});

  @override
  State<CreateBattleView> createState() => _CreateBattleViewState();
}

class _CreateBattleViewState extends State<CreateBattleView> {
  List<CharacterListView> starterCharacters = [];
  String starterSelectedId = "";
  List<CharacterListView> receiverCharacters = [];
  String receiverSelectedId = "";
  final ScrollController _starterScrollController = ScrollController();
  CharacterListView? starterSelectedItem;
  TextEditingController starterTextController = TextEditingController();
  TextEditingController receiverTextController = TextEditingController();
  final ScrollController _receiverScrollController = ScrollController();
  CharacterListView? receiverSelectedItem;
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
    return Padding(
        padding: const EdgeInsets.all(15.0),
        child: Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 300,
                            height: 60,
                            child: TextFormField(
                              controller: starterTextController,
                              decoration: InputDecoration(
                                label: Text(
                                  AppLocalizations.of(context)!.characterName,
                                  style: OnepieceFonts.hintFont,
                                ),
                                disabledBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: OnepieceColors.fancyGreen)),
                                enabledBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: OnepieceColors.fancyGreen)),
                                focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: OnepieceColors.fancyGreen)),
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
                          width: 300,
                          height: 350,
                          decoration: const BoxDecoration(
                            color: OnepieceColors.fancyBlue,
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          child: getStarter(context),
                        ),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            AppLocalizations.of(context)!.initiator,
                            style: OnepieceFonts.tableHeaderStyle,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(60, 10, 60, 10),
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(8)),
                              border: starterSelectedItem == null
                                  ? null
                                  : Border.all(
                                      color: OnepieceColors.fancyBlue,
                                      width: 5,
                                      style: BorderStyle.solid),
                            ),
                            child: FittedBox(
                              fit: BoxFit.fill,
                              child: starterSelectedItem == null
                                  ? const Image(
                                      image:
                                          AssetImage(PathConstants.userImage))
                                  : Image.memory(Base64Helper.decode(
                                      starterSelectedItem!.profileImage!)),
                            ),
                          ),
                        ),
                        starterSelectedItem == null
                            ? const SizedBox(
                                height: 30,
                                child: Text(
                                  "?",
                                  style: OnepieceFonts.headerStyle,
                                ),
                              )
                            : SizedBox(
                                height: 30,
                                child: Text(
                                    I18nHelper.getI18nByLocale2(starterSelectedItem!.name),
                                  style: OnepieceFonts.headerStyle,
                                )),
                      ],
                    ),
                    const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "VS",
                          style: OnepieceFonts.fancyMax,
                        ),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            AppLocalizations.of(context)!.receiver,
                            style: OnepieceFonts.tableHeaderStyle,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(60, 10, 60, 10),
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(8)),
                              border: receiverSelectedItem == null
                                  ? null
                                  : Border.all(
                                      color: OnepieceColors.fancyBlue,
                                      width: 5,
                                      style: BorderStyle.solid),
                            ),
                            child: FittedBox(
                              fit: BoxFit.fill,
                              child: receiverSelectedItem == null
                                  ? const Image(
                                      image:
                                          AssetImage(PathConstants.userImage))
                                  : Image.memory(Base64Helper.decode(
                                      receiverSelectedItem!.profileImage!)),
                            ),
                          ),
                        ),
                        receiverSelectedItem == null
                            ? const SizedBox(
                                height: 30,
                                child: Text(
                                  "?",
                                  style: OnepieceFonts.headerStyle,
                                ),
                              )
                            : SizedBox(
                                height: 30,
                                child: Text(
                                    I18nHelper.getI18nByLocale2(receiverSelectedItem!.name),
                                  style: OnepieceFonts.headerStyle,
                                )),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 300,
                            height: 60,
                            child: TextFormField(
                              controller: receiverTextController,
                              decoration: InputDecoration(
                                label: Text(
                                  AppLocalizations.of(context)!.characterName,
                                  style: OnepieceFonts.hintFont,
                                ),
                                disabledBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: OnepieceColors.fancyGreen)),
                                enabledBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: OnepieceColors.fancyGreen)),
                                focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: OnepieceColors.fancyGreen)),
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
                            color: OnepieceColors.fancyBlue,
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          height: 350,
                          width: 300,
                          child: getReceiver(context),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 3),
                _getFoot(context)
              ],
            ),
          ),
        ));
  }

  Widget _getFoot(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 50),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              style: OnepieceButtonStyle.getDefaultStyle(),
              child: Text(AppLocalizations.of(context)!.back),
              onPressed: () {
                context.goNamed("battle");
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              style: OnepieceButtonStyle.getDefaultStyle(),
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
          ),
          ElevatedButton(
            style: OnepieceButtonStyle.getDefaultStyle(),
            onPressed:
                (starterSelectedItem == null || receiverSelectedItem == null)
                    ? null
                    : () {
                        AddBattleRequest request = AddBattleRequest(
                            userId: getIt<User>().id,
                            starterId: starterSelectedId,
                            receiverId: receiverSelectedId);
                        getIt<BattleDao>().addBattle(request);
                        context.goNamed("battle");
                      },
            child: Text(AppLocalizations.of(context)!.submitForm),
          ),
        ],
      ),
    );
  }

  Widget getStarter(BuildContext context) {
    Map<CharacterType, String> enumValueToDisplayValue =
        <CharacterType, String>{
      CharacterType.BODY: AppLocalizations.of(context)!.body,
      CharacterType.FOOT: AppLocalizations.of(context)!.leg,
      CharacterType.SCIENCE: AppLocalizations.of(context)!.science,
      CharacterType.FIST: AppLocalizations.of(context)!.fist,
      CharacterType.KATANA: AppLocalizations.of(context)!.katana,
      CharacterType.SHOOTER: AppLocalizations.of(context)!.shoot
    };
    return ListView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      controller: _starterScrollController,
      itemCount: starterCharacters.length,
      itemBuilder: (context, index) {
        final character = starterCharacters[index];
        if (starterCharacters.length == (index)) {
          return const Padding(
            padding: EdgeInsets.only(top: 10, bottom: 10),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (starterCharacters.length == (index + 1) && starterToEnd == true) {
          return Center(child: Text(AppLocalizations.of(context)!.endOfList));
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(3.0),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              "${AppLocalizations.of(context)!.name}: ${character.name}",
                              style: OnepieceFonts.smallContentStyle),
                          Text(
                              "${AppLocalizations.of(context)!.characterTypeLabel}: ${character.characterTypes.map((e) => enumValueToDisplayValue[e]).join(", ")}",
                              style: OnepieceFonts.smallContentStyle),
                        ],
                      ),
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
      CharacterType.BODY: AppLocalizations.of(context)!.body,
      CharacterType.FOOT: AppLocalizations.of(context)!.leg,
      CharacterType.SCIENCE: AppLocalizations.of(context)!.science,
      CharacterType.FIST: AppLocalizations.of(context)!.fist,
      CharacterType.KATANA: AppLocalizations.of(context)!.katana,
      CharacterType.SHOOTER: AppLocalizations.of(context)!.shoot
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(3.0),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              "${AppLocalizations.of(context)!.name}: ${character.name}",
                              style: OnepieceFonts.smallContentStyle),
                          Text(
                              "${AppLocalizations.of(context)!.characterTypeLabel}: ${character.characterTypes.map((e) => enumValueToDisplayValue[e]).join(", ")}",
                              style: OnepieceFonts.smallContentStyle),
                        ],
                      ),
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
