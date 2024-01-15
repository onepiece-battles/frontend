import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:one_piece_battles_flutter/utils/data_validator.dart';
import 'package:one_piece_battles_flutter/utils/random_string_generator.dart';
import 'package:one_piece_battles_flutter/utils/string_extensions.dart';
import 'package:openapi/api.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../constants/path_constants.dart';
import '../../popup/onepiece_alert.dart';
import '../../repository/character_dao.dart';
import '../../repository/image_dao.dart';
import '../../utils/base64_helper.dart';
import '../../utils/data_converter.dart';
import '../../utils/onepiece_image_picker.dart';

GetIt getIt = GetIt.instance;

class CreateCharacterView extends StatefulWidget {
  const CreateCharacterView({super.key});

  @override
  State<CreateCharacterView> createState() => _CreateCharacterViewState();
}

class _CreateCharacterViewState extends State<CreateCharacterView> {
  TextEditingController characterNameEnController =
      TextEditingController(text: RandomStringGenerator.generateRandomName(8));
  TextEditingController characterNameCnController =
      TextEditingController(text: RandomStringGenerator.generateRandomChineseName(3));

  // battle data controller
  TextEditingController characterFruitLimitController = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(1, 2));
  TextEditingController characterGroupGainController = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(1, 5));
  TextEditingController characterAttackController = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(10, 1000));
  TextEditingController characterDefenseController = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(10, 1000));
  TextEditingController characterIntelligenceController = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(70, 260));
  TextEditingController characterBloodController = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(100, 10000));
  TextEditingController characterSpeedController = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(10, 200));
  TextEditingController characterEnergyController = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(10, 50));

  // character details controller
  TextEditingController characterAge = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(0, 100000));
  TextEditingController characterHeight = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(1, 100000));
  TextEditingController characterBirthPlace = TextEditingController(
      text: RandomStringGenerator.generateRandomString(10));
  TextEditingController characterDateOfBirth =
      TextEditingController(text: RandomStringGenerator.generateDateString());
  TextEditingController characterBounty = TextEditingController(
      text: RandomStringGenerator.generateRandomNumber(10, 100000));

  List<TextEditingController> characterControllerListRequired() {
    return <TextEditingController>[
      characterNameEnController,
      characterNameCnController,
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

  List<TextEditingController> characterControllerListAll() {
    return <TextEditingController>[
      characterNameEnController,
      characterNameCnController,
      characterFruitLimitController,
      characterGroupGainController,
      characterAttackController,
      characterDefenseController,
      characterDefenseController,
      characterIntelligenceController,
      characterBloodController,
      characterSpeedController,
      characterEnergyController,
      characterAge,
      characterHeight,
      characterDateOfBirth,
      characterBirthPlace,
      characterBounty
    ];
  }

  Uint8List _pickedImage = Uint8List(0);
  bool _newImagePicked = false;
  String _chosenImageName = "";
  List<CharacterType> selectedCharacterTypes = [];
  List<Haki> selectedHakis = [];

  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
            _getAvatar(context),
            Row(
              children: [
                SizedBox(
                  width: 280,
                  child: TextFormField(
                    controller: characterNameCnController,
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
                      labelText: AppLocalizations.of(context)!.characterName,
                      prefixIcon: const Icon(Icons.people),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 25,
                ),
                if(getIt<User>().loginRole==UserRole.NIKA) SizedBox(
                  width: 280,
                  child: TextFormField(
                    controller: characterNameEnController,
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
                      labelText: AppLocalizations.of(context)!.characterName,
                      prefixIcon: const Icon(Icons.people),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                _getTypeList(context),
                const SizedBox(
                  width: 30,
                ),
                _getHakiList(context),
              ],
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 8),
              child: Divider(
                height: 2,
              ),
            ),
            Form(
              key: _formKey,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 15),
                        child: Row(
                          children: [
                            Text(
                              AppLocalizations.of(context)!.battleInfo,
                              style: OnepieceFonts.headerStyle,
                            ),
                            Text(
                              "  ( ${AppLocalizations.of(context)!.required} )",
                              style: OnepieceFonts.hintFont,
                            )
                          ],
                        ),
                      ),
                      _getFormField(
                          1,
                          2,
                          context,
                          characterFruitLimitController,
                          AppLocalizations.of(context)!.fruitLimit,
                          const Icon(Icons.ac_unit)),
                      _getFormField(
                          1,
                          5,
                          context,
                          characterGroupGainController,
                          AppLocalizations.of(context)!.groupGain,
                          const Icon(Icons.face)),
                      _getFormField(
                          10,
                          1000,
                          context,
                          characterAttackController,
                          AppLocalizations.of(context)!.characterAttack,
                          const Icon(Icons.face)),
                      _getFormField(
                          10,
                          1000,
                          context,
                          characterDefenseController,
                          AppLocalizations.of(context)!.characterDefense,
                          const Icon(Icons.face)),
                      _getFormField(
                          70,
                          260,
                          context,
                          characterIntelligenceController,
                          AppLocalizations.of(context)!.characterIntelligence,
                          const Icon(Icons.face)),
                      _getFormField(
                          100,
                          10000,
                          context,
                          characterBloodController,
                          AppLocalizations.of(context)!.characterBlood,
                          const Icon(Icons.face)),
                      _getFormField(
                          10,
                          200,
                          context,
                          characterSpeedController,
                          AppLocalizations.of(context)!.characterSpeed,
                          const Icon(Icons.face)),
                      _getFormField(
                          10,
                          50,
                          context,
                          characterEnergyController,
                          AppLocalizations.of(context)!.characterEnergy,
                          const Icon(Icons.face)),
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
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 15),
                        child: Row(
                          children: [
                            Text(
                              AppLocalizations.of(context)!.characterDetail,
                              style: OnepieceFonts.headerStyle,
                            ),
                            Text(
                              "  ( ${AppLocalizations.of(context)!.optional} )",
                              style: OnepieceFonts.hintFont,
                            )
                          ],
                        ),
                      ),
                      _getFormField(
                          0,
                          100000,
                          context,
                          characterAge,
                          AppLocalizations.of(context)!.age,
                          const Icon(Icons.ac_unit)),
                      _getFormField(
                          1,
                          100000,
                          context,
                          characterHeight,
                          AppLocalizations.of(context)!.height,
                          const Icon(Icons.face)),
                      _getStringFormField(
                          20,
                          context,
                          characterBirthPlace,
                          AppLocalizations.of(context)!.birthPlace,
                          const Icon(Icons.face)),
                      _getStringFormField(
                          20,
                          context,
                          characterDateOfBirth,
                          AppLocalizations.of(context)!.birthDay,
                          const Icon(Icons.face)),
                      _getFormField(
                          10,
                          100000000000,
                          context,
                          characterBounty,
                          AppLocalizations.of(context)!.bounty,
                          const Icon(Icons.face)),
                    ],
                  ),
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
                      onPressed: () async {
                        XFile? pickedImage =
                            await OnepieceImagePicker.pickWebImage();
                        Uint8List imageInByte =
                            await pickedImage!.readAsBytes();
                        _pickedImage = imageInByte;
                        setState(() {
                          _chosenImageName = pickedImage.name;
                          _newImagePicked = true;
                        });
                      },
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

  Widget _getTypeList(BuildContext context) {
    Map<CharacterType, String> enumValueToDisplayValue = {
      CharacterType.BODY: AppLocalizations.of(context)!.body,
      CharacterType.FOOT: AppLocalizations.of(context)!.leg,
      CharacterType.SCIENCE: AppLocalizations.of(context)!.science,
      CharacterType.FIST: AppLocalizations.of(context)!.fist,
      CharacterType.KATANA: AppLocalizations.of(context)!.katana,
      CharacterType.SHOOTER: AppLocalizations.of(context)!.shoot
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2(
          isExpanded: true,
          value: selectedCharacterTypes.isEmpty
              ? null
              : selectedCharacterTypes.last,
          hint: Text(
            AppLocalizations.of(context)!.characterTypeLabel,
            style: OnepieceFonts.dropDownItemStyle,
          ),
          onChanged: (value) {},
          selectedItemBuilder: (context) {
            return CharacterType.values.map(
              (item) {
                return Container(
                  alignment: AlignmentDirectional.center,
                  child: Text(
                    selectedCharacterTypes
                        .map((selectedType) {
                          return enumValueToDisplayValue[selectedType];
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
          items: CharacterType.values.map((CharacterType characterType) {
            return DropdownMenuItem<CharacterType>(
              value: characterType,
              enabled: false,
              child: StatefulBuilder(
                builder: (context, menuSetState) {
                  final isSelected =
                      selectedCharacterTypes.contains(characterType);
                  return InkWell(
                    onTap: () {
                      isSelected
                          ? selectedCharacterTypes.remove(characterType)
                          : selectedCharacterTypes.add(characterType);
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
                              enumValueToDisplayValue[characterType]!,
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

  Widget _getStringFormField(int length, BuildContext context,
      TextEditingController controller, String label, Icon icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
      child: SizedBox(
        width: 300,
        child: TextFormField(
          controller: controller,
          maxLength: length,
          decoration: InputDecoration(
            prefixIcon: icon,
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            contentPadding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
            labelText: label,
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
                          AppLocalizations.of(context)!.characterImageRequired);
                      return;
                    }
                    var monthDay = characterDateOfBirth.text
                        .split("/")
                        .map((e) => DataConverter.stringToInt(e))
                        .toList();
                    CreateCharacterRequest addCharacterRequest =
                        CreateCharacterRequest(
                      characterTypes: selectedCharacterTypes,
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
                      age: DataConverter.stringToInt(characterAge.text.trim()),
                      birthPlace: characterBirthPlace.text.trim(),
                      dateOfBirth: DateTime(monthDay.first, monthDay.last),
                      bounty: DataConverter.stringToInt(
                          characterBounty.text.trim()),
                    );
                    getIt<CharacterDao>()
                        .addCharacter(addCharacterRequest)
                        .then((value) {
                      var encodedImage = Base64Helper.encode(_pickedImage);
                      UploadImageRequest uploadImageRequest =
                          UploadImageRequest(
                              resourceId: value!.id,
                              image: encodedImage,
                              type: ResourceType.CHARACTER);
                      getIt<ImageDao>()
                          .addImage(uploadImageRequest)
                          .then((value) => context.goNamed("characters"));
                    });
                  },
            child: Text(AppLocalizations.of(context)!.submitForm),
          ),
        ],
      ),
    );
  }

  bool _allElementsAreFilled() {
    characterControllerListRequired().map((e) {
      if (e.text == '') {
        return false;
      }
    });
    return true;
  }
}
