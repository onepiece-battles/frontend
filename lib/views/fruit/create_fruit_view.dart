import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/utils/string_extensions.dart';
import 'package:openapi/api.dart';
import '../../components/digit_text_form_field.dart';
import '../../components/string_text_form_field.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../repository/fruit_dao.dart';
import '../../utils/data_converter.dart';
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
  TextEditingController fruitAttackStrengthenController = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(
          1, 5, getIt<User>().loginRole == UserRole.NIKA));
  TextEditingController fruitDefenseStrengthenController =
      TextEditingController(
          text: RandomStringGenerator.generateRandomNumber(
              1, 5, getIt<User>().loginRole == UserRole.NIKA));
  TextEditingController fruitIntelligenceStrengthenController =
      TextEditingController(
          text: RandomStringGenerator.generateRandomNumber(
              1, 5, getIt<User>().loginRole == UserRole.NIKA));
  TextEditingController fruitBloodStrengthenController = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(
          1, 5, getIt<User>().loginRole == UserRole.NIKA));
  TextEditingController fruitSpeedStrengthenController = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(
          1, 8, getIt<User>().loginRole == UserRole.NIKA));
  TextEditingController fruitGroupGainStrengthenController =
      TextEditingController(
          text: RandomStringGenerator.generateRandomNumber(
              1, 5, getIt<User>().loginRole == UserRole.NIKA));
  TextEditingController fruitEnergyConsumeController = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(
          1, 10, getIt<User>().loginRole == UserRole.NIKA));
  List<TextEditingController> fruitControllerList() {
    return <TextEditingController>[
      fruitNameEnController,
      fruitNameChController,
      fruitAttackStrengthenController,
      fruitDefenseStrengthenController,
      fruitIntelligenceStrengthenController,
      fruitBloodStrengthenController,
      fruitSpeedStrengthenController,
      fruitGroupGainStrengthenController,
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
                                  10,
                                  ImageHelper.getTextFormFieldIcon(
                                      'images/character_digits_icon/name.svg',
                                      true),
                                  true),
                              if (getIt<User>().loginRole == UserRole.NIKA)
                                StringTextFormField(
                                    context,
                                    true,
                                    fruitNameEnController,
                                    AppLocalizations.of(context)!.name,
                                    10,
                                    ImageHelper.getTextFormFieldIcon(
                                        'images/character_digits_icon/name.svg',
                                        true),
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
                                  style: OnepieceFonts.smallHeaderStyle,
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
                                DigitTextFormField(
                                    context,
                                    true,
                                    fruitAttackStrengthenController,
                                    AppLocalizations.of(context)!
                                        .attackStrengthen,
                                    1,
                                    5,
                                    ImageHelper.getTextFormFieldIcon(
                                        'images/character_digits_icon/attack.svg',
                                        true)),
                                DigitTextFormField(
                                    context,
                                    true,
                                    fruitDefenseStrengthenController,
                                    AppLocalizations.of(context)!
                                        .defenseStrengthen,
                                    1,
                                    5,
                                    ImageHelper.getTextFormFieldIcon(
                                        'images/character_digits_icon/defense.svg',
                                        true)),
                                DigitTextFormField(
                                    context,
                                    true,
                                    fruitBloodStrengthenController,
                                    AppLocalizations.of(context)!
                                        .bloodStrengthen,
                                    1,
                                    5,
                                    ImageHelper.getTextFormFieldIcon(
                                        'images/character_digits_icon/blood.svg',
                                        true)),
                                DigitTextFormField(
                                    context,
                                    true,
                                    fruitEnergyConsumeController,
                                    AppLocalizations.of(context)!.energyConsume,
                                    1,
                                    10,
                                    ImageHelper.getTextFormFieldIcon(
                                        'images/character_digits_icon/energy.svg',
                                        true)),
                              ],
                            ),
                            Column(
                              children: [
                                DigitTextFormField(
                                    context,
                                    true,
                                    fruitIntelligenceStrengthenController,
                                    AppLocalizations.of(context)!
                                        .intelligenceStrengthen,
                                    1,
                                    5,
                                    ImageHelper.getTextFormFieldIcon(
                                        'images/character_digits_icon/intelligence.svg',
                                        true)),
                                DigitTextFormField(
                                    context,
                                    true,
                                    fruitSpeedStrengthenController,
                                    AppLocalizations.of(context)!
                                        .speedStrengthen,
                                    1,
                                    8,
                                    ImageHelper.getTextFormFieldIcon(
                                        'images/character_digits_icon/speed.svg',
                                        true)),
                                DigitTextFormField(
                                    context,
                                    true,
                                    fruitGroupGainStrengthenController,
                                    AppLocalizations.of(context)!
                                        .groupStrengthen,
                                    1,
                                    5,
                                    ImageHelper.getTextFormFieldIcon(
                                        'images/character_digits_icon/group_gain.svg',
                                        true)),
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
                      attackStrengthen: DataConverter.stringToInt(
                          fruitAttackStrengthenController.text.trim()),
                      defenseStrengthen: DataConverter.stringToInt(
                          fruitDefenseStrengthenController.text.trim()),
                      bloodStrengthen: DataConverter.stringToInt(
                          fruitBloodStrengthenController.text.trim()),
                      intelligenceStrengthen: DataConverter.stringToInt(
                          fruitIntelligenceStrengthenController.text.trim()),
                      speedStrengthen: DataConverter.stringToInt(
                          fruitSpeedStrengthenController.text.trim()),
                      energyConsume: DataConverter.stringToInt(
                          fruitEnergyConsumeController.text),
                      groupGainStrengthen: DataConverter.stringToInt(
                          fruitGroupGainStrengthenController.text.trim()),
                    );

                    getIt<FruitDao>().add(addFruitRequest).then((value) {
                      context.goNamed("fruit");
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
