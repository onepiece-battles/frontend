import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:one_piece_battles_flutter/components/digit_text_form_field.dart';
import 'package:one_piece_battles_flutter/components/string_text_form_field.dart';
import 'package:one_piece_battles_flutter/constants/button_style.dart';
import 'package:one_piece_battles_flutter/utils/random_string_generator.dart';
import 'package:openapi/api.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../constants/path_constants.dart';
import '../../popup/onepiece_alert.dart';
import '../../repository/character_dao.dart';
import '../../repository/image_dao.dart';
import '../../utils/base64_helper.dart';
import '../../utils/data_converter.dart';
import '../../utils/i18n_helper.dart';
import '../../utils/image_helper.dart';
import '../../utils/onepiece_image_picker.dart';

GetIt getIt = GetIt.instance;

class CreateCharacterView extends StatefulWidget {
  const CreateCharacterView({super.key});

  @override
  State<CreateCharacterView> createState() => _CreateCharacterViewState();
}

class _CreateCharacterViewState extends State<CreateCharacterView> {
  TextEditingController characterNameEnController = TextEditingController(
      text: RandomStringGenerator.generateRandomName(
          8,
          getIt<User>().loginRole == UserRole.NIKA &&
              getIt<User>().nickname != "Nika"));
  TextEditingController characterNameCnController = TextEditingController(
      text: RandomStringGenerator.generateRandomChineseName(
          3,
          getIt<User>().loginRole == UserRole.NIKA &&
              getIt<User>().nickname != "Nika"));

  // battle data controller
  TextEditingController characterFruitLimitController = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(
          1, 1, getIt<User>().loginRole == UserRole.NIKA));
  TextEditingController characterGroupGainController = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(
          100,
          200,
          getIt<User>().loginRole == UserRole.NIKA &&
              getIt<User>().nickname != "Nika"));
  TextEditingController characterAttackController = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(
          10,
          1000,
          getIt<User>().loginRole == UserRole.NIKA &&
              getIt<User>().nickname != "Nika"));
  TextEditingController characterDefenseController = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(
          10,
          1000,
          getIt<User>().loginRole == UserRole.NIKA &&
              getIt<User>().nickname != "Nika"));
  TextEditingController characterIntelligenceController = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(
          70,
          260,
          getIt<User>().loginRole == UserRole.NIKA &&
              getIt<User>().nickname != "Nika"));
  TextEditingController characterBloodController = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(
          100,
          10000,
          getIt<User>().loginRole == UserRole.NIKA &&
              getIt<User>().nickname != "Nika"));
  TextEditingController characterSpeedController = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(
          10,
          200,
          getIt<User>().loginRole == UserRole.NIKA &&
              getIt<User>().nickname != "Nika"));
  TextEditingController characterEnergyController = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(
          100,
          300,
          getIt<User>().loginRole == UserRole.NIKA &&
              getIt<User>().nickname != "Nika"));

  // character details controller
  TextEditingController characterAge = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(
          0,
          100000,
          getIt<User>().loginRole == UserRole.NIKA &&
              getIt<User>().nickname != "Nika"));
  TextEditingController characterHeight = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(
          1,
          100000,
          getIt<User>().loginRole == UserRole.NIKA &&
              getIt<User>().nickname != "Nika"));
  TextEditingController characterBirthPlace = TextEditingController(
      text: RandomStringGenerator.generateRandomName(
          10,
          getIt<User>().loginRole == UserRole.NIKA &&
              getIt<User>().nickname != "Nika"));
  TextEditingController characterDateOfBirthMonth = TextEditingController();
  TextEditingController characterDateOfBirthDay = TextEditingController();
  TextEditingController characterBounty = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(
          10,
          100000,
          getIt<User>().loginRole == UserRole.NIKA &&
              getIt<User>().nickname != "Nika"));

  List<TextEditingController> characterControllerListRequired() {
    return <TextEditingController>[
      characterNameEnController,
      characterNameCnController,
      characterFruitLimitController,
      characterGroupGainController,
      characterAttackController,
      characterDefenseController,
      characterIntelligenceController,
      characterBloodController,
      characterSpeedController,
      characterEnergyController
    ];
  }

  List<TextEditingController> characterControllerListAll() {
    return <TextEditingController>[
      characterNameEnController,
      characterNameCnController,
      characterFruitLimitController,
      characterGroupGainController,
      characterAttackController,
      characterDefenseController,
      characterIntelligenceController,
      characterBloodController,
      characterSpeedController,
      characterEnergyController,
      characterAge,
      characterHeight,
      characterDateOfBirthMonth,
      characterDateOfBirthDay,
      characterBirthPlace,
      characterBounty
    ];
  }

  Uint8List _pickedImage = Uint8List(0);
  bool _newImagePicked = false;
  String _chosenImageName = "";
  BattleStyle selectedBattleStyle = BattleStyle.BODY;
  Race selectedRace = Race.HUMAN;
  List<Haki> selectedHakis = [];
  String selectedDay = "1";
  String selectedMonth = "1";
  double dividerWidth = 900;
  double sideWidth = 50;

  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: dividerWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(sideWidth, 10, 0, 20),
                      child: Text(
                        AppLocalizations.of(context)!.basicInfo,
                        style: OnepieceFonts.headerStyle,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: sideWidth),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                _getAvatar(context),
                                StringTextFormField(
                                    context,
                                    true,
                                    characterNameCnController,
                                    AppLocalizations.of(context)!.name,
                                    30,
                                    ImageHelper.getTextFormFieldIcon(
                                        'images/character_digits_icon/name.svg',
                                        true,
                                        null),
                                    true),
                                if (getIt<User>().loginRole == UserRole.NIKA)
                                  StringTextFormField(
                                      context,
                                      true,
                                      characterNameEnController,
                                      AppLocalizations.of(context)!.name,
                                      30,
                                      ImageHelper.getTextFormFieldIcon(
                                          'images/character_digits_icon/name.svg',
                                          true,
                                          null),
                                      true),
                              ]),
                          SizedBox(
                            width: 300,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.battleStyle,
                                  style: OnepieceFonts.fancyBlueHintFont,
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                _getBattleStyle(context),
                                const SizedBox(
                                  height: 30,
                                ),
                                Text(
                                  AppLocalizations.of(context)!.race,
                                  style: OnepieceFonts.fancyBlueHintFont,
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                _getRace(context),
                                const SizedBox(
                                  height: 30,
                                ),
                                Text(
                                  AppLocalizations.of(context)!.hakis,
                                  style: OnepieceFonts.fancyBlueHintFont,
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                _getHakiList(context),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    SizedBox(
                      width: dividerWidth,
                      height: 30,
                      child: const Divider(
                        height: 2,
                        color: Colors.grey,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: sideWidth),
                      child: Form(
                        key: _formKey,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 0, 0, 15),
                                  child: Row(
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!
                                            .battleInfo,
                                        style: OnepieceFonts.headerStyle,
                                      ),
                                      Text(
                                        "  ( ${AppLocalizations.of(context)!.required} )",
                                        style: OnepieceFonts.hintFont,
                                      )
                                    ],
                                  ),
                                ),
                                DigitTextFormField(
                                    context,
                                    true,
                                    characterFruitLimitController,
                                    AppLocalizations.of(context)!.fruitLimit,
                                    1,
                                    2,
                                    ImageHelper.getTextFormFieldIcon(
                                        'images/character_digits_icon/fruit_limit.svg',
                                        true,
                                        null),
                                    true),
                                DigitTextFormField(
                                    context,
                                    true,
                                    characterGroupGainController,
                                    AppLocalizations.of(context)!.groupGain,
                                    100,
                                    200,
                                    ImageHelper.getTextFormFieldIcon(
                                        'images/character_digits_icon/group_gain.svg',
                                        true,
                                        null),
                                    true),
                                DigitTextFormField(
                                    context,
                                    true,
                                    characterAttackController,
                                    AppLocalizations.of(context)!
                                        .characterAttack,
                                    10,
                                    1000,
                                    ImageHelper.getTextFormFieldIcon(
                                        'images/character_digits_icon/attack.svg',
                                        true,
                                        null),
                                    true),
                                DigitTextFormField(
                                    context,
                                    true,
                                    characterDefenseController,
                                    AppLocalizations.of(context)!
                                        .characterDefense,
                                    10,
                                    1000,
                                    ImageHelper.getTextFormFieldIcon(
                                        'images/character_digits_icon/defense.svg',
                                        true,
                                        null),
                                    true),
                                DigitTextFormField(
                                    context,
                                    true,
                                    characterIntelligenceController,
                                    AppLocalizations.of(context)!
                                        .characterIntelligence,
                                    70,
                                    260,
                                    ImageHelper.getTextFormFieldIcon(
                                        'images/character_digits_icon/intelligence.svg',
                                        true,
                                        null),
                                    true),
                                DigitTextFormField(
                                    context,
                                    true,
                                    characterBloodController,
                                    AppLocalizations.of(context)!
                                        .characterBlood,
                                    100,
                                    10000,
                                    ImageHelper.getTextFormFieldIcon(
                                        'images/character_digits_icon/blood.svg',
                                        true,
                                        null),
                                    true),
                                DigitTextFormField(
                                    context,
                                    true,
                                    characterSpeedController,
                                    AppLocalizations.of(context)!
                                        .characterSpeed,
                                    10,
                                    200,
                                    ImageHelper.getTextFormFieldIcon(
                                        'images/character_digits_icon/speed.svg',
                                        true,
                                        null),
                                    true),
                                DigitTextFormField(
                                    context,
                                    true,
                                    characterEnergyController,
                                    AppLocalizations.of(context)!
                                        .characterEnergy,
                                    100,
                                    300,
                                    ImageHelper.getTextFormFieldIcon(
                                        'images/character_digits_icon/energy.svg',
                                        true,
                                        null),
                                    true),
                              ],
                            ),
                            const SizedBox(
                              width: 100,
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 0, 0, 15),
                                  child: Row(
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!
                                            .characterDetail,
                                        style: OnepieceFonts.headerStyle,
                                      ),
                                      Text(
                                        "  ( ${AppLocalizations.of(context)!.optional} )",
                                        style: OnepieceFonts.hintFont,
                                      )
                                    ],
                                  ),
                                ),
                                DigitTextFormField(
                                    context,
                                    true,
                                    characterAge,
                                    AppLocalizations.of(context)!.age,
                                    0,
                                    100000,
                                    ImageHelper.getTextFormFieldIcon(
                                        'images/character_digits_icon/age.svg',
                                        true,
                                        null),
                                    false),
                                DigitTextFormField(
                                    context,
                                    true,
                                    characterHeight,
                                    AppLocalizations.of(context)!.height,
                                    1,
                                    100000,
                                    ImageHelper.getTextFormFieldIcon(
                                        'images/character_digits_icon/height.svg',
                                        true,
                                        null),
                                    false),
                                StringTextFormField(
                                    context,
                                    true,
                                    characterBirthPlace,
                                    AppLocalizations.of(context)!.birthPlace,
                                    20,
                                    ImageHelper.getTextFormFieldIcon(
                                        'images/character_digits_icon/birth_place.svg',
                                        true,
                                        null),
                                    false),
                                DigitTextFormField(
                                    context,
                                    true,
                                    characterBounty,
                                    AppLocalizations.of(context)!.bounty,
                                    10,
                                    100000000000,
                                    ImageHelper.getTextFormFieldIcon(
                                        'images/character_digits_icon/bounty.svg',
                                        true,
                                        null),
                                    false),
                                SizedBox(
                                  width: 240,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          width: 300,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              ImageHelper.getTextFormFieldIcon(
                                                  "images/character_digits_icon/birthday.svg",
                                                  true,
                                                  null),
                                              Text(
                                                AppLocalizations.of(context)!
                                                    .birthDay,
                                                style: OnepieceFonts
                                                    .deepBlackHintFont,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            SizedBox(
                                              width: 60,
                                              child:
                                                  DropdownButtonHideUnderline(
                                                child: DropdownButton2(
                                                  isExpanded: true,
                                                  value: selectedMonth,
                                                  onChanged: (String? month) {
                                                    setState(() {
                                                      selectedMonth = month!;
                                                    });
                                                  },
                                                  buttonStyleData:
                                                      ButtonStyleData(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 5),
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(3),
                                                        color: OnepieceColors
                                                            .liteFancyGreen),
                                                    height: 30,
                                                    width: 60,
                                                  ),
                                                  menuItemStyleData:
                                                      const MenuItemStyleData(
                                                    height: 30,
                                                  ),
                                                  selectedItemBuilder:
                                                      (context) {
                                                    return List<
                                                            String>.generate(
                                                        12,
                                                        (int index) => (index +
                                                                1)
                                                            .toString()).map(
                                                        (String month) {
                                                      return Container(
                                                        alignment:
                                                            AlignmentDirectional
                                                                .center,
                                                        child: Text(
                                                          month,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 16,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      );
                                                    }).toList();
                                                  },
                                                  items: List<String>.generate(
                                                      12,
                                                      (int index) => (index + 1)
                                                          .toString()).map(
                                                      (String month) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: month,
                                                      child: Text(
                                                        month,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                            ),
                                            Text(
                                              AppLocalizations.of(context)!
                                                  .month,
                                              style: OnepieceFonts.contentStyle,
                                            ),
                                            SizedBox(
                                              width: 60,
                                              child:
                                                  DropdownButtonHideUnderline(
                                                child: DropdownButton2(
                                                  isExpanded: true,
                                                  value: selectedDay,
                                                  onChanged: (String? day) {
                                                    setState(() {
                                                      selectedDay = day!;
                                                    });
                                                  },
                                                  buttonStyleData:
                                                      ButtonStyleData(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6),
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(3),
                                                        color: OnepieceColors
                                                            .liteFancyGreen),
                                                    height: 30,
                                                    width: 60,
                                                  ),
                                                  menuItemStyleData:
                                                      const MenuItemStyleData(
                                                    height: 30,
                                                  ),
                                                  selectedItemBuilder:
                                                      (context) {
                                                    return List<
                                                            String>.generate(
                                                        31,
                                                        (int index) => (index +
                                                                1)
                                                            .toString()).map(
                                                        (String day) {
                                                      return Container(
                                                        alignment:
                                                            AlignmentDirectional
                                                                .center,
                                                        child: Text(
                                                          day,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 16,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      );
                                                    }).toList();
                                                  },
                                                  items: List<String>.generate(
                                                      31,
                                                      (int index) => (index + 1)
                                                          .toString()).map(
                                                      (String day) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: day,
                                                      child: Text(
                                                        day,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                            ),
                                            Text(
                                              AppLocalizations.of(context)!.day,
                                              style: OnepieceFonts.contentStyle,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 40,
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
        _getFootBar(context)
      ],
    );
  }

  Widget _getAvatar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 15.0, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: _pickedImage.isEmpty
                  ? ClipOval(
                      child: Image.asset(PathConstants.luffyHat),
                    )
                  : ClipOval(
                      child: Image.memory(_pickedImage),
                    ),
            ),
            const SizedBox(
              width: 10,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.uploadNewAvatar,
                  style: const TextStyle(
                      color: OnepieceFonts.headerFontColor,
                      fontSize: OnepieceFonts.contentFontSize,
                      fontWeight: OnepieceFonts.headerFontWeight),
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _pickAndProcessImage,
                      style: OnepieceButtonStyle.getDefaultStyle(),
                      child: Text(AppLocalizations.of(context)!.chooseFile),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    SizedBox(
                      width: 200,
                      child: Text(
                        _chosenImageName != ""
                            ? _chosenImageName
                            : AppLocalizations.of(context)!.noFileChosen,
                        style: OnepieceFonts.contentStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  AppLocalizations.of(context)!.maxFileSizeDescription,
                  style: OnepieceFonts.contentStyle,
                )
              ],
            )
          ],
        )
      ]),
    );
  }

  Widget _getBattleStyle(BuildContext context) {
    Map<BattleStyle, String> battleStyleToDisplayValue = {
      BattleStyle.BODY: AppLocalizations.of(context)!.body,
      BattleStyle.SCIENCE: AppLocalizations.of(context)!.science,
      BattleStyle.KATANA: AppLocalizations.of(context)!.katana,
      BattleStyle.SHOOTER: AppLocalizations.of(context)!.shoot
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2(
          isExpanded: true,
          value: selectedBattleStyle,
          hint: Text(
            AppLocalizations.of(context)!.battleStyle,
            style: OnepieceFonts.dropDownItemStyle,
          ),
          onChanged: (value) {
            setState(() {
              selectedBattleStyle = value as BattleStyle;
            });
          },
          selectedItemBuilder: (context) {
            return BattleStyle.values.map(
              (item) {
                return Container(
                  alignment: AlignmentDirectional.center,
                  child: Text(
                    battleStyleToDisplayValue[selectedBattleStyle]!,
                    style: const TextStyle(
                      fontSize: 16,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ),
                );
              },
            ).toList();
          },
          buttonStyleData: ButtonStyleData(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 35,
            width: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: OnepieceColors.liteFancyGreen,
            ),
          ),
          menuItemStyleData: const MenuItemStyleData(
            height: 35,
          ),
          items: BattleStyle.values.map((BattleStyle battleStyle) {
            return DropdownMenuItem<BattleStyle>(
              value: battleStyle,
              enabled: true,
              child: Text(battleStyleToDisplayValue[battleStyle]!,
                  style: OnepieceFonts.dropDownItemStyle),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _getRace(BuildContext context) {
    Map<Race, String> raceEnumToDisplayName = {
      Race.HUMAN: AppLocalizations.of(context)!.human,
      Race.FISH_MAN: AppLocalizations.of(context)!.fishman,
      Race.MERFOLK: AppLocalizations.of(context)!.merfolk,
      Race.GIANT: AppLocalizations.of(context)!.giant,
      Race.LONG_ARM: AppLocalizations.of(context)!.longArm,
      Race.LONG_LEG: AppLocalizations.of(context)!.longLeg,
      Race.SNAKE_NECK: AppLocalizations.of(context)!.snakeNeck,
      Race.THREE_EYE: AppLocalizations.of(context)!.threeEye,
      Race.LUNARIAN: AppLocalizations.of(context)!.lunarian,
      Race.MINK: AppLocalizations.of(context)!.mink,
      Race.WORLD_NOBEL: AppLocalizations.of(context)!.worldNobel,
      Race.DWARVES: AppLocalizations.of(context)!.dwarves,
      Race.NO_LIFE_OBJECT: AppLocalizations.of(context)!.lifeless_object,
      Race.ANIMAL: AppLocalizations.of(context)!.animal,
      Race.SOUL: AppLocalizations.of(context)!.soul,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2(
          isExpanded: true,
          value: selectedRace,
          hint: Text(
            AppLocalizations.of(context)!.race,
            style: OnepieceFonts.dropDownItemStyle,
          ),
          onChanged: (value) {
            setState(() {
              selectedRace = value as Race;
            });
          },
          selectedItemBuilder: (context) {
            return Race.values.map(
              (item) {
                return Container(
                  alignment: AlignmentDirectional.center,
                  child: Text(
                    raceEnumToDisplayName[selectedRace]!,
                    style: const TextStyle(
                      fontSize: 16,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ),
                );
              },
            ).toList();
          },
          buttonStyleData: ButtonStyleData(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 35,
            width: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: OnepieceColors.liteFancyGreen,
            ),
          ),
          menuItemStyleData: const MenuItemStyleData(
            height: 35,
          ),
          items: Race.values.map((Race race) {
            return DropdownMenuItem<Race>(
              value: race,
              enabled: true,
              child: Text(raceEnumToDisplayName[race]!,
                  style: OnepieceFonts.dropDownItemStyle),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _getHakiList(BuildContext context) {
    Map<Haki, String> enumValueToDisplayValue = {
      Haki.busoshoku: AppLocalizations.of(context)!.busoshoku,
      Haki.haoshoku: AppLocalizations.of(context)!.haoshoku,
      Haki.kenbunshoku: AppLocalizations.of(context)!.kenbunshoku,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2(
          isExpanded: true,
          value: selectedHakis.isEmpty ? null : selectedHakis.last,
          hint: Text(
            AppLocalizations.of(context)!.hakis,
            style: OnepieceFonts.dropDownItemStyle,
          ),
          onChanged: (value) {},
          selectedItemBuilder: (context) {
            return Haki.values.map(
              (item) {
                return Container(
                  alignment: AlignmentDirectional.center,
                  child: Text(
                    selectedHakis
                        .map((selectedHaki) {
                          return enumValueToDisplayValue[selectedHaki];
                        })
                        .toSet()
                        .join(', '),
                    style: const TextStyle(
                      fontSize: 16,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ),
                );
              },
            ).toList();
          },
          buttonStyleData: ButtonStyleData(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 35,
            width: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: OnepieceColors.liteFancyGreen,
            ),
          ),
          menuItemStyleData: const MenuItemStyleData(
            height: 35,
          ),
          items: Haki.values.map((Haki haki) {
            return DropdownMenuItem<Haki>(
              value: haki,
              enabled: false,
              child: StatefulBuilder(
                builder: (context, menuSetState) {
                  final isSelected = selectedHakis.contains(haki);
                  return InkWell(
                    onTap: () {
                      isSelected
                          ? selectedHakis.remove(haki)
                          : selectedHakis.add(haki);
                      // //This rebuilds the StatefulWidget to update the button's text
                      setState(() {});
                      //This rebuilds the dropdownMenu Widget to update the check mark
                      menuSetState(() {});
                    },
                    child: Container(
                      height: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 3.0),
                      child: Row(
                        children: [
                          if (isSelected)
                            const Icon(Icons.check_box_outlined)
                          else
                            const Icon(Icons.check_box_outline_blank),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              enumValueToDisplayValue[haki]!,
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _getFootBar(BuildContext context) {
    return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  child: Text(AppLocalizations.of(context)!.clearForm),
                  onPressed: () {
                    setState(() {
                      characterControllerListAll().forEach((element) {
                        element.clear();
                      });
                      _pickedImage = Uint8List(0);
                      _chosenImageName = '';
                      _newImagePicked = false;
                    });
                  },
                ),
                ElevatedButton(
                  onPressed: !_allElementsAreFilled()
                      ? null
                      : () {
                          final isValid = _formKey.currentState!.validate();
                          if (!isValid) {
                            return;
                          }
                          if (!_newImagePicked) {
                            OnepieceAlert.getBasicAlertDialogFunc(
                                context,
                                AppLocalizations.of(context)!.hint,
                                AppLocalizations.of(context)!
                                    .characterImageRequired);
                            return;
                          }
                          CreateCharacterRequest addCharacterRequest =
                              CreateCharacterRequest(
                            battleStyle: selectedBattleStyle,
                            race: selectedRace,
                            hakis: selectedHakis,
                            name: RandomStringGenerator.generateI18n(
                                characterNameEnController.text,
                                characterNameCnController.text),
                            maximumFruitCount: DataConverter.stringToInt(
                                characterFruitLimitController.text.trim()),
                            groupGain: DataConverter.stringToInt(
                                characterGroupGainController.text.trim()),
                            attack: DataConverter.stringToInt(
                                characterAttackController.text.trim()),
                            defense: DataConverter.stringToInt(
                                characterDefenseController.text.trim()),
                            intelligence: DataConverter.stringToInt(
                                characterIntelligenceController.text.trim()),
                            blood: DataConverter.stringToInt(
                                characterBloodController.text.trim()),
                            speed: DataConverter.stringToInt(
                                characterSpeedController.text.trim()),
                            energy: DataConverter.stringToInt(
                                characterEnergyController.text.trim()),
                            height: DataConverter.stringToInt(
                                characterHeight.text.trim()),
                            age: DataConverter.stringToInt(
                                characterAge.text.trim()),
                            birthPlace: characterBirthPlace.text.trim(),
                            dateOfBirth: "$selectedMonth-$selectedDay",
                            bounty: DataConverter.stringToInt(
                                characterBounty.text.trim()),
                          );
                          getIt<CharacterDao>()
                              .addCharacter(addCharacterRequest)
                              .then((characterResponse) {
                            var encodedImage =
                                Base64Helper.encode(_pickedImage);
                            UploadImageRequest uploadImageRequest =
                                UploadImageRequest(
                                    resourceId: characterResponse!.id,
                                    image: encodedImage,
                                    type: ResourceType.CHARACTER);
                            getIt<ImageDao>().addImage(uploadImageRequest).then(
                                (value) => context.goNamed('characterDetails',
                                        extra: characterResponse.id,
                                        pathParameters: {
                                          'name':
                                              I18nHelper.getDisplayNameFromI18n(
                                                  characterResponse.name)
                                        }));
                          });
                        },
                  child: Text(AppLocalizations.of(context)!.submitForm),
                ),
              ],
            ),
          ),
        ));
  }

  bool _allElementsAreFilled() {
    characterControllerListRequired().map((e) {
      if (e.text == '') {
        return false;
      }
    });
    return true;
  }

  // 1. 抽象出选择并处理图片的逻辑到单独的方法
  Future<void> _pickAndProcessImage() async {
    try {
      // 尝试选择图片
      XFile? pickedImage = await OnepieceImagePicker.pickWebImage();
      if (pickedImage == null) {
        // 如果没有选择图片，则直接返回
        return;
      }

      // 读取图片字节数据
      Uint8List imageInByte = await pickedImage.readAsBytes();

      // 验证图片大小
      if (!ImageHelper.isValidImageSize(500 * 1024, imageInByte)) {
        showImageSizeErrorDialog();
        return;
      }

      // 更新UI状态
      setState(() {
        _pickedImage = imageInByte;
        _chosenImageName = pickedImage.name;
        _newImagePicked = true;
      });
    } catch (e) {
      // 异常处理：例如，可以显示一个错误对话框或日志记录等
    }
  }

  // 2. 抽象出显示图片大小错误的对话框逻辑
  void showImageSizeErrorDialog() {
    OnepieceAlert.getBasicAlertDialogFunc(
        context,
        AppLocalizations.of(context)!.alert,
        AppLocalizations.of(context)!.imageSizeExceedsLimit);
  }
}
