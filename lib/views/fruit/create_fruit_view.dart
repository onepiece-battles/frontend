import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/utils/string_extensions.dart';
import 'package:openapi/api.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../repository/fruit_dao.dart';
import '../../utils/data_converter.dart';
import '../../utils/data_validator.dart';
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

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 0, 0, 15),
            child: Text(
              AppLocalizations.of(context)!.basicInfo,
              style: OnepieceFonts.headerStyle,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15.0),
            child: Row(
              children: [
                SizedBox(
                  width: 300,
                  child: TextFormField(
                    controller: fruitNameChController,
                    validator: (value) {
                      if (value!.isWhiteSpace()) {
                        return AppLocalizations.of(context)!.requiredField;
                      }
                      if (!DataValidator.validName(value)) {
                        return AppLocalizations.of(context)!.invalidName;
                      }
                      return null;
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    maxLength: 10,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.fruitName,
                      prefixIcon: const Icon(Icons.people),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 25,
                ),
                if (getIt<User>().loginRole == UserRole.NIKA)
                  SizedBox(
                    width: 300,
                    child: TextFormField(
                      controller: fruitNameEnController,
                      validator: (value) {
                        if (value!.isWhiteSpace()) {
                          return AppLocalizations.of(context)!.requiredField;
                        }
                        if (!DataValidator.validName(value)) {
                          return AppLocalizations.of(context)!.invalidName;
                        }
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      maxLength: 10,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.fruitName,
                        prefixIcon: const Icon(Icons.people),
                      ),
                    ),
                  )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 10, 0, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.fruitType,
                  style: OnepieceFonts.smallHeaderStyle,
                ),
                const SizedBox(width: 10,),
                _getDropDownList(context),
              ],
            ),
          ),
          const Divider(
            color: Colors.grey,
            height: 2,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 10, 0, 0),
            child: Text(
              AppLocalizations.of(context)!.battleInfo,
              style: OnepieceFonts.headerStyle,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  _getFormField(
                      1,
                      5,
                      context,
                      fruitAttackStrengthenController,
                      AppLocalizations.of(context)!.attackStrengthen,
                      _getIcon('images/character_digits_icon/attack.svg')),
                  _getFormField(
                      1,
                      5,
                      context,
                      fruitDefenseStrengthenController,
                      AppLocalizations.of(context)!.defenseStrengthen,
                      _getIcon('images/character_digits_icon/defense.svg')),
                  _getFormField(
                      1,
                      5,
                      context,
                      fruitIntelligenceStrengthenController,
                      AppLocalizations.of(context)!.intelligenceStrengthen,
                      _getIcon(
                          'images/character_digits_icon/intelligence.svg')),
                  _getFormField(
                      1,
                      8,
                      context,
                      fruitSpeedStrengthenController,
                      AppLocalizations.of(context)!.speedStrengthen,
                      _getIcon('images/character_digits_icon/speed.svg')),
                  _getFormField(
                      1,
                      5,
                      context,
                      fruitBloodStrengthenController,
                      AppLocalizations.of(context)!.bloodStrengthen,
                      _getIcon('images/character_digits_icon/blood.svg')),
                  _getFormField(
                      1,
                      5,
                      context,
                      fruitGroupGainStrengthenController,
                      AppLocalizations.of(context)!.groupStrengthen,
                      _getIcon('images/character_digits_icon/group_gain.svg')),
                  _getFormField(
                      1,
                      10,
                      context,
                      fruitEnergyConsumeController,
                      AppLocalizations.of(context)!.energyConsume,
                      _getIcon('images/character_digits_icon/energy.svg')),
                ],
              ),
            ),
          ),
          const Divider(
            height: 2,
            color: Colors.grey,
          ),
          _getFootBar(context)
        ],
      ),
    );
  }

  Widget _getIcon(String path) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child:
          ImageHelper.getSvgIconWithColor(path, 3, 3, OnepieceColors.fancyBlue),
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

  Widget _getFormField(int min, int max, BuildContext context,
      TextEditingController controller, String label, Widget icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
      child: SizedBox(
        width: 300,
        child: TextFormField(
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
            prefixIcon: icon,
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            contentPadding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
            labelText: "$label ($min-$max)",
          ),
        ),
      ),
    );
  }

  Widget _getFootBar(BuildContext context) {
    return Padding(
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
                    fruitNameEnController.text, fruitNameChController.text),
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
    );
  }
}
