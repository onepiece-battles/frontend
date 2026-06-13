import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:openapi/api.dart';
import '../../components/digit_text_form_field.dart';
import '../../components/fruit_digit_text_form_field.dart';
import '../../components/string_text_form_field.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../repository/fruit_dao.dart';
import '../../utils/data_converter.dart';
import '../../utils/i18n_helper.dart';
import '../../utils/image_helper.dart';
import '../../utils/random_string_generator.dart';
import '../../utils/responsive_breakpoints.dart';

GetIt getIt = GetIt.instance;

class CreateFruitView extends StatefulWidget {
  const CreateFruitView({Key? key}) : super(key: key);

  @override
  State<CreateFruitView> createState() => _CreateFruitViewState();
}

class _CreateFruitViewState extends State<CreateFruitView> {
  TextEditingController fruitNameEnController = TextEditingController(
      text: "");
  TextEditingController fruitNameChController = TextEditingController(
      text: "");
  TextEditingController attackSlopeController = TextEditingController(
      text: "");
  TextEditingController attackInterceptController = TextEditingController(
      text: "");
  TextEditingController defenseSlopeController = TextEditingController(
      text: "");
  TextEditingController defenseInterceptController = TextEditingController(
      text: "");
  TextEditingController intelligenceSlopeController = TextEditingController(
      text: "");
  TextEditingController intelligenceInterceptController = TextEditingController(
      text: "");
  TextEditingController bloodSlopeController = TextEditingController(
      text: '');
  TextEditingController bloodInterceptController = TextEditingController(
      text: '');
  TextEditingController speedSlopeController = TextEditingController(
      text: '');
  TextEditingController speedInterceptController = TextEditingController(
      text: '');
  TextEditingController groupGainSlopeController = TextEditingController(
      text: '');
  TextEditingController groupGainInterceptController = TextEditingController(
      text: '');
  TextEditingController fruitEnergyConsumeController = TextEditingController(
      text: "");

  List<TextEditingController> fruitControllerList() {
    return <TextEditingController>[
      fruitNameEnController,
      fruitNameChController,
      attackSlopeController,
      attackInterceptController,
      bloodInterceptController,
      bloodSlopeController,
      groupGainInterceptController,
      groupGainSlopeController,
      intelligenceInterceptController,
      intelligenceSlopeController,
      speedInterceptController,
      speedSlopeController,
      defenseInterceptController,
      defenseSlopeController,
      fruitEnergyConsumeController,
    ];
  }

  FruitType selectedFruitType = FruitType.paramecia;

  double dividerWidth = 800;
  double sideWidth = 50;
  final _formKey = GlobalKey<FormState>();

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Basic Info card
        Card(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.basicInfo,
                        style:
                            OnepieceFonts.headerStyle.copyWith(fontSize: 16)),
                    const SizedBox(height: 10),
                    SizedBox(
                        height: 35,
                        child: TextFormField(
                          controller: fruitNameEnController,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            disabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: OnepieceColors.menuHoverColor)),
                            enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: OnepieceColors.menuHoverColor)),
                            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: OnepieceColors.fancyGreen, width: 1.5)),
                            labelText: AppLocalizations.of(context)!.name,
                            labelStyle: OnepieceFonts.dropDownItemStyle,
                          ),
                        )),
                    const SizedBox(height: 10),
                    _getDropDownList(context),
                  ])),
        ),
        const SizedBox(height: 12),
        // Battle Info card
        Card(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.battleInfo,
                        style:
                            OnepieceFonts.headerStyle.copyWith(fontSize: 16)),
                    const SizedBox(height: 10),
                    _buildDigitField(context, fruitEnergyConsumeController,
                        AppLocalizations.of(context)!.energyConsume, 0, 300),
                    _buildStatPair(
                        context,
                        attackSlopeController,
                        attackInterceptController,
                        AppLocalizations.of(context)!.characterAttack),
                    _buildStatPair(
                        context,
                        defenseSlopeController,
                        defenseInterceptController,
                        AppLocalizations.of(context)!.characterDefense),
                    _buildStatPair(
                        context,
                        bloodSlopeController,
                        bloodInterceptController,
                        AppLocalizations.of(context)!.characterBlood),
                    _buildStatPair(
                        context,
                        intelligenceSlopeController,
                        intelligenceInterceptController,
                        AppLocalizations.of(context)!.characterIntelligence),
                    _buildStatPair(
                        context,
                        speedSlopeController,
                        speedInterceptController,
                        AppLocalizations.of(context)!.characterSpeed),
                    _buildStatPair(
                        context,
                        groupGainSlopeController,
                        groupGainInterceptController,
                        AppLocalizations.of(context)!.groupGain),
                  ])),
        ),
      ]),
    );
  }

  Widget _buildDigitField(BuildContext context, TextEditingController ctrl,
      String hint, int min, int max) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SizedBox(
            height: 35,
            child: TextFormField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  disabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: OnepieceColors.menuHoverColor)),
                  enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: OnepieceColors.menuHoverColor)),
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: OnepieceColors.fancyGreen, width: 1.5)),
                  labelText: hint, labelStyle: OnepieceFonts.dropDownItemStyle),
            )));
  }

  Widget _buildStatPair(BuildContext context, TextEditingController slope,
      TextEditingController intercept, String label) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Text(label, style: OnepieceFonts.deepBlackHintFont, maxLines: 2, overflow: TextOverflow.visible),
          const SizedBox(width: 6),
          const Text('=', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(AppLocalizations.of(context)!.basicValue, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(width: 2),
          const Text('×', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Expanded(child: SizedBox(height: 35, child: TextFormField(
              controller: slope, keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  disabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: OnepieceColors.menuHoverColor)),
                  enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: OnepieceColors.menuHoverColor)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: OnepieceColors.fancyGreen, width: 1.5)),
                  labelStyle: OnepieceFonts.dropDownItemStyle)))),
          const SizedBox(width: 4),
          const Text('+', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Expanded(child: SizedBox(height: 35, child: TextFormField(
              controller: intercept, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: OnepieceColors.menuHoverColor)),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: OnepieceColors.menuHoverColor)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: OnepieceColors.fancyGreen, width: 1.5)))))),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow =
            ResponsiveBreakpoints.isMobileFromConstraints(constraints);
        dividerWidth = isNarrow ? constraints.maxWidth - 30 : 800;
        sideWidth = isNarrow ? 8.0 : 50;
        return Stack(
          children: [
            if (isNarrow)
              _buildMobileLayout(context)
            else
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
                            padding: EdgeInsets.only(left: sideWidth),
                            child: Text(
                              AppLocalizations.of(context)!.basicInfo,
                              style: OnepieceFonts.headerStyle,
                            ),
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                          Padding(
                            padding:
                                EdgeInsets.symmetric(horizontal: sideWidth),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    StringTextFormField(
                                        context,
                                        true,
                                        fruitNameChController,
                                        AppLocalizations.of(context)!.name,
                                        30,
                                        ImageHelper.getTextFormFieldIcon(
                                            'images/character_digits_icon/name.svg',
                                            true,
                                            25),
                                        true),
                                    if (getIt<User>().loginRole ==
                                        UserRole.NIKA)
                                      StringTextFormField(
                                          context,
                                          true,
                                          fruitNameEnController,
                                          AppLocalizations.of(context)!.name,
                                          30,
                                          ImageHelper.getTextFormFieldIcon(
                                              'images/character_digits_icon/name.svg',
                                              true,
                                              25),
                                          true),
                                  ],
                                ),
                                SizedBox(
                                  width: 300,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.fruitType,
                                        style: OnepieceFonts.deepBlackHintFont,
                                      ),
                                      const SizedBox(
                                        height: 18,
                                      ),
                                      _getDropDownList(context),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 30,
                            child: Divider(
                              color: Colors.grey,
                              height: 2,
                            ),
                          ),
                          Padding(
                            padding:
                                EdgeInsets.symmetric(horizontal: sideWidth),
                            child: Text(
                              AppLocalizations.of(context)!.battleInfo,
                              style: OnepieceFonts.headerStyle,
                            ),
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                          Padding(
                            padding:
                                EdgeInsets.symmetric(horizontal: sideWidth),
                            child: Form(
                              key: _formKey,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Column(
                                    children: [
                                      FruitDigitTextFormField(
                                          context,
                                          true,
                                          attackSlopeController,
                                          attackInterceptController,
                                          AppLocalizations.of(context)!
                                              .attackStrengthen,
                                          0.8,
                                          1.5,
                                          -100,
                                          300,
                                          ImageHelper.getTextFormFieldIcon(
                                              'images/character_digits_icon/attack.svg',
                                              true,
                                              25)),
                                      FruitDigitTextFormField(
                                          context,
                                          true,
                                          defenseSlopeController,
                                          defenseInterceptController,
                                          AppLocalizations.of(context)!
                                              .defenseStrengthen,
                                          0.8,
                                          1.5,
                                          -100,
                                          800,
                                          ImageHelper.getTextFormFieldIcon(
                                              'images/character_digits_icon/defense.svg',
                                              true,
                                              25)),
                                      FruitDigitTextFormField(
                                          context,
                                          true,
                                          bloodSlopeController,
                                          bloodInterceptController,
                                          AppLocalizations.of(context)!
                                              .bloodStrengthen,
                                          0.8,
                                          1.5,
                                          -1000,
                                          3000,
                                          ImageHelper.getTextFormFieldIcon(
                                              'images/character_digits_icon/blood.svg',
                                              true,
                                              25)),
                                      DigitTextFormField(
                                          context,
                                          true,
                                          fruitEnergyConsumeController,
                                          AppLocalizations.of(context)!
                                              .energyConsume,
                                          1,
                                          10,
                                          ImageHelper.getTextFormFieldIcon(
                                              'images/character_digits_icon/energy.svg',
                                              true,
                                              25),
                                          true),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      FruitDigitTextFormField(
                                          context,
                                          true,
                                          intelligenceSlopeController,
                                          intelligenceInterceptController,
                                          AppLocalizations.of(context)!
                                              .intelligenceStrengthen,
                                          0.8,
                                          2,
                                          -30,
                                          30,
                                          ImageHelper.getTextFormFieldIcon(
                                              'images/character_digits_icon/intelligence.svg',
                                              true,
                                              25)),
                                      FruitDigitTextFormField(
                                          context,
                                          true,
                                          speedSlopeController,
                                          speedInterceptController,
                                          AppLocalizations.of(context)!
                                              .speedStrengthen,
                                          0.8,
                                          3,
                                          -10,
                                          30,
                                          ImageHelper.getTextFormFieldIcon(
                                              'images/character_digits_icon/speed.svg',
                                              true,
                                              25)),
                                      FruitDigitTextFormField(
                                          context,
                                          true,
                                          groupGainSlopeController,
                                          groupGainInterceptController,
                                          AppLocalizations.of(context)!
                                              .groupStrengthen,
                                          0.8,
                                          2,
                                          -10,
                                          30,
                                          ImageHelper.getTextFormFieldIcon(
                                              'images/character_digits_icon/group_gain.svg',
                                              true,
                                              25)),
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

  Widget _getDropDownList(BuildContext context) {
    Map<FruitType, String> fruitTypeToDisplayValue = {
      FruitType.logia: AppLocalizations.of(context)!.logiaFruit,
      FruitType.zoan: AppLocalizations.of(context)!.zoanFruit,
      FruitType.ancientZoan: AppLocalizations.of(context)!.ancientZoanFruit,
      FruitType.mythicalZoan: AppLocalizations.of(context)!.mythicalZoanFruit,
      FruitType.artificialZoan:
          AppLocalizations.of(context)!.artificialZoanFruit,
      FruitType.paramecia: AppLocalizations.of(context)!.parameciaFruit,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2(
          isExpanded: true,
          value: selectedFruitType,
          hint: Text(
            AppLocalizations.of(context)!.fruitType,
            style: OnepieceFonts.dropDownItemStyle,
          ),
          onChanged: (value) {
            setState(() {
              selectedFruitType = value!;
            });
          },
          selectedItemBuilder: (context) {
            return FruitType.values.map(
              (item) {
                return Container(
                  alignment: AlignmentDirectional.center,
                  child: Text(
                    fruitTypeToDisplayValue[selectedFruitType]!,
                    style: const TextStyle(
                      fontSize: 16,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ).toList();
          },
          buttonStyleData: ButtonStyleData(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 34,
              width: MediaQuery.of(context).size.width < 600 ? double.infinity : 210,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: OnepieceColors.liteFancyGreen,
              )),
          menuItemStyleData: const MenuItemStyleData(
            height: 35,
          ),
          items: FruitType.values.map((FruitType fruitType) {
            return DropdownMenuItem<FruitType>(
              value: fruitType,
              child: Text(
                fruitTypeToDisplayValue[fruitType]!,
                style: const TextStyle(
                  fontSize: 14,
                ),
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
                      fruitControllerList().forEach((element) {
                        element.clear();
                      });
                    });
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    final isValid = _formKey.currentState!.validate();
                    if (!isValid) {
                      return;
                    }
                    CreateFruitRequest addFruitRequest = CreateFruitRequest(
                      name: RandomStringGenerator.generateI18n(
                          fruitNameEnController.text,
                          fruitNameChController.text),
                      fruitType: selectedFruitType,
                      attackSlope: DataConverter.stringToDouble(
                          attackSlopeController.text.trim()),
                      attackIntercept: DataConverter.stringToInt(
                          attackInterceptController.text.trim()),
                      defenseSlope: DataConverter.stringToDouble(
                          defenseSlopeController.text.trim()),
                      defenseIntercept: DataConverter.stringToInt(
                          defenseInterceptController.text.trim()),
                      bloodSlope: DataConverter.stringToDouble(
                          bloodSlopeController.text.trim()),
                      bloodIntercept: DataConverter.stringToInt(
                          bloodInterceptController.text.trim()),
                      groupGainSlope: DataConverter.stringToDouble(
                          groupGainSlopeController.text.trim()),
                      groupGainIntercept: DataConverter.stringToInt(
                          groupGainInterceptController.text.trim()),
                      speedSlope: DataConverter.stringToDouble(
                          speedSlopeController.text.trim()),
                      speedIntercept: DataConverter.stringToInt(
                          speedInterceptController.text.trim()),
                      intelligenceSlope: DataConverter.stringToDouble(
                          intelligenceSlopeController.text.trim()),
                      intelligenceIntercept: DataConverter.stringToInt(
                          intelligenceInterceptController.text.trim()),
                      energyConsume: DataConverter.stringToInt(
                          fruitEnergyConsumeController.text),
                    );

                    final router = GoRouter.of(context);
                    getIt<FruitDao>().add(addFruitRequest).then((value) {
                      if (!mounted) return;
                      router.goNamed('fruitDetails',
                          extra: value!.id,
                          pathParameters: {
                            'name':
                                I18nHelper.getDisplayNameFromI18n(value.name!)
                          });
                    });
                  },
                  child: Text(AppLocalizations.of(context)!.submitForm),
                ),
              ],
            ),
          ),
        ));
  }
}
