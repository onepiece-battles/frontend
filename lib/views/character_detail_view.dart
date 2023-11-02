import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:openapi/api.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../repository/battle_dao.dart';
import '../repository/image_dao.dart';
import '../utils/base64_helper.dart';
import '../utils/compare_uint8list.dart';
import '../utils/image_helper.dart';
import '../utils/onepiece_image_picker.dart';

GetIt getIt = GetIt.instance;

class CharacterDetail extends StatefulWidget {
  final String characterId;
  const CharacterDetail({super.key, required this.characterId});

  @override
  State<CharacterDetail> createState() => _CharacterDetailState();
}

class _CharacterDetailState extends State<CharacterDetail> {
  CharacterFullView characterFullView = CharacterFullView();
  List<Battle> battles = [];
  late Uint8List _pickedImage;
  late Uint8List _originalImage;
  bool _newImagePicked = false;
  @override
  void initState() {
    super.initState();
    //todo(yichi): consider future builder!
    _loadData();
  }

  Future<void> _loadData() async {
    getIt<CharacterDao>()
        .getCharacter(
            GetCharacterFullViewRequest(characterId: widget.characterId))
        .then((value) {
      characterFullView = value!;
      _originalImage =
          Base64Helper.decode(characterFullView.character!.profileImage!);
      _pickedImage = _originalImage;
      getIt<BattleDao>()
          .batchFindByIds(ListBattleByIdsRequest(
              battleIds: characterFullView.battleIds, userId: getIt<User>().id))
          .then((value) {
        battles = value!.battles;
        setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(3.0),
          child: _getCharacterTopBar(),
        ),
        const Divider(
          height: 10,
          thickness: 1,
        ),
        Row(
          children: [
            _getProfileSection(context),
            _getCharacterDataList(context),
          ],
        )
      ],
    );
  }

  Widget _getProfileSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () async {
            XFile? pickedImage = await OnepieceImagePicker.pickWebImage();
            Uint8List imageInByte = await pickedImage!.readAsBytes();
            _pickedImage = imageInByte;
            setState(() {
              _compareImage();
            });
          },
          iconSize: 300,
          splashRadius: 10,
          icon: Image.memory(_pickedImage),
        ),
        Row(
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
            const SizedBox(
              width: 250,
            ),
            ElevatedButton(
                onPressed: !_newImagePicked
                    ? null
                    : () async {
                        var encodedImage = Base64Helper.encode(_pickedImage);
                        UploadImageRequest uploadImageRequest =
                            UploadImageRequest(
                                resourceId: characterFullView.character!.id,
                                image: encodedImage,
                                type: ResourceType.CHARACTER);
                        var getImageResponse = await getIt<ImageDao>()
                            .addImage(uploadImageRequest);
                        setState(() {
                          _originalImage =
                              Base64Helper.decode(getImageResponse!.image);
                          _compareImage();
                        });
                      },
                child: Text(AppLocalizations.of(context)!.confirm))
          ],
        )
      ],
    );
  }

  Widget _getCharacterTopBar() {
    Map<CharacterType, Widget> characterTypeToIconMap = {
      CharacterType.fist: const Icon(
        Icons.sports_mma,
        color: OnepieceColors.themeColor,
        size: 30,
      ),
      CharacterType.body: const Icon(
        Icons.accessibility,
        color: OnepieceColors.themeColor,
        size: 30,
      ),
      CharacterType.foot: const Icon(
        Icons.airline_seat_legroom_extra,
        color: OnepieceColors.themeColor,
        size: 30,
      ),
      CharacterType.katana: ImageHelper.getSvgIcon(
        'images/svgs/katana.svg',
        30,
        30,
      ),
      CharacterType.science: const Icon(
        Icons.science,
        color: OnepieceColors.themeColor,
        size: 30,
      ),
      CharacterType.shooter: ImageHelper.getSvgIcon(
        'images/svgs/sniper.svg',
        30,
        30,
      ),
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(5)),
                color: OnepieceColors.menuSelectedTileColor,
              ),
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: SizedBox(
                  height: 30,
                  child: Text(
                    characterFullView.character!.name,
                    style: OnepieceFonts.contentStyleBold,
                  ),
                ),
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                  color: OnepieceColors.menuSelectedTileColor,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: characterTypeToIconMap[
                      characterFullView.character!.characterType]!,
                ))
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(5)),
                color: OnepieceColors.menuSelectedTileColor,
              ),
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: ImageHelper.getSvgIconWithColor(
                  'images/svgs/fruit.svg',
                  30,
                  30,
                  characterFullView.character!.hasFruits
                      ? Colors.blue
                      : Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10,),
            Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(5)),
                color: OnepieceColors.menuSelectedTileColor,
              ),
              child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: characterFullView.character!.isSystemResource
                      ? const Icon(
                          Icons.computer,
                          size: 30,
                          color: OnepieceColors.secondaryThemeColor,
                        )
                      : const Icon(
                          Icons.person,
                          size: 30,
                          color: OnepieceColors.secondaryThemeColor,
                        )),
            ),
          ],
        )
      ],
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
        _getDataRow(AppLocalizations.of(context)!.characterAttack,
            characterFullView.character!.attack, 1000, 1000, 0),
        _getDataRow(AppLocalizations.of(context)!.characterDefense,
            characterFullView.character!.defense, 1000, 1000, 0),
        _getDataRow(AppLocalizations.of(context)!.characterBlood,
            characterFullView.character!.blood, 10000, 10000, 0),
        _getDataRow(AppLocalizations.of(context)!.characterSpeed,
            characterFullView.character!.speed, 200, 200, 0),
        _getDataRow(AppLocalizations.of(context)!.groupGain,
            characterFullView.character!.groupGain, 5, 5, 0),
        _getDataRow(AppLocalizations.of(context)!.characterIntelligence,
            characterFullView.character!.intelligence, 260, 260, 0),
      ],
    );
  }

  Padding _getDataRow(String name, int value, int base, int max, int min) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
            child: SizedBox(
                width: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text(name), Text(value.toString())],
                )),
          ),
          Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: 300,
                    height: 25,
                    decoration: const BoxDecoration(
                        color: OnepieceColors.menuBackgroundColor,
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                  ),
                  Container(
                    width: 300 * value / base,
                    height: 25,
                    decoration: const BoxDecoration(
                      color: OnepieceColors.themeColor,
                      borderRadius: BorderRadius.all(
                        Radius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(min.toString()),
                  const SizedBox(
                    width: 250,
                  ),
                  Text(max.toString()),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}
