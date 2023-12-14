import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:one_piece_battles_flutter/utils/string_extensions.dart';
import 'package:openapi/api.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../repository/image_dao.dart';
import '../utils/base64_helper.dart';
import '../utils/compare_uint8list.dart';
import '../utils/data_converter.dart';
import '../utils/onepiece_image_picker.dart';
import '../utils/random_string_generator.dart';

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

  late CharacterFullView character;
  List<BattleListView> battles = [];
  List<Fruit> fruits = [];
  List<Group> groups = [];

  // Uint8List _pickedImage = Uint8List(0);
  // Uint8List _originalImage = Uint8List(0);
  // bool _newImagePicked = false;
  SliderData sliderData = SliderData();

  final _basicFormKey = GlobalKey<FormState>();
  final _digitFormKey = GlobalKey<FormState>();

  bool basicInfoEditable = false;
  bool combatInfoEditable = false;

  @override
  void initState() {
    super.initState();
  }

  _loadData() {
    return getIt<CharacterDao>().getCharacter(
        GetCharacterFullViewRequest(characterId: widget.characterId));
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
                padding: const EdgeInsets.fromLTRB(8,0,8,0),
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
                    _getCombatInfo(context)
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

  // void _compareImage() {
  //   if (CompareUint8List.equals(_originalImage, _pickedImage)) {
  //     _newImagePicked = false;
  //   } else {
  //     _newImagePicked = true;
  //   }
  // }

  // Column _getCharacterDataList(BuildContext context) {
  //   return Column(
  //     children: [
  //       _getDataRow(AppLocalizations.of(context)!.characterAttack, 1000, 10,
  //           sliderData.attack, character.attack.toDouble(), (value) {
  //         sliderData.setAttack(value);
  //       }),
  //       _getDataRow(AppLocalizations.of(context)!.characterDefense, 1000, 10,
  //           sliderData.defense, character.defense.toDouble(), (value) {
  //         sliderData.setDefense(value);
  //       }),
  //       _getDataRow(AppLocalizations.of(context)!.characterBlood, 10000, 100,
  //           sliderData.blood, character.blood.toDouble(), (value) {
  //         sliderData.setBlood(value);
  //       }),
  //       _getDataRow(AppLocalizations.of(context)!.characterSpeed, 200, 10,
  //           sliderData.speed, character.speed.toDouble(), (value) {
  //         sliderData.setSpeed(value);
  //       }),
  //       _getDataRow(AppLocalizations.of(context)!.groupGain, 5, 1,
  //           sliderData.groupGain, character.groupGain.toDouble(), (value) {
  //         sliderData.setGroupGain(value);
  //       }),
  //       _getDataRow(
  //           AppLocalizations.of(context)!.characterIntelligence,
  //           260,
  //           70,
  //           sliderData.intelligence,
  //           character.intelligence.toDouble(), (value) {
  //         sliderData.setIntelligence(value);
  //       }),
  //     ],
  //   );
  // }
  //
  // Row _getDataRow(String name, int max, int min, double currentValue,
  //     double originalValue, Function(double) onChangeFunction) {
  //   return Row(
  //     children: [
  //       Padding(
  //         padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
  //         child: Row(
  //           crossAxisAlignment: CrossAxisAlignment.center,
  //           mainAxisAlignment: MainAxisAlignment.start,
  //           children: [
  //             SizedBox(width: 70, child: Text(name)),
  //             Padding(
  //               padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
  //               child: SizedBox(
  //                   width: 42, child: Text(currentValue.toInt().toString())),
  //             )
  //           ],
  //         ),
  //       ),
  //       SizedBox(
  //         width: 360,
  //         height: 35,
  //         child: Expanded(
  //           child: Slider(
  //             value: currentValue,
  //             // allowedInteraction: SliderInteraction.tapAndSlide,
  //             label: currentValue.round().toString(),
  //             divisions: max - min,
  //             min: min.toDouble(),
  //             max: max.toDouble(),
  //             secondaryTrackValue: originalValue,
  //             secondaryActiveColor: OnepieceColors.themeColor,
  //             onChanged: (value) {
  //               setState(() {
  //                 currentValue = value;
  //                 onChangeFunction(value);
  //               });
  //             },
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // show character basic information (editable if permitted)
  Widget _getBasicInfo(BuildContext context) {
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
                  setState(() {
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
                    borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                    border: Border.all(
                        color: OnepieceColors.liteFancyBlue, width: 5, style: BorderStyle.solid),
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
  }

// show character combat information (editable if permitted)
  Widget _getCombatInfo(BuildContext context) {
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
                  setState(() {
                    combatInfoEditable = !combatInfoEditable;
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
                      basicInfoEditable,
                      characterAttackController,
                      AppLocalizations.of(context)!.characterAttack,
                      10,
                      1000,
                    ),
                    _getDigitFormField(
                      context,
                      basicInfoEditable,
                      characterDefenseController,
                      AppLocalizations.of(context)!.characterDefense,
                      10,
                      1000,
                    ),
                    _getDigitFormField(
                      context,
                      basicInfoEditable,
                      characterBloodController,
                      AppLocalizations.of(context)!.characterBlood,
                      100,
                      10000,
                    ),
                    _getDigitFormField(
                      context,
                      basicInfoEditable,
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
                      basicInfoEditable,
                      characterIntelligenceController,
                      AppLocalizations.of(context)!.characterIntelligence,
                      70,
                      260,
                    ),
                    _getDigitFormField(
                      context,
                      basicInfoEditable,
                      characterEnergyController,
                      AppLocalizations.of(context)!.age,
                      10,
                      50,
                    ),
                    _getDigitFormField(
                      context,
                      basicInfoEditable,
                      characterGroupGainController,
                      AppLocalizations.of(context)!.groupGain,
                      1,
                      5,
                    ),
                    _getDigitFormField(
                      context,
                      basicInfoEditable,
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
                contentPadding: EdgeInsets.fromLTRB(10, 2, 10, 2)
              ),
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

  Widget _EatFruit(BuildContext context) {
    return Column();
  }

  Widget _getFruits(BuildContext context) {
    return Column();
  }

  Widget _getBattle(BuildContext context) {
    return Column();
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
