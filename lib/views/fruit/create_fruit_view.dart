import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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

GetIt getIt = GetIt.instance;

class CreateFruitView extends StatefulWidget {
  const CreateFruitView({Key? key}) : super(key: key);

  @override
  State<CreateFruitView> createState() => _CreateFruitViewState();
}

class _CreateFruitViewState extends State<CreateFruitView> {
  TextEditingController fruitNameEnController = TextEditingController(
      text: RandomStringGenerator.generateRandomName(
          8, getIt<User>().loginRole == UserRole.NIKA));
  TextEditingController fruitNameChController = TextEditingController(
      text: RandomStringGenerator.generateRandomChineseName(
          3, getIt<User>().loginRole == UserRole.NIKA));
  TextEditingController attackSlopeController = TextEditingController(
      text: RandomStringGenerator.generateRandomDouble(
              1.5, 0.8, 1, getIt<User>().loginRole == UserRole.NIKA)
          .toString());
  TextEditingController attackInterceptController = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(
          -100, 300, getIt<User>().loginRole == UserRole.NIKA));
  TextEditingController defenseSlopeController = TextEditingController(
      text: RandomStringGenerator.generateRandomDouble(
              1.5, 0.8, 1, getIt<User>().loginRole == UserRole.NIKA)
          .toString());
  TextEditingController defenseInterceptController = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(
          -100, 800, getIt<User>().loginRole == UserRole.NIKA));
  TextEditingController intelligenceSlopeController = TextEditingController(
      text: RandomStringGenerator.generateRandomDouble(
              2, 0.8, 1, getIt<User>().loginRole == UserRole.NIKA)
          .toString());
  TextEditingController intelligenceInterceptController = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(
          -30, 30, getIt<User>().loginRole == UserRole.NIKA));
  TextEditingController bloodSlopeController = TextEditingController(
      text: RandomStringGenerator.generateRandomDouble(
              1.5, 0.8, 1, getIt<User>().loginRole == UserRole.NIKA)
          .toString());
  TextEditingController bloodInterceptController = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(
          -1000, 3000, getIt<User>().loginRole == UserRole.NIKA));
  TextEditingController speedSlopeController = TextEditingController(
      text: RandomStringGenerator.generateRandomDouble(
              3, 0.8, 1, getIt<User>().loginRole == UserRole.NIKA)
          .toString());
  TextEditingController speedInterceptController = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(
          -30, 30, getIt<User>().loginRole == UserRole.NIKA));
  TextEditingController groupGainSlopeController = TextEditingController(
      text: RandomStringGenerator.generateRandomDouble(
              2, 0.8, 1, getIt<User>().loginRole == UserRole.NIKA)
          .toString());
  TextEditingController groupGainInterceptController = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(
          -10, 30, getIt<User>().loginRole == UserRole.NIKA));
  TextEditingController fruitEnergyConsumeController = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(
          1, 10, getIt<User>().loginRole == UserRole.NIKA));
  List<TextEditingController> fruitControllerList() {
    return <TextEditingController>[
      fruitNameEnController,
      fruitNameChController,
      attackSlopeController,
      attackSlopeController,
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
                      padding: EdgeInsets.symmetric(horizontal: sideWidth),
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
                              if (getIt<User>().loginRole == UserRole.NIKA)
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                      padding: EdgeInsets.symmetric(horizontal: sideWidth),
                      child: Text(
                        AppLocalizations.of(context)!.battleInfo,
                        style: OnepieceFonts.headerStyle,
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: sideWidth),
                      child: Form(
                        key: _formKey,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                    AppLocalizations.of(context)!.energyConsume,
                                    1,
                                    10,
                                    ImageHelper.getTextFormFieldIcon(
                                        'images/character_digits_icon/energy.svg',
                                        true,
                                        25),true),
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
              width: 210,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: OnepieceColors.menuBackgroundColor,
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

                    getIt<FruitDao>().add(addFruitRequest).then((value) {
                      context.goNamed('fruitDetails',
                          extra: value!.id,
                          pathParameters: {
                            'name': I18nHelper.getDisplayNameFromI18n(value.name!)
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
