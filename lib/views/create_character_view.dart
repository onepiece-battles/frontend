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
import '../constants/onepiece_colors.dart';
import '../constants/onepiece_fonts.dart';
import '../constants/path_constants.dart';
import '../popup/onepiece_alert.dart';
import '../repository/character_dao.dart';
import '../repository/image_dao.dart';
import '../utils/base64_helper.dart';
import '../utils/data_converter.dart';
import '../utils/onepiece_image_picker.dart';

GetIt getIt = GetIt.instance;

class CreateCharacterView extends StatefulWidget {
  const CreateCharacterView({super.key});

  @override
  State<CreateCharacterView> createState() => _CreateCharacterViewState();
}

class _CreateCharacterViewState extends State<CreateCharacterView> {
  TextEditingController characterNameController =
      TextEditingController(text: RandomStringGenerator.generateRandomName(8));
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
  List<TextEditingController> characterControllerList() {
    return <TextEditingController>[
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

  Uint8List _pickedImage = Uint8List(0);
  bool _newImagePicked = false;
  String _chosenImageName = "";
  CharacterType selectedCharacterType = CharacterType.body;

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
            SizedBox(
              width: 300,
              child: TextFormField(
                controller: characterNameController,
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
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                  child: Text(
                    AppLocalizations.of(context)!.characterTypeLabel,
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
                AppLocalizations.of(context)!.digitalInfo,
                style: OnepieceFonts.headerStyle,
              ),
            ),
            Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
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
                      child: Image.asset(PathConstants.loginLuffyImage),
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

  Widget _getDropDownList(BuildContext context) {
    Map<CharacterType, String> enumToCharacterTypeDisplayName = {
      CharacterType.body: AppLocalizations.of(context)!.body,
      CharacterType.science: AppLocalizations.of(context)!.science,
      CharacterType.katana: AppLocalizations.of(context)!.katana,
      CharacterType.shooter: AppLocalizations.of(context)!.shoot,
      CharacterType.fist: AppLocalizations.of(context)!.fist,
      CharacterType.foot: AppLocalizations.of(context)!.leg
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2(
          isExpanded: true,
          value: selectedCharacterType,
          hint: Text(
            AppLocalizations.of(context)!.characterTypeLabel,
            style: OnepieceFonts.dropDownItemStyle,
          ),
          onChanged: (value) {
            setState(() {
              selectedCharacterType = value!;
            });
          },
          selectedItemBuilder: (context) {
            return CharacterType.values.map(
              (item) {
                return Container(
                  alignment: AlignmentDirectional.center,
                  child: Text(
                    enumToCharacterTypeDisplayName[selectedCharacterType]!,
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
          items: CharacterType.values.map((CharacterType characterType) {
            return DropdownMenuItem<CharacterType>(
              value: characterType,
              child: Text(
                enumToCharacterTypeDisplayName[characterType]!,
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
                characterControllerList().forEach((element) {
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
                    AddCharacterRequest addCharacterRequest =
                        AddCharacterRequest(
                            characterType: selectedCharacterType,
                            name: characterNameController.text,
                            fruitLimit: DataConverter.stringToInt(
                                characterFruitLimitController.text),
                            groupGain: DataConverter.stringToInt(
                                characterGroupGainController.text),
                            attack: DataConverter.stringToInt(
                                characterAttackController.text),
                            defense: DataConverter.stringToInt(
                                characterDefenseController.text),
                            intelligence: DataConverter.stringToInt(
                                characterIntelligenceController.text),
                            blood: DataConverter.stringToInt(
                                characterBloodController.text),
                            speed: DataConverter.stringToInt(
                                characterSpeedController.text),
                            magic: DataConverter.stringToInt(
                                characterEnergyController.text));
                    getIt<CharacterDao>()
                        .addCharacter(addCharacterRequest)
                        .then((value) {
                      var encodedImage = Base64Helper.encode(_pickedImage);
                      UploadImageRequest uploadImageRequest =
                          UploadImageRequest(
                              resourceId: value!.id,
                              image: encodedImage,
                              type: ResourceType.CHARACTER);
                      getIt<ImageDao>().addImage(uploadImageRequest);
                      context.goNamed("characters");
                    });
                  },
            child: Text(AppLocalizations.of(context)!.submitForm),
          ),
        ],
      ),
    );
  }

  bool _allElementsAreFilled() {
    characterControllerList().map((e) {
      if (e.text == '') {
        return false;
      }
    });
    return true;
  }
}
