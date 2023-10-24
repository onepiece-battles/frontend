import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:get_it/get_it.dart';
import 'package:one_piece_battles_flutter/utils/random_string_generator.dart';
import 'package:one_piece_battles_flutter/utils/string_extensions.dart';
import 'package:openapi/api.dart';
import '../constants/path_constants.dart';
import '../repository/character_dao.dart';
import '../utils/data_converter.dart';

GetIt getIt = GetIt.instance;

class AddCharacterView extends StatefulWidget {
  const AddCharacterView({super.key});

  @override
  State<AddCharacterView> createState() => _AddCharacterViewState();
}

class _AddCharacterViewState extends State<AddCharacterView> {
  TextEditingController characterNameController = TextEditingController(
      text: RandomStringGenerator.generateRandomString(8));
  TextEditingController characterFruitLimitController =
      TextEditingController(text: '1');
  TextEditingController characterGroupGainController =
      TextEditingController(text: '5');
  TextEditingController characterAttackController =
      TextEditingController(text: '500');
  TextEditingController characterDefenseController =
      TextEditingController(text: '500');
  TextEditingController characterIntelligenceController =
      TextEditingController(text: '155');
  TextEditingController characterBloodController =
      TextEditingController(text: '5000');
  TextEditingController characterSpeedController =
      TextEditingController(text: '50');
  TextEditingController characterEnergyController =
      TextEditingController(text: '50');
  List<TextEditingController> characterControllerList() {
    return [
      characterNameController,
      characterFruitLimitController,
      characterGroupGainController,
      characterAttackController,
      characterDefenseController,
      characterDefenseController,
      characterIntelligenceController,
      characterBloodController,
      characterSpeedController,
      characterEnergyController
    ];
  }

  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    List<String> displayCharacterTypes = [
      AppLocalizations.of(context)!.body,
      AppLocalizations.of(context)!.science,
      AppLocalizations.of(context)!.katana,
      AppLocalizations.of(context)!.shoot,
      AppLocalizations.of(context)!.fist,
      AppLocalizations.of(context)!.leg
    ];
    Map<String, CharacterType> displayValueToEnumValue =
        <String, CharacterType>{
      AppLocalizations.of(context)!.body: CharacterType.body,
      AppLocalizations.of(context)!.leg: CharacterType.foot,
      AppLocalizations.of(context)!.science: CharacterType.science,
      AppLocalizations.of(context)!.fist: CharacterType.fist,
      AppLocalizations.of(context)!.katana: CharacterType.katana,
      AppLocalizations.of(context)!.shoot: CharacterType.shooter,
    };
    String selectedItem = displayCharacterTypes.first;
    return AlertDialog(
      title: Center(
        child: Text(
          AppLocalizations.of(context)!.createCharacter,
          style: const TextStyle(
              color: Colors.blue, fontSize: 28, fontStyle: FontStyle.normal),
        ),
      ),
      content: Container(
        width: 800,
        height: 800,
        padding: const EdgeInsets.all(50),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      debugPrint('icon pressed');
                    },
                    iconSize: 100,
                    splashRadius: 10,
                    splashColor: Colors.red,
                    icon: Image.asset(PathConstants.loginLuffyImage),
                  ),
                ],
              ),
              const SizedBox(
                height: 60,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 300,
                    child: TextFormField(
                      controller: characterNameController,
                      validator: (value) {
                        if (value!.isWhiteSpace()) {
                          return AppLocalizations.of(context)!.requiredField;
                        }
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      maxLength: 10,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      decoration: InputDecoration(
                          labelText:
                              AppLocalizations.of(context)!.characterName,
                          prefixIcon: const Icon(Icons.people),
                          suffixIcon: IconButton(
                            onPressed: () {
                              characterNameController.text = '';
                            },
                            icon: const Icon(Icons.cancel),
                            splashRadius: 0.1,
                          ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 30,
                  ),
                  SizedBox(
                    width: 300,
                    child: DropdownSearch<String>(
                      items: displayCharacterTypes,
                      selectedItem: selectedItem,
                      onChanged: (value) {
                        selectedItem = value!;
                      },
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!
                                .characterTypeLable,
                            hintText: AppLocalizations.of(context)!
                                .characterTypeHint),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 30,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 300,
                    child: TextFormField(
                      controller: characterFruitLimitController,
                      validator: (value) {
                        if (value!.isWhiteSpace()) {
                          return AppLocalizations.of(context)!.requiredField;
                        } else if (!value.isValidInt()) {
                          return AppLocalizations.of(context)!.fieldMustBeInt;
                        }
                        int valueInt = int.parse(value);
                        if (valueInt < 1 || valueInt > 3) {
                          return AppLocalizations.of(context)!
                              .valueExceedsLimit;
                        }
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.fruitLimit,
                          hintStyle: const TextStyle(color: Colors.grey),
                          hintText:
                              "${AppLocalizations.of(context)!.valueRange}[1-2]"),
                    ),
                  ),
                  const SizedBox(
                    width: 30,
                  ),
                  SizedBox(
                    width: 300,
                    child: TextFormField(
                      controller: characterGroupGainController,
                      validator: (value) {
                        if (value!.isWhiteSpace()) {
                          return AppLocalizations.of(context)!.requiredField;
                        } else if (!value.isValidInt()) {
                          return AppLocalizations.of(context)!.fieldMustBeInt;
                        }
                        int valueInt = int.parse(value);
                        if (valueInt < 1 || valueInt > 10) {
                          return AppLocalizations.of(context)!
                              .valueExceedsLimit;
                        }
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.groupGain,
                          hintStyle: const TextStyle(color: Colors.grey),
                          hintText:
                              "${AppLocalizations.of(context)!.valueRange}[1-10]"),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 30,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 300,
                    child: TextFormField(
                      controller: characterAttackController,
                      validator: (value) {
                        if (value!.isWhiteSpace()) {
                          return AppLocalizations.of(context)!.requiredField;
                        } else if (!value.isValidInt()) {
                          return AppLocalizations.of(context)!.fieldMustBeInt;
                        }
                        int valueInt = int.parse(value);
                        if (valueInt < 10 || valueInt > 1000) {
                          return AppLocalizations.of(context)!
                              .valueExceedsLimit;
                        }
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context)!.characterAttack,
                        hintStyle: const TextStyle(color: Colors.grey),
                        hintText:
                            "${AppLocalizations.of(context)!.valueRange}[10-1000]",
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 30,
                  ),
                  SizedBox(
                    width: 300,
                    child: TextFormField(
                      controller: characterDefenseController,
                      validator: (value) {
                        if (value!.isWhiteSpace()) {
                          return AppLocalizations.of(context)!.requiredField;
                        } else if (!value.isValidInt()) {
                          return AppLocalizations.of(context)!.fieldMustBeInt;
                        }
                        int valueInt = int.parse(value);
                        if (valueInt < 10 || valueInt > 1000) {
                          return AppLocalizations.of(context)!
                              .valueExceedsLimit;
                        }
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: InputDecoration(
                        hintStyle: const TextStyle(color: Colors.grey),
                        hintText:
                            "${AppLocalizations.of(context)!.valueRange}[10-1000]",
                        labelText:
                            AppLocalizations.of(context)!.characterDefense,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 30,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 300,
                    child: TextFormField(
                      controller: characterIntelligenceController,
                      validator: (value) {
                        if (value!.isWhiteSpace()) {
                          return AppLocalizations.of(context)!.requiredField;
                        } else if (!value.isValidInt()) {
                          return AppLocalizations.of(context)!.fieldMustBeInt;
                        }
                        int valueInt = int.parse(value);
                        if (valueInt < 70 || valueInt > 260) {
                          return AppLocalizations.of(context)!
                              .valueExceedsLimit;
                        }
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!
                              .characterIntelligence,
                          hintStyle: const TextStyle(color: Colors.grey),
                          hintText:
                              "${AppLocalizations.of(context)!.valueRange}[70-260]"),
                    ),
                  ),
                  const SizedBox(
                    width: 30,
                  ),
                  SizedBox(
                    width: 300,
                    child: TextFormField(
                      controller: characterBloodController,
                      validator: (value) {
                        if (value!.isWhiteSpace()) {
                          return AppLocalizations.of(context)!.requiredField;
                        } else if (!value.isValidInt()) {
                          return AppLocalizations.of(context)!.fieldMustBeInt;
                        }
                        int valueInt = int.parse(value);
                        if (valueInt < 100 || valueInt > 10000) {
                          return AppLocalizations.of(context)!
                              .valueExceedsLimit;
                        }
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: InputDecoration(
                          labelText:
                              AppLocalizations.of(context)!.characterBlood,
                          hintStyle: const TextStyle(color: Colors.grey),
                          hintText:
                              "${AppLocalizations.of(context)!.valueRange}[100-10000]"),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 30,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 300,
                    child: TextFormField(
                      controller: characterSpeedController,
                      validator: (value) {
                        if (value!.isWhiteSpace()) {
                          return AppLocalizations.of(context)!.requiredField;
                        } else if (!value.isValidInt()) {
                          return AppLocalizations.of(context)!.fieldMustBeInt;
                        }
                        int valueInt = int.parse(value);
                        if (valueInt < 10 || valueInt > 200) {
                          return AppLocalizations.of(context)!
                              .valueExceedsLimit;
                        }
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: InputDecoration(
                          labelText:
                              AppLocalizations.of(context)!.characterSpeed,
                          hintStyle: const TextStyle(color: Colors.grey),
                          hintText:
                              "${AppLocalizations.of(context)!.valueRange}[10-200]"),
                    ),
                  ),
                  const SizedBox(
                    width: 30,
                  ),
                  SizedBox(
                    width: 300,
                    child: TextFormField(
                      controller: characterEnergyController,
                      validator: (value) {
                        if (value!.isWhiteSpace()) {
                          return AppLocalizations.of(context)!.requiredField;
                        } else if (!value.isValidInt()) {
                          return AppLocalizations.of(context)!.fieldMustBeInt;
                        }
                        int valueInt = int.parse(value);
                        if (valueInt < 10 || valueInt > 50) {
                          return AppLocalizations.of(context)!
                              .valueExceedsLimit;
                        }
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: InputDecoration(
                          labelText:
                              AppLocalizations.of(context)!.characterEnergy,
                          hintStyle: const TextStyle(color: Colors.grey),
                          hintText:
                              "${AppLocalizations.of(context)!.valueRange}[10-50]"),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          child: Text(AppLocalizations.of(context)!.cancelPopUp),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        ElevatedButton(
          child: Text(AppLocalizations.of(context)!.clearForm),
          onPressed: () {
            characterControllerList().forEach((element) {
              element.clear();
            });
          },
        ),
        ElevatedButton(
          child: Text(AppLocalizations.of(context)!.submitForm),
          onPressed: () {
            final isValid = _formKey.currentState!.validate();
            if (isValid) {
              debugPrint("start creating request");
              AddCharacterRequest addCharacterRequest = AddCharacterRequest(
                  characterType: displayValueToEnumValue[selectedItem] ??
                      CharacterType.body,
                  name: characterNameController.text,
                  fruitLimit: DataConverter.stringToInt(
                      characterFruitLimitController.text),
                  groupGain: DataConverter.stringToInt(
                      characterGroupGainController.text),
                  attack:
                      DataConverter.stringToInt(characterAttackController.text),
                  defense: DataConverter.stringToInt(
                      characterDefenseController.text),
                  intelligence: DataConverter.stringToInt(
                      characterIntelligenceController.text),
                  blood:
                      DataConverter.stringToInt(characterBloodController.text),
                  speed:
                      DataConverter.stringToInt(characterSpeedController.text),
                  magic: DataConverter.stringToInt(
                      characterEnergyController.text));
              getIt<CharacterDao>().addCharacter(addCharacterRequest);
              Navigator.of(context).pop();
            } else {
              debugPrint("form is not valid");
            }
          },
        ),
      ],
    );
  }
}
