import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:one_piece_battles_flutter/components/digit_text_form_field.dart';
import 'package:one_piece_battles_flutter/components/string_text_form_field.dart';
import 'package:one_piece_battles_flutter/components/creation_form_card.dart';
import 'package:one_piece_battles_flutter/utils/random_string_generator.dart';
import 'package:openapi/api.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../constants/path_constants.dart';
import '../../popup/onepiece_alert.dart';
import '../../utils/base64_helper.dart';
import '../../utils/data_converter.dart';
import '../../utils/i18n_helper.dart';
import '../../utils/image_helper.dart';
import '../../utils/nested_scroll_helper.dart';
import '../../utils/onepiece_image_picker.dart';
import 'create_character_controller.dart';

GetIt getIt = GetIt.instance;

class CreateCharacterView extends StatefulWidget {
  const CreateCharacterView({super.key});

  @override
  State<CreateCharacterView> createState() => _CreateCharacterViewState();
}

class _CreateCharacterViewState extends State<CreateCharacterView> {
  final ScrollController _pageScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  final CreateCharacterController _controller = CreateCharacterController();
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
      characterNameCnController,
      if (getIt<User>().loginRole == UserRole.NIKA) characterNameEnController,
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

  @override
  void dispose() {
    _pageScrollController.dispose();
    _horizontalScrollController.dispose();
    for (final controller in characterControllerListAll()) {
      controller.dispose();
    }
    _controller.dispose();
    super.dispose();
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

  Widget _buildCardLayout(BuildContext context, bool isWide) {
    final localizations = AppLocalizations.of(context)!;

    final profileCard = CreationFormCard(
      icon: Icons.person_rounded,
      title: localizations.basicInfo,
      badge: localizations.required,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _getAvatar(context),
          const SizedBox(height: 18),
          _buildStringField(
              context, characterNameCnController, localizations.name, true),
          if (getIt<User>().loginRole == UserRole.NIKA)
            _buildStringField(
                context, characterNameEnController, localizations.name, true),
          _selectionLabel(localizations.battleStyle),
          _getBattleStyle(context),
          const SizedBox(height: 14),
          _selectionLabel(localizations.race),
          _getRace(context),
          const SizedBox(height: 14),
          _selectionLabel(localizations.hakis),
          _getHakiList(context),
        ],
      ),
    );

    final detailsCard = CreationFormCard(
      icon: Icons.badge_rounded,
      title: localizations.characterDetail,
      badge: localizations.optional,
      child: Column(
        children: [
          _responsiveFieldGrid(
            context,
            [
              _buildDigitField(context, characterBounty, localizations.bounty,
                  10, 100000000000, false),
              _buildDigitField(
                  context, characterAge, localizations.age, 0, 100000, false),
              _buildDigitField(context, characterHeight, localizations.height,
                  1, 100000, false),
              _buildStringField(context, characterBirthPlace,
                  localizations.birthPlace, false),
            ],
          ),
          _getBirthDropdown(context),
        ],
      ),
    );

    final battleCard = CreationFormCard(
      icon: Icons.shield_rounded,
      title: localizations.battleInfo,
      badge: localizations.required,
      child: _responsiveFieldGrid(
        context,
        [
          _buildDigitField(context, characterAttackController,
              localizations.characterAttack, 10, 1500, true),
          _buildDigitField(context, characterDefenseController,
              localizations.characterDefense, 10, 1400, true),
          _buildDigitField(context, characterBloodController,
              localizations.characterBlood, 100, 10000, true),
          _buildDigitField(context, characterEnergyController,
              localizations.characterEnergy, 100, 300, true),
          _buildDigitField(context, characterSpeedController,
              localizations.characterSpeed, 10, 200, true),
          _buildDigitField(context, characterIntelligenceController,
              localizations.characterIntelligence, 70, 260, true),
          _buildDigitField(context, characterGroupGainController,
              localizations.groupGain, 100, 200, true),
          _buildDigitField(context, characterFruitLimitController,
              localizations.fruitLimit, 1, 2, true),
        ],
      ),
    );

    return SingleChildScrollView(
      controller: _pageScrollController,
      padding: EdgeInsets.fromLTRB(isWide ? 28 : 12, 18, isWide ? 28 : 12, 100),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                CreationPageHeader(
                  icon: Icons.person_add_alt_1_rounded,
                  title: localizations.createCharacter,
                ),
                const SizedBox(height: 18),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            profileCard,
                            const SizedBox(height: 18),
                            detailsCard,
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(flex: 6, child: battleCard),
                    ],
                  )
                else ...[
                  profileCard,
                  const SizedBox(height: 14),
                  detailsCard,
                  const SizedBox(height: 14),
                  battleCard,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        label,
        style: OnepieceFonts.deepBlackHintFont
            .copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _responsiveFieldGrid(BuildContext context, List<Widget> fields) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 540;
        final width =
            twoColumns ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          children: fields
              .map((field) => SizedBox(width: width, child: field))
              .toList(),
        );
      },
    );
  }

  Widget _buildDigitField(BuildContext context, TextEditingController ctrl,
      String hint, int min, int max, bool required) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (value) {
          if (!required && (value == null || value.trim().isEmpty)) {
            return null;
          }
          if (value == null || value.trim().isEmpty) {
            return AppLocalizations.of(context)!.requiredField;
          }
          final number = int.tryParse(value.trim());
          if (number == null) {
            return AppLocalizations.of(context)!.fieldMustBeInt;
          }
          if (number < min || number > max) {
            return AppLocalizations.of(context)!.valueExceedsLimit;
          }
          return null;
        },
        decoration: _fieldDecoration(hint, '$min – $max'),
      ),
    );
  }

  Widget _buildStringField(BuildContext context, TextEditingController ctrl,
      String hint, bool required) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        textInputAction: TextInputAction.next,
        validator: (value) =>
            required && (value == null || value.trim().isEmpty)
                ? AppLocalizations.of(context)!.requiredField
                : null,
        decoration: _fieldDecoration(hint, null),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label, String? hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDCE4EC)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDCE4EC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: OnepieceColors.fancyGreen, width: 1.6),
      ),
    );
  }

  Widget _getBirthDropdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _selectionLabel(AppLocalizations.of(context)!.birthDay),
        Row(children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                      width: 60,
                      child: DropdownButtonHideUnderline(
                          child: DropdownButton2<String>(
                        isExpanded: true,
                        value: selectedMonth,
                        onChanged: (v) =>
                            setState(() => selectedMonth = v ?? ''),
                        buttonStyleData: ButtonStyleData(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            height: 30,
                            width: 60,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                color: OnepieceColors.liteFancyGreen)),
                        menuItemStyleData: const MenuItemStyleData(height: 30),
                        items: List.generate(12, (i) => (i + 1).toString())
                            .map((m) => DropdownMenuItem<String>(
                                value: m,
                                child: Text(m,
                                    style: const TextStyle(fontSize: 14))))
                            .toList(),
                      ))),
                  Text(' ${AppLocalizations.of(context)!.month} ',
                      style: OnepieceFonts.smallContentStyle),
                  SizedBox(
                      width: 60,
                      child: DropdownButtonHideUnderline(
                          child: DropdownButton2<String>(
                        isExpanded: true,
                        value: selectedDay,
                        onChanged: (v) => setState(() => selectedDay = v ?? ''),
                        buttonStyleData: ButtonStyleData(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            height: 30,
                            width: 60,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                color: OnepieceColors.liteFancyGreen)),
                        menuItemStyleData: const MenuItemStyleData(height: 30),
                        items: List.generate(31, (i) => (i + 1).toString())
                            .map((d) => DropdownMenuItem<String>(
                                value: d,
                                child: Text(d,
                                    style: const TextStyle(fontSize: 14))))
                            .toList(),
                      ))),
                  Text(' ${AppLocalizations.of(context)!.day}',
                      style: OnepieceFonts.smallContentStyle),
                ],
              ),
            ),
          ),
        ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useCardLayout = constraints.maxWidth.isFinite;
        dividerWidth = useCardLayout ? constraints.maxWidth - 30 : 900;
        sideWidth = useCardLayout ? 8.0 : 50;
        return Stack(
          children: [
            if (useCardLayout)
              ColoredBox(
                color: const Color(0xFFF5F7FB),
                child: _buildCardLayout(context, constraints.maxWidth >= 900),
              )
            else
              SingleChildScrollView(
                controller: _pageScrollController,
                scrollDirection: Axis.vertical,
                child: Center(
                  child: NestedHorizontalScrollView(
                    controller: _horizontalScrollController,
                    verticalParentController: _pageScrollController,
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
                            padding:
                                EdgeInsets.symmetric(horizontal: sideWidth),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      if (getIt<User>().loginRole ==
                                          UserRole.NIKA)
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!
                                            .battleStyle,
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
                            padding:
                                EdgeInsets.symmetric(horizontal: sideWidth),
                            child: Form(
                              key: _formKey,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            0, 0, 0, 15),
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
                                          AppLocalizations.of(context)!
                                              .fruitLimit,
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
                                          AppLocalizations.of(context)!
                                              .groupGain,
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
                                          1500,
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
                                          1400,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            0, 0, 0, 15),
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
                                          AppLocalizations.of(context)!
                                              .birthPlace,
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
                                          padding:
                                              const EdgeInsets.only(left: 8.0),
                                          child: Column(
                                            children: [
                                              SizedBox(
                                                width: 300,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    ImageHelper
                                                        .getTextFormFieldIcon(
                                                            "images/character_digits_icon/birthday.svg",
                                                            true,
                                                            null),
                                                    Text(
                                                      AppLocalizations.of(
                                                              context)!
                                                          .birthDay,
                                                      style: OnepieceFonts
                                                          .deepBlackHintFont,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
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
                                                        onChanged:
                                                            (String? month) {
                                                          setState(() {
                                                            selectedMonth =
                                                                month!;
                                                          });
                                                        },
                                                        buttonStyleData:
                                                            ButtonStyleData(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      5),
                                                          decoration: BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          3),
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
                                                              (int index) =>
                                                                  (index + 1)
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
                                                        items: List<
                                                                String>.generate(
                                                            12,
                                                            (int index) => (index +
                                                                    1)
                                                                .toString()).map(
                                                            (String month) {
                                                          return DropdownMenuItem<
                                                              String>(
                                                            value: month,
                                                            child: Text(
                                                              month,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                          );
                                                        }).toList(),
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    AppLocalizations.of(
                                                            context)!
                                                        .month,
                                                    style: OnepieceFonts
                                                        .contentStyle,
                                                  ),
                                                  SizedBox(
                                                    width: 60,
                                                    child:
                                                        DropdownButtonHideUnderline(
                                                      child: DropdownButton2(
                                                        isExpanded: true,
                                                        value: selectedDay,
                                                        onChanged:
                                                            (String? day) {
                                                          setState(() {
                                                            selectedDay = day!;
                                                          });
                                                        },
                                                        buttonStyleData:
                                                            ButtonStyleData(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      6),
                                                          decoration: BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          3),
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
                                                              (int index) =>
                                                                  (index + 1)
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
                                                        items: List<
                                                                String>.generate(
                                                            31,
                                                            (int index) => (index +
                                                                    1)
                                                                .toString()).map(
                                                            (String day) {
                                                          return DropdownMenuItem<
                                                              String>(
                                                            value: day,
                                                            child: Text(
                                                              day,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                          );
                                                        }).toList(),
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    AppLocalizations.of(
                                                            context)!
                                                        .day,
                                                    style: OnepieceFonts
                                                        .contentStyle,
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
      },
    );
  }

  Widget _getAvatar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECF2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: OnepieceColors.fancyGreen, width: 2),
            ),
            child: ClipOval(
              child: _pickedImage.isEmpty
                  ? Image.asset(PathConstants.luffyHat, fit: BoxFit.cover)
                  : Image.memory(_pickedImage, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.uploadNewAvatar,
                  style: OnepieceFonts.deepBlackHintFont
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickAndProcessImage,
                      icon: const Icon(Icons.upload_rounded, size: 18),
                      label: Text(AppLocalizations.of(context)!.chooseFile),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text(
                        _chosenImageName.isNotEmpty
                            ? _chosenImageName
                            : AppLocalizations.of(context)!.noFileChosen,
                        style: OnepieceFonts.contentStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  AppLocalizations.of(context)!.maxFileSizeDescription,
                  style: OnepieceFonts.contentStyle.copyWith(
                    color: OnepieceColors.menuIconColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getBattleStyle(BuildContext context) {
    Map<BattleStyle, String> battleStyleToDisplayValue = {
      BattleStyle.BODY: AppLocalizations.of(context)!.body,
      BattleStyle.SCIENCE: AppLocalizations.of(context)!.science,
      BattleStyle.KATANA: AppLocalizations.of(context)!.katana,
      BattleStyle.SHOOTER: AppLocalizations.of(context)!.shoot,
      BattleStyle.STICK: AppLocalizations.of(context)!.stick,
      BattleStyle.RIFLE: AppLocalizations.of(context)!.rifle,
      BattleStyle.SWORD: AppLocalizations.of(context)!.sword
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
            height: 46,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFF7F9FC),
              border: Border.all(color: const Color(0xFFDCE4EC)),
            ),
          ),
          menuItemStyleData: const MenuItemStyleData(height: 35),
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
            height: 46,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFF7F9FC),
              border: Border.all(color: const Color(0xFFDCE4EC)),
            ),
          ),
          menuItemStyleData: const MenuItemStyleData(height: 35),
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
            height: 46,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFF7F9FC),
              border: Border.all(color: const Color(0xFFDCE4EC)),
            ),
          ),
          menuItemStyleData: const MenuItemStyleData(height: 35),
          items: Haki.values.map((Haki haki) {
            return DropdownMenuItem<Haki>(
              value: haki,
              enabled: false,
              child: StatefulBuilder(
                builder: (context, menuSetState) {
                  final isSelected = selectedHakis.contains(haki);
                  return InkWell(
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(AppLocalizations.of(context)!.clearForm),
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
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(132, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 19),
                  onPressed: () {
                    final isValid = _formKey.currentState!.validate();
                    if (!isValid) {
                      return;
                    }
                    if (!_newImagePicked) {
                      OnepieceAlert.getBasicAlertDialogFunc(
                          context,
                          AppLocalizations.of(context)!.hint,
                          AppLocalizations.of(context)!.characterImageRequired);
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
                      height: characterHeight.text.isEmpty
                          ? null
                          : DataConverter.stringToInt(
                              characterHeight.text.trim()),
                      age: characterAge.text.isEmpty
                          ? null
                          : DataConverter.stringToInt(characterAge.text.trim()),
                      birthPlace: characterBirthPlace.text.trim(),
                      dateOfBirth: "$selectedMonth-$selectedDay",
                      bounty: characterBounty.text.isEmpty
                          ? null
                          : DataConverter.stringToInt(
                              characterBounty.text.trim()),
                    );
                    final router = GoRouter.of(context);
                    _controller
                        .addCharacter(addCharacterRequest)
                        .then((characterResponse) {
                      if (!mounted) return;
                      var encodedImage = Base64Helper.encode(_pickedImage);
                      UploadImageRequest uploadImageRequest =
                          UploadImageRequest(
                              resourceId: characterResponse!.id,
                              image: encodedImage,
                              type: ResourceType.CHARACTER);
                      _controller
                          .uploadImage(uploadImageRequest)
                          .then((value) {
                        if (!mounted) return;
                        router.goNamed('characterDetails',
                            extra: characterResponse.id,
                            pathParameters: {
                              'name': I18nHelper.getDisplayNameFromI18n(
                                  characterResponse.name)
                            });
                      });
                    });
                  },
                  label: Text(AppLocalizations.of(context)!.submitForm),
                ),
              ],
            ),
          ),
        ));
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
