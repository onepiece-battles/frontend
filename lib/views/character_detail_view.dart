import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_tag.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:one_piece_battles_flutter/utils/string_extensions.dart';
import 'package:openapi/api.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../repository/fruit_dao.dart';
import '../utils/base64_helper.dart';

GetIt getIt = GetIt.instance;

class CharacterDetail extends StatefulWidget {
  final String characterId;
  const CharacterDetail({super.key, required this.characterId});

  @override
  State<CharacterDetail> createState() => _CharacterDetailState();
}

class _CharacterDetailState extends State<CharacterDetail> {
  TextEditingController characterNameController = TextEditingController();

  // battle data controller
  TextEditingController characterFruitLimitController = TextEditingController();
  TextEditingController characterGroupGainController = TextEditingController();
  TextEditingController characterAttackController = TextEditingController();
  TextEditingController characterDefenseController = TextEditingController();
  TextEditingController characterIntelligenceController =
      TextEditingController();
  TextEditingController characterBloodController = TextEditingController();
  TextEditingController characterSpeedController = TextEditingController();
  TextEditingController characterEnergyController = TextEditingController();

  // character details controller
  TextEditingController characterAge = TextEditingController();
  TextEditingController characterHeight = TextEditingController();
  TextEditingController characterBirthPlace = TextEditingController();
  TextEditingController characterDateOfBirth = TextEditingController();
  TextEditingController characterBounty = TextEditingController();

  // fruit search data
  TextEditingController fruitNameController = TextEditingController();
  FruitFilter fruitFilter = FruitFilter();
  List<FruitListView> searchingFruitList = [];
  String? selectedFruitId;

  // initial date
  late CharacterFullView character;
  List<BattleListView> battles = [];
  List<FruitListView> fruits = [];
  List<Group> groups = [];

  SliderData sliderData = SliderData();

  final _basicFormKey = GlobalKey<FormState>();
  final _digitFormKey = GlobalKey<FormState>();

  bool basicInfoEditable = false;
  bool combatInfoEditable = false;
  bool fruitSearchEnabled = false;

  @override
  void initState() {
    super.initState();
  }

  _loadData() {
    return getIt<CharacterDao>().getCharacter(
        GetCharacterFullViewRequest(characterId: widget.characterId));
  }

  _eatFruit() {
    EatFruitRequest request =
        EatFruitRequest(characterId: character.id, fruitId: selectedFruitId!);
    Future<EatFruitResponse?> response =
        getIt<CharacterDao>().eatFruit(request);
    response.then(
      (value) => {
        setState(
          () {},
        )
      },
    );
  }

  void _updateData(CharacterFullView characterFullView) {
    character = characterFullView;
    battles = characterFullView.battles;
    fruits = characterFullView.fruits;
    // set initial slider value
    sliderData.setAttack(characterFullView.attack.toDouble());
    sliderData.setDefense(characterFullView.defense.toDouble());
    sliderData.setBlood(characterFullView.blood.toDouble());
    sliderData.setGroupGain(characterFullView.groupGain.toDouble());
    sliderData.setIntelligence(characterFullView.intelligence.toDouble());
    sliderData.setSpeed(characterFullView.speed.toDouble());
    battles = characterFullView.battles;
    fruits = characterFullView.fruits;
    if (fruits.length < character.maximumFruitCount) {
      fruitSearchEnabled = true;
    }
  }

  void _updateControllerData() {
    // update basic information
    characterNameController.text = character.name.toString();
    characterAge.text = character.age == null ? "" : character.age.toString();
    characterHeight.text =
        character.height == null ? "" : character.height.toString();
    characterBirthPlace.text =
        character.birthPlace == null ? "" : character.birthPlace.toString();
    characterDateOfBirth.text =
        character.dateOfBirth == null ? "" : character.dateOfBirth.toString();
    characterBounty.text =
        character.bounty == null ? "" : character.bounty.toString();
    // update combat information
    characterFruitLimitController.text = character.maximumFruitCount.toString();
    characterGroupGainController.text = character.groupGain.toString();
    characterAttackController.text = character.attack.toString();
    characterDefenseController.text = character.defense.toString();
    characterIntelligenceController.text = character.intelligence.toString();
    characterBloodController.text = character.blood.toString();
    characterSpeedController.text = character.speed.toString();
    characterEnergyController.text = character.energy.toString();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _loadData(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            _updateData(snapshot.data);
            _updateControllerData();
            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: Column(
                  children: [
                    _getBasicInfo(context),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Divider(
                        color: OnepieceColors.fancyBlue,
                        thickness: 1,
                      ),
                    ),
                    _getCombatInfo(context),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Divider(
                        color: OnepieceColors.fancyBlue,
                        thickness: 1,
                      ),
                    ),
                    _getEatFruit(context),
                  ],
                ),
              ),
            );
          } else {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.loading,
                style: OnepieceFonts.loadingFont,
              ),
            );
          }
        });
  }

  Widget _getBasicInfo(BuildContext context) {
    return StatefulBuilder(builder: (context, basicState) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.basicInfo,
                  style: OnepieceFonts.headerStyle,
                ),
                const SizedBox(
                  width: 15,
                ),
                IconButton(
                  splashRadius: 0.1,
                  onPressed: () {
                    basicState(() {
                      basicInfoEditable = !basicInfoEditable;
                    });
                  },
                  icon: basicInfoEditable
                      ? const Icon(
                          Icons.check,
                          size: 25,
                          color: OnepieceColors.fancyBlue,
                        )
                      : const Icon(
                          Icons.edit,
                          size: 25,
                          color: OnepieceColors.fancyBlue,
                        ),
                )
              ],
            ),
          ),
          Form(
            key: _basicFormKey,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    width: 270,
                    height: 270,
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.all(Radius.circular(5.0)),
                      border: Border.all(
                          color: OnepieceColors.liteFancyBlue,
                          width: 5,
                          style: BorderStyle.solid),
                    ),
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: character.profileImage == null
                          ? Container()
                          : Image.memory(
                              Base64Helper.decode(character.profileImage!)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      _getStringFormField(
                        context,
                        basicInfoEditable,
                        characterNameController,
                        AppLocalizations.of(context)!.name,
                        20,
                      ),
                      _getStringFormField(
                        context,
                        basicInfoEditable,
                        characterBirthPlace,
                        AppLocalizations.of(context)!.birthPlace,
                        20,
                      ),
                      _getStringFormField(
                        context,
                        basicInfoEditable,
                        characterDateOfBirth,
                        AppLocalizations.of(context)!.birthDay,
                        20,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      _getDigitFormField(
                        context,
                        basicInfoEditable,
                        characterBounty,
                        AppLocalizations.of(context)!.bounty,
                        10,
                        100000000000,
                      ),
                      _getDigitFormField(
                        context,
                        basicInfoEditable,
                        characterAge,
                        AppLocalizations.of(context)!.age,
                        0,
                        100000,
                      ),
                      _getDigitFormField(
                        context,
                        basicInfoEditable,
                        characterHeight,
                        AppLocalizations.of(context)!.height,
                        1,
                        100000,
                      ),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      );
    });
  }

// show character combat information (editable if permitted)
  Widget _getCombatInfo(BuildContext context) {
    return StatefulBuilder(builder: (context, combatState) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.battleInfo,
                  style: OnepieceFonts.headerStyle,
                ),
                const SizedBox(
                  width: 15,
                ),
                IconButton(
                  splashRadius: 0.1,
                  onPressed: () {
                    combatState(() {
                      combatInfoEditable = !combatInfoEditable;
                    });
                  },
                  icon: combatInfoEditable
                      ? const Icon(
                          Icons.check,
                          size: 25,
                          color: OnepieceColors.fancyBlue,
                        )
                      : const Icon(
                          Icons.edit,
                          size: 25,
                          color: OnepieceColors.fancyBlue,
                        ),
                )
              ],
            ),
          ),
          Form(
            key: _digitFormKey,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      _getDigitFormField(
                        context,
                        combatInfoEditable,
                        characterAttackController,
                        AppLocalizations.of(context)!.characterAttack,
                        10,
                        1000,
                      ),
                      _getDigitFormField(
                        context,
                        combatInfoEditable,
                        characterDefenseController,
                        AppLocalizations.of(context)!.characterDefense,
                        10,
                        1000,
                      ),
                      _getDigitFormField(
                        context,
                        combatInfoEditable,
                        characterBloodController,
                        AppLocalizations.of(context)!.characterBlood,
                        100,
                        10000,
                      ),
                      _getDigitFormField(
                        context,
                        combatInfoEditable,
                        characterSpeedController,
                        AppLocalizations.of(context)!.characterSpeed,
                        10,
                        200,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      _getDigitFormField(
                        context,
                        combatInfoEditable,
                        characterIntelligenceController,
                        AppLocalizations.of(context)!.characterIntelligence,
                        70,
                        260,
                      ),
                      _getDigitFormField(
                        context,
                        combatInfoEditable,
                        characterEnergyController,
                        AppLocalizations.of(context)!.characterEnergy,
                        10,
                        50,
                      ),
                      _getDigitFormField(
                        context,
                        combatInfoEditable,
                        characterGroupGainController,
                        AppLocalizations.of(context)!.groupGain,
                        1,
                        5,
                      ),
                      _getDigitFormField(
                        context,
                        combatInfoEditable,
                        characterFruitLimitController,
                        AppLocalizations.of(context)!.fruitLimit,
                        1,
                        2,
                      ),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      );
    });
  }

  Widget _getEatFruit(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.devilFruit,
                style: OnepieceFonts.headerStyle,
              ),
              const SizedBox(
                width: 15,
              ),
            ],
          ),
        ),
        if (fruits.length < character.maximumFruitCount) _getFruitEat(context),
        if (fruits.isNotEmpty) _getFruitList(context)
      ],
    );
  }

  Widget _getFruitEat(BuildContext context) {
    Map<FruitType, String> fruitTypeToDisplayValue = {
      FruitType.logia: AppLocalizations.of(context)!.logiaFruit,
      FruitType.zoan: AppLocalizations.of(context)!.zoanFruit,
      FruitType.ancientZoan: AppLocalizations.of(context)!.ancientZoanFruit,
      FruitType.mythicalZoan: AppLocalizations.of(context)!.mythicalZoanFruit,
      FruitType.artificialZoan:
          AppLocalizations.of(context)!.artificialZoanFruit,
      FruitType.paramecia: AppLocalizations.of(context)!.parameciaFruit,
    };
    return StatefulBuilder(builder: (context, fruitSetstate) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.all(Radius.circular(5.0)),
          border: Border.all(
              color: OnepieceColors.fancyBlue,
              width: 3,
              style: BorderStyle.solid),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 8, 8, 0),
                child: SizedBox(
                  width: 300,
                  child: TextFormField(
                    enabled: fruitSearchEnabled,
                    controller: fruitNameController,
                    decoration: InputDecoration(
                      label: Text(
                        AppLocalizations.of(context)!.fruitName,
                        style: OnepieceFonts.hintFont,
                      ),
                      disabledBorder: const OutlineInputBorder(
                          borderSide:
                              BorderSide(color: OnepieceColors.fancyGreen)),
                      enabledBorder: const OutlineInputBorder(
                          borderSide:
                              BorderSide(color: OnepieceColors.fancyGreen)),
                      focusedBorder: const OutlineInputBorder(
                          borderSide:
                              BorderSide(color: OnepieceColors.fancyGreen)),
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      selectedFruitId = null;
                      fruitSetstate(() {});
                      if (value.isEmpty) {
                        searchingFruitList = [];
                        fruitSetstate(() {});
                        return;
                      }
                      fruitFilter.name = value;
                      ListFruitRequest request = ListFruitRequest(
                          pageSize: 5,
                          pageIndex: 1,
                          sortKeys: [],
                          fruitFilter: fruitFilter);
                      Future<ListFruitResponse?> response =
                          getIt<FruitDao>().list(request);
                      response.then(
                        (value) => {
                          searchingFruitList = value!.fruits,
                          fruitSetstate(() {})
                        },
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 300,
                  decoration: const BoxDecoration(
                    color: OnepieceColors.menuBackgroundColor,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: searchingFruitList.length,
                    itemBuilder: (context, index) {
                      var fruit = searchingFruitList[index];
                      return Material(
                        type: MaterialType.transparency,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                          decoration: const BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5))),
                          child: ListTile(
                            minLeadingWidth: 10,
                            contentPadding:
                                const EdgeInsets.fromLTRB(8, 0, 0, 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            selected: selectedFruitId == fruit.id,
                            selectedTileColor: OnepieceColors.liteFancyBlue,
                            onTap: () {
                              selectedFruitId = fruit.id!;
                              fruitSetstate(() {});
                            },
                            hoverColor: OnepieceColors.liteFancyBlue,
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(fruit.name!),
                                Padding(
                                  padding: const EdgeInsets.only(right: 5),
                                  child: OnepieceTag.getFruitTag(
                                    fruit.fruitType!,
                                    fruitTypeToDisplayValue[fruit.fruitType!]!,
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
              if (searchingFruitList.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: ElevatedButton(
                      onPressed: selectedFruitId == null
                          ? null
                          : () {
                              setState(() {
                                _eatFruit();
                              });
                            },
                      child: Text(AppLocalizations.of(context)!.eat)),
                )
            ],
          ),
        ),
      );
    });
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
    List<Widget> fruitPart = [];
    for (var fruit in fruits) {
      var column = Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(fruit.name!),
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: OnepieceTag.getFruitTag(
                  fruit.fruitType!,
                  fruitTypeToDisplayValue[fruit.fruitType!]!,
                ),
              ),
            ],
          ),
        ],
      );
      fruitPart.add(column);
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
          width: 300,
          child: Column(
            children: fruitPart,
          )),
    );
  }

  Widget _getBattle(BuildContext context) {
    return Column();
  }

  Widget _getStringFormField(BuildContext context, bool editable,
      TextEditingController controller, String label, int length) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 300,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                label,
                style: OnepieceFonts.deepBlackHintFont,
              ),
            ),
          ),
          SizedBox(
            width: 300,
            child: TextFormField(
              controller: controller,
              enabled: editable,
              // maxLength: length,
              decoration: const InputDecoration(
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  contentPadding: EdgeInsets.fromLTRB(10, 2, 10, 2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getDigitFormField(BuildContext context, bool editable,
      TextEditingController controller, String label, int min, int max) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 300,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                label,
                style: OnepieceFonts.deepBlackHintFont,
              ),
            ),
          ),
          SizedBox(
            width: 300,
            child: TextFormField(
              enabled: editable,
              controller: controller,
              validator: (value) {
                if (value!.isWhiteSpace()) {
                  return AppLocalizations.of(context)!.requiredField;
                } else if (!value.isValidInt()) {
                  return AppLocalizations.of(context)!.fieldMustBeInt;
                }
                int valueInt = int.parse(value);
                if (valueInt < min || valueInt > max) {
                  return AppLocalizations.of(context)!.valueExceedsLimit;
                }
                return null;
              },
              decoration: InputDecoration(
                floatingLabelBehavior: FloatingLabelBehavior.auto,
                contentPadding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
                labelText: "($min-$max)",
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SliderData {
  late double _currentAttack;
  late double _currentDefense;
  late double _currentBlood;
  late double _currentIntelligence;
  late double _currentSpeed;
  late double _currentGroupGain;

  void setAttack(double attack) {
    _currentAttack = attack;
  }

  void setDefense(double defense) {
    _currentDefense = defense;
  }

  void setBlood(double blood) {
    _currentBlood = blood;
  }

  void setIntelligence(double intelligence) {
    _currentIntelligence = intelligence;
  }

  void setSpeed(double speed) {
    _currentSpeed = speed;
  }

  void setGroupGain(double groupGain) {
    _currentGroupGain = groupGain;
  }

  double get attack => _currentAttack;
  double get defense => _currentDefense;
  double get blood => _currentBlood;
  double get speed => _currentSpeed;
  double get intelligence => _currentIntelligence;
  double get groupGain => _currentGroupGain;
}
