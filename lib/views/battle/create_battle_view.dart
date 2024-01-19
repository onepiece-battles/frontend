import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:openapi/api.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../constants/button_style.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/path_constants.dart';
import '../../repository/battle_dao.dart';
import '../../repository/character_dao.dart';
import '../../utils/base64_helper.dart';
import '../../utils/i18n_helper.dart';

GetIt getIt = GetIt.instance;
Timer? _timer;

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
  final ScrollController _receiverScrollController = ScrollController();
  ValueNotifier<CharacterListView?> starterSelectedItem = ValueNotifier(null);
  ValueNotifier<CharacterListView?> receiverSelectedItem = ValueNotifier(null);
  TextEditingController starterTextController = TextEditingController();
  TextEditingController receiverTextController = TextEditingController();
  CharacterFilter starterCharacterFilter = CharacterFilter();
  CharacterFilter receiverCharacterFilter = CharacterFilter();
  // these two indexes are used when loading more data
  int starterSelectedPageIndex = 1;
  int receiverSelectedPageIndex = 1;

  bool starterIsLoading = false;
  bool receiverIsLoading = false;
  bool starterToEnd = false;
  bool receiverToEnd = false;

  @override
  void initState() {
    super.initState();
    searchOnStart();
  }

  void searchOnStart() {
    ListCharacterRequest listCharacterRequest =
    ListCharacterRequest(
        pageSize: 5,
        pageIndex: 1,
        // do not need to sort in this case.
        sortKeys: [],
        characterFilter: CharacterFilter());
    Future<ListCharacterResponse?> listCharacterResponse =
    getIt<CharacterDao>()
        .listCharacter(listCharacterRequest);
    listCharacterResponse.then((value) {
      setState(() {
        starterCharacters = value!.characters;
        receiverCharacters = value.characters;
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
            child: Padding(
              padding: const EdgeInsets.only(top: 100.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      getLeftPanel(context),
                      const SizedBox(width: 100,),
                      getRightPanel(context)
                    ],
                  ),
                  const Divider(height: 3),
                  _getFoot(context)
                ],
              ),
            ),
          ),
        ));
  }

  Widget getLeftPanel(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(60, 10, 60, 10),
          child: ValueListenableBuilder<CharacterListView?>(
            valueListenable: starterSelectedItem,
            builder: (context, value, _) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8)),
                        border: starterSelectedItem.value == null
                            ? null
                            : Border.all(
                                color: OnepieceColors.fancyBlue,
                                width: 5,
                                style: BorderStyle.solid),
                      ),
                      child: FittedBox(
                        fit: BoxFit.fill,
                        child: starterSelectedItem.value == null
                            ? const Image(
                                image: AssetImage(PathConstants.userImage))
                            : Image.memory(Base64Helper.decode(
                                starterSelectedItem.value!.profileImage!)),
                      ),
                    ),
                  ),
                  starterSelectedItem.value == null
                      ? const SizedBox(
                          height: 50,
                          child: Text(
                            "?",
                            style: OnepieceFonts.headerStyle,
                          ),
                        )
                      : SizedBox(
                          height: 50,
                          child: Text(
                            I18nHelper.getDisplayNameFromI18n(
                                starterSelectedItem.value!.name),
                            style: OnepieceFonts.headerStyle,
                          )),
                ],
              );
            },
          ),
        ),
        getLeftSearchPanel(context)
      ],
    );
  }

  Widget getLeftSearchPanel(BuildContext context) {
    Map<CharacterType, String> enumValueToDisplayValue =
        <CharacterType, String>{
      CharacterType.BODY: AppLocalizations.of(context)!.body,
      CharacterType.FOOT: AppLocalizations.of(context)!.leg,
      CharacterType.SCIENCE: AppLocalizations.of(context)!.science,
      CharacterType.FIST: AppLocalizations.of(context)!.fist,
      CharacterType.KATANA: AppLocalizations.of(context)!.katana,
      CharacterType.SHOOTER: AppLocalizations.of(context)!.shoot
    };
    return StatefulBuilder(builder: (context, leftSearchState) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.all(Radius.circular(10.0)),
          border: Border.all(
              color: OnepieceColors.fancyBlue,
              width: 3,
              style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: SizedBox(
                width: 300,
                height: 60,
                child: TextFormField(
                  controller: starterTextController,
                  decoration: InputDecoration(
                    label: Text(
                      AppLocalizations.of(context)!.searchStarter,
                      style: OnepieceFonts.hintFont,
                    ),
                    enabledBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: OnepieceColors.fancyGreen)),
                    focusedBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: OnepieceColors.fancyGreen)),
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    if (_timer?.isActive ?? false) _timer?.cancel();
                    _timer = Timer(const Duration(milliseconds: 500), () {
                      starterCharacterFilter.name = value;
                      starterCharacterFilter.languageCode =
                          I18nHelper.getLanguageCode();
                      ListCharacterRequest listCharacterRequest =
                          ListCharacterRequest(
                              pageSize: 5,
                              pageIndex: 1,
                              // do not need to sort in this case.
                              sortKeys: [],
                              characterFilter: starterCharacterFilter);
                      Future<ListCharacterResponse?> listCharacterResponse =
                          getIt<CharacterDao>()
                              .listCharacter(listCharacterRequest);
                      listCharacterResponse.then((value) {
                        leftSearchState(() {
                          starterCharacters = value!.characters;
                        });
                      });
                    });
                  },
                ),
              ),
            ),
            SizedBox(
              width: 300,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
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
                          leftSearchState(() {
                            if (starterSelectedId == character.id) {
                              starterSelectedId = "";
                              starterSelectedItem.value = null;
                            } else {
                              starterSelectedId = character.id;
                              starterSelectedItem.value = character;
                            }
                          });
                        },
                        contentPadding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        selected: starterSelectedId == character.id,
                        hoverColor: OnepieceColors.fancyBlue,
                        selectedTileColor: OnepieceColors.fancyBlue,
                        tileColor: Colors.black54,
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(3, 3, 8, 3),
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(2.0)),
                                      border: Border.all(
                                          color: Colors.black54,
                                          width: 2,
                                          style: BorderStyle.solid),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.fill,
                                      child: Image.memory(Base64Helper.decode(
                                          character.profileImage!)),
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        "${AppLocalizations.of(context)!.name}: ${I18nHelper.getDisplayNameFromI18n(character.name)}",
                                        style: OnepieceFonts
                                            .smallContentStyleWhite),
                                    Text(
                                        "${AppLocalizations.of(context)!.characterTypeLabel}: ${character.characterTypes.map((e) => enumValueToDisplayValue[e]).join(", ")}",
                                        style: OnepieceFonts
                                            .smallContentStyleWhite),
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
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget getRightPanel(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(60, 10, 60, 10),
            child: ValueListenableBuilder<CharacterListView?>(
                valueListenable: receiverSelectedItem,
                builder: (context, value, _) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(8)),
                            border: receiverSelectedItem.value == null
                                ? null
                                : Border.all(
                                    color: OnepieceColors.fancyBlue,
                                    width: 5,
                                    style: BorderStyle.solid),
                          ),
                          child: FittedBox(
                            fit: BoxFit.fill,
                            child: receiverSelectedItem.value == null
                                ? const Image(
                                    image: AssetImage(PathConstants.userImage))
                                : Image.memory(Base64Helper.decode(
                                    receiverSelectedItem.value!.profileImage!)),
                          ),
                        ),
                      ),
                      receiverSelectedItem.value == null
                          ? const SizedBox(
                              height: 50,
                              child: Text(
                                "?",
                                style: OnepieceFonts.headerStyle,
                              ),
                            )
                          : SizedBox(
                              height: 50,
                              child: Text(
                                I18nHelper.getDisplayNameFromI18n(
                                    receiverSelectedItem.value!.name),
                                style: OnepieceFonts.headerStyle,
                              ),
                            ),
                    ],
                  );
                })),
        getRightSearchPanel(context)
      ],
    );
  }

  Widget getRightSearchPanel(BuildContext context) {
    Map<CharacterType, String> enumValueToDisplayValue =
        <CharacterType, String>{
      CharacterType.BODY: AppLocalizations.of(context)!.body,
      CharacterType.FOOT: AppLocalizations.of(context)!.leg,
      CharacterType.SCIENCE: AppLocalizations.of(context)!.science,
      CharacterType.FIST: AppLocalizations.of(context)!.fist,
      CharacterType.KATANA: AppLocalizations.of(context)!.katana,
      CharacterType.SHOOTER: AppLocalizations.of(context)!.shoot
    };
    return StatefulBuilder(builder: (context, rightSearchState) {
      return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            border: Border.all(
                color: OnepieceColors.fancyBlue,
                width: 3,
                style: BorderStyle.solid),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: SizedBox(
                  width: 300,
                  height: 60,
                  child: TextFormField(
                    controller: receiverTextController,
                    decoration: InputDecoration(
                      label: Text(
                        AppLocalizations.of(context)!.searchReceiver,
                        style: OnepieceFonts.hintFont,
                      ),
                      enabledBorder: const OutlineInputBorder(
                          borderSide:
                              BorderSide(color: OnepieceColors.fancyGreen)),
                      focusedBorder: const OutlineInputBorder(
                          borderSide:
                              BorderSide(color: OnepieceColors.fancyGreen)),
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      if (_timer?.isActive ?? false) _timer?.cancel();
                      _timer = Timer(const Duration(milliseconds: 500), () {
                        receiverCharacterFilter.name = value;
                        receiverCharacterFilter.languageCode =
                            I18nHelper.getLanguageCode();
                        ListCharacterRequest listCharacterRequest =
                            ListCharacterRequest(
                                pageSize: 5,
                                pageIndex: receiverSelectedPageIndex,
                                // do not need to sort in this case.
                                sortKeys: [],
                                characterFilter: receiverCharacterFilter);
                        Future<ListCharacterResponse?> listCharacterResponse =
                            getIt<CharacterDao>()
                                .listCharacter(listCharacterRequest);
                        listCharacterResponse.then((value) {
                          rightSearchState(() {
                            receiverCharacters = value!.characters;
                          });
                        });
                      });
                    },
                  ),
                ),
              ),
              SizedBox(
                width: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
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
                            rightSearchState(() {
                              if (receiverSelectedId == character.id) {
                                receiverSelectedId = "";
                                receiverSelectedItem.value = null;
                              } else {
                                receiverSelectedId = character.id;
                                receiverSelectedItem.value = character;
                              }
                            });
                          },
                          contentPadding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          selected: receiverSelectedId == character.id,
                          hoverColor: OnepieceColors.fancyBlue,
                          selectedTileColor: OnepieceColors.fancyBlue,
                          tileColor: Colors.grey,
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(3, 3, 8, 3),
                                    child: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(2.0)),
                                        border: Border.all(
                                            color: Colors.grey,
                                            width: 2,
                                            style: BorderStyle.solid),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.fill,
                                        child: Image.memory(Base64Helper.decode(
                                            character.profileImage!)),
                                      ),
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          "${AppLocalizations.of(context)!.name}: ${I18nHelper.getDisplayNameFromI18n(character.name)}",
                                          style: OnepieceFonts
                                              .smallContentStyleWhite),
                                      Text(
                                          "${AppLocalizations.of(context)!.characterTypeLabel}: ${character.characterTypes.map((e) => enumValueToDisplayValue[e]).join(", ")}",
                                          style: OnepieceFonts
                                              .smallContentStyleWhite),
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
                ),
              )
            ],
          ));
    });
  }

  Widget _getFoot(BuildContext context) {
    return ValueListenableBuilder<CharacterListView?>(
        valueListenable: starterSelectedItem,
        builder: (context, value, _) {
          return ValueListenableBuilder<CharacterListView?>(
              valueListenable: receiverSelectedItem,
              builder: (context, value, _) {
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
                          onPressed: (starterSelectedId.isEmpty &&
                              receiverSelectedId.isEmpty)
                              ? null
                              : () {
                            setState(() {
                              starterSelectedItem.value = null;
                              starterSelectedId = "";
                              receiverSelectedItem.value = null;
                              receiverSelectedId = "";
                            });
                          },
                          child: Text(AppLocalizations.of(context)!.clearForm),
                        ),
                      ),
                      ElevatedButton(
                        style: OnepieceButtonStyle.getDefaultStyle(),
                        onPressed: (starterSelectedId.isEmpty ||
                            receiverSelectedId.isEmpty)
                            ? null
                            : () {
                          AddBattleRequest request = AddBattleRequest(
                              userId: getIt<User>().id,
                              starterId: starterSelectedId,
                              receiverId: receiverSelectedId);
                          getIt<BattleDao>().addBattle(request);
                          context.goNamed("battle");
                        },
                        child: Text(AppLocalizations.of(context)!.create),
                      ),
                    ],
                  ),
                );
              });
        });
  }
}
