import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/utils/string_extensions.dart';
import 'package:openapi/api.dart';
import '../constants/onepiece_colors.dart';
import '../constants/onepiece_fonts.dart';
import '../repository/fruit_dao.dart';
import '../utils/data_converter.dart';
import '../utils/data_validator.dart';
import '../utils/random_string_generator.dart';

GetIt getIt = GetIt.instance;

class CreateFruitView extends StatefulWidget {
  const CreateFruitView({Key? key}) : super(key: key);

  @override
  State<CreateFruitView> createState() => _CreateFruitViewState();
}

class _CreateFruitViewState extends State<CreateFruitView> {
  TextEditingController fruitNameController =
      TextEditingController(text: RandomStringGenerator.generateRandomName(8));
  TextEditingController fruitAttackStrengthenController = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(1, 5));
  TextEditingController fruitDefenseStrengthenController =
      TextEditingController(
          text: RandomStringGenerator.generateRandomNumber(1, 5));
  TextEditingController fruitIntelligenceStrengthenController =
      TextEditingController(
          text: RandomStringGenerator.generateRandomNumber(1, 5));
  TextEditingController fruitBloodStrengthenController = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(1, 5));
  TextEditingController fruitSpeedStrengthenController = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(1, 8));
  TextEditingController fruitGroupGainStrengthenController =
      TextEditingController(
          text: RandomStringGenerator.generateRandomNumber(1, 5));
  TextEditingController fruitEnergyConsumeController = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(1, 10));
  List<TextEditingController> fruitControllerList() {
    return <TextEditingController>[
      fruitNameController,
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 15),
              child: Text(
                AppLocalizations.of(context)!.basicInfo,
                style: OnepieceFonts.headerStyle,
              ),
            ),
            SizedBox(
              width: 300,
              child: TextFormField(
                controller: fruitNameController,
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
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                  child: Text(
                    AppLocalizations.of(context)!.fruitType,
                    style: OnepieceFonts.tableHeaderStyle,
                  ),
                ),
                _getDropDownList(context),
              ],
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 8),
              child: Divider(
                height: 2,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 15),
              child: Text(
                AppLocalizations.of(context)!.battleInfo,
                style: OnepieceFonts.headerStyle,
              ),
            ),
            Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  _getFormField(
                      1,
                      5,
                      context,
                      fruitAttackStrengthenController,
                      AppLocalizations.of(context)!.attackStrengthen,
                      const Icon(Icons.ac_unit)),
                  _getFormField(
                      1,
                      5,
                      context,
                      fruitDefenseStrengthenController,
                      AppLocalizations.of(context)!.defenseStrengthen,
                      const Icon(Icons.face)),
                  _getFormField(
                      1,
                      5,
                      context,
                      fruitIntelligenceStrengthenController,
                      AppLocalizations.of(context)!.intelligenceStrengthen,
                      const Icon(Icons.face)),
                  _getFormField(
                      1,
                      8,
                      context,
                      fruitSpeedStrengthenController,
                      AppLocalizations.of(context)!.speedStrengthen,
                      const Icon(Icons.face)),
                  _getFormField(
                      1,
                      5,
                      context,
                      fruitBloodStrengthenController,
                      AppLocalizations.of(context)!.bloodStrengthen,
                      const Icon(Icons.face)),
                  _getFormField(
                      1,
                      5,
                      context,
                      fruitGroupGainStrengthenController,
                      AppLocalizations.of(context)!.groupStrengthen,
                      const Icon(Icons.face)),
                  _getFormField(
                      1,
                      10,
                      context,
                      fruitEnergyConsumeController,
                      AppLocalizations.of(context)!.energyConsume,
                      const Icon(Icons.face)),
                ],
              ),
            ),
            const Divider(
              height: 2,
            ),
            _getFootBar(context)
          ],
        ),
      ),
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
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2(
          isExpanded: true,
          value: selectedFruitType,
          hint: Text(
            AppLocalizations.of(context)!.characterTypeLabel,
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
      TextEditingController controller, String label, Icon icon) {
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
                name: fruitNameController.text.trim(),
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
                energyConsume:
                    DataConverter.stringToInt(fruitEnergyConsumeController.text),
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
