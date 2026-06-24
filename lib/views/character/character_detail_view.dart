import 'dart:typed_data';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:one_piece_battles_flutter/components/digit_text_form_field.dart';
import 'package:one_piece_battles_flutter/components/image_lazy_loader.dart';
import 'package:one_piece_battles_flutter/components/string_text_form_field.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_colors.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_fonts.dart';
import 'package:one_piece_battles_flutter/constants/onepiece_tag.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:openapi/api.dart';
import '../../l10n/app_localizations.dart';
import '../../popup/onepiece_alert.dart';
import '../../repository/fruit_dao.dart';
import '../../repository/image_dao.dart';
import '../../utils/base64_helper.dart';
import '../../utils/data_converter.dart';
import '../../utils/i18n_helper.dart';
import '../../utils/image_helper.dart';
import '../../utils/onepiece_image_picker.dart';
import '../../utils/permission_check.dart';
import '../../utils/nested_scroll_helper.dart';
import '../../utils/responsive_breakpoints.dart';

GetIt getIt = GetIt.instance;

class CharacterDetail extends StatefulWidget {
  final String characterId;

  const CharacterDetail({super.key, required this.characterId});

  @override
  State<CharacterDetail> createState() => _CharacterDetailState();
}

class _CharacterDetailState extends State<CharacterDetail> {
  ScrollController verticalController = ScrollController();

  @override
  void dispose() {
    verticalController.dispose();
    super.dispose();
  }

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
  FruitFilter fruitFilter = FruitFilter();
  List<FruitListView> searchingFruitList = [];
  List<Haki> selectedHakis = [];
  String? selectedFruitId;
  String? selectedImage;

  double dividerWidth = 860;
  double sideWidth = 50;

  // initial date
  late Future<CharacterFullView?> _characterFuture;
  String? _preparedCharacterId;
  late CharacterFullView character;
  List<BattleListView> battles = [];
  List<FruitListView> fruits = [];
  List<GroupForCharacterView> groups = [];

  BattleStyle selectedBattleStyle = BattleStyle.BODY;
  Race selectedRace = Race.HUMAN;
  String? selectedDay;
  String? selectedMonth;

  final _basicFormKey = GlobalKey<FormState>();
  final _digitFormKey = GlobalKey<FormState>();

  bool _editButtonVisible = false;

  bool basicInfoEditable = false;
  bool combatInfoEditable = false;
  bool fruitSearchEnabled = false;
  bool showBaseValue = false;

  int battleStartIndex = 0;
  int battleEndIndex = 0;
  int pageCount = 1;

  @override
  void initState() {
    super.initState();
    _characterFuture = _loadData();
  }

  @override
  void didUpdateWidget(covariant CharacterDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.characterId != widget.characterId) {
      _preparedCharacterId = null;
      _characterFuture = _loadData();
    }
  }

  Future<CharacterFullView?> _loadData() {
    return getIt<CharacterDao>().getCharacter(
        GetCharacterFullViewRequest(characterId: widget.characterId));
  }

  void _refreshCharacterData() {
    _preparedCharacterId = null;
    _characterFuture = _loadData();
  }

  _eatFruit() {
    EatFruitRequest request =
        EatFruitRequest(characterId: character.id, fruitId: selectedFruitId!);
    Future<EatFruitResponse?> response =
        getIt<CharacterDao>().eatFruit(request);
    response.then(
      (value) {
        if (!mounted) return;
        setState(() {
          _refreshCharacterData();
        });
      },
    );
  }

  bool _updateData(CharacterFullView characterFullView) {
    if (_preparedCharacterId == characterFullView.id) return false;
    _preparedCharacterId = characterFullView.id;
    character = characterFullView;
    battles = characterFullView.battles;
    fruits = characterFullView.fruits;
    groups = characterFullView.groups;
    selectedHakis = characterFullView.hakis.toList(growable: true);
    battleEndIndex = battles.length >= 10 ? 10 : battles.length;
    _editButtonVisible = (PermissionCheck.checkPermission(
                getIt<User>().loginRoleResourcesPermissionMap,
                ResourceType.CHARACTER,
                Permission.UPDATE) &&
            PermissionCheck.isMyResource(
                character.creationRecord!.userId!,
                character.creationRecord!.roleId!,
                getIt<User>().id,
                getIt<User>().loginRoleId!)) ||
        getIt<User>().loginRole == UserRole.NIKA;
    // nika role has the edit permission for all resources
    if (getIt<User>().loginRole == UserRole.NIKA) {
      _editButtonVisible = true;
    }
    if (fruits.length < character.maximumFruitCount) {
      fruitSearchEnabled = true;
    }
    return true;
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
    final birthdayParts = _parseBirthday(character.dateOfBirth);
    selectedMonth = birthdayParts.$1;
    selectedDay = birthdayParts.$2;
    characterBounty.text =
        character.bounty == null ? "" : character.bounty.toString();
    selectedBattleStyle = character.battleStyle;
    selectedRace = character.race;
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

  (String?, String?) _parseBirthday(String? birthday) {
    if (birthday == null || birthday.trim().isEmpty) {
      return (null, null);
    }
    final parts = birthday.split('-');
    if (parts.length != 2) {
      return (null, null);
    }
    return (
      _normalizeBirthdayPart(parts[0], 12),
      _normalizeBirthdayPart(parts[1], 31),
    );
  }

  String? _normalizeBirthdayPart(String? value, int max) {
    if (value == null) return null;
    final parsed = int.tryParse(value);
    if (parsed == null || parsed < 1 || parsed > max) return null;
    return parsed.toString();
  }

  String? _formattedBirthday() {
    final month = _normalizeBirthdayPart(selectedMonth, 12);
    final day = _normalizeBirthdayPart(selectedDay, 31);
    if (month == null || day == null) return null;
    return '$month-$day';
  }

  String? _normalizeStoredBirthday(String? birthday) {
    final parts = _parseBirthday(birthday);
    if (parts.$1 == null || parts.$2 == null) return null;
    return '${parts.$1}-${parts.$2}';
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        controller: verticalController,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildMobileHeader(context),
          const SizedBox(height: 12),
          _buildMobileBasicInfo(context),
          const SizedBox(height: 12),
          _buildMobileCombatInfo(context),
          const SizedBox(height: 12),
          _buildMobileFruits(context),
          if (fruits.isNotEmpty) const SizedBox(height: 12),
          _buildMobileGroups(context),
          const SizedBox(height: 12),
          _buildMobileBattles(context),
        ]),
      ),
    );
  }

  // ── Mobile section builders ──────────────────────────────────────

  Widget _buildMobileHeader(BuildContext context) {
    return Center(
        child: Column(children: [
      GestureDetector(
        onTap: basicInfoEditable
            ? () async {
                final showAlert = OnepieceAlert.createAlertShower(context);
                final alertTitle = AppLocalizations.of(context)!.alert;
                final imageSizeHint =
                    AppLocalizations.of(context)!.imageSizeExceedsLimit;
                final XFile? img = await OnepieceImagePicker.pickWebImage();
                if (!mounted || img == null) return;
                final bytes = await img.readAsBytes();
                if (!mounted) return;
                if (!ImageHelper.isValidImageSize(500 * 1024, bytes)) {
                  showAlert(alertTitle, imageSizeHint);
                  return;
                }
                setState(() => selectedImage = Base64Helper.encode(bytes));
              }
            : null,
        child: selectedImage != null
            ? ImageHelper.getRoundImageFrame(
                150,
                150,
                3,
                OnepieceColors.liteFancyBlue,
                150,
                Base64Helper.decode(selectedImage!))
            : ImageLazyLoader(
                key: ValueKey(character.imageUri),
                uriProvider: () => character.imageUri!,
                width: 150,
                borderWidth: 3,
                borderRadios: 150,
                fullImage: true),
      ),
      const SizedBox(height: 8),
      Text(I18nHelper.getDisplayNameFromI18n(character.name),
          style: OnepieceFonts.headerStyle.copyWith(fontSize: 20)),
      if (_editButtonVisible) ...[
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          TextButton.icon(
            onPressed: () => setState(() {
              basicInfoEditable = !basicInfoEditable;
              if (!basicInfoEditable && _basicInfoUpdated()) {
                _submitBasicInfo(context);
              }
              if (selectedImage != null && !basicInfoEditable) {
                _uploadImage(context);
              }
            }),
            icon: Icon(basicInfoEditable ? Icons.check : Icons.edit,
                size: 16, color: OnepieceColors.fancyBlue),
            label: Text(
                basicInfoEditable
                    ? AppLocalizations.of(context)!.submitForm
                    : AppLocalizations.of(context)!.editHint,
                style: const TextStyle(
                    fontSize: 13, color: OnepieceColors.fancyBlue)),
          ),
        ]),
      ],
    ]));
  }

  Widget _buildMobileBasicInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(AppLocalizations.of(context)!.basicInfo,
            style: OnepieceFonts.headerStyle.copyWith(fontSize: 16)),
        const SizedBox(height: 10),
        _mobileField(
            context,
            basicInfoEditable,
            characterNameController,
            AppLocalizations.of(context)!.name,
            'images/character_digits_icon/name.svg'),
        _mobileField(
            context,
            basicInfoEditable,
            characterBirthPlace,
            AppLocalizations.of(context)!.birthPlace,
            'images/character_digits_icon/birth_place.svg'),
        _mobileField(
            context,
            basicInfoEditable,
            characterBounty,
            AppLocalizations.of(context)!.bounty,
            'images/character_digits_icon/bounty.svg',
            isNum: true),
        _mobileField(
            context,
            basicInfoEditable,
            characterAge,
            AppLocalizations.of(context)!.age,
            'images/character_digits_icon/age.svg',
            isNum: true),
        _mobileField(
            context,
            basicInfoEditable,
            characterHeight,
            AppLocalizations.of(context)!.height,
            'images/character_digits_icon/height.svg',
            isNum: true),
        Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              ImageHelper.getTextFormFieldIcon(
                  "images/character_digits_icon/birthday.svg", true, 20),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.birthDay,
                  style: OnepieceFonts.deepBlackHintFont),
              const Spacer(),
              _monthDayDropdown<String>(basicInfoEditable, selectedMonth, 12,
                  (v) => setState(() => selectedMonth = v)),
              Text(' ${AppLocalizations.of(context)!.month} ',
                  style: OnepieceFonts.smallContentStyle),
              _monthDayDropdown<String>(basicInfoEditable, selectedDay, 31,
                  (v) => setState(() => selectedDay = v)),
              Text(' ${AppLocalizations.of(context)!.day}',
                  style: OnepieceFonts.smallContentStyle),
            ])),
        _mobileDropdown<BattleStyle>(
            basicInfoEditable,
            selectedBattleStyle,
            BattleStyle.values,
            _bsMap(context),
            AppLocalizations.of(context)!.battleStyle,
            'images/svgs/knife.svg',
            (v) => setState(() => selectedBattleStyle = v)),
        _mobileDropdown<Race>(
            basicInfoEditable,
            selectedRace,
            Race.values,
            _raceMap(context),
            AppLocalizations.of(context)!.race,
            'images/svgs/earth.svg',
            (v) => setState(() => selectedRace = v)),
        const Divider(),
      ]),
    );
  }

  Widget _buildMobileCombatInfo(BuildContext context) {
    final hakiMap = {
      Haki.busoshoku: AppLocalizations.of(context)!.busoshoku,
      Haki.haoshoku: AppLocalizations.of(context)!.haoshoku,
      Haki.kenbunshoku: AppLocalizations.of(context)!.kenbunshoku
    };
    return StatefulBuilder(builder: (context, localSetState) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(AppLocalizations.of(context)!.battleInfo,
                style: OnepieceFonts.headerStyle.copyWith(fontSize: 16)),
            if (_editButtonVisible) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: () => localSetState(() {
                  combatInfoEditable = !combatInfoEditable;
                  if (combatInfoEditable) {
                    showBaseValue = true;
                    changeValue();
                  }
                  if (!combatInfoEditable && _combatInfoUpdated()) {
                    _submitCombatInfo(context);
                  }
                }),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                      combatInfoEditable ? Icons.check_circle : Icons.edit,
                      size: 18,
                      color: OnepieceColors.fancyBlue),
                ),
              ),
            ],
            const Spacer(),
            if (fruits.isNotEmpty)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text(AppLocalizations.of(context)!.realValue,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                Transform.scale(
                  scale: 0.7,
                  child: Switch(
                    value: showBaseValue,
                    activeTrackColor:
                        OnepieceColors.fancyBlue.withValues(alpha: 0.4),
                    thumbColor:
                        WidgetStateProperty.all(OnepieceColors.fancyBlue),
                    onChanged: (v) => localSetState(() {
                      showBaseValue = v;
                      changeValue();
                    }),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                Text(AppLocalizations.of(context)!.basicValue,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
              ]),
          ]),
          const SizedBox(height: 10),
          if (combatInfoEditable)
            _mobileMultiSelect<Haki>(
                Haki.values,
                hakiMap,
                selectedHakis,
                AppLocalizations.of(context)!.hakis,
                (h) => localSetState(() {
                      if (selectedHakis.contains(h)) {
                        selectedHakis.remove(h);
                      } else {
                        selectedHakis.add(h);
                      }
                    }))
          else if (character.hakis.isNotEmpty)
            Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Wrap(
                    spacing: 4,
                    children: character.hakis
                        .map((e) => OnepieceTag.getHakiTag(e, hakiMap[e]!))
                        .toList())),
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                ImageHelper.getTextFormFieldIcon(
                    'images/svgs/user.svg', true, 20),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.combatPower,
                    style: OnepieceFonts.contentStyleBold),
                const Spacer(),
                Text('${character.score}',
                    style: OnepieceFonts.contentStyleBoldFancyBlue
                        .copyWith(fontSize: 18)),
              ])),
          _mobileField(
              context,
              combatInfoEditable,
              characterAttackController,
              AppLocalizations.of(context)!.characterAttack,
              'images/character_digits_icon/attack.svg',
              isNum: true),
          _mobileField(
              context,
              combatInfoEditable,
              characterDefenseController,
              AppLocalizations.of(context)!.characterDefense,
              'images/character_digits_icon/defense.svg',
              isNum: true),
          _mobileField(
              context,
              combatInfoEditable,
              characterBloodController,
              AppLocalizations.of(context)!.characterBlood,
              'images/character_digits_icon/blood.svg',
              isNum: true),
          _mobileField(
              context,
              combatInfoEditable,
              characterEnergyController,
              AppLocalizations.of(context)!.characterEnergy,
              'images/character_digits_icon/energy.svg',
              isNum: true),
          _mobileField(
              context,
              combatInfoEditable,
              characterSpeedController,
              AppLocalizations.of(context)!.characterSpeed,
              'images/character_digits_icon/speed.svg',
              isNum: true),
          _mobileField(
              context,
              combatInfoEditable,
              characterIntelligenceController,
              AppLocalizations.of(context)!.characterIntelligence,
              'images/character_digits_icon/intelligence.svg',
              isNum: true),
          _mobileField(
              context,
              combatInfoEditable,
              characterGroupGainController,
              AppLocalizations.of(context)!.groupGain,
              'images/character_digits_icon/group_gain.svg',
              isNum: true),
          _mobileField(
              context,
              combatInfoEditable,
              characterFruitLimitController,
              AppLocalizations.of(context)!.fruitLimit,
              'images/character_digits_icon/fruit_limit.svg',
              isNum: true),
          const Divider(),
        ]),
      );
    });
  }

  Widget _buildMobileFruits(BuildContext context) {
    final fruitMap = _fruitTypeMap(context);
    return StatefulBuilder(builder: (context, fruitSetState) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
            padding: const EdgeInsets.all(12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppLocalizations.of(context)!.devilFruit,
                  style: OnepieceFonts.headerStyle.copyWith(fontSize: 16)),
              const SizedBox(height: 10),
              if (fruits.isNotEmpty)
                ...fruits.map((f) => Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => context.goNamed('fruitDetails',
                            extra: f.id,
                            pathParameters: {
                              'name': I18nHelper.getDisplayNameFromI18n(f.name!)
                            }),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          child: Row(children: [
                            Expanded(
                                child: Text(
                                    I18nHelper.getDisplayNameFromI18n(f.name!),
                                    style: OnepieceFonts.contentStyle)),
                            OnepieceTag.getFruitTag(
                                f.fruitType!, fruitMap[f.fruitType]!),
                          ]),
                        ),
                      ),
                    )),
              if (character.maximumFruitCount > fruits.length &&
                  _editButtonVisible) ...[
                const SizedBox(height: 8),
                SizedBox(
                    height: 35,
                    child: TextFormField(
                      controller: fruitNameController,
                      decoration: InputDecoration(
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        disabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                                color: OnepieceColors.menuHoverColor)),
                        enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                                color: OnepieceColors.menuHoverColor)),
                        focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                                color: OnepieceColors.fancyGreen, width: 2.2)),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        labelText: AppLocalizations.of(context)!.search,
                      ),
                      onChanged: (v) {
                        selectedFruitId = null;
                        fruitSetState(() {});
                        if (v.isEmpty) {
                          searchingFruitList = [];
                          fruitSetState(() {});
                          return;
                        }
                        fruitFilter.name = v;
                        fruitFilter.languageCode = I18nHelper.getLanguageCode();
                        getIt<FruitDao>()
                            .list(ListFruitRequest(
                                pageSize: 5,
                                pageIndex: 1,
                                sortKeys: [],
                                fruitFilter: fruitFilter))
                            .then((r) {
                          if (mounted) {
                            fruitSetState(() => searchingFruitList = r!.fruits);
                          }
                        });
                      },
                    )),
                if (searchingFruitList.isNotEmpty)
                  Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: const BoxDecoration(
                          color: OnepieceColors.menuBackgroundColor,
                          borderRadius: BorderRadius.all(Radius.circular(8))),
                      child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: searchingFruitList.length,
                          itemBuilder: (_, i) => _buildFruitSearchResultCard(
                              context: context,
                              fruit: searchingFruitList[i],
                              fruitMap: fruitMap,
                              fruitSetState: fruitSetState))),
              ],
            ])),
      );
    });
  }

  Widget _buildFruitSearchResultCard({
    required BuildContext context,
    required FruitListView fruit,
    required Map<FruitType, String> fruitMap,
    required StateSetter fruitSetState,
  }) {
    final isSelected = selectedFruitId == fruit.id;
    final alreadyEaten = fruits.map((e) => e.id).contains(fruit.id);
    return Card(
      elevation: isSelected ? 2 : 0,
      margin: const EdgeInsets.fromLTRB(6, 6, 6, 2),
      color: isSelected
          ? OnepieceColors.liteFancyBlue.withValues(alpha: 0.65)
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected
              ? OnepieceColors.fancyBlue.withValues(alpha: 0.35)
              : OnepieceColors.menuHoverColor.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            hoverColor: OnepieceColors.liteFancyBlue,
            onTap: () {
              fruitSetState(() {
                selectedFruitId = isSelected ? null : fruit.id;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      I18nHelper.getDisplayNameFromI18n(fruit.name!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: isSelected
                          ? OnepieceFonts.contentStyleBold
                          : OnepieceFonts.contentStyle,
                    ),
                  ),
                  OnepieceTag.getFruitTag(
                      fruit.fruitType!, fruitMap[fruit.fruitType!]!),
                ],
              ),
            ),
          ),
          if (isSelected && !alreadyEaten)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: ElevatedButton(
                onPressed: () {
                  _eatFruit();
                  fruitNameController.text = '';
                  selectedFruitId = null;
                  searchingFruitList = [];
                  fruitSetState(() {});
                },
                child: Text(AppLocalizations.of(context)!.eat),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileGroups(BuildContext context) {
    final catMap = _groupCategoryMap(context);
    final posMap = _groupPositionMap(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppLocalizations.of(context)!.group,
                style: OnepieceFonts.headerStyle.copyWith(fontSize: 16)),
            if (groups.isNotEmpty) ...[
              const SizedBox(height: 6),
              ...groups.map((g) => Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => context.goNamed('groupDetails',
                          extra: g.groupId,
                          pathParameters: {
                            'name': I18nHelper.getDisplayNameFromI18n(g.name!)
                          }),
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          child: Row(children: [
                            ImageLazyLoader(
                                key: ValueKey(g.imageUri),
                                uriProvider: () => g.imageUri!,
                                width: 36,
                                borderWidth: 1.5,
                                borderRadios: 8),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Row(children: [
                                    Expanded(
                                        child: Text(
                                            I18nHelper.getDisplayNameFromI18n(
                                                g.name!),
                                            style: OnepieceFonts.contentStyle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis)),
                                    OnepieceTag.getGroupTag(
                                        g.category!, catMap[g.category!]!)
                                  ]),
                                  Text(posMap[g.position!]!,
                                      style: OnepieceFonts.smallContentStyle),
                                ])),
                          ])),
                    ),
                  )),
            ],
          ])),
    );
  }

  Widget _buildMobileBattles(BuildContext context) {
    final statusMap = {
      BattleStatus.CREATED: AppLocalizations.of(context)!.battleStatusCreated,
      BattleStatus.IN_PROGRESS:
          AppLocalizations.of(context)!.battleStatusStarted,
      BattleStatus.FINISHED: AppLocalizations.of(context)!.battleStatusFinished,
      BattleStatus.FAILED: AppLocalizations.of(context)!.battleStatusFailed
    };
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppLocalizations.of(context)!.relatedBattles,
                style: OnepieceFonts.headerStyle.copyWith(fontSize: 16)),
            const SizedBox(height: 10),
            if (battles.isEmpty)
              Text(AppLocalizations.of(context)!.empty,
                  style: OnepieceFonts.contentStyle)
            else ...[
              ...battles.take(10).map((b) {
                final ex = b.battleExecution;
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => context.goNamed('battleDetails',
                        extra: b.id, pathParameters: {'id': b.id}),
                    child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(children: [
                          _battleCharMini(
                              context, b.starter!, ex?.starterScoreBefore),
                          const SizedBox(width: 6),
                          Column(children: [
                            Text('VS',
                                style: OnepieceFonts.boldFancySmallFont
                                    .copyWith(
                                        color: OnepieceColors.fancyBlue,
                                        fontSize: 12)),
                            ex?.winnerId != null
                                ? ImageLazyLoader(
                                    key: ValueKey('w${b.id}'),
                                    uriProvider: () =>
                                        ex!.winnerId == b.starterId
                                            ? b.starter!.imageUri!
                                            : b.receiver!.imageUri!,
                                    width: 24,
                                    borderWidth: 1.5,
                                    borderRadios: 24)
                                : Icon(Icons.help_outline,
                                    size: 24, color: Colors.grey[400]),
                          ]),
                          const SizedBox(width: 6),
                          _battleCharMini(
                              context, b.receiver!, ex?.receiverScoreBefore),
                          const Spacer(),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: OnepieceColors.fancyBlue
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: Text(
                                        statusMap[ex?.battleStatus] ?? '',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: OnepieceColors.fancyBlue))),
                                if (ex?.winnerId != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                      getScoreText(character.id == ex!.winnerId
                                          ? ex.winnerScoreChange!
                                          : ex.loserScoreChange!),
                                      style: OnepieceFonts.boldFancyBlueHintFont
                                          .copyWith(fontSize: 12))
                                ],
                              ]),
                        ])),
                  ),
                );
              }),
              if (battles.length > 10)
                Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Center(
                        child: Text(
                            '${battles.length} ${AppLocalizations.of(context)!.relatedBattles}',
                            style: OnepieceFonts.smallContentStyle))),
            ],
          ])),
    );
  }

  // ── Mobile helpers ────────────────────────────────────────────────

  Widget _mobileField(BuildContext context, bool editable,
      TextEditingController ctrl, String label, String? icon,
      {bool isNum = false}) {
    final value = ctrl.text.isNotEmpty ? ctrl.text : '-';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: editable
          ? SizedBox(
              height: 35,
              child: TextFormField(
                controller: ctrl,
                keyboardType: isNum ? TextInputType.number : TextInputType.text,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  disabledBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: OnepieceColors.menuHoverColor)),
                  enabledBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: OnepieceColors.menuHoverColor)),
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: OnepieceColors.fancyGreen)),
                  prefixIcon: icon != null
                      ? ImageHelper.getTextFormFieldIcon(icon, true, 18)
                      : null,
                  labelText: label,
                ),
              ))
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                if (icon != null) ...[
                  ImageHelper.getTextFormFieldIcon(icon, true, 20),
                  const SizedBox(width: 10)
                ],
                Text(label, style: OnepieceFonts.deepBlackHintFont),
                const Spacer(),
                Text(value,
                    style: OnepieceFonts.contentStyle
                        .copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
              ]),
            ),
    );
  }

  Widget _monthDayDropdown<T>(
      bool enabled, String? value, int count, Function(String?) onChanged) {
    final dropdownValue = _normalizeBirthdayPart(value, count);
    return SizedBox(
        width: 60,
        child: DropdownButtonHideUnderline(
            child: DropdownButton2<String>(
          isExpanded: true,
          value: dropdownValue,
          onChanged: enabled ? onChanged : null,
          buttonStyleData: ButtonStyleData(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              height: 30,
              width: 60,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: OnepieceColors.liteFancyGreen)),
          menuItemStyleData: const MenuItemStyleData(height: 30),
          items: List.generate(count, (i) => (i + 1).toString())
              .map((m) => DropdownMenuItem<String>(
                  value: m,
                  child: Text(m, style: const TextStyle(fontSize: 14))))
              .toList(),
        )));
  }

  Widget _mobileDropdown<T>(
      bool enabled,
      T value,
      List<T> items,
      Map<T, String> displayMap,
      String hint,
      String? icon,
      Function(T) onChanged) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DropdownButtonHideUnderline(
            child: DropdownButton2<T>(
          isExpanded: true,
          value: value,
          hint: Row(children: [
            if (icon != null) ...[
              ImageHelper.getTextFormFieldIcon(icon, true, 18),
              const SizedBox(width: 8)
            ],
            Text(hint, style: OnepieceFonts.dropDownItemStyle)
          ]),
          onChanged: enabled
              ? (T? v) {
                  if (v != null) onChanged(v);
                }
              : null,
          buttonStyleData: ButtonStyleData(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              height: 35,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: OnepieceColors.liteFancyGreen)),
          menuItemStyleData: const MenuItemStyleData(height: 30),
          items: items
              .map((i) => DropdownMenuItem<T>(
                  value: i,
                  child: Text(displayMap[i]!,
                      style: const TextStyle(fontSize: 16))))
              .toList(),
        )));
  }

  Widget _mobileMultiSelect<T>(List<T> items, Map<T, String> displayMap,
      List<T> selected, String hint, Function(T) onChanged) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DropdownButtonHideUnderline(
            child: DropdownButton2<T>(
          isExpanded: true,
          value: selected.isNotEmpty ? selected.last : null,
          hint: Text(hint, style: OnepieceFonts.dropDownItemStyle),
          onChanged: (T? v) {},
          selectedItemBuilder: (_) => items
              .map((_) => Container(
                  alignment: Alignment.centerLeft,
                  child: Text(selected.map((e) => displayMap[e]!).join(', '),
                      style: const TextStyle(
                          fontSize: 16, overflow: TextOverflow.ellipsis),
                      maxLines: 1)))
              .toList(),
          buttonStyleData: ButtonStyleData(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              height: 35,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: OnepieceColors.liteFancyGreen)),
          menuItemStyleData: const MenuItemStyleData(height: 30),
          items: items
              .map((i) => DropdownMenuItem<T>(
                  value: i,
                  enabled: false,
                  child: StatefulBuilder(
                      builder: (_, ms) => InkWell(
                            hoverColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            onTap: () {
                              onChanged(i);
                              ms(() {});
                            },
                            child: Row(children: [
                              Icon(
                                  selected.contains(i)
                                      ? Icons.check_box_outlined
                                      : Icons.check_box_outline_blank,
                                  size: 20),
                              const SizedBox(width: 8),
                              Text(displayMap[i]!,
                                  style: const TextStyle(fontSize: 16))
                            ]),
                          ))))
              .toList(),
        )));
  }

  Widget _battleCharMini(BuildContext context, Character char, int? score) {
    return Expanded(
        child: Column(children: [
      ImageLazyLoader(
          key: ValueKey(char.imageUri),
          uriProvider: () => char.imageUri!,
          width: 32,
          borderWidth: 1.5,
          borderRadios: 32),
      const SizedBox(height: 2),
      Text(I18nHelper.getDisplayNameFromI18n(char.name),
          style: const TextStyle(fontSize: 10),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      Text(score?.toString() ?? '?',
          style: OnepieceFonts.boldFancySmallFont.copyWith(fontSize: 11)),
    ]));
  }

  // ── Shared lookup maps ────────────────────────────────────────────

  Map<FruitType, String> _fruitTypeMap(BuildContext context) => {
        FruitType.logia: AppLocalizations.of(context)!.logiaFruit,
        FruitType.zoan: AppLocalizations.of(context)!.zoanFruit,
        FruitType.ancientZoan: AppLocalizations.of(context)!.ancientZoanFruit,
        FruitType.mythicalZoan: AppLocalizations.of(context)!.mythicalZoanFruit,
        FruitType.artificialZoan:
            AppLocalizations.of(context)!.artificialZoanFruit,
        FruitType.paramecia: AppLocalizations.of(context)!.parameciaFruit,
      };
  Map<GroupCategory, String> _groupCategoryMap(BuildContext context) => {
        GroupCategory.marine: AppLocalizations.of(context)!.marine,
        GroupCategory.pirate: AppLocalizations.of(context)!.pirate,
        GroupCategory.underWorld: AppLocalizations.of(context)!.underworld,
        GroupCategory.government: AppLocalizations.of(context)!.worldGovernment,
        GroupCategory.group: AppLocalizations.of(context)!.group,
        GroupCategory.other: AppLocalizations.of(context)!.otherType,
        GroupCategory.revolutionArmy:
            AppLocalizations.of(context)!.revolutionaryArmy,
      };
  Map<GroupPosition, String> _groupPositionMap(BuildContext context) => {
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
  Map<BattleStyle, String> _bsMap(BuildContext context) => {
        BattleStyle.BODY: AppLocalizations.of(context)!.body,
        BattleStyle.SCIENCE: AppLocalizations.of(context)!.science,
        BattleStyle.KATANA: AppLocalizations.of(context)!.katana,
        BattleStyle.SHOOTER: AppLocalizations.of(context)!.shoot,
        BattleStyle.STICK: AppLocalizations.of(context)!.stick,
        BattleStyle.RIFLE: AppLocalizations.of(context)!.rifle,
        BattleStyle.SWORD: AppLocalizations.of(context)!.sword,
      };
  Map<Race, String> _raceMap(BuildContext context) => {
        Race.HUMAN: AppLocalizations.of(context)!.human,
        Race.FISH_MAN: AppLocalizations.of(context)!.fishman,
        Race.MERFOLK: AppLocalizations.of(context)!.merfolk,
        Race.GIANT: AppLocalizations.of(context)!.giant,
        Race.LONG_ARM: AppLocalizations.of(context)!.longArm,
        Race.LONG_LEG: AppLocalizations.of(context)!.longLeg,
        Race.SNAKE_NECK: AppLocalizations.of(context)!.snakeNeck,
        Race.THREE_EYE: AppLocalizations.of(context)!.threeEye,
        Race.LUNARIAN: AppLocalizations.of(context)!.lunarian,
        Race.MINK: AppLocalizations.of(context)!.mink,
        Race.WORLD_NOBEL: AppLocalizations.of(context)!.worldNobel,
        Race.DWARVES: AppLocalizations.of(context)!.dwarves,
        Race.NO_LIFE_OBJECT: AppLocalizations.of(context)!.lifeless_object,
        Race.ANIMAL: AppLocalizations.of(context)!.animal,
        Race.SOUL: AppLocalizations.of(context)!.soul,
      };

  void _submitBasicInfo(BuildContext context) {
    final router = GoRouter.of(context);
    final alertHint = AppLocalizations.of(context)!.hint;
    final showAlert = OnepieceAlert.createAlertShower(context);
    final updated = UpdateCharacterRequest(
      id: character.id,
      maximumFruitCount: character.maximumFruitCount,
      hakis: character.hakis,
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
      imageUri: character.imageUri,
      systemResource: character.systemResource,
      battleStyle: selectedBattleStyle,
      race: selectedRace,
      name: I18nHelper.getI18nFromDisplayName(
          character.name, characterNameController.text),
      dateOfBirth: _formattedBirthday(),
      birthPlace: characterBirthPlace.text,
      age: characterAge.text.isEmpty
          ? null
          : DataConverter.stringToInt(characterAge.text.trim()),
      bounty: characterBounty.text.isEmpty
          ? null
          : DataConverter.stringToInt(characterBounty.text.trim()),
      height: characterHeight.text.isEmpty
          ? null
          : DataConverter.stringToInt(characterHeight.text.trim()),
      score: character.score,
    );
    getIt<CharacterDao>().update(updated).then((v) {
      if (!mounted) return;
      showAlert(alertHint, I18nHelper.getDisplayNameFromI18n(v!.result));
      if (v.success) {
        router.goNamed('characterDetails',
            extra: character.id,
            pathParameters: {
              'name': I18nHelper.getDisplayNameFromI18n(character.name)
            });
      }
    });
  }

  void _submitCombatInfo(BuildContext context) {
    final router = GoRouter.of(context);
    final alertHint = AppLocalizations.of(context)!.hint;
    final showAlert = OnepieceAlert.createAlertShower(context);
    final updated = UpdateCharacterRequest(
      groupGain: character.groupGain,
      attack: character.attack,
      defense: character.defense,
      intelligence: character.intelligence,
      blood: character.blood,
      speed: character.speed,
      maximumFruitCount:
          DataConverter.stringToInt(characterFruitLimitController.text),
      baseGroupGain:
          DataConverter.stringToInt(characterGroupGainController.text),
      baseAttack: DataConverter.stringToInt(characterAttackController.text),
      baseDefense: DataConverter.stringToInt(characterDefenseController.text),
      baseIntelligence:
          DataConverter.stringToInt(characterIntelligenceController.text),
      baseBlood: DataConverter.stringToInt(characterBloodController.text),
      baseSpeed: DataConverter.stringToInt(characterSpeedController.text),
      energy: DataConverter.stringToInt(characterEnergyController.text),
      hakis: selectedHakis,
      id: character.id,
      race: character.race,
      score: character.score,
      battleStyle: selectedBattleStyle,
      name: character.name,
    );
    getIt<CharacterDao>().update(updated).then((v) {
      if (!mounted) return;
      showAlert(alertHint, I18nHelper.getDisplayNameFromI18n(v!.result));
      if (v.success) {
        showBaseValue = false;
        router.replaceNamed('characterDetails',
            extra: character.id,
            pathParameters: {
              'name': I18nHelper.getDisplayNameFromI18n(character.name)
            });
      }
    });
  }

  void _uploadImage(BuildContext context) {
    if (selectedImage == null) return;
    final router = GoRouter.of(context);
    final alertHint = AppLocalizations.of(context)!.hint;
    final showAlert = OnepieceAlert.createAlertShower(context);
    getIt<ImageDao>()
        .addImage(UploadImageRequest(
            type: ResourceType.CHARACTER,
            resourceId: character.id,
            image: selectedImage!))
        .then((v) {
      if (!mounted) return;
      showAlert(alertHint, I18nHelper.getDisplayNameFromI18n(v!.result));
      router.goNamed('characterDetails', extra: character.id, pathParameters: {
        'name': I18nHelper.getDisplayNameFromI18n(character.name)
      });
    });
  }

  List<Widget> _stackChildren(BuildContext context, bool isNarrow) {
    final content = isNarrow
        ? Positioned.fill(child: _buildMobileLayout(context))
        : Positioned.fill(
            child: SingleChildScrollView(
              controller: verticalController,
              scrollDirection: Axis.vertical,
              child: Center(
                child: NestedHorizontalScrollView(
                  verticalParentController: verticalController,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _getBasicInfo(context),
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: SizedBox(
                                width: dividerWidth,
                                child: const Divider(
                                    color: Colors.grey, thickness: 1))),
                        _getCombatInfo(context),
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: SizedBox(
                                width: dividerWidth,
                                child: const Divider(
                                    color: Colors.grey, thickness: 1))),
                        _getFruitSearchBar(context),
                        if (fruits.isNotEmpty)
                          Padding(
                              padding: EdgeInsets.fromLTRB(sideWidth, 8, 8, 8),
                              child: _getFruitList(context)),
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: SizedBox(
                                width: dividerWidth,
                                child: const Divider(
                                    color: Colors.grey, thickness: 1))),
                        _getGroupSearchBar(context),
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: SizedBox(
                                width: dividerWidth,
                                child: const Divider(
                                    color: Colors.grey, thickness: 1))),
                        _getBattle(context),
                        const SizedBox(height: 60),
                      ]),
                ),
              ),
            ),
          );
    return [
      content,
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
                        : () => context.goNamed('characterDetails',
                                extra: character.previousCharacter!.id,
                                pathParameters: {
                                  'name': I18nHelper.getDisplayNameFromI18n(
                                      character.previousCharacter!.name)
                                }),
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
                        : () => context.goNamed('characterDetails',
                                extra: character.nextCharacter!.id,
                                pathParameters: {
                                  'name': I18nHelper.getDisplayNameFromI18n(
                                      character.nextCharacter!.name)
                                }),
                    child: const Icon(Icons.arrow_forward),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _characterFuture,
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.data == null) {
              return const SizedBox.shrink();
            }
            if (_updateData(snapshot.data)) {
              _updateControllerData();
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow =
                    ResponsiveBreakpoints.isMobileFromConstraints(constraints);
                dividerWidth = isNarrow ? constraints.maxWidth - 30 : 860;
                sideWidth = isNarrow ? 8.0 : 50;
                return Stack(
                  children: _stackChildren(context, isNarrow),
                );
              },
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
                      splashColor: Colors.transparent,
                      onTap: () {
                        basicState(() {
                          basicInfoEditable = !basicInfoEditable;
                          if (!basicInfoEditable) {
                            if (_basicInfoUpdated()) {
                              var updatedCharacter = UpdateCharacterRequest(
                                  id: character.id,
                                  maximumFruitCount:
                                      character.maximumFruitCount,
                                  // keep combat info consistent with original data!
                                  hakis: character.hakis,
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
                                  // basic info
                                  imageUri: character.imageUri,
                                  systemResource: character.systemResource,
                                  battleStyle: selectedBattleStyle,
                                  race: selectedRace,
                                  name: I18nHelper.getI18nFromDisplayName(
                                      character.name,
                                      characterNameController.text),
                                  dateOfBirth: _formattedBirthday(),
                                  birthPlace: characterBirthPlace.text,
                                  age: characterAge.text.isEmpty
                                      ? null
                                      : DataConverter.stringToInt(
                                          characterAge.text.trim()),
                                  bounty: characterBounty.text.isEmpty
                                      ? null
                                      : DataConverter.stringToInt(
                                          characterBounty.text.trim()),
                                  height: characterHeight.text.isEmpty
                                      ? null
                                      : DataConverter.stringToInt(
                                          characterHeight.text.trim()),
                                  score: character.score);
                              final router = GoRouter.of(context);
                              final alertHint =
                                  AppLocalizations.of(context)!.hint;
                              final showAlert =
                                  OnepieceAlert.createAlertShower(context);
                              getIt<CharacterDao>()
                                  .update(updatedCharacter)
                                  .then((value) {
                                if (!mounted) return;
                                showAlert(
                                    alertHint,
                                    I18nHelper.getDisplayNameFromI18n(
                                        value!.result));
                                if (value.success) {
                                  router.goNamed('characterDetails',
                                      extra: character.id,
                                      pathParameters: {
                                        'name':
                                            I18nHelper.getDisplayNameFromI18n(
                                                character.name)
                                      });
                                }
                              });
                            }
                            if (selectedImage != null) {
                              final router2 = GoRouter.of(context);
                              final alertHint2 =
                                  AppLocalizations.of(context)!.hint;
                              final showAlert2 =
                                  OnepieceAlert.createAlertShower(context);
                              getIt<ImageDao>()
                                  .addImage(UploadImageRequest(
                                      type: ResourceType.CHARACTER,
                                      resourceId: character.id,
                                      image: selectedImage!))
                                  .then((value) {
                                if (!mounted) return;
                                showAlert2(
                                    alertHint2,
                                    I18nHelper.getDisplayNameFromI18n(
                                        value!.result));
                                router2.goNamed('characterDetails',
                                    extra: character.id,
                                    pathParameters: {
                                      'name': I18nHelper.getDisplayNameFromI18n(
                                          character.name)
                                    });
                              });
                            }
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
              child: InkWell(
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                onTap: basicInfoEditable
                    ? () async {
                        final alertTitle = AppLocalizations.of(context)!.alert;
                        final alertMsg =
                            AppLocalizations.of(context)!.imageSizeExceedsLimit;
                        final showAlert =
                            OnepieceAlert.createAlertShower(context);
                        XFile? pickedImage =
                            await OnepieceImagePicker.pickWebImage();
                        Uint8List imageInByte =
                            await pickedImage!.readAsBytes();
                        if (!ImageHelper.isValidImageSize(
                            500 * 1024, imageInByte)) {
                          showAlert(alertTitle, alertMsg);
                          return;
                        }
                        basicState(() {
                          selectedImage = Base64Helper.encode(imageInByte);
                        });
                      }
                    : null,
                child: selectedImage == null
                    ? ImageLazyLoader(
                        key: UniqueKey(),
                        uriProvider: () => character.imageUri!,
                        width: 200,
                        borderWidth: 3,
                        borderRadios: 200,
                        fullImage: true)
                    : ImageHelper.getRoundImageFrame(
                        200,
                        200,
                        3,
                        OnepieceColors.liteFancyBlue,
                        200,
                        Base64Helper.decode(selectedImage!)),
              )),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                    null),
                                false),
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
                                    null),
                                false),
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
                                    null),
                                false),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: sideWidth),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: dividerWidth < 700
                                      ? dividerWidth - sideWidth - 20
                                      : 300,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      ImageHelper.getTextFormFieldIcon(
                                          "images/character_digits_icon/birthday.svg",
                                          true,
                                          null),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        AppLocalizations.of(context)!.birthDay,
                                        style: OnepieceFonts.deepBlackHintFont,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: 3,
                                ),
                                SizedBox(
                                  width: dividerWidth < 700
                                      ? dividerWidth - sideWidth - 20
                                      : 300,
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
                                            value: _normalizeBirthdayPart(
                                                selectedMonth, 12),
                                            onChanged: basicInfoEditable
                                                ? (String? month) {
                                                    basicState(() {
                                                      selectedMonth = month;
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
                                            value: _normalizeBirthdayPart(
                                                selectedDay, 31),
                                            onChanged: basicInfoEditable
                                                ? (String? day) {
                                                    basicState(() {
                                                      selectedDay = day;
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
                            ),
                            const SizedBox(
                              height: 30,
                            ),
                            SizedBox(
                              width: dividerWidth < 700
                                  ? dividerWidth - sideWidth - 20
                                  : 300,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  ImageHelper.getTextFormFieldIcon(
                                      "images/svgs/knife.svg", true, null),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!.battleStyle,
                                    style: OnepieceFonts.deepBlackHintFont,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 3,
                            ),
                            _getBattleStyle(context, basicState),
                            const SizedBox(
                              height: 28,
                            ),
                            SizedBox(
                              width: dividerWidth < 700
                                  ? dividerWidth - sideWidth - 20
                                  : 300,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  ImageHelper.getTextFormFieldIcon(
                                      "images/svgs/earth.svg", true, 22),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!.race,
                                    style: OnepieceFonts.deepBlackHintFont,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 3,
                            ),
                            _getRace(context, basicState),
                            const SizedBox(
                              height: 28,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _getBattleStyle(BuildContext context, Function basicState) {
    Map<BattleStyle, String> battleStyleToDisplayValue = {
      BattleStyle.BODY: AppLocalizations.of(context)!.body,
      BattleStyle.SCIENCE: AppLocalizations.of(context)!.science,
      BattleStyle.KATANA: AppLocalizations.of(context)!.katana,
      BattleStyle.SHOOTER: AppLocalizations.of(context)!.shoot,
      BattleStyle.STICK: AppLocalizations.of(context)!.stick,
      BattleStyle.RIFLE: AppLocalizations.of(context)!.rifle,
      BattleStyle.SWORD: AppLocalizations.of(context)!.sword
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2(
          isExpanded: true,
          value: selectedBattleStyle,
          hint: Text(
            AppLocalizations.of(context)!.battleStyle,
            style: OnepieceFonts.dropDownItemStyle,
          ),
          onChanged: basicInfoEditable
              ? (value) {
                  basicState(() {
                    selectedBattleStyle = value as BattleStyle;
                  });
                }
              : null,
          selectedItemBuilder: (context) {
            return BattleStyle.values.map(
              (item) {
                return Container(
                  alignment: AlignmentDirectional.center,
                  child: Text(
                    battleStyleToDisplayValue[selectedBattleStyle]!,
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
            height: 30,
            width: dividerWidth < 700 ? dividerWidth - sideWidth - 20 : 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: OnepieceColors.liteFancyGreen,
            ),
          ),
          menuItemStyleData: const MenuItemStyleData(
            height: 30,
          ),
          items: BattleStyle.values.map((BattleStyle battleStyle) {
            return DropdownMenuItem<BattleStyle>(
              value: battleStyle,
              enabled: true,
              child: Text(battleStyleToDisplayValue[battleStyle]!,
                  style: OnepieceFonts.dropDownItemStyle),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _getRace(BuildContext context, Function basicState) {
    Map<Race, String> raceEnumToDisplayName = {
      Race.HUMAN: AppLocalizations.of(context)!.human,
      Race.FISH_MAN: AppLocalizations.of(context)!.fishman,
      Race.MERFOLK: AppLocalizations.of(context)!.merfolk,
      Race.GIANT: AppLocalizations.of(context)!.giant,
      Race.LONG_ARM: AppLocalizations.of(context)!.longArm,
      Race.LONG_LEG: AppLocalizations.of(context)!.longLeg,
      Race.SNAKE_NECK: AppLocalizations.of(context)!.snakeNeck,
      Race.THREE_EYE: AppLocalizations.of(context)!.threeEye,
      Race.LUNARIAN: AppLocalizations.of(context)!.lunarian,
      Race.MINK: AppLocalizations.of(context)!.mink,
      Race.WORLD_NOBEL: AppLocalizations.of(context)!.worldNobel,
      Race.DWARVES: AppLocalizations.of(context)!.dwarves,
      Race.NO_LIFE_OBJECT: AppLocalizations.of(context)!.lifeless_object,
      Race.ANIMAL: AppLocalizations.of(context)!.animal,
      Race.SOUL: AppLocalizations.of(context)!.soul,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2(
          isExpanded: true,
          value: selectedRace,
          hint: Text(
            AppLocalizations.of(context)!.race,
            style: OnepieceFonts.dropDownItemStyle,
          ),
          onChanged: basicInfoEditable
              ? (value) {
                  basicState(() {
                    selectedRace = value as Race;
                  });
                }
              : null,
          selectedItemBuilder: (context) {
            return Race.values.map(
              (item) {
                return Container(
                  alignment: AlignmentDirectional.center,
                  child: Text(
                    raceEnumToDisplayName[selectedRace]!,
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
            height: 30,
            width: dividerWidth < 700 ? dividerWidth - sideWidth - 20 : 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: OnepieceColors.liteFancyGreen,
            ),
          ),
          menuItemStyleData: const MenuItemStyleData(
            height: 30,
          ),
          items: Race.values.map((Race race) {
            return DropdownMenuItem<Race>(
              value: race,
              enabled: true,
              child: Text(raceEnumToDisplayName[race]!,
                  style: OnepieceFonts.dropDownItemStyle),
            );
          }).toList(),
        ),
      ),
    );
  }

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
            padding: const EdgeInsets.fromLTRB(0, 3, 0, 0),
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
                              hoverColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              onTap: () {
                                combatState(() {
                                  combatInfoEditable = !combatInfoEditable;
                                  if (combatInfoEditable) {
                                    showBaseValue = true;
                                    changeValue();
                                  }
                                  if (!combatInfoEditable) {
                                    if (_combatInfoUpdated()) {
                                      var updatedCharacter =
                                          UpdateCharacterRequest(
                                        // combat info update
                                        groupGain: character.groupGain,
                                        attack: character.attack,
                                        defense: character.defense,
                                        intelligence: character.intelligence,
                                        blood: character.blood,
                                        speed: character.speed,
                                        maximumFruitCount:
                                            DataConverter.stringToInt(
                                                characterFruitLimitController
                                                    .text),
                                        baseGroupGain:
                                            DataConverter.stringToInt(
                                                characterGroupGainController
                                                    .text),
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
                                        hakis: selectedHakis,
                                        /* basic info keep consistent with original
                                       value, will probably updated on backend */
                                        id: character.id,
                                        race: character.race,
                                        score: character.score,
                                        battleStyle: selectedBattleStyle,
                                        name: character.name,
                                      );
                                      final router3 = GoRouter.of(context);
                                      final alertHint3 =
                                          AppLocalizations.of(context)!.hint;
                                      final showAlert3 =
                                          OnepieceAlert.createAlertShower(
                                              context);
                                      getIt<CharacterDao>()
                                          .update(updatedCharacter)
                                          .then((value) {
                                        if (!mounted) return;
                                        showAlert3(
                                            alertHint3,
                                            I18nHelper.getDisplayNameFromI18n(
                                                value!.result));
                                        if (value.success) {
                                          showBaseValue = false;
                                          router3.replaceNamed(
                                              'characterDetails',
                                              extra: character.id,
                                              pathParameters: {
                                                'name': I18nHelper
                                                    .getDisplayNameFromI18n(
                                                        character.name)
                                              });
                                        }
                                      });
                                    }
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
                        width: 80,
                        height: 26,
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
                                  'images/svgs/user.svg', true, 20)
                              : ImageHelper.getTextFormFieldIcon(
                                  'images/svgs/fruit_total.svg', true, 20),
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
          SizedBox(
            width: dividerWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (character.hakis.isNotEmpty && !combatInfoEditable)
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
                if (combatInfoEditable)
                  Padding(
                    padding: EdgeInsets.fromLTRB(sideWidth, 0, 0, 0),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton2(
                        isExpanded: true,
                        value:
                            selectedHakis.isEmpty ? null : selectedHakis.last,
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
                                      .map((selectedType) {
                                        return hakiEnumValueToDisplayValue[
                                            selectedType];
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
                          width: 200,
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
                                  hoverColor: Colors.transparent,
                                  splashColor: Colors.transparent,
                                  onTap: () {
                                    isSelected
                                        ? selectedHakis.remove(haki)
                                        : selectedHakis.add(haki);
                                    debugPrint("$selectedHakis");
                                    // //This rebuilds the StatefulWidget to update the button's text
                                    combatState(() {});
                                    //This rebuilds the dropdownMenu Widget to update the check mark
                                    menuSetState(() {});
                                  },
                                  child: Container(
                                    height: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 3.0),
                                    child: Row(
                                      children: [
                                        if (isSelected)
                                          const Icon(Icons.check_box_outlined)
                                        else
                                          const Icon(
                                              Icons.check_box_outline_blank),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            hakiEnumValueToDisplayValue[haki]!,
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
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(sideWidth, 0, sideWidth, 0),
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
              ],
            ),
          ),
          const SizedBox(
            height: 30,
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
                            1500,
                            ImageHelper.getTextFormFieldIcon(
                                'images/character_digits_icon/attack.svg',
                                true,
                                21),
                            true),
                        DigitTextFormField(
                            context,
                            combatInfoEditable,
                            characterDefenseController,
                            AppLocalizations.of(context)!.characterDefense,
                            10,
                            1400,
                            ImageHelper.getTextFormFieldIcon(
                                'images/character_digits_icon/defense.svg',
                                true,
                                22),
                            true),
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
                                22),
                            true),
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
                                null),
                            true),
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
                            characterSpeedController,
                            AppLocalizations.of(context)!.characterSpeed,
                            10,
                            200,
                            ImageHelper.getTextFormFieldIcon(
                                'images/character_digits_icon/speed.svg',
                                true,
                                22),
                            true),
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
                                20),
                            true),
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
                                20),
                            true),
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
                                null),
                            true),
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
                        borderSide: BorderSide(
                            color: OnepieceColors.fancyGreen, width: 2.2)),
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
                      (value) {
                        fruitSetState(() {
                          searchingFruitList = value!.fruits;
                        });
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
                    width: dividerWidth - sideWidth - 16,
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
                        return _buildFruitSearchResultCard(
                            context: context,
                            fruit: fruit,
                            fruitMap: fruitTypeToDisplayValue,
                            fruitSetState: fruitSetState);
                      },
                    ),
                  ),
                ),
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
      width: dividerWidth - sideWidth - 16,
      decoration: const BoxDecoration(
        color: OnepieceColors.menuBackgroundColor,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: fruits.length,
        itemBuilder: (context, index) {
          var fruit = fruits[index];
          return Card(
            elevation: 0,
            margin: const EdgeInsets.fromLTRB(8, 6, 8, 2),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: OnepieceColors.menuHoverColor.withValues(alpha: 0.45),
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              hoverColor: OnepieceColors.liteFancyBlue,
              onTap: () {
                context.goNamed('fruitDetails',
                    extra: fruit.id,
                    pathParameters: {
                      'name': I18nHelper.getDisplayNameFromI18n(fruit.name!)
                    });
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        I18nHelper.getDisplayNameFromI18n(fruit.name!),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: OnepieceFonts.contentStyle,
                      ),
                    ),
                    OnepieceTag.getFruitTag(
                      fruit.fruitType!,
                      fruitTypeToDisplayValue[fruit.fruitType!]!,
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
        Padding(
          padding: EdgeInsets.fromLTRB(sideWidth, 8, 8, 8),
          child: _getGroupList(context),
        ),
      ],
    );
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
        width: dividerWidth - sideWidth - 16,
        decoration: const BoxDecoration(
          color: OnepieceColors.menuBackgroundColor,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        constraints: const BoxConstraints(maxHeight: 300),
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
                                child: ImageLazyLoader(
                                    key: UniqueKey(),
                                    uriProvider: () => currentGroup.imageUri!,
                                    width: 50,
                                    borderWidth: 2,
                                    borderRadios: 10)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  I18nHelper.getDisplayNameFromI18n(
                                      currentGroup.name!),
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
                          child: ImageLazyLoader(
                              key: UniqueKey(),
                              uriProvider: () => entry.value.starter!.imageUri!,
                              width: 40,
                              borderWidth: 1.5,
                              borderRadios: 40),
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
                          child: ImageLazyLoader(
                              key: UniqueKey(),
                              uriProvider: () =>
                                  entry.value.receiver!.imageUri!,
                              width: 40,
                              borderWidth: 1.5,
                              borderRadios: 40),
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
                      child: ImageLazyLoader(
                          key: UniqueKey(),
                          uriProvider: () =>
                              entry.value.battleExecution!.winnerId ==
                                      entry.value.starterId
                                  ? entry.value.starter!.imageUri!
                                  : entry.value.receiver!.imageUri!,
                          width: 40,
                          borderWidth: 1.5,
                          borderRadios: 40),
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

  bool _basicInfoUpdated() {
    return character.race.toString() != selectedRace.toString() ||
        character.battleStyle.toString() != selectedBattleStyle.toString() ||
        I18nHelper.getDisplayNameFromI18n(character.name) !=
            characterNameController.text.toString() ||
        character.birthPlace.toString() !=
            characterBirthPlace.text.toString() ||
        _normalizeStoredBirthday(character.dateOfBirth) !=
            _formattedBirthday() ||
        !intValueEquals(character.bounty, characterBounty.text.toString()) ||
        !intValueEquals(character.height, characterHeight.text.toString()) ||
        !intValueEquals(character.age, characterAge.text.toString());
  }

  bool intValueEquals(int? value, String text) {
    if (value == null) {
      if (text.isEmpty) {
        return true;
      }
      return false;
    } else {
      return value.toString() == text;
    }
  }

  bool _combatInfoUpdated() {
    return character.groupGain.toString() !=
            characterGroupGainController.text ||
        character.maximumFruitCount.toString() !=
            characterFruitLimitController.text ||
        character.attack.toString() != characterAttackController.text ||
        character.defense.toString() != characterDefenseController.text ||
        character.intelligence.toString() !=
            characterIntelligenceController.text ||
        character.speed.toString() != characterSpeedController.text ||
        character.blood.toString() != characterBloodController.text ||
        character.energy.toString() != characterEnergyController.text;
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
