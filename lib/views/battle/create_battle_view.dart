import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/components/creation_form_card.dart';
import 'package:one_piece_battles_flutter/components/image_lazy_loader.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:openapi/api.dart';
import 'create_battle_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_tag.dart';
import 'package:one_piece_battles_flutter/graph/character_data.dart';
import '../../graph/character_bar_graph.dart';
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
  final CreateBattleController _controller = CreateBattleController();

  @override
  void initState() {
    super.initState();
    searchOnStart();
  }

  @override
  void dispose() {
    _starterScrollController.dispose();
    _receiverScrollController.dispose();
    _verticalScrollController.dispose();
    starterSelectedItem.dispose();
    receiverSelectedItem.dispose();
    starterTextController.dispose();
    receiverTextController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void searchOnStart() {
    ListCharacterRequest listCharacterRequest = ListCharacterRequest(
        pageSize: 30,
        pageIndex: 1,
        // do not need to sort in this case.
        sortKeys: [],
        characterFilter: CharacterFilter());
    Future<ListCharacterResponse?> listCharacterResponse =
        _controller.listCharacter(listCharacterRequest);
    listCharacterResponse.then((value) {
      setState(() {
        starterCharacters = value!.characters;
        receiverCharacters = value.characters;
      });
    });
  }

  CharacterData _characterData(CharacterListView character) {
    return CharacterData(
      character.attack,
      character.defense,
      character.intelligence,
      character.speed,
      character.blood,
      character.energy,
    );
  }

  Widget _mobileCharacterGraph(CharacterListView character) {
    return SizedBox(
      width: 72,
      height: 62,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 132,
          height: 104,
          child: RotatedBox(
            quarterTurns: 1,
            child: CharacterBarGraph(
              symmetric: false,
              characterData: _characterData(character),
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectedCharacterSummary(CharacterListView? character, bool isSmall) {
    if (character == null) {
      return SizedBox(height: isSmall ? 44 : 58);
    }

    return Padding(
      padding: EdgeInsets.only(top: isSmall ? 8 : 12, bottom: isSmall ? 4 : 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            I18nHelper.getDisplayNameFromI18n(character.name),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: OnepieceColors.fancyBlue,
              fontSize: isSmall ? 13 : 18,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: OnepieceColors.liteFancyGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${AppLocalizations.of(context)!.combatPower} ${character.score}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: OnepieceColors.deepFancyBlue,
                fontSize: isSmall ? 11 : 13,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final localizations = AppLocalizations.of(context)!;
        final starterCard = CreationFormCard(
          icon: Icons.bolt_rounded,
          title: localizations.starterName,
          child: getLeftPanel(context),
        );
        final receiverCard = CreationFormCard(
          icon: Icons.shield_rounded,
          title: localizations.receiverName,
          child: getRightPanel(context),
        );

        return Stack(
          children: [
            ColoredBox(
              color: const Color(0xFFF5F7FB),
              child: SingleChildScrollView(
                controller: _verticalScrollController,
                padding: EdgeInsets.fromLTRB(
                  isWide ? 28 : 12,
                  18,
                  isWide ? 28 : 12,
                  105,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      children: [
                        CreationPageHeader(
                          icon: Icons.sports_martial_arts_rounded,
                          title: localizations.createBattle,
                        ),
                        const SizedBox(height: 18),
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: starterCard),
                              const SizedBox(width: 18),
                              Container(
                                width: 44,
                                height: 44,
                                margin: const EdgeInsets.only(top: 80),
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: OnepieceColors.deepFancyBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Text(
                                  'VS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(child: receiverCard),
                            ],
                          )
                        else ...[
                          starterCard,
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: CircleAvatar(
                              radius: 23,
                              backgroundColor: OnepieceColors.deepFancyBlue,
                              child: Text(
                                'VS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          receiverCard,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _getFoot(context),
          ],
        );
      },
    );
  }

  Widget getLeftPanel(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: MediaQuery.of(context).size.width < 600 ? 6 : 10,
          ),
          child: ValueListenableBuilder<CharacterListView?>(
            valueListenable: starterSelectedItem,
            builder: (context, value, _) {
              final isSmall = MediaQuery.of(context).size.width < 600;
              final imgSize = isSmall ? 64.0 : 130.0;
              final graphW = isSmall ? 120.0 : 170.0;
              final graphH = isSmall ? 120.0 : 140.0;
              return SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: isSmall ? 4 : 10),
                      child: isSmall
                          ? SizedBox(
                              height: 62,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (starterSelectedItem.value != null) ...[
                                    _mobileCharacterGraph(
                                        starterSelectedItem.value!),
                                    const SizedBox(width: 10),
                                  ],
                                  SizedBox(
                                    width: imgSize,
                                    height: imgSize,
                                    child: starterSelectedItem.value == null
                                        ? ImageHelper.getSvgIconWithColor(
                                            'images/svgs/question.svg',
                                            32,
                                            32,
                                            OnepieceColors.liteFancyBlue)
                                        : ImageLazyLoader(
                                            key: UniqueKey(),
                                            uriProvider: () =>
                                                starterSelectedItem
                                                    .value!.imageUri!,
                                            width: 54,
                                            borderWidth: 1.5,
                                            borderRadios: 54),
                                  ),
                                ],
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                  SizedBox(
                                      width: imgSize,
                                      height: imgSize,
                                      child: FittedBox(
                                          fit: BoxFit.fill,
                                          child: starterSelectedItem.value ==
                                                  null
                                              ? ImageHelper.getSvgIconWithColor(
                                                  'images/svgs/question.svg',
                                                  60,
                                                  60,
                                                  OnepieceColors.liteFancyBlue)
                                              : Padding(
                                                  padding: const EdgeInsets.all(
                                                      20.0),
                                                  child: ImageLazyLoader(
                                                      key: UniqueKey(),
                                                      uriProvider: () =>
                                                          starterSelectedItem
                                                              .value!.imageUri!,
                                                      width: 200,
                                                      borderWidth: 3,
                                                      borderRadios: 100)))),
                                  if (starterSelectedItem.value != null)
                                    SizedBox(
                                        width: graphW,
                                        height: graphH,
                                        child: Padding(
                                            padding: const EdgeInsets.only(
                                                left: 30.0),
                                            child: RotatedBox(
                                                quarterTurns: 1,
                                                child: CharacterBarGraph(
                                                    symmetric: false,
                                                    characterData:
                                                        CharacterData(
                                                            starterSelectedItem
                                                                .value!.attack,
                                                            starterSelectedItem
                                                                .value!.defense,
                                                            starterSelectedItem
                                                                .value!
                                                                .intelligence,
                                                            starterSelectedItem
                                                                .value!.speed,
                                                            starterSelectedItem
                                                                .value!.blood,
                                                            starterSelectedItem
                                                                .value!
                                                                .energy))))),
                                ]),
                    ),
                    _selectedCharacterSummary(
                        starterSelectedItem.value, isSmall),
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
      final isSmall = MediaQuery.of(context).size.width < 600;
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE7ECF2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(isSmall ? 8.0 : 15.0),
              child: SizedBox(
                width: isSmall ? double.infinity : 400,
                height: 46,
                child: TextFormField(
                  controller: starterTextController,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFDCE4EC)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: OnepieceColors.fancyGreen, width: 1.6),
                    ),
                    prefixIcon: Icon(Icons.search, size: isSmall ? 18 : 24),
                    labelText: AppLocalizations.of(context)!.characterName,
                  ),
                  style: TextStyle(fontSize: isSmall ? 12 : null),
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
                          _controller
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
              padding: EdgeInsets.only(
                  left: isSmall ? 2.0 : 0,
                  right: isSmall ? 2.0 : 0,
                  bottom: isSmall ? 8.0 : 10.0),
              child: SizedBox(
                width: isSmall ? double.infinity : 400,
                height: isSmall ? 320 : 400,
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
                        padding: EdgeInsets.all(isSmall ? 2 : 3),
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
                          dense: isSmall,
                          visualDensity: isSmall
                              ? const VisualDensity(
                                  horizontal: -4, vertical: -4)
                              : VisualDensity.standard,
                          minVerticalPadding: isSmall ? 0 : null,
                          contentPadding: EdgeInsets.fromLTRB(
                              isSmall ? 4 : 8, 0, isSmall ? 2 : 0, 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          selected: starterSelectedId == character.id,
                          hoverColor: OnepieceColors.fancyBlue,
                          selectedTileColor: OnepieceColors.fancyBlue,
                          tileColor: const Color(0xFF243B53),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(
                                        3, 3, isSmall ? 5 : 8, 3),
                                    child: ImageLazyLoader(
                                        key: UniqueKey(),
                                        uriProvider: () => character.imageUri!,
                                        width: isSmall ? 34 : 50,
                                        borderWidth: isSmall ? 1.5 : 2,
                                        borderRadios: 6),
                                  ),
                                  SizedBox(
                                    width: isSmall ? 74 : 260,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          I18nHelper.getDisplayNameFromI18n(
                                              character.name),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: isSmall
                                              ? OnepieceFonts
                                                  .smallContentStyleWhite
                                                  .copyWith(fontSize: 11)
                                              : OnepieceFonts
                                                  .smallContentStyleWhite,
                                        ),
                                        if (!isSmall &&
                                            character.hakis.isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 3.0),
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 3.0),
                                              child: Row(
                                                children: character.hakis
                                                    .map((e) => Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  right: 5),
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
                                  ),
                                ],
                              ),
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                    isSmall ? 2 : 20, 0, isSmall ? 1 : 3, 0),
                                child: starterSelectedId == character.id
                                    ? Icon(
                                        Icons.check_circle,
                                        size: isSmall ? 16 : 20,
                                      )
                                    : Icon(
                                        Icons.check_circle_outline,
                                        size: isSmall ? 16 : 20,
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
            padding: EdgeInsets.symmetric(
              vertical: MediaQuery.of(context).size.width < 600 ? 6 : 10,
            ),
            child: ValueListenableBuilder<CharacterListView?>(
                valueListenable: receiverSelectedItem,
                builder: (context, value, _) {
                  final isSmall = MediaQuery.of(context).size.width < 600;
                  final imgSize = isSmall ? 64.0 : 130.0;
                  final graphW = isSmall ? 120.0 : 170.0;
                  final graphH = isSmall ? 120.0 : 140.0;
                  return SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: isSmall ? 4 : 10),
                          child: isSmall
                              ? SizedBox(
                                  height: 62,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                          width: imgSize,
                                          height: imgSize,
                                          child: receiverSelectedItem.value ==
                                                  null
                                              ? ImageHelper.getSvgIconWithColor(
                                                  'images/svgs/question.svg',
                                                  32,
                                                  32,
                                                  OnepieceColors.liteFancyBlue)
                                              : ImageLazyLoader(
                                                  key: UniqueKey(),
                                                  uriProvider: () =>
                                                      receiverSelectedItem
                                                          .value!.imageUri!,
                                                  width: 54,
                                                  borderWidth: 1.5,
                                                  borderRadios: 54)),
                                      if (receiverSelectedItem.value !=
                                          null) ...[
                                        const SizedBox(width: 10),
                                        _mobileCharacterGraph(
                                            receiverSelectedItem.value!),
                                      ],
                                    ],
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                      if (receiverSelectedItem.value != null)
                                        SizedBox(
                                            width: graphW,
                                            height: graphH,
                                            child: Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 30.0),
                                                child: RotatedBox(
                                                    quarterTurns: 1,
                                                    child: CharacterBarGraph(
                                                        characterData: CharacterData(
                                                            receiverSelectedItem
                                                                .value!.attack,
                                                            receiverSelectedItem
                                                                .value!.defense,
                                                            receiverSelectedItem
                                                                .value!
                                                                .intelligence,
                                                            receiverSelectedItem
                                                                .value!.speed,
                                                            receiverSelectedItem
                                                                .value!.blood,
                                                            receiverSelectedItem
                                                                .value!.energy),
                                                        symmetric: false)))),
                                      SizedBox(
                                          width: imgSize,
                                          height: imgSize,
                                          child: FittedBox(
                                              fit: BoxFit.fill,
                                              child: receiverSelectedItem
                                                          .value ==
                                                      null
                                                  ? ImageHelper.getSvgIconWithColor(
                                                      'images/svgs/question.svg',
                                                      60,
                                                      60,
                                                      OnepieceColors
                                                          .liteFancyBlue)
                                                  : Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              20.0),
                                                      child: ImageLazyLoader(
                                                          key: UniqueKey(),
                                                          uriProvider: () =>
                                                              receiverSelectedItem
                                                                  .value!
                                                                  .imageUri!,
                                                          width: 200,
                                                          borderWidth: 3,
                                                          borderRadios: 100)))),
                                    ]),
                        ),
                        _selectedCharacterSummary(
                            receiverSelectedItem.value, isSmall),
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
      final isSmall = MediaQuery.of(context).size.width < 600;
      return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE7ECF2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(isSmall ? 8.0 : 15.0),
                child: SizedBox(
                  width: isSmall ? double.infinity : 400,
                  height: 46,
                  child: TextFormField(
                    controller: receiverTextController,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDCE4EC)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: OnepieceColors.fancyGreen, width: 1.6),
                      ),
                      prefixIcon: Icon(Icons.search, size: isSmall ? 18 : 24),
                      labelText: AppLocalizations.of(context)!.characterName,
                    ),
                    style: TextStyle(fontSize: isSmall ? 12 : null),
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
                            _controller
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
                padding: EdgeInsets.only(
                    left: isSmall ? 2.0 : 0,
                    right: isSmall ? 2.0 : 0,
                    bottom: isSmall ? 8.0 : 10.0),
                child: SizedBox(
                  width: isSmall ? double.infinity : 400,
                  height: isSmall ? 320 : 400,
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
                          padding: EdgeInsets.all(isSmall ? 2 : 3),
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
                            dense: isSmall,
                            visualDensity: isSmall
                                ? const VisualDensity(
                                    horizontal: -4, vertical: -4)
                                : VisualDensity.standard,
                            minVerticalPadding: isSmall ? 0 : null,
                            contentPadding: EdgeInsets.fromLTRB(
                                isSmall ? 4 : 8, 0, isSmall ? 2 : 0, 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            selected: receiverSelectedId == character.id,
                            hoverColor: OnepieceColors.fancyBlue,
                            selectedTileColor: OnepieceColors.fancyBlue,
                            tileColor: const Color(0xFF243B53),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(
                                          3, 3, isSmall ? 5 : 8, 3),
                                      child: ImageLazyLoader(
                                          key: UniqueKey(),
                                          uriProvider: () =>
                                              character.imageUri!,
                                          width: isSmall ? 34 : 50,
                                          borderWidth: isSmall ? 1.5 : 2,
                                          borderRadios: 6),
                                    ),
                                    SizedBox(
                                      width: isSmall ? 74 : 260,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            I18nHelper.getDisplayNameFromI18n(
                                                character.name),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: isSmall
                                                ? OnepieceFonts
                                                    .smallContentStyleWhite
                                                    .copyWith(fontSize: 11)
                                                : OnepieceFonts
                                                    .smallContentStyleWhite,
                                          ),
                                          if (!isSmall &&
                                              character.hakis.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 5.0),
                                              child: Row(
                                                children: character.hakis
                                                    .map(
                                                      (e) => Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(right: 5),
                                                        child: OnepieceTag
                                                            .getHakiTag(
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
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                      isSmall ? 2 : 20, 0, isSmall ? 1 : 3, 0),
                                  child: receiverSelectedId == character.id
                                      ? Icon(
                                          Icons.check_circle,
                                          size: isSmall ? 16 : 20,
                                        )
                                      : Icon(
                                          Icons.check_circle_outline,
                                          size: isSmall ? 16 : 20,
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
    final isSmall = MediaQuery.of(context).size.width < 600;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A16324F),
              blurRadius: 18,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: ValueListenableBuilder<CharacterListView?>(
            valueListenable: starterSelectedItem,
            builder: (context, value, _) {
              return ValueListenableBuilder<CharacterListView?>(
                  valueListenable: receiverSelectedItem,
                  builder: (context, value, _) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 11),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(right: isSmall ? 5 : 8),
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.arrow_back_rounded,
                                  size: 18),
                              label: Text(
                                AppLocalizations.of(context)!.back,
                                style: TextStyle(fontSize: isSmall ? 12 : null),
                              ),
                              onPressed: () {
                                context.goNamed("battle");
                              },
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(right: isSmall ? 5 : 8),
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.refresh_rounded, size: 18),
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
                              label: Text(
                                AppLocalizations.of(context)!.clearForm,
                                style: TextStyle(fontSize: isSmall ? 12 : null),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(isSmall ? 88 : 120, 46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.sports_martial_arts_rounded,
                                size: 18),
                            onPressed: (starterSelectedId.isEmpty ||
                                    receiverSelectedId.isEmpty)
                                ? null
                                : () {
                                    CreateBattleRequest request =
                                        CreateBattleRequest(
                                            userId: getIt<User>().id,
                                            starterId: starterSelectedId,
                                            receiverId: receiverSelectedId);
                                    final router = GoRouter.of(context);
                                    Future<CreateBattleResponse?> response =
                                        _controller
                                            .createBattle(request);
                                    response.then((value) {
                                      if (!mounted) return;
                                      if (value?.battleId != null) {
                                        router.goNamed('battleDetails',
                                            extra: value?.battleId,
                                            pathParameters: {
                                              'id': value!.battleId!
                                            });
                                      } else {
                                        router.goNamed("battle");
                                      }
                                    });
                                  },
                            label: Text(
                              AppLocalizations.of(context)!.create,
                              style: TextStyle(fontSize: isSmall ? 12 : null),
                            ),
                          ),
                        ],
                      ),
                    );
                  });
            }),
      ),
    );
  }
}
