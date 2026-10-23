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
import 'package:openapi/api.dart';
import '../../l10n/app_localizations.dart';
import '../../popup/onepiece_alert.dart';
import '../../utils/base64_helper.dart';
import '../../utils/data_converter.dart';
import '../../utils/i18n_helper.dart';
import '../../utils/image_helper.dart';
import '../../utils/onepiece_image_picker.dart';
import '../../utils/permission_check.dart';
import '../../utils/nested_scroll_helper.dart';
import '../../utils/responsive_breakpoints.dart';
import 'character_detail_controller.dart';
import 'widgets/character_battles_section.dart';
import 'widgets/character_groups_section.dart';
import 'widgets/character_fruits_section.dart';

GetIt getIt = GetIt.instance;

class CharacterDetail extends StatefulWidget {
  final String characterId;

  const CharacterDetail({super.key, required this.characterId});

  @override
  State<CharacterDetail> createState() => _CharacterDetailState();
}

class _CharacterDetailState extends State<CharacterDetail> {
  final CharacterDetailController _controller = CharacterDetailController();
  ScrollController verticalController = ScrollController();

  @override
  void dispose() {
    verticalController.dispose();
    _controller.dispose();
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

  List<Haki> selectedHakis = [];
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
  bool showBaseValue = false;

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
    return _controller.getCharacter(
        GetCharacterFullViewRequest(characterId: widget.characterId));
  }

  void _refreshCharacterData() {
    _preparedCharacterId = null;
    _characterFuture = _loadData();
  }

  bool _updateData(CharacterFullView characterFullView) {
    if (_preparedCharacterId == characterFullView.id) return false;
    _preparedCharacterId = characterFullView.id;
    character = characterFullView;
    battles = characterFullView.battles;
    fruits = characterFullView.fruits;
    groups = characterFullView.groups;
    selectedHakis = characterFullView.hakis.toList(growable: true);
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
          CharacterFruitsSection(
              character: character,
              editButtonVisible: _editButtonVisible,
              controller: _controller,
              onFruitEaten: () {
                setState(() {
                  _refreshCharacterData();
                });
              },
              isNarrow: true),
          if (fruits.isNotEmpty) const SizedBox(height: 12),
          CharacterGroupsSection(groups: groups, isNarrow: true),
          const SizedBox(height: 12),
          CharacterBattlesSection(character: character, isNarrow: true),
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

  // ── Shared lookup maps ────────────────────────────────────────────

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
    _controller.updateCharacter(updated).then((v) {
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
    _controller.updateCharacter(updated).then((v) {
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
    _controller
        .uploadImage(UploadImageRequest(
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
                        CharacterFruitsSection(
                            character: character,
                            editButtonVisible: _editButtonVisible,
                            controller: _controller,
                            onFruitEaten: () {
                              setState(() {
                                _refreshCharacterData();
                              });
                            },
                            isNarrow: false,
                            dividerWidth: dividerWidth,
                            sideWidth: sideWidth),
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: SizedBox(
                                width: dividerWidth,
                                child: const Divider(
                                    color: Colors.grey, thickness: 1))),
                        CharacterGroupsSection(
                            groups: groups,
                            isNarrow: false,
                            dividerWidth: dividerWidth,
                            sideWidth: sideWidth),
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: SizedBox(
                                width: dividerWidth,
                                child: const Divider(
                                    color: Colors.grey, thickness: 1))),
                        CharacterBattlesSection(
                            character: character,
                            isNarrow: false,
                            dividerWidth: dividerWidth,
                            sideWidth: sideWidth),
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
                            // Shared with the mobile layout; see _submitBasicInfo
                            // / _uploadImage (both route through the controller).
                            if (_basicInfoUpdated()) {
                              _submitBasicInfo(context);
                            }
                            if (selectedImage != null) {
                              _uploadImage(context);
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
                                    // Shared with the mobile layout; see
                                    // _submitCombatInfo (routes through the controller).
                                    if (_combatInfoUpdated()) {
                                      _submitCombatInfo(context);
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

}
