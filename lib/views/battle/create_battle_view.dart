import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/components/image_lazy_loader.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:openapi/api.dart';
import '../../l10n/app_localizations.dart';
import '../../constants/button_style.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_tag.dart';
import 'package:one_piece_battles_flutter/graph/character_data.dart';
import '../../graph/character_bar_graph.dart';
import '../../repository/battle_dao.dart';
import '../../repository/character_dao.dart';
import '../../utils/base64_helper.dart';
import '../../utils/i18n_helper.dart';
import '../../utils/image_helper.dart';

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
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
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
    ListCharacterRequest listCharacterRequest = ListCharacterRequest(
        pageSize: 30,
        pageIndex: 1,
        // do not need to sort in this case.
        sortKeys: [],
        characterFilter: CharacterFilter());
    Future<ListCharacterResponse?> listCharacterResponse =
        getIt<CharacterDao>().listCharacter(listCharacterRequest);
    listCharacterResponse.then((value) {
      setState(() {
        starterCharacters = value!.characters;
        receiverCharacters = value.characters;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      controller: _verticalScrollController,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _horizontalScrollController,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [getLeftPanel(context), getRightPanel(context)],
              ),
              const Divider(height: 3),
              _getFoot(context)
            ],
          ),
        ),
      ),
    );
  }

  Widget getLeftPanel(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(60, 10, 30, 10),
          child: ValueListenableBuilder<CharacterListView?>(
            valueListenable: starterSelectedItem,
            builder: (context, value, _) {
              return SizedBox(
                width: 500,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: FittedBox(
                              fit: BoxFit.fill,
                              child: starterSelectedItem.value == null
                                  ? ImageHelper.getSvgIconWithColor(
                                      'images/svgs/question.svg',
                                      60,
                                      60,
                                      OnepieceColors.liteFancyBlue)
                                  : Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: ImageLazyLoader(
                                          key: UniqueKey(),
                                          uriProvider: () => starterSelectedItem
                                              .value!.imageUri!,
                                          width: 200,
                                          borderWidth: 3,
                                          borderRadios: 100),
                                    ),
                            ),
                          ),
                          if (starterSelectedItem.value != null)
                            SizedBox(
                              width: 200,
                              height: 180,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 30.0),
                                child: RotatedBox(
                                  quarterTurns: 1,
                                  child: CharacterBarGraph(
                                      symmetric: false,
                                      characterData: CharacterData(
                                        starterSelectedItem.value!.attack,
                                        starterSelectedItem.value!.defense,
                                        starterSelectedItem.value!.intelligence,
                                        starterSelectedItem.value!.speed,
                                        starterSelectedItem.value!.blood,
                                        starterSelectedItem.value!.energy,
                                      )),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    starterSelectedItem.value == null
                        ? const SizedBox(
                            height: 80,
                            child: Text(
                              "",
                              style: OnepieceFonts.headerStyle,
                            ),
                          )
                        : SizedBox(
                            height: 80,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    I18nHelper.getDisplayNameFromI18n(
                                        starterSelectedItem.value!.name),
                                    style: const TextStyle(
                                        color: OnepieceColors.fancyBlue,
                                        fontStyle: FontStyle.normal,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    "${AppLocalizations.of(context)!.combatPower} ${starterSelectedItem.value!.score}",
                                    style: const TextStyle(
                                        color: OnepieceColors.fancyGreen,
                                        fontStyle: FontStyle.normal,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w200),
                                  )
                                ],
                              ),
                            ),
                          ),
                  ],
                ),
              );
            },
          ),
        ),
        getLeftSearchPanel(context)
      ],
    );
  }

  Widget getLeftSearchPanel(BuildContext context) {
    Map<Haki, String> hakiEnumValueToDisplayValue = {
      Haki.busoshoku: AppLocalizations.of(context)!.busoshoku,
      Haki.haoshoku: AppLocalizations.of(context)!.haoshoku,
      Haki.kenbunshoku: AppLocalizations.of(context)!.kenbunshoku,
    };
    return StatefulBuilder(builder: (context, leftSearchState) {
      return Container(
        decoration: const BoxDecoration(
          color: OnepieceColors.liteFancyGreen,
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: SizedBox(
                width: 400,
                height: 60,
                child: TextFormField(
                  controller: starterTextController,
                  decoration: InputDecoration(
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    disabledBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: OnepieceColors.menuHoverColor)),
                    enabledBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: OnepieceColors.menuHoverColor)),
                    focusedBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: OnepieceColors.fancyGreen)),
                    prefixIcon: const Icon(Icons.search),
                    labelText: AppLocalizations.of(context)!.characterName,
                  ),
                  onChanged: (value) {
                    if (_timer?.isActive ?? false) _timer?.cancel();
                    _timer = Timer(const Duration(milliseconds: 500), () {
                      starterCharacterFilter.name = value;
                      starterCharacterFilter.languageCode =
                          I18nHelper.getLanguageCode();
                      ListCharacterRequest listCharacterRequest =
                          ListCharacterRequest(
                              pageSize: 20,
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
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: SizedBox(
                width: 400,
                height: 400,
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
                                    child: ImageLazyLoader(
                                        key: UniqueKey(),
                                        uriProvider: () => character.imageUri!,
                                        width: 50,
                                        borderWidth: 2,
                                        borderRadios: 6),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          I18nHelper.getDisplayNameFromI18n(
                                              character.name),
                                          style: OnepieceFonts
                                              .smallContentStyleWhite),
                                      if (character.hakis.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 3.0),
                                          child: Padding(
                                            padding:
                                                const EdgeInsets.only(top: 3.0),
                                            child: Row(
                                              children: character.hakis
                                                  .map((e) => Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(right: 5),
                                                        child: OnepieceTag
                                                            .getHakiTag(
                                                                e,
                                                                hakiEnumValueToDisplayValue[
                                                                    e]!),
                                                      ))
                                                  .toList(),
                                            ),
                                          ),
                                        ),
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
            padding: const EdgeInsets.fromLTRB(30, 10, 60, 10),
            child: ValueListenableBuilder<CharacterListView?>(
                valueListenable: receiverSelectedItem,
                builder: (context, value, _) {
                  return SizedBox(
                    width: 500,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (receiverSelectedItem.value != null)
                                SizedBox(
                                  width: 200,
                                  height: 180,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 30.0),
                                    child: RotatedBox(
                                      quarterTurns: 1,
                                      child: CharacterBarGraph(
                                        characterData: CharacterData(
                                          receiverSelectedItem.value!.attack,
                                          receiverSelectedItem.value!.defense,
                                          receiverSelectedItem
                                              .value!.intelligence,
                                          receiverSelectedItem.value!.speed,
                                          receiverSelectedItem.value!.blood,
                                          receiverSelectedItem.value!.energy,
                                        ),
                                        symmetric: false,
                                      ),
                                    ),
                                  ),
                                ),
                              SizedBox(
                                width: 180,
                                height: 180,
                                child: FittedBox(
                                  fit: BoxFit.fill,
                                  child: receiverSelectedItem.value == null
                                      ? ImageHelper.getSvgIconWithColor(
                                          'images/svgs/question.svg',
                                          60,
                                          60,
                                          OnepieceColors.liteFancyBlue)
                                      : Padding(
                                          padding: const EdgeInsets.all(20.0),
                                          child: ImageLazyLoader(
                                              key: UniqueKey(),
                                              uriProvider: () =>
                                                  receiverSelectedItem
                                                      .value!.imageUri!,
                                              width: 200,
                                              borderWidth: 3,
                                              borderRadios: 100),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        receiverSelectedItem.value == null
                            ? const SizedBox(
                                height: 80,
                                child: Text(
                                  "",
                                  style: OnepieceFonts.headerStyle,
                                ),
                              )
                            : SizedBox(
                                height: 80,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 10.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        I18nHelper.getDisplayNameFromI18n(
                                            receiverSelectedItem.value!.name),
                                        style: const TextStyle(
                                            color: OnepieceColors.fancyBlue,
                                            fontStyle: FontStyle.normal,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        "${AppLocalizations.of(context)!.combatPower} ${receiverSelectedItem.value!.score}",
                                        style: const TextStyle(
                                            color: OnepieceColors.fancyGreen,
                                            fontStyle: FontStyle.normal,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w200),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                      ],
                    ),
                  );
                })),
        getRightSearchPanel(context)
      ],
    );
  }

  Widget getRightSearchPanel(BuildContext context) {
    Map<Haki, String> hakiEnumValueToDisplayValue = {
      Haki.busoshoku: AppLocalizations.of(context)!.busoshoku,
      Haki.haoshoku: AppLocalizations.of(context)!.haoshoku,
      Haki.kenbunshoku: AppLocalizations.of(context)!.kenbunshoku,
    };
    return StatefulBuilder(builder: (context, rightSearchState) {
      return Container(
          decoration: const BoxDecoration(
            color: OnepieceColors.liteFancyGreen,
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: SizedBox(
                  width: 400,
                  height: 60,
                  child: TextFormField(
                    controller: receiverTextController,
                    decoration: InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      disabledBorder: const OutlineInputBorder(
                          borderSide:
                              BorderSide(color: OnepieceColors.menuHoverColor)),
                      enabledBorder: const OutlineInputBorder(
                          borderSide:
                              BorderSide(color: OnepieceColors.menuHoverColor)),
                      focusedBorder: const OutlineInputBorder(
                          borderSide:
                              BorderSide(color: OnepieceColors.fancyGreen)),
                      prefixIcon: const Icon(Icons.search),
                      labelText: AppLocalizations.of(context)!.characterName,
                    ),
                    onChanged: (value) {
                      if (_timer?.isActive ?? false) _timer?.cancel();
                      _timer = Timer(const Duration(milliseconds: 500), () {
                        receiverCharacterFilter.name = value;
                        receiverCharacterFilter.languageCode =
                            I18nHelper.getLanguageCode();
                        ListCharacterRequest listCharacterRequest =
                            ListCharacterRequest(
                                pageSize: 20,
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
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: SizedBox(
                  width: 400,
                  height: 400,
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
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5))),
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
                            contentPadding:
                                const EdgeInsets.fromLTRB(8, 0, 0, 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            selected: receiverSelectedId == character.id,
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
                                      child: ImageLazyLoader(
                                          key: UniqueKey(),
                                          uriProvider: () =>
                                              character.imageUri!,
                                          width: 50,
                                          borderWidth: 2,
                                          borderRadios: 6),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            I18nHelper.getDisplayNameFromI18n(
                                                character.name),
                                            style: OnepieceFonts
                                                .smallContentStyleWhite),
                                        if (character.hakis.isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 5.0),
                                            child: Row(
                                              children: character.hakis
                                                  .map(
                                                    (e) => Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              right: 5),
                                                      child: OnepieceTag.getHakiTag(
                                                          e,
                                                          hakiEnumValueToDisplayValue[
                                                              e]!),
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 0, 3, 0),
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
                  padding: const EdgeInsets.symmetric(vertical: 50),
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
                                CreateBattleRequest request =
                                    CreateBattleRequest(
                                        userId: getIt<User>().id,
                                        starterId: starterSelectedId,
                                        receiverId: receiverSelectedId);
                                Future<CreateBattleResponse?> response =
                                    getIt<BattleDao>().createBattle(request);
                                response.then((value) {
                                  if (!mounted) return;
                                  if (value?.battleId != null) {
                                    context.goNamed('battleDetails',
                                        extra: value?.battleId,
                                        pathParameters: {
                                          'id': value!.battleId!
                                        });
                                  } else {
                                    context.goNamed("battle");
                                  }
                                });
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
