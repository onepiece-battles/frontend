import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/components/digit_text_form_field.dart';
import 'package:one_piece_battles_flutter/components/string_text_form_field.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_tag.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:one_piece_battles_flutter/repository/group_dao.dart';
import 'package:openapi/api.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../popup/onepiece_alert.dart';
import '../../repository/fruit_dao.dart';
import '../../utils/base64_helper.dart';
import '../../utils/data_converter.dart';
import '../../utils/i18n_helper.dart';
import '../../utils/image_helper.dart';
import '../../utils/permission_check.dart';

GetIt getIt = GetIt.instance;

class CharacterDetail extends StatefulWidget {
  final String characterId;
  const CharacterDetail({super.key, required this.characterId});

  @override
  State<CharacterDetail> createState() => _CharacterDetailState();
}

class _CharacterDetailState extends State<CharacterDetail> {
  ScrollController verticalController = ScrollController();
  // character details controller
  TextEditingController characterNameController = TextEditingController();
  TextEditingController characterAge = TextEditingController();
  TextEditingController characterHeight = TextEditingController();
  TextEditingController characterBirthPlace = TextEditingController();
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

  double dividerWidth = 860;
  double sideWidth = 50;

  // initial date
  late CharacterFullView character;
  List<BattleListView> battles = [];
  List<FruitListView> fruits = [];
  List<GroupForCharacterView> groups = [];

  // CharacterBattleInfo characterBattleInfo = CharacterBattleInfo();
  // CharacterBasicInfo characterBasicInfo = CharacterBasicInfo();

  BattleStyle selectedBattleStyle = BattleStyle.BODY;
  GroupPosition selectedGroupPosition = GroupPosition.member;
  Race selectedRace = Race.HUMAN;
  String? selectedDay;
  String? selectedMonth;

  final _basicFormKey = GlobalKey<FormState>();
  final _digitFormKey = GlobalKey<FormState>();

  bool _editButtonVisible = false;

  bool basicInfoEditable = false;
  bool combatInfoEditable = false;
  bool fruitSearchEnabled = false;
  bool groupSearchEnabled = true;
  bool showBaseValue = false;

  int battleStartIndex = 0;
  int battleEndIndex = 0;
  int pageCount = 1;

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
    JoinGroupRequest request = JoinGroupRequest(
        characterId: character.id,
        groupId: selectedGroupId!,
        position: selectedGroupPosition);
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
    battleEndIndex = battles.length >= 10 ? 10 : battles.length;
    _editButtonVisible = PermissionCheck.checkPermission(
            getIt<User>().loginRoleResourcesPermissionMap,
            ResourceType.CHARACTER,
            Permission.UPDATE) &&
        PermissionCheck.isMyResource(
            character.creationRecord!.userId!,
            character.creationRecord!.roleId!,
            getIt<User>().id,
            getIt<User>().loginRoleId!);
    // nika role has the edit permission for all resources
    if (getIt<User>().loginRole == UserRole.NIKA) {
      _editButtonVisible = true;
    }
    if (fruits.length < character.maximumFruitCount) {
      fruitSearchEnabled = true;
    }
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
    selectedMonth = character.dateOfBirth == null
        ? null
        : character.dateOfBirth!.split("-")[0].toString();
    selectedDay = character.dateOfBirth == null
        ? null
        : character.dateOfBirth!.split("-")[1].toString();
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
            return Stack(
              children: [
                SingleChildScrollView(
                  controller: verticalController,
                  scrollDirection: Axis.vertical,
                  child: Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _getBasicInfo(context),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: SizedBox(
                              width: dividerWidth,
                              child: const Divider(
                                color: Colors.grey,
                                thickness: 1,
                              ),
                            ),
                          ),
                          _getCombatInfo(context),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: SizedBox(
                              width: dividerWidth,
                              child: const Divider(
                                color: Colors.grey,
                                thickness: 1,
                              ),
                            ),
                          ),
                          _getFruitSearchBar(context),
                          if (fruits.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.fromLTRB(sideWidth, 8, 8, 8),
                              child: _getFruitList(context),
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: SizedBox(
                              width: dividerWidth,
                              child: const Divider(
                                color: Colors.grey,
                                thickness: 1,
                              ),
                            ),
                          ),
                          _getGroupSearchBar(context),
                          if (groups.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.fromLTRB(sideWidth, 0, 8, 0),
                              child: Text(
                                  AppLocalizations.of(context)!.historyGroups,
                                  style: OnepieceFonts.fancyBlueHintFont),
                            ),
                          if (groups.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.fromLTRB(sideWidth, 0, 8, 8),
                              child: _getGroupList(context),
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: SizedBox(
                              width: dividerWidth,
                              child: const Divider(
                                color: Colors.grey,
                                thickness: 1,
                              ),
                            ),
                          ),
                          _getBattle(context),
                          // bottom space
                          const SizedBox(
                            height: 60,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
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
                            Tooltip(
                              message: character.previousCharacter == null
                                  ? ""
                                  : I18nHelper.getDisplayNameFromI18n(
                                      character.previousCharacter!.name),
                              child: ElevatedButton(
                                onPressed: character.previousCharacter == null
                                    ? null
                                    : () {
                                        context.goNamed('characterDetails',
                                            extra:
                                                character.previousCharacter!.id,
                                            pathParameters: {
                                              'name': I18nHelper
                                                  .getDisplayNameFromI18n(
                                                      character
                                                          .previousCharacter!
                                                          .name)
                                            });
                                      },
                                child: const Icon(Icons.arrow_back),
                              ),
                            ),
                            Tooltip(
                              message: character.nextCharacter == null
                                  ? ""
                                  : I18nHelper.getDisplayNameFromI18n(
                                      character.nextCharacter!.name),
                              child: ElevatedButton(
                                onPressed: character.nextCharacter == null
                                    ? null
                                    : () {
                                        context.goNamed('characterDetails',
                                            extra: character.nextCharacter!.id,
                                            pathParameters: {
                                              'name': I18nHelper
                                                  .getDisplayNameFromI18n(
                                                      character
                                                          .nextCharacter!.name)
                                            });
                                      },
                                child: const Icon(Icons.arrow_forward),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
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

  Widget _getBasicInfo(BuildContext context) {
    return StatefulBuilder(builder: (context, basicState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(sideWidth, 8, 8, 8),
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
                if (_editButtonVisible)
                  Tooltip(
                    message: basicInfoEditable
                        ? AppLocalizations.of(context)!.submitForm
                        : AppLocalizations.of(context)!.editHint,
                    child: InkWell(
                      hoverColor: Colors.transparent,
                      onTap: () {
                        basicState(() {
                          basicInfoEditable = !basicInfoEditable;
                          if (!basicInfoEditable) {
                            var updatedCharacter = Character(
                                id: character.id,
                                maximumFruitCount: character.maximumFruitCount,
                                // keep combat info consistent with original data!
                                groupGain: character.groupGain,
                                attack: character.attack,
                                defense: character.defense,
                                intelligence: character.intelligence,
                                blood: character.blood,
                                speed: character.speed,
                                energy: character.energy,
                                baseGroupGain: character.baseGroupGain,
                                baseAttack: character.baseAttack,
                                baseDefense: character.baseDefense,
                                baseIntelligence: character.baseIntelligence,
                                baseBlood: character.baseBlood,
                                baseSpeed: character.baseSpeed,
                                battleStyle: selectedBattleStyle,
                                race: selectedRace,
                                // basic info
                                name: I18nHelper.getI18nFromDisplayName(
                                    character.name,
                                    characterNameController.text),
                                dateOfBirth:
                                    selectedDay == null || selectedMonth == null
                                        ? null
                                        : "$selectedMonth-$selectedDay",
                                // todo(yichi): profile image update
                                birthPlace: characterBirthPlace.text,
                                age: DataConverter.stringToInt(
                                    characterAge.text.trim()),
                                bounty: DataConverter.stringToInt(
                                    characterBounty.text.trim()),
                                height: DataConverter.stringToInt(
                                    characterHeight.text.trim()),
                                score: character.score);
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
            padding: EdgeInsets.fromLTRB(sideWidth, 8, 8, 8),
            child: ImageHelper.getRoundImageFrame(
                200,
                200,
                3,
                OnepieceColors.liteFancyBlue,
                100,
                Base64Helper.decode(character.profileImage!)),
          ),
          Form(
            key: _basicFormKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: dividerWidth,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: sideWidth),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            StringTextFormField(
                                context,
                                basicInfoEditable,
                                characterNameController,
                                AppLocalizations.of(context)!.name,
                                20,
                                ImageHelper.getTextFormFieldIcon(
                                    'images/character_digits_icon/name.svg',
                                    true,
                                    null),
                                true),
                            StringTextFormField(
                                context,
                                basicInfoEditable,
                                characterBirthPlace,
                                AppLocalizations.of(context)!.birthPlace,
                                20,
                                ImageHelper.getTextFormFieldIcon(
                                    'images/character_digits_icon/birth_place.svg',
                                    true,
                                    null),
                                false),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 300,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      ImageHelper.getTextFormFieldIcon(
                                          "images/character_digits_icon/birthday.svg",
                                          true,
                                          null),
                                      Text(
                                        AppLocalizations.of(context)!.birthDay,
                                        style: OnepieceFonts.deepBlackHintFont,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: 15,
                                ),
                                SizedBox(
                                  width: 300,
                                  height: 35,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 60,
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton2(
                                            isExpanded: true,
                                            value: selectedMonth,
                                            onChanged: basicInfoEditable
                                                ? (String? month) {
                                                    basicState(() {
                                                      selectedMonth = month!;
                                                    });
                                                  }
                                                : null,
                                            buttonStyleData: ButtonStyleData(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 5),
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(3),
                                                  color: OnepieceColors
                                                      .liteFancyGreen),
                                              height: 30,
                                              width: 60,
                                            ),
                                            menuItemStyleData:
                                                const MenuItemStyleData(
                                              height: 30,
                                            ),
                                            selectedItemBuilder: (context) {
                                              return List<String>.generate(
                                                      12,
                                                      (int index) => (index + 1)
                                                          .toString())
                                                  .map((String month) {
                                                return Container(
                                                  alignment:
                                                      AlignmentDirectional
                                                          .center,
                                                  child: Text(
                                                    month,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                );
                                              }).toList();
                                            },
                                            items: List<String>.generate(
                                                    12,
                                                    (int index) =>
                                                        (index + 1).toString())
                                                .map((String month) {
                                              return DropdownMenuItem<String>(
                                                value: month,
                                                child: Text(
                                                  month,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        child: Text(
                                          AppLocalizations.of(context)!.month,
                                          style: OnepieceFonts.contentStyle,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 60,
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton2(
                                            isExpanded: true,
                                            value: selectedDay,
                                            onChanged: basicInfoEditable
                                                ? (String? day) {
                                                    basicState(() {
                                                      selectedDay = day!;
                                                    });
                                                  }
                                                : null,
                                            buttonStyleData: ButtonStyleData(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6),
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(3),
                                                  color: OnepieceColors
                                                      .liteFancyGreen),
                                              height: 30,
                                              width: 60,
                                            ),
                                            menuItemStyleData:
                                                const MenuItemStyleData(
                                              height: 30,
                                            ),
                                            selectedItemBuilder: (context) {
                                              return List<String>.generate(
                                                      31,
                                                      (int index) => (index + 1)
                                                          .toString())
                                                  .map((String day) {
                                                return Container(
                                                  alignment:
                                                      AlignmentDirectional
                                                          .center,
                                                  child: Text(
                                                    day,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                );
                                              }).toList();
                                            },
                                            items: List<String>.generate(
                                                    31,
                                                    (int index) =>
                                                        (index + 1).toString())
                                                .map((String day) {
                                              return DropdownMenuItem<String>(
                                                value: day,
                                                child: Text(
                                                  day,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        child: Text(
                                          AppLocalizations.of(context)!.day,
                                          style: OnepieceFonts.contentStyle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: sideWidth),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            DigitTextFormField(
                                context,
                                basicInfoEditable,
                                characterBounty,
                                AppLocalizations.of(context)!.bounty,
                                10,
                                100000000000,
                                ImageHelper.getTextFormFieldIcon(
                                    'images/character_digits_icon/bounty.svg',
                                    true,
                                    null)),
                            DigitTextFormField(
                                context,
                                basicInfoEditable,
                                characterAge,
                                AppLocalizations.of(context)!.age,
                                0,
                                100000,
                                ImageHelper.getTextFormFieldIcon(
                                    'images/character_digits_icon/age.svg',
                                    true,
                                    null)),
                            DigitTextFormField(
                                context,
                                basicInfoEditable,
                                characterHeight,
                                AppLocalizations.of(context)!.height,
                                1,
                                100000,
                                ImageHelper.getTextFormFieldIcon(
                                    'images/character_digits_icon/height.svg',
                                    true,
                                    null)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      );
    });
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              width: dividerWidth,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: sideWidth),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.battleInfo,
                          style: OnepieceFonts.headerStyle,
                        ),
                        const SizedBox(
                          width: 15,
                        ),
                        if (_editButtonVisible)
                          Tooltip(
                            message: combatInfoEditable
                                ? AppLocalizations.of(context)!.submitForm
                                : AppLocalizations.of(context)!.editHint,
                            child: InkWell(
                              hoverColor: Colors.white,
                              onTap: () {
                                combatState(() {
                                  combatInfoEditable = !combatInfoEditable;
                                  if (combatInfoEditable) {
                                    showBaseValue = true;
                                    changeValue();
                                  }
                                  if (!combatInfoEditable) {
                                    var updatedCharacter = Character(
                                      /* basic info keep consistent with original
                                       value, will probably updated on backend */
                                      id: character.id,
                                      battleStyle: character.battleStyle,
                                      race: character.race,
                                      score: character.score,
                                      groupGain: character.groupGain,
                                      attack: character.attack,
                                      defense: character.defense,
                                      intelligence: character.intelligence,
                                      blood: character.blood,
                                      speed: character.speed,
                                      // digit info update
                                      maximumFruitCount:
                                          DataConverter.stringToInt(
                                              characterFruitLimitController
                                                  .text),
                                      baseGroupGain: DataConverter.stringToInt(
                                          characterGroupGainController.text),
                                      baseAttack: DataConverter.stringToInt(
                                          characterAttackController.text),
                                      baseDefense: DataConverter.stringToInt(
                                          characterDefenseController.text),
                                      baseIntelligence:
                                          DataConverter.stringToInt(
                                              characterIntelligenceController
                                                  .text),
                                      baseBlood: DataConverter.stringToInt(
                                          characterBloodController.text),
                                      baseSpeed: DataConverter.stringToInt(
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
                                            value!.result),
                                      );
                                      if (value.success) {
                                        showBaseValue = false;
                                        context.replaceNamed('characterDetails',
                                            extra: character.id,
                                            pathParameters: {
                                              'name': I18nHelper
                                                  .getDisplayNameFromI18n(
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
                                  child: !combatInfoEditable
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
                    if (fruits.isNotEmpty)
                      SizedBox(
                        width: 130,
                        height: 36,
                        child: AnimatedToggleSwitch<bool>.dual(
                          current: showBaseValue,
                          first: false,
                          second: true,
                          spacing: 1.0,
                          style: const ToggleStyle(
                            borderColor: Colors.transparent,
                            backgroundColor:
                                OnepieceColors.menuSelectedTileColor,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                spreadRadius: 1,
                                blurRadius: 2,
                                offset: Offset(0, 1.5),
                              ),
                            ],
                          ),
                          borderWidth: 3.0,
                          height: 36,
                          onChanged: (b) => combatState(() {
                            showBaseValue = !showBaseValue;
                            changeValue();
                          }),
                          styleBuilder: (b) => ToggleStyle(
                              indicatorColor: b ? Colors.white : Colors.white),
                          iconBuilder: (value) => value
                              ? ImageHelper.getTextFormFieldIcon(
                                  'images/svgs/user.svg', true, 30)
                              : ImageHelper.getTextFormFieldIcon(
                                  'images/svgs/fruit_total.svg', true, 30),
                          textBuilder: (value) => value
                              ? Text(
                                  AppLocalizations.of(context)!.basicValue,
                                  style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                )
                              : Text(
                                  AppLocalizations.of(context)!.realValue,
                                  style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (character.hakis.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(sideWidth, 0, 0, 0),
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
          Padding(
            padding: EdgeInsets.fromLTRB(sideWidth, 20, 0, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tooltip(
                  message: AppLocalizations.of(context)!.getByJoinCombat,
                  child: Text(
                    AppLocalizations.of(context)!.combatPower,
                    style: OnepieceFonts.contentStyleBold,
                  ),
                ),
                Text(
                  " ${character.score}",
                  style: OnepieceFonts.contentStyleBoldFancyBlue,
                )
              ],
            ),
          ),
          Form(
            key: _digitFormKey,
            child: SizedBox(
              width: dividerWidth,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: sideWidth),
                    child: Column(
                      children: [
                        DigitTextFormField(
                            context,
                            combatInfoEditable,
                            characterAttackController,
                            AppLocalizations.of(context)!.characterAttack,
                            10,
                            1000,
                            ImageHelper.getTextFormFieldIcon(
                                'images/character_digits_icon/attack.svg',
                                true,
                                null)),
                        DigitTextFormField(
                            context,
                            combatInfoEditable,
                            characterDefenseController,
                            AppLocalizations.of(context)!.characterDefense,
                            10,
                            1000,
                            ImageHelper.getTextFormFieldIcon(
                                'images/character_digits_icon/defense.svg',
                                true,
                                null)),
                        DigitTextFormField(
                            context,
                            combatInfoEditable,
                            characterBloodController,
                            AppLocalizations.of(context)!.characterBlood,
                            100,
                            10000,
                            ImageHelper.getTextFormFieldIcon(
                                'images/character_digits_icon/blood.svg',
                                true,
                                null)),
                        DigitTextFormField(
                            context,
                            combatInfoEditable,
                            characterSpeedController,
                            AppLocalizations.of(context)!.characterSpeed,
                            10,
                            200,
                            ImageHelper.getTextFormFieldIcon(
                                'images/character_digits_icon/speed.svg',
                                true,
                                null)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: sideWidth),
                    child: Column(
                      children: [
                        DigitTextFormField(
                            context,
                            combatInfoEditable,
                            characterIntelligenceController,
                            AppLocalizations.of(context)!.characterIntelligence,
                            70,
                            260,
                            ImageHelper.getTextFormFieldIcon(
                                'images/character_digits_icon/intelligence.svg',
                                true,
                                null)),
                        DigitTextFormField(
                            context,
                            combatInfoEditable,
                            characterEnergyController,
                            AppLocalizations.of(context)!.characterEnergy,
                            100,
                            300,
                            ImageHelper.getTextFormFieldIcon(
                                'images/character_digits_icon/energy.svg',
                                true,
                                null)),
                        DigitTextFormField(
                            context,
                            combatInfoEditable,
                            characterGroupGainController,
                            AppLocalizations.of(context)!.groupGain,
                            100,
                            200,
                            ImageHelper.getTextFormFieldIcon(
                                'images/character_digits_icon/group_gain.svg',
                                true,
                                null)),
                        DigitTextFormField(
                            context,
                            combatInfoEditable,
                            characterFruitLimitController,
                            AppLocalizations.of(context)!.fruitLimit,
                            1,
                            2,
                            ImageHelper.getTextFormFieldIcon(
                                'images/character_digits_icon/fruit_limit.svg',
                                true,
                                null)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      );
    });
  }

  changeValue() {
    if (showBaseValue) {
      characterAttackController.text = character.baseAttack.toString();
      characterDefenseController.text = character.baseDefense.toString();
      characterBloodController.text = character.baseBlood.toString();
      characterIntelligenceController.text =
          character.baseIntelligence.toString();
      characterGroupGainController.text = character.baseGroupGain.toString();
      characterSpeedController.text = character.baseSpeed.toString();
    } else {
      characterGroupGainController.text = character.groupGain.toString();
      characterAttackController.text = character.attack.toString();
      characterDefenseController.text = character.defense.toString();
      characterIntelligenceController.text = character.intelligence.toString();
      characterBloodController.text = character.blood.toString();
      characterSpeedController.text = character.speed.toString();
    }
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
            padding: EdgeInsets.symmetric(horizontal: sideWidth),
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
              ],
            ),
          ),
          if (character.maximumFruitCount > fruits.length && _editButtonVisible)
            Padding(
              padding: EdgeInsets.fromLTRB(sideWidth, 8, 8, 0),
              child: SizedBox(
                width: 200,
                height: 35,
                child: TextFormField(
                  enabled: fruitSearchEnabled,
                  controller: fruitNameController,
                  decoration: InputDecoration(
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    disabledBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: OnepieceColors.menuHoverColor)),
                    enabledBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: OnepieceColors.menuHoverColor)),
                    focusedBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: OnepieceColors.fancyGreen)),
                    prefixIcon: const Icon(Icons.search),
                    labelText: AppLocalizations.of(context)!.search,
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
                    fruitFilter.languageCode = I18nHelper.getLanguageCode();
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
          Padding(
            padding: EdgeInsets.fromLTRB(sideWidth, 8, 8, 8),
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
                        onPressed: selectedFruitId == null ||
                                fruits
                                    .map((e) => e.id)
                                    .toList()
                                    .contains(selectedFruitId)
                            ? null
                            : () {
                                _eatFruit();
                                fruitNameController.text = '';
                                selectedFruitId = null;
                                searchingFruitList = [];
                                fruitSetState(() {});
                              },
                        child: fruits
                                .map((e) => e.id)
                                .toList()
                                .contains(selectedFruitId)
                            ? Text(AppLocalizations.of(context)!.eaten)
                            : Text(AppLocalizations.of(context)!.eat)),
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
    return Container(
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
    );
  }

  Widget _getGroupSearchBar(BuildContext context) {
    Map<GroupCategory, String> groupCategoryToDisplayValue = {
      GroupCategory.pirate: AppLocalizations.of(context)!.pirate,
      GroupCategory.government: AppLocalizations.of(context)!.worldGovernment,
      GroupCategory.group: AppLocalizations.of(context)!.group,
      GroupCategory.marine: AppLocalizations.of(context)!.marine,
      GroupCategory.underWorld: AppLocalizations.of(context)!.underworld,
    };
    Map<GroupPosition, String> groupPositionToDisplayValue = {
      GroupPosition.member: AppLocalizations.of(context)!.member,
      GroupPosition.captain: AppLocalizations.of(context)!.caption,
      GroupPosition.combatant: AppLocalizations.of(context)!.combatant,
      GroupPosition.cook: AppLocalizations.of(context)!.cook,
      GroupPosition.doctor: AppLocalizations.of(context)!.doctor,
      GroupPosition.firstMate: AppLocalizations.of(context)!.firstMate,
      GroupPosition.helmsman: AppLocalizations.of(context)!.helmsman,
      GroupPosition.intern: AppLocalizations.of(context)!.intern,
      GroupPosition.musician: AppLocalizations.of(context)!.musician,
      GroupPosition.navigator: AppLocalizations.of(context)!.navigator,
      GroupPosition.scholar: AppLocalizations.of(context)!.scholar,
      GroupPosition.shipwright: AppLocalizations.of(context)!.shipwright,
    };
    return StatefulBuilder(builder: (context, groupSetState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(sideWidth, 8, 8, 8),
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
              ],
            ),
          ),
          if (_editButtonVisible)
            Padding(
              padding: EdgeInsets.fromLTRB(sideWidth, 8, 8, 0),
              child: SizedBox(
                width: 200,
                height: 35,
                child: TextFormField(
                  enabled: groupSearchEnabled,
                  controller: groupNameController,
                  decoration: InputDecoration(
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    disabledBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: OnepieceColors.menuHoverColor)),
                    enabledBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: OnepieceColors.menuHoverColor)),
                    focusedBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: OnepieceColors.fancyGreen)),
                    prefixIcon: const Icon(Icons.search),
                    labelText: AppLocalizations.of(context)!.search,
                  ),
                  onChanged: (value) {
                    debugPrint(value);
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
          if (searchingGroupList.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(sideWidth, 8, 8, 0),
              child: Text(
                AppLocalizations.of(context)!.searchList,
                style: OnepieceFonts.fancyBlueHintFont,
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(sideWidth, 8, 8, 8),
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
                        var group = searchingGroupList[index];
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
                              selected: selectedGroupId == group.id,
                              selectedTileColor: OnepieceColors.liteFancyBlue,
                              onTap: () {
                                selectedGroupId = group.id;
                                groupSetState(() {});
                              },
                              hoverColor: OnepieceColors.liteFancyBlue,
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(I18nHelper.getDisplayNameFromI18n(
                                      group.name!)),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 5),
                                    child: OnepieceTag.getGroupTag(
                                      group.groupCategory!,
                                      groupCategoryToDisplayValue[
                                          group.groupCategory!]!,
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
                if (selectedGroupId != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 8, 0),
                    child: Text(
                      AppLocalizations.of(context)!.positionList,
                      style: OnepieceFonts.fancyBlueHintFont,
                    ),
                  ),
                if (selectedGroupId != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 500,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton2(
                          isExpanded: true,
                          value: selectedGroupPosition,
                          onChanged: groups
                                  .where((element) =>
                                      element.onceBelongedTo == false)
                                  .map((e) => e.groupId)
                                  .toList()
                                  .contains(selectedGroupId)
                              ? null
                              : (GroupPosition? value) {
                                  selectedGroupPosition = value!;
                                  groupSetState(() {});
                                },
                          buttonStyleData: ButtonStyleData(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                color: OnepieceColors.liteFancyGreen),
                            height: 40,
                            width: 500,
                          ),
                          menuItemStyleData: const MenuItemStyleData(
                            height: 30,
                          ),
                          items: GroupPosition.values
                              .map((GroupPosition groupPosition) {
                            return DropdownMenuItem<GroupPosition>(
                              value: groupPosition,
                              child: Text(
                                groupPositionToDisplayValue[groupPosition]!,
                                style: OnepieceFonts.contentStyle,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                if (searchingGroupList.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: ElevatedButton(
                        onPressed: selectedGroupId == null ||
                                groups
                                    .where((element) =>
                                        element.onceBelongedTo == false)
                                    .map((e) => e.groupId)
                                    .toList()
                                    .contains(selectedGroupId)
                            ? null
                            : () {
                                _joinGroup();
                                selectedGroupId = null;
                                groupNameController.text = "";
                                searchingGroupList = [];
                                groupSetState(() {});
                              },
                        child: groups
                                .where((element) =>
                                    element.onceBelongedTo == false)
                                .map((e) => e.groupId)
                                .toList()
                                .contains(selectedGroupId)
                            ? Text(AppLocalizations.of(context)!.joined)
                            : Text(AppLocalizations.of(context)!.join)),
                  )
              ],
            ),
          )
        ],
      );
    });
  }

  Widget _getGroupList(BuildContext context) {
    Map<GroupCategory, String> groupCategoryToDisplayValue =
        <GroupCategory, String>{
      GroupCategory.marine: AppLocalizations.of(context)!.marine,
      GroupCategory.pirate: AppLocalizations.of(context)!.pirate,
      GroupCategory.underWorld: AppLocalizations.of(context)!.underworld,
      GroupCategory.group: AppLocalizations.of(context)!.group,
      GroupCategory.other: AppLocalizations.of(context)!.otherType,
      GroupCategory.government: AppLocalizations.of(context)!.worldGovernment,
      GroupCategory.revolutionArmy:
          AppLocalizations.of(context)!.revolutionaryArmy,
    };
    Map<GroupPosition, String> groupPositionToDisplayValue = {
      GroupPosition.member: AppLocalizations.of(context)!.member,
      GroupPosition.captain: AppLocalizations.of(context)!.caption,
      GroupPosition.combatant: AppLocalizations.of(context)!.combatant,
      GroupPosition.cook: AppLocalizations.of(context)!.cook,
      GroupPosition.doctor: AppLocalizations.of(context)!.doctor,
      GroupPosition.firstMate: AppLocalizations.of(context)!.firstMate,
      GroupPosition.helmsman: AppLocalizations.of(context)!.helmsman,
      GroupPosition.intern: AppLocalizations.of(context)!.intern,
      GroupPosition.musician: AppLocalizations.of(context)!.musician,
      GroupPosition.navigator: AppLocalizations.of(context)!.navigator,
      GroupPosition.scholar: AppLocalizations.of(context)!.scholar,
      GroupPosition.shipwright: AppLocalizations.of(context)!.shipwright,
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
                decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(5))),
                child: ListTile(
                  minLeadingWidth: 10,
                  contentPadding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  selectedTileColor: OnepieceColors.liteFancyBlue,
                  onTap: () {
                    context.goNamed('groupDetails',
                        extra: currentGroup.groupId,
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
                                child: ImageHelper.getRoundImageFrame(
                                    50,
                                    50,
                                    2,
                                    Colors.black12,
                                    6,
                                    Base64Helper.decode(
                                        currentGroup.profileImage!))),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${I18nHelper.getDisplayNameFromI18n(currentGroup.name!)} "
                                  "${currentGroup.onceBelongedTo! ? "(${AppLocalizations.of(context)!.onceBelongTo})" : ""}",
                                  style: OnepieceFonts.deepBlackHintFont,
                                ),
                                Text(
                                  groupPositionToDisplayValue[
                                      currentGroup.position!]!,
                                  style: OnepieceFonts.boldLiteFancySmallFont,
                                )
                              ],
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
    return StatefulBuilder(builder: (context, battleListState) {
      return Padding(
        padding: EdgeInsets.fromLTRB(sideWidth, 8, sideWidth, 8),
        child: SizedBox(
          width: dividerWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.relatedBattles,
                    style: OnepieceFonts.headerStyle,
                  ),
                  if (battles.length > 10)
                    _getPageController(context, battleListState)
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              _getBattlesTable(context),
              const SizedBox(
                height: 10,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _getBattlesTable(BuildContext context) {
    return DataTable(
      showCheckboxColumn: false,
      showBottomBorder: true,
      headingRowHeight: 50,
      border: const TableBorder(
          top: BorderSide(color: OnepieceColors.themeColor),
          bottom: BorderSide(color: OnepieceColors.themeColor)),
      columns: _createColumns(character.id, context),
      rows: _createRows(context),
      columnSpacing: 8,
    );
  }

  Widget _getPageController(BuildContext context, Function battleListState) {
    return Padding(
      padding: const EdgeInsets.only(right: 80.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 40,
            height: 30,
            child: Center(
              child: IconButton(
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                color: Colors.transparent,
                highlightColor: Colors.transparent,
                onPressed: battleStartIndex == 0
                    ? null
                    : () {
                        battleListState(() {
                          pageCount--;
                          battleStartIndex = battleStartIndex - 10;
                          if (battleEndIndex % 10 != 0) {
                            battleEndIndex =
                                battleEndIndex - battleEndIndex % 10;
                          } else {
                            battleEndIndex = battleEndIndex - 10;
                          }
                          if (battleStartIndex < 0) {
                            battleStartIndex = 0;
                          }
                        });
                      },
                icon: Icon(
                  Icons.keyboard_arrow_left_sharp,
                  size: 20,
                  color: battleStartIndex == 0
                      ? Colors.transparent
                      : OnepieceColors.fancyBlue,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 20,
            height: 30,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: Text(
                  pageCount.toString(),
                  style: const TextStyle(
                      color: OnepieceColors.fancyBlue, fontSize: 15),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 40,
            height: 30,
            child: Center(
              child: IconButton(
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                color: Colors.transparent,
                highlightColor: Colors.transparent,
                onPressed: battleEndIndex == battles.length
                    ? null
                    : () {
                        battleListState(() {
                          pageCount++;
                          battleStartIndex = battleStartIndex + 10;
                          battleEndIndex = battleEndIndex + 10;
                          if (battleEndIndex > battles.length) {
                            battleEndIndex = battles.length;
                          }
                        });
                      },
                icon: Icon(
                  Icons.keyboard_arrow_right_sharp,
                  size: 20,
                  color: battleEndIndex == battles.length
                      ? Colors.transparent
                      : OnepieceColors.fancyBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DataColumn> _createColumns(
      String currentCharacterId, BuildContext context) {
    var headerStyle = OnepieceFonts.tableHeaderStyle;
    return [
      const DataColumn(
        label: Text(""),
      ),
      DataColumn(
        label: SizedBox(
            width: 150,
            child: Text(
              AppLocalizations.of(context)!.initiator,
              style: headerStyle,
            )),
      ),
      DataColumn(
        label: SizedBox(
            width: 150,
            child: Text(AppLocalizations.of(context)!.receiver,
                style: headerStyle)),
      ),
      DataColumn(
        label: SizedBox(
            width: 150,
            child:
                Text(AppLocalizations.of(context)!.winner, style: headerStyle)),
      ),
      DataColumn(
        label: SizedBox(
            width: 80,
            child:
                Text(AppLocalizations.of(context)!.status, style: headerStyle)),
      ),
      DataColumn(
        label: SizedBox(
            width: 150,
            child: Text(AppLocalizations.of(context)!.combatScoreChange,
                style: headerStyle)),
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
        .getRange(battleStartIndex, battleEndIndex)
        .toList()
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
                  DataCell(
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                          child: ImageHelper.getRoundImageFrame(
                              40,
                              40,
                              1.5,
                              OnepieceColors.liteFancyBlue,
                              40,
                              Base64Helper.decode(
                                  entry.value.starter!.profileImage!)),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                              child: Text(I18nHelper.getDisplayNameFromI18n(
                                  entry.value.starter!.name)),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 5.0),
                              child: Text(
                                  entry.value.battleExecution!
                                      .starterScoreBefore!
                                      .toString(),
                                  style: OnepieceFonts.boldFancySmallFont),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                          child: ImageHelper.getRoundImageFrame(
                              40,
                              40,
                              1.5,
                              OnepieceColors.liteFancyBlue,
                              40,
                              Base64Helper.decode(
                                  entry.value.receiver!.profileImage!)),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                              child: Text(I18nHelper.getDisplayNameFromI18n(
                                  entry.value.receiver!.name)),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 5.0),
                              child: Text(
                                  entry.value.battleExecution!
                                      .receiverScoreBefore!
                                      .toString(),
                                  style: OnepieceFonts.boldFancySmallFont),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Padding(
                      padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                      child: entry.value.battleExecution!.winnerId == null
                          ? Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(2.0)),
                              ),
                              child: FittedBox(
                                fit: BoxFit.fill,
                                child: ImageHelper.getSvgIconWithColor(
                                    'images/svgs/question.svg',
                                    100,
                                    100,
                                    OnepieceColors.liteFancyBlue),
                              ),
                            )
                          : ImageHelper.getRoundImageFrame(
                              40,
                              40,
                              1.5,
                              OnepieceColors.liteFancyBlue,
                              40,
                              Base64Helper.decode(
                                  entry.value.battleExecution!.winnerId ==
                                          entry.value.starterId
                                      ? entry.value.starter!.profileImage!
                                      : entry.value.receiver!.profileImage!)),
                    ),
                  ),
                  _getDataCell(
                      battleStatusToDisplayName[
                          entry.value.battleExecution!.battleStatus]!,
                      false),
                  DataCell(
                    Row(
                      children: [
                        entry.value.battleExecution!.winnerId != null
                            ? Text(
                                style: OnepieceFonts.boldFancyBlueHintFont,
                                character.id ==
                                        entry.value.battleExecution!.winnerId
                                    ? getScoreText(entry.value.battleExecution!
                                        .winnerScoreChange!)
                                    : getScoreText(entry.value.battleExecution!
                                        .loserScoreChange!))
                            : const Text(""),
                        const SizedBox(
                          width: 10,
                        ),
                        entry.value.battleExecution!.winnerId != null
                            ? Text(
                                style: OnepieceFonts.superSmallContentStyle,
                                character.id == entry.value.starterId
                                    ? "(${entry.value.battleExecution!.starterScoreBefore!} -> ${entry.value.battleExecution!.starterScoreAfter!})"
                                    : "(${entry.value.battleExecution!.receiverScoreBefore!} ->${entry.value.battleExecution!.receiverScoreAfter!})")
                            : const Text(""),
                      ],
                    ),
                  ),
                ]))
        .toList();
  }

  String getScoreText(int scoreChange) {
    return scoreChange >= 0 ? "+ $scoreChange" : "- ${(0 - scoreChange)}";
  }

  DataCell _getDataCell(String value, bool heightLight) {
    return DataCell(heightLight
        ? Text(
            value,
            style: OnepieceFonts.tableHeightStyle,
          )
        : Text(value));
  }
}
