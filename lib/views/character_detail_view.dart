import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:openapi/api.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../repository/image_dao.dart';
import '../utils/base64_helper.dart';
import '../utils/compare_uint8list.dart';
import '../utils/onepiece_image_picker.dart';

GetIt getIt = GetIt.instance;

class CharacterDetail extends StatefulWidget {
  final String characterId;
  const CharacterDetail({super.key, required this.characterId});

  @override
  State<CharacterDetail> createState() => _CharacterDetailState();
}

class _CharacterDetailState extends State<CharacterDetail> {
  late CharacterFullView character;
  List<BattleListView> battles = [];
  List<Fruit> fruits = [];
  List<Group> groups = [];
  Uint8List _pickedImage = Uint8List(0);
  Uint8List _originalImage = Uint8List(0);
  bool _newImagePicked = false;
  SliderData sliderData = SliderData();

  @override
  void initState() {
    super.initState();
  }

  _loadData()  {
    getIt<CharacterDao>().getCharacter(
        GetCharacterFullViewRequest(characterId: widget.characterId)).then((value) => {
          _updateData(value!)
    });
    return null;
  }

  void _updateData(CharacterFullView characterFullView) {
    character = characterFullView;
    character.profileImage = null;
    debugPrint(character.toString());
    battles = characterFullView.battles;
    fruits = characterFullView.fruits;
    // set initial slider value
    sliderData.setAttack(characterFullView.attack.toDouble());
    sliderData.setDefense(characterFullView.defense.toDouble());
    sliderData.setBlood(characterFullView.blood.toDouble());
    sliderData.setGroupGain(characterFullView.groupGain.toDouble());
    sliderData.setIntelligence(characterFullView.intelligence.toDouble());
    sliderData.setSpeed(characterFullView.speed.toDouble());

    // set initial image value
    _originalImage = Base64Helper.decode(characterFullView.profileImage!);
    _pickedImage = _originalImage;
    battles = characterFullView.battles;
    fruits = characterFullView.fruits;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _loadData(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                Row(
                  children: [
                    _getProfileSection(context),
                    _getCharacterDataList(context),
                  ],
                )
              ],
            );
          } else {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.loading,
                style: OnepieceFonts.loadingFont,
              ),
            );
          }
        });
  }

  Widget _getProfileSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                image: DecorationImage(
                    image: Image.memory(_pickedImage).image, fit: BoxFit.fill),
              ),
            ),
            onTap: () async {
              XFile? pickedImage = await OnepieceImagePicker.pickWebImage();
              Uint8List imageInByte = await pickedImage!.readAsBytes();
              _pickedImage = imageInByte;
              setState(() {
                _compareImage();
              });
            },
          ),
          SizedBox(
            width: 200,
            height: 23,
            child: Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                      onPressed: !_newImagePicked
                          ? null
                          : () {
                              setState(() {
                                _pickedImage = _originalImage;
                                _compareImage();
                              });
                            },
                      child: Text(AppLocalizations.of(context)!.clearAll)),
                  ElevatedButton(
                      onPressed: !_newImagePicked
                          ? null
                          : () async {
                              var encodedImage =
                                  Base64Helper.encode(_pickedImage);
                              UploadImageRequest uploadImageRequest =
                                  UploadImageRequest(
                                      resourceId: character.id,
                                      image: encodedImage,
                                      type: ResourceType.CHARACTER);
                              var getImageResponse = await getIt<ImageDao>()
                                  .addImage(uploadImageRequest);
                              setState(() {
                                _originalImage = Base64Helper.decode(
                                    getImageResponse!.image);
                                _compareImage();
                              });
                            },
                      child: Text(AppLocalizations.of(context)!.submitForm))
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  void _compareImage() {
    if (CompareUint8List.equals(_originalImage, _pickedImage)) {
      _newImagePicked = false;
    } else {
      _newImagePicked = true;
    }
  }

  Column _getCharacterDataList(BuildContext context) {
    return Column(
      children: [
        _getDataRow(AppLocalizations.of(context)!.characterAttack, 1000, 10,
            sliderData.attack, character.attack.toDouble(), (value) {
          sliderData.setAttack(value);
        }),
        _getDataRow(AppLocalizations.of(context)!.characterDefense, 1000, 10,
            sliderData.defense, character.defense.toDouble(), (value) {
          sliderData.setDefense(value);
        }),
        _getDataRow(AppLocalizations.of(context)!.characterBlood, 10000, 100,
            sliderData.blood, character.blood.toDouble(), (value) {
          sliderData.setBlood(value);
        }),
        _getDataRow(AppLocalizations.of(context)!.characterSpeed, 200, 10,
            sliderData.speed, character.speed.toDouble(), (value) {
          sliderData.setSpeed(value);
        }),
        _getDataRow(AppLocalizations.of(context)!.groupGain, 5, 1,
            sliderData.groupGain, character.groupGain.toDouble(), (value) {
          sliderData.setGroupGain(value);
        }),
        _getDataRow(
            AppLocalizations.of(context)!.characterIntelligence,
            260,
            70,
            sliderData.intelligence,
            character.intelligence.toDouble(), (value) {
          sliderData.setIntelligence(value);
        }),
      ],
    );
  }

  Row _getDataRow(String name, int max, int min, double currentValue,
      double originalValue, Function(double) onChangeFunction) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(width: 70, child: Text(name)),
              Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
                child: SizedBox(
                    width: 42, child: Text(currentValue.toInt().toString())),
              )
            ],
          ),
        ),
        SizedBox(
          width: 360,
          height: 35,
          child: Expanded(
            child: Slider(
              value: currentValue,
              // allowedInteraction: SliderInteraction.tapAndSlide,
              label: currentValue.round().toString(),
              divisions: max - min,
              min: min.toDouble(),
              max: max.toDouble(),
              secondaryTrackValue: originalValue,
              secondaryActiveColor: OnepieceColors.themeColor,
              onChanged: (value) {
                setState(() {
                  currentValue = value;
                  onChangeFunction(value);
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}

class SliderData {
  late double _currentAttack;
  late double _currentDefense;
  late double _currentBlood;
  late double _currentIntelligence;
  late double _currentSpeed;
  late double _currentGroupGain;

  void setAttack(double attack) {
    _currentAttack = attack;
  }

  void setDefense(double defense) {
    _currentDefense = defense;
  }

  void setBlood(double blood) {
    _currentBlood = blood;
  }

  void setIntelligence(double intelligence) {
    _currentIntelligence = intelligence;
  }

  void setSpeed(double speed) {
    _currentSpeed = speed;
  }

  void setGroupGain(double groupGain) {
    _currentGroupGain = groupGain;
  }

  double get attack => _currentAttack;
  double get defense => _currentDefense;
  double get blood => _currentBlood;
  double get speed => _currentSpeed;
  double get intelligence => _currentIntelligence;
  double get groupGain => _currentGroupGain;
}
