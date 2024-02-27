import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_tag.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:one_piece_battles_flutter/repository/group_dao.dart';
import 'package:one_piece_battles_flutter/utils/string_extensions.dart';
import 'package:openapi/api.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../popup/onepiece_alert.dart';
import '../../repository/fruit_dao.dart';
import '../../utils/base64_helper.dart';
import '../../utils/data_converter.dart';
import '../../utils/i18n_helper.dart';
import '../../utils/image_helper.dart';

GetIt getIt = GetIt.instance;

class CharacterDetail extends StatefulWidget {
  final String characterId;
  const CharacterDetail({super.key, required this.characterId});

  @override
  State<CharacterDetail> createState() => _CharacterDetailState();
}

class _CharacterDetailState extends State<CharacterDetail> {
  // character details controller
  TextEditingController characterNameController = TextEditingController();
  TextEditingController characterAge = TextEditingController();
  TextEditingController characterHeight = TextEditingController();
  TextEditingController characterBirthPlace = TextEditingController();
  TextEditingController characterDateOfBirthMonth = TextEditingController();
  TextEditingController characterDateOfBirthDay = TextEditingController();
  TextEditingController characterBounty = TextEditingController();
  // battle data controller
  TextEditingController characterFruitLimitController = TextEditingController();
  TextEditingController characterGroupGainController = TextEditingController();
  TextEditingController characterAttackController = TextEditingController();
  TextEditingController characterDefenseController = TextEditingController();
  TextEditingController characterIntelligenceController =
      TextEditingController();
  TextEditingController characterBloodController = TextEditingController();
  TextEditingController characterSpeedController = TextEditingController();
  TextEditingController characterEnergyController = TextEditingController();

  // fruit search data
  TextEditingController fruitNameController = TextEditingController();
  TextEditingController groupNameController = TextEditingController();
  GroupFilter groupFilter = GroupFilter();
  FruitFilter fruitFilter = FruitFilter();
  List<GroupListView> searchingGroupList = [];
  List<FruitListView> searchingFruitList = [];
  String? selectedFruitId;
  String? selectedGroupId;

  // initial date
  late CharacterFullView character;
  List<BattleListView> battles = [];
  List<FruitListView> fruits = [];
  List<GroupForCharacterView> groups = [];

  CharacterBattleInfo characterBattleInfo = CharacterBattleInfo();
  CharacterBasicInfo characterBasicInfo = CharacterBasicInfo();

  BattleStyle selectedBattleStyle = BattleStyle.BODY;
  Race selectedRace = Race.HUMAN;

  final _basicFormKey = GlobalKey<FormState>();
  final _digitFormKey = GlobalKey<FormState>();

  bool basicInfoEditable = false;
  bool combatInfoEditable = false;
  bool fruitSearchEnabled = false;
  bool groupSearchEnabled = true;

  @override
  void initState() {
    super.initState();
  }

  _loadData() {
    return getIt<CharacterDao>().getCharacter(
        GetCharacterFullViewRequest(characterId: widget.characterId));
  }

  _eatFruit() {
    EatFruitRequest request =
        EatFruitRequest(characterId: character.id, fruitId: selectedFruitId!);
    Future<EatFruitResponse?> response =
        getIt<CharacterDao>().eatFruit(request);
    response.then(
      (value) => {
        setState(
          () {},
        )
      },
    );
  }

  _joinGroup() {
    JoinGroupRequest request =
        JoinGroupRequest(characterId: character.id, groupId: selectedGroupId!);
    Future<JoinGroupResponse?> response =
        getIt<CharacterDao>().joinGroup(request);
    response.then(
      (value) => {
        setState(
          () {},
        )
      },
    );
  }

  void _updateData(CharacterFullView characterFullView) {
    character = characterFullView;
    battles = characterFullView.battles;
    fruits = characterFullView.fruits;
    groups = characterFullView.groups;
    if (fruits.length < character.maximumFruitCount) {
      fruitSearchEnabled = true;
    }
    // set battle info
    characterBattleInfo.setAttack(characterFullView.attack);
    characterBattleInfo.setDefense(characterFullView.defense);
    characterBattleInfo.setBlood(characterFullView.blood);
    characterBattleInfo.setGroupGain(characterFullView.groupGain);
    characterBattleInfo.setIntelligence(characterFullView.intelligence);
    characterBattleInfo.setSpeed(characterFullView.speed);
    // set basic info
    characterBasicInfo.setAge(characterFullView.age);
    characterBasicInfo.setBirthPlace(characterFullView.birthPlace);
    characterBasicInfo.setBounty(characterFullView.bounty);
    characterBasicInfo.setHeight(characterFullView.height);
    characterBasicInfo
        .setName(I18nHelper.getDisplayNameFromI18n(characterFullView.name));
    characterBasicInfo.setProfileImage(characterFullView.profileImage);
  }

  void _updateControllerData() {
    // update basic information
    characterNameController.text =
        I18nHelper.getDisplayNameFromI18n(character.name);
    characterAge.text = character.age == null ? "" : character.age.toString();
    characterHeight.text =
        character.height == null ? "" : character.height.toString();
    characterBirthPlace.text =
        character.birthPlace == null ? "" : character.birthPlace.toString();
    characterDateOfBirthMonth.text = character.dateOfBirth == null
        ? ""
        : character.dateOfBirth!.month.toString();
    characterDateOfBirthDay.text = character.dateOfBirth == null
        ? ""
        : character.dateOfBirth!.day.toString();
    characterBounty.text =
        character.bounty == null ? "" : character.bounty.toString();
    // update combat information
    characterFruitLimitController.text = character.maximumFruitCount.toString();
    characterGroupGainController.text = character.groupGain.toString();
    characterAttackController.text = character.attack.toString();
    characterDefenseController.text = character.defense.toString();
    characterIntelligenceController.text = character.intelligence.toString();
    characterBloodController.text = character.blood.toString();
    characterSpeedController.text = character.speed.toString();
    characterEnergyController.text = character.energy.toString();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _loadData(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            _updateData(snapshot.data);
            _updateControllerData();
            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _getBasicInfo(context),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Divider(
                        color: OnepieceColors.fancyBlue,
                        thickness: 1,
                      ),
                    ),
                    _getCombatInfo(context),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Divider(
                        color: OnepieceColors.fancyBlue,
                        thickness: 1,
                      ),
                    ),
                    _getFruitSearchBar(context),
                    if (fruits.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(AppLocalizations.of(context)!.eaten,
                            style: OnepieceFonts.fancyBlueHintFont),
                      ),
                    if (fruits.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: _getFruitList(context),
                      ),
                    if(fruits.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(AppLocalizations.of(context)!.none,
                            style: OnepieceFonts.fancyBlueHintFont),
                      ),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Divider(
                        color: OnepieceColors.fancyBlue,
                        thickness: 1,
                      ),
                    ),
                    _getGroupSearchBar(context),
                    if (groups.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(AppLocalizations.of(context)!.joinedGroups,
                            style: OnepieceFonts.fancyBlueHintFont),
                      ),
                    if (groups.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: _getGroupList(context),
                    ),
                    if(groups.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(AppLocalizations.of(context)!.none,
                            style: OnepieceFonts.fancyBlueHintFont),
                      ),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Divider(
                        color: OnepieceColors.fancyBlue,
                        thickness: 1,
                      ),
                    ),
                    _getBattle(context),
                  ],
                ),
              ),
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

  Widget _getBasicInfo(BuildContext context) {
    return StatefulBuilder(builder: (context, basicState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.basicInfo,
                  style: OnepieceFonts.headerStyle,
                ),
                const SizedBox(
                  width: 15,
                ),
                Tooltip(
                  message: basicInfoEditable
                      ? AppLocalizations.of(context)!.submitForm
                      : AppLocalizations.of(context)!.editHint,
                  child: InkWell(
                    hoverColor: Colors.white,
                    onTap: () {
                      basicState(() {
                        basicInfoEditable = !basicInfoEditable;
                        if (!basicInfoEditable) {
                          var updatedCharacter = Character(
                            id: character.id,
                            maximumFruitCount: character.maximumFruitCount,
                            groupGain: character.groupGain,
                            attack: character.attack,
                            defense: character.defense,
                            intelligence: character.intelligence,
                            blood: character.blood,
                            speed: character.speed,
                            energy: character.energy,
                            battleStyle: selectedBattleStyle,
                            race: selectedRace,
                            // basic info
                            name: I18nHelper.getI18nFromDisplayName(
                                character.name, characterNameController.text),
                            dateOfBirth: DateTime(
                                1900,
                                DataConverter.stringToInt(
                                    characterDateOfBirthMonth.text),
                                DataConverter.stringToInt(
                                    characterDateOfBirthDay.text)),
                            // todo(yichi): profile image update
                            birthPlace: characterBirthPlace.text,
                            age: DataConverter.stringToInt(
                                characterAge.text.trim()),
                            bounty: DataConverter.stringToInt(
                                characterBounty.text.trim()),
                            height: DataConverter.stringToInt(
                                characterHeight.text.trim()),
                          );
                          getIt<CharacterDao>()
                              .update(updatedCharacter)
                              .then((value) {
                            OnepieceAlert.getBasicAlertDialogFunc(
                                context,
                                AppLocalizations.of(context)!.hint,
                                I18nHelper.getDisplayNameFromI18n(
                                    value!.result));
                            if (value.success) {
                              context.goNamed('characterDetails',
                                  extra: character.id,
                                  pathParameters: {
                                    'name': I18nHelper.getDisplayNameFromI18n(
                                        character.name)
                                  });
                            }
                          });
                        }
                      });
                    },
                    child: SizedBox(
                        width: 25,
                        height: 25,
                        child: !basicInfoEditable
                            ? ImageHelper.getSvgIconWithColor(
                                'images/svgs/edit.svg',
                                150,
                                150,
                                OnepieceColors.fancyBlue)
                            : ImageHelper.getSvgIconWithColor(
                                'images/svgs/check.svg',
                                150,
                                150,
                                OnepieceColors.fancyBlue)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                border: Border.all(
                    color: OnepieceColors.fancyBlue,
                    width: 5,
                    style: BorderStyle.solid),
              ),
              child: FittedBox(
                fit: BoxFit.fill,
                child: character.profileImage == null
                    ? Container()
                    : Image.memory(
                        Base64Helper.decode(character.profileImage!)),
              ),
            ),
          ),
          Form(
            key: _basicFormKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _getStringFormField(
                          context,
                          basicInfoEditable,
                          characterNameController,
                          AppLocalizations.of(context)!.name,
                          20,
                          _getIcon('images/character_digits_icon/name.svg')),
                      const SizedBox(
                        width: 15,
                      ),
                      _getDigitFormField(
                          context,
                          basicInfoEditable,
                          characterBounty,
                          AppLocalizations.of(context)!.bounty,
                          10,
                          100000000000,
                          _getIcon('images/character_digits_icon/bounty.svg')),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _getStringFormField(
                          context,
                          basicInfoEditable,
                          characterBirthPlace,
                          AppLocalizations.of(context)!.birthPlace,
                          20,
                          _getIcon(
                              'images/character_digits_icon/birth_place.svg')),
                      const SizedBox(
                        width: 15,
                      ),
                      _getDigitFormField(
                          context,
                          basicInfoEditable,
                          characterAge,
                          AppLocalizations.of(context)!.age,
                          0,
                          100000,
                          _getIcon('images/character_digits_icon/age.svg')),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 300,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  AppLocalizations.of(context)!.birthDay,
                                  style: OnepieceFonts.deepBlackHintFont,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 240,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    ImageHelper.getSvgIconWithColor(
                                        "images/character_digits_icon/birthday.svg",
                                        25,
                                        25,
                                        OnepieceColors.fancyBlue),
                                    SizedBox(
                                      width: 60,
                                      child: TextFormField(
                                        controller: characterDateOfBirthMonth,
                                        enabled: basicInfoEditable,
                                        validator: (value) {
                                          if (value!.isWhiteSpace()) {
                                            return AppLocalizations.of(context)!
                                                .requiredField;
                                          } else if (!value.isValidInt()) {
                                            return AppLocalizations.of(context)!
                                                .fieldMustBeInt;
                                          }
                                          int valueInt = int.parse(value);
                                          if (valueInt < 1 || valueInt > 12) {
                                            return AppLocalizations.of(context)!
                                                .valueExceedsLimit;
                                          }
                                          return null;
                                        },
                                        decoration: const InputDecoration(
                                          floatingLabelBehavior:
                                              FloatingLabelBehavior.never,
                                          contentPadding:
                                              EdgeInsets.fromLTRB(5, 15, 0, 0),
                                          hintText: "1-12",
                                        ),
                                      ),
                                    ),
                                    Text(AppLocalizations.of(context)!.month),
                                    SizedBox(
                                      width: 60,
                                      child: TextFormField(
                                        controller: characterDateOfBirthDay,
                                        enabled: basicInfoEditable,
                                        validator: (value) {
                                          if (value!.isWhiteSpace()) {
                                            return AppLocalizations.of(context)!
                                                .requiredField;
                                          } else if (!value.isValidInt()) {
                                            return AppLocalizations.of(context)!
                                                .fieldMustBeInt;
                                          }
                                          int valueInt = int.parse(value);
                                          if (valueInt < 1 || valueInt > 31) {
                                            return AppLocalizations.of(context)!
                                                .valueExceedsLimit;
                                          }
                                          return null;
                                        },
                                        decoration: const InputDecoration(
                                          floatingLabelBehavior:
                                              FloatingLabelBehavior.never,
                                          contentPadding:
                                              EdgeInsets.fromLTRB(5, 15, 0, 0),
                                          hintText: "1-31",
                                        ),
                                      ),
                                    ),
                                    Text(AppLocalizations.of(context)!.day),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        width: 15,
                      ),
                      _getDigitFormField(
                          context,
                          basicInfoEditable,
                          characterHeight,
                          AppLocalizations.of(context)!.height,
                          1,
                          100000,
                          _getIcon('images/character_digits_icon/height.svg')),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      );
    });
  }

  Widget _getIcon(String path) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child:
          ImageHelper.getSvgIconWithColor(path, 3, 3, OnepieceColors.fancyBlue),
    );
  }

// show character combat information (editable if permitted)
  Widget _getCombatInfo(BuildContext context) {
    Map<Haki, String> hakiEnumValueToDisplayValue = {
      Haki.busoshoku: AppLocalizations.of(context)!.busoshoku,
      Haki.haoshoku: AppLocalizations.of(context)!.haoshoku,
      Haki.kenbunshoku: AppLocalizations.of(context)!.kenbunshoku,
    };
    return StatefulBuilder(builder: (context, combatState) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.battleInfo,
                  style: OnepieceFonts.headerStyle,
                ),
                const SizedBox(
                  width: 15,
                ),
                Tooltip(
                  message: combatInfoEditable
                      ? AppLocalizations.of(context)!.submitForm
                      : AppLocalizations.of(context)!.editHint,
                  child: InkWell(
                    hoverColor: Colors.white,
                    onTap: () {
                      combatState(() {
                        combatInfoEditable = !combatInfoEditable;
                        if (!combatInfoEditable) {
                          var updatedCharacter = Character(
                            // basic info keep consistent with original value
                            id: character.id,
                            battleStyle: character.battleStyle,
                            race: character.race,
                            // digit info
                            maximumFruitCount: DataConverter.stringToInt(
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
                            energy: DataConverter.stringToInt(
                                characterEnergyController.text),
                            // basic info
                            name: character.name,
                          );
                          getIt<CharacterDao>()
                              .update(updatedCharacter)
                              .then((value) {
                            OnepieceAlert.getBasicAlertDialogFunc(
                                context,
                                AppLocalizations.of(context)!.hint,
                                I18nHelper.getDisplayNameFromI18n(
                                    value!.result));
                            if (value.success) {
                              context.goNamed('characterDetails',
                                  extra: character.id,
                                  pathParameters: {
                                    'name': I18nHelper.getDisplayNameFromI18n(
                                        character.name)
                                  });
                            }
                          });
                        }
                      });
                    },
                    child: SizedBox(
                        width: 25,
                        height: 25,
                        child: !basicInfoEditable
                            ? ImageHelper.getSvgIconWithColor(
                                'images/svgs/edit.svg',
                                150,
                                150,
                                OnepieceColors.fancyBlue)
                            : ImageHelper.getSvgIconWithColor(
                                'images/svgs/check.svg',
                                150,
                                150,
                                OnepieceColors.fancyBlue)),
                  ),
                ),
              ],
            ),
          ),
          if (character.hakis.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
              child: Row(
                children: character.hakis
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: OnepieceTag.getHakiTag(
                              e, hakiEnumValueToDisplayValue[e]!),
                        ))
                    .toList(),
              ),
            ),
          Form(
            key: _digitFormKey,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      _getDigitFormField(
                          context,
                          combatInfoEditable,
                          characterAttackController,
                          AppLocalizations.of(context)!.characterAttack,
                          10,
                          1000,
                          _getIcon('images/character_digits_icon/attack.svg')),
                      _getDigitFormField(
                          context,
                          combatInfoEditable,
                          characterDefenseController,
                          AppLocalizations.of(context)!.characterDefense,
                          10,
                          1000,
                          _getIcon('images/character_digits_icon/defense.svg')),
                      _getDigitFormField(
                          context,
                          combatInfoEditable,
                          characterBloodController,
                          AppLocalizations.of(context)!.characterBlood,
                          100,
                          10000,
                          _getIcon('images/character_digits_icon/blood.svg')),
                      _getDigitFormField(
                          context,
                          combatInfoEditable,
                          characterSpeedController,
                          AppLocalizations.of(context)!.characterSpeed,
                          10,
                          200,
                          _getIcon('images/character_digits_icon/speed.svg')),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      _getDigitFormField(
                          context,
                          combatInfoEditable,
                          characterIntelligenceController,
                          AppLocalizations.of(context)!.characterIntelligence,
                          70,
                          260,
                          _getIcon(
                              'images/character_digits_icon/intelligence.svg')),
                      _getDigitFormField(
                          context,
                          combatInfoEditable,
                          characterEnergyController,
                          AppLocalizations.of(context)!.characterEnergy,
                          10,
                          50,
                          _getIcon('images/character_digits_icon/energy.svg')),
                      _getDigitFormField(
                          context,
                          combatInfoEditable,
                          characterGroupGainController,
                          AppLocalizations.of(context)!.groupGain,
                          1,
                          5,
                          _getIcon(
                              'images/character_digits_icon/group_gain.svg')),
                      _getDigitFormField(
                          context,
                          combatInfoEditable,
                          characterFruitLimitController,
                          AppLocalizations.of(context)!.fruitLimit,
                          1,
                          2,
                          _getIcon(
                              'images/character_digits_icon/fruit_limit.svg')),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      );
    });
  }

  Widget _getFruitSearchBar(BuildContext context) {
    Map<FruitType, String> fruitTypeToDisplayValue = {
      FruitType.logia: AppLocalizations.of(context)!.logiaFruit,
      FruitType.zoan: AppLocalizations.of(context)!.zoanFruit,
      FruitType.ancientZoan: AppLocalizations.of(context)!.ancientZoanFruit,
      FruitType.mythicalZoan: AppLocalizations.of(context)!.mythicalZoanFruit,
      FruitType.artificialZoan:
          AppLocalizations.of(context)!.artificialZoanFruit,
      FruitType.paramecia: AppLocalizations.of(context)!.parameciaFruit,
    };
    return StatefulBuilder(builder: (context, fruitSetState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 160,
                  child: Text(
                    AppLocalizations.of(context)!.devilFruit,
                    style: OnepieceFonts.headerStyle,
                  ),
                ),
                if (character.maximumFruitCount > fruits.length)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: SizedBox(
                      width: 300,
                      height: 40,
                      child: TextFormField(
                        enabled: fruitSearchEnabled,
                        controller: fruitNameController,
                        decoration: InputDecoration(
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                          label: Text(
                            AppLocalizations.of(context)!.fruitName,
                            style: OnepieceFonts.hintFont,
                          ),
                          disabledBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: OnepieceColors.fancyGreen)),
                          enabledBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: OnepieceColors.fancyGreen)),
                          focusedBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: OnepieceColors.fancyGreen)),
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          selectedFruitId = null;
                          fruitSetState(() {});
                          if (value.isEmpty) {
                            searchingFruitList = [];
                            fruitSetState(() {});
                            return;
                          }
                          fruitFilter.name = value;
                          fruitFilter.languageCode =
                              I18nHelper.getLanguageCode();
                          ListFruitRequest request = ListFruitRequest(
                              pageSize: 5,
                              pageIndex: 1,
                              sortKeys: [],
                              fruitFilter: fruitFilter);
                          Future<ListFruitResponse?> response =
                              getIt<FruitDao>().list(request);
                          response.then(
                            (value) => {
                              searchingFruitList = value!.fruits,
                              fruitSetState(() {})
                            },
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (searchingGroupList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Text(
                AppLocalizations.of(context)!.searchList,
                style: OnepieceFonts.fancyBlueHintFont,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    width: 300,
                    decoration: const BoxDecoration(
                      color: OnepieceColors.menuBackgroundColor,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: searchingFruitList.length,
                      itemBuilder: (context, index) {
                        var fruit = searchingFruitList[index];
                        return Material(
                          type: MaterialType.transparency,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                            decoration: const BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(5))),
                            child: ListTile(
                              minLeadingWidth: 10,
                              contentPadding:
                                  const EdgeInsets.fromLTRB(8, 0, 0, 0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              selected: selectedFruitId == fruit.id,
                              selectedTileColor: OnepieceColors.liteFancyBlue,
                              onTap: () {
                                selectedFruitId = fruit.id!;
                                fruitSetState(() {});
                              },
                              hoverColor: OnepieceColors.liteFancyBlue,
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(I18nHelper.getDisplayNameFromI18n(
                                      fruit.name!)),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 5),
                                    child: OnepieceTag.getFruitTag(
                                      fruit.fruitType!,
                                      fruitTypeToDisplayValue[
                                          fruit.fruitType!]!,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (searchingFruitList.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: ElevatedButton(
                        onPressed: selectedFruitId == null
                            ? null
                            : () {
                                setState(() {
                                  _eatFruit();
                                });
                              },
                        child: Text(AppLocalizations.of(context)!.eat)),
                  )
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _getFruitList(BuildContext context) {
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
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: 500,
        decoration: const BoxDecoration(
          color: OnepieceColors.menuBackgroundColor,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: fruits.length,
          itemBuilder: (context, index) {
            var fruit = fruits[index];
            return Material(
              type: MaterialType.transparency,
              child: Container(
                padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(5))),
                child: ListTile(
                  minLeadingWidth: 10,
                  contentPadding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  selectedTileColor: OnepieceColors.liteFancyBlue,
                  onTap: () {
                    context.goNamed('fruitDetails',
                        extra: fruit.id,
                        pathParameters: {
                          'name': I18nHelper.getDisplayNameFromI18n(fruit.name!)
                        });
                  },
                  hoverColor: OnepieceColors.liteFancyBlue,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(I18nHelper.getDisplayNameFromI18n(fruit.name!)),
                      Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: OnepieceTag.getFruitTag(
                          fruit.fruitType!,
                          fruitTypeToDisplayValue[fruit.fruitType!]!,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _getGroupSearchBar(BuildContext context) {
    return StatefulBuilder(builder: (context, groupSetState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 160,
                  child: Text(
                    AppLocalizations.of(context)!.group,
                    style: OnepieceFonts.headerStyle,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 8, 8, 0),
                  child: SizedBox(
                    width: 300,
                    height: 40,
                    child: TextFormField(
                      enabled: groupSearchEnabled,
                      controller: groupNameController,
                      decoration: InputDecoration(
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        label: Text(
                          AppLocalizations.of(context)!.groupName,
                          style: OnepieceFonts.hintFont,
                        ),
                        disabledBorder: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: OnepieceColors.fancyGreen)),
                        enabledBorder: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: OnepieceColors.fancyGreen)),
                        focusedBorder: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: OnepieceColors.fancyGreen)),
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        selectedGroupId = null;
                        groupSetState(() {});
                        if (value.isEmpty) {
                          searchingGroupList = [];
                          groupSetState(() {});
                          return;
                        }
                        groupFilter.name = value;
                        groupFilter.languageCode = I18nHelper.getLanguageCode();
                        ListGroupRequest request = ListGroupRequest(
                            pageSize: 5,
                            pageIndex: 1,
                            sortKeys: [],
                            groupFilter: groupFilter);
                        Future<ListGroupResponse?> response =
                            getIt<GroupDao>().listGroups(request);
                        response.then(
                          (value) => {
                            searchingGroupList = value!.groups,
                            groupSetState(() {})
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (searchingGroupList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Text(
                AppLocalizations.of(context)!.searchList,
                style: OnepieceFonts.fancyBlueHintFont,
              ),
            ),
          _getGroupSearchList(context, groupSetState),
        ],
      );
    });
  }

  Widget _getGroupSearchList(BuildContext context, Function groupSetState) {
    Map<GroupCategory, String> groupCategoryToDisplayValue = {
      GroupCategory.pirate: AppLocalizations.of(context)!.pirate,
      GroupCategory.worldGovernment:
          AppLocalizations.of(context)!.worldGovernment,
      GroupCategory.marine: AppLocalizations.of(context)!.marine,
      GroupCategory.underWorld: AppLocalizations.of(context)!.underworld,
    };
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              width: 500,
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: const BoxDecoration(
                color: OnepieceColors.menuBackgroundColor,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: searchingGroupList.length,
                itemBuilder: (context, index) {
                  var currentGroup = searchingGroupList[index];
                  return Material(
                    type: MaterialType.transparency,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                      decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(5))),
                      child: ListTile(
                        minLeadingWidth: 10,
                        contentPadding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        selected: selectedGroupId == currentGroup.id,
                        selectedTileColor: OnepieceColors.liteFancyBlue,
                        onTap: () {
                          groupSetState(() {
                            selectedGroupId = currentGroup.id;
                          });
                        },
                        hoverColor: OnepieceColors.liteFancyBlue,
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(I18nHelper.getDisplayNameFromI18n(
                                currentGroup.name!)),
                            Padding(
                              padding: const EdgeInsets.only(right: 5),
                              child: OnepieceTag.getGroupTag(
                                currentGroup.groupCategory!,
                                groupCategoryToDisplayValue[
                                    currentGroup.groupCategory!]!,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (searchingGroupList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: ElevatedButton(
                  onPressed: selectedGroupId == null
                      ? null
                      : () {
                          setState(() {
                            _joinGroup();
                            groupNameController.text = "";
                            searchingGroupList = [];
                          });
                        },
                  child: Text(AppLocalizations.of(context)!.join)),
            )
        ],
      ),
    );
  }

  Widget _getGroupList(BuildContext context) {
    Map<GroupCategory, String> groupCategoryToDisplayValue =
        <GroupCategory, String>{
      GroupCategory.marine: AppLocalizations.of(context)!.marine,
      GroupCategory.pirate: AppLocalizations.of(context)!.pirate,
      GroupCategory.underWorld: AppLocalizations.of(context)!.underworld,
      GroupCategory.worldGovernment:
          AppLocalizations.of(context)!.worldGovernment,
    };
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: const BoxDecoration(
          color: OnepieceColors.menuBackgroundColor,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: groups.length,
          itemBuilder: (context, index) {
            var currentGroup = groups[index];
            return Material(
              type: MaterialType.transparency,
              child: Container(
                padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(5))),
                child: ListTile(
                  minLeadingWidth: 10,
                  contentPadding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  selected: selectedGroupId == currentGroup.id,
                  selectedTileColor: OnepieceColors.liteFancyBlue,
                  onTap: () {
                    context.goNamed('groupDetails',
                        extra: currentGroup.id,
                        pathParameters: {
                          'name': I18nHelper.getDisplayNameFromI18n(
                              currentGroup.name!)
                        });
                  },
                  hoverColor: OnepieceColors.liteFancyBlue,
                  title: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(2.0)),
                                  border: Border.all(
                                      color: OnepieceColors.fancyBlue,
                                      width: 2,
                                      style: BorderStyle.solid),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.fill,
                                  child: Image.memory(Base64Helper.decode(
                                      currentGroup.profileImage!)),
                                ),
                              ),
                            ),
                            Text(
                              "${I18nHelper.getDisplayNameFromI18n(currentGroup.name!)} "
                              "${currentGroup.onceBelongedTo! ? "(${AppLocalizations.of(context)!.onceBelongTo})" : ""}",
                              style: OnepieceFonts.fancyBlueHintFont,
                            ),
                          ],
                        ),
                        OnepieceTag.getGroupTag(
                            currentGroup.category!,
                            groupCategoryToDisplayValue[
                                currentGroup.category!]!)
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _getBattle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.relatedBattles,
            style: OnepieceFonts.headerStyle,
          ),
          const SizedBox(
            height: 20,
          ),
          _getBattlesTable()
        ],
      ),
    );
  }

  Widget _getBattlesTable() {
    return DataTable(
      showCheckboxColumn: false,
      showBottomBorder: true,
      headingRowHeight: 50,
      border: const TableBorder(
          top: BorderSide(color: OnepieceColors.themeColor),
          bottom: BorderSide(color: OnepieceColors.themeColor)),
      columns: _createColumns(character.id),
      rows: _createRows(context),
      columnSpacing: 20,
    );
  }

  List<DataColumn> _createColumns(String currentCharacterId) {
    return [
      const DataColumn(
        label: Text(""),
      ),
      DataColumn(
        label: SizedBox(
            width: 150, child: Text(AppLocalizations.of(context)!.initiator)),
      ),
      DataColumn(
        label: SizedBox(
            width: 150, child: Text(AppLocalizations.of(context)!.receiver)),
      ),
      DataColumn(
        label: SizedBox(
            width: 150, child: Text(AppLocalizations.of(context)!.winner)),
      ),
      DataColumn(
        label: SizedBox(
            width: 80, child: Text(AppLocalizations.of(context)!.status)),
      ),
    ];
  }

  List<DataRow> _createRows(BuildContext context) {
    Map<BattleStatus, String> battleStatusToDisplayName = {
      BattleStatus.CREATED: AppLocalizations.of(context)!.battleStatusCreated,
      BattleStatus.IN_PROGRESS:
          AppLocalizations.of(context)!.battleStatusStarted,
      BattleStatus.FINISHED: AppLocalizations.of(context)!.battleStatusFinished,
      BattleStatus.FAILED: AppLocalizations.of(context)!.battleStatusFailed,
    };
    var battles = character.battles;
    return battles
        .asMap()
        .entries
        .map((entry) => DataRow(
                onSelectChanged: (value) {
                  context.goNamed('battleDetails',
                      extra: entry.value.id,
                      pathParameters: {'id': entry.value.id});
                },
                cells: [
                  _getDataCell("${entry.key + 1}", false),
                  _getDataCell(
                      I18nHelper.getDisplayNameFromI18n(
                          entry.value.starter!.name),
                      character.id == entry.value.starterId),
                  _getDataCell(
                      I18nHelper.getDisplayNameFromI18n(
                          entry.value.receiver!.name),
                      character.id == entry.value.receiverId),
                  _getDataCell(
                      entry.value.winnerId != null
                          ? (entry.value.winnerId == entry.value.starterId
                              ? I18nHelper.getDisplayNameFromI18n(
                                  entry.value.starter!.name)
                              : I18nHelper.getDisplayNameFromI18n(
                                  entry.value.receiver!.name))
                          : "",
                      false),
                  _getDataCell(
                      battleStatusToDisplayName[entry.value.battleExecution!.battleStatus]!,
                      false),
                ]))
        .toList();
  }

  DataCell _getDataCell(String value, bool heightLight) {
    return DataCell(heightLight
        ? Text(
            value,
            style: OnepieceFonts.tableHeightStyle,
          )
        : Text(value));
  }

  Widget _getStringFormField(
      BuildContext context,
      bool editable,
      TextEditingController controller,
      String label,
      int length,
      Widget? icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 300,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                label,
                style: OnepieceFonts.deepBlackHintFont,
              ),
            ),
          ),
          SizedBox(
            width: 300,
            child: TextFormField(
              controller: controller,
              enabled: editable,
              maxLength: length,
              buildCounter: (
                context, {
                required currentLength,
                required isFocused,
                maxLength,
              }) {
                if (!isFocused) {
                  return const Text("");
                } else {
                  return Text(
                      "$currentLength/$maxLength ${AppLocalizations.of(context)!.characters}");
                }
              },
              decoration: InputDecoration(
                prefixIcon: icon,
                floatingLabelBehavior: FloatingLabelBehavior.never,
                contentPadding: const EdgeInsets.fromLTRB(0, 15, 0, 0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getDigitFormField(
      BuildContext context,
      bool editable,
      TextEditingController controller,
      String label,
      int min,
      int max,
      Widget? icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 300,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                label,
                style: OnepieceFonts.deepBlackHintFont,
              ),
            ),
          ),
          SizedBox(
            width: 300,
            child: TextFormField(
              enabled: editable,
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
                floatingLabelBehavior: FloatingLabelBehavior.never,
                contentPadding: const EdgeInsets.fromLTRB(0, 15, 0, 0),
                hintText: "$min-$max",
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CharacterBattleInfo {
  late int _currentAttack;
  late int _currentDefense;
  late int _currentBlood;
  late int _currentIntelligence;
  late int _currentSpeed;
  late int _currentGroupGain;

  void setAttack(int attack) {
    _currentAttack = attack;
  }

  void setDefense(int defense) {
    _currentDefense = defense;
  }

  void setBlood(int blood) {
    _currentBlood = blood;
  }

  void setIntelligence(int intelligence) {
    _currentIntelligence = intelligence;
  }

  void setSpeed(int speed) {
    _currentSpeed = speed;
  }

  void setGroupGain(int groupGain) {
    _currentGroupGain = groupGain;
  }

  int get attack => _currentAttack;
  int get defense => _currentDefense;
  int get blood => _currentBlood;
  int get speed => _currentSpeed;
  int get intelligence => _currentIntelligence;
  int get groupGain => _currentGroupGain;
}

class CharacterBasicInfo {
  late String? _name;
  late int? _age;
  late String? _profileImage;
  late int? _height;
  late String? _birthPlace;
  late DateTime? _dateOfBirth;
  late int? _bounty;

  void setName(String? name) {
    _name = name;
  }

  void setAge(int? age) {
    _age = age;
  }

  void setProfileImage(String? profileImage) {
    _profileImage = profileImage;
  }

  void setHeight(int? height) {
    _height = height;
  }

  void setBirthPlace(String? birthPlace) {
    birthPlace = birthPlace;
  }

  void setDateOfBirth(DateTime? dateOfBirth) {
    _dateOfBirth = dateOfBirth;
  }

  void setBounty(int? bounty) {
    _bounty = bounty;
  }

  String? get name => _name;
  int? get age => _age;
  String? get profileImage => _profileImage;
  int? get height => _height;
  String? get birthPlace => _birthPlace;
  DateTime? get dateOfBirth => _dateOfBirth;
  int? get bounty => _bounty;
}
