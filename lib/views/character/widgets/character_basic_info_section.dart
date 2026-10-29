import 'dart:typed_data';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import '../../../components/resource_detail_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openapi/api.dart';

import '../../../components/digit_text_form_field.dart';
import '../../../components/image_lazy_loader.dart';
import '../../../components/string_text_form_field.dart';
import '../../../constants/onepiece_colors.dart';
import '../../../constants/onepiece_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../popup/onepiece_alert.dart';
import '../../../utils/base64_helper.dart';
import '../../../utils/data_converter.dart';
import '../../../utils/i18n_helper.dart';
import '../../../utils/image_helper.dart';
import '../../../utils/onepiece_image_picker.dart';
import '../character_detail_controller.dart';
import 'character_detail_fields.dart';

/// The "basic info" section of the character detail screen: the avatar (with
/// upload while editing), name, birth place, bounty, age, height, birthday,
/// battle style and race. Owns its own form state (the five text controllers,
/// the battle-style / race / birthday selections, the edit flag and the picked
/// image) and submits through [CharacterDetailController], then navigates to
/// reload.
class CharacterBasicInfoSection extends StatefulWidget {
  final CharacterFullView character;
  final bool editButtonVisible;
  final CharacterDetailController controller;
  final bool isNarrow;
  final double dividerWidth;
  final double sideWidth;

  const CharacterBasicInfoSection({
    super.key,
    required this.character,
    required this.editButtonVisible,
    required this.controller,
    required this.isNarrow,
    this.dividerWidth = 860,
    this.sideWidth = 50,
  });

  @override
  State<CharacterBasicInfoSection> createState() =>
      _CharacterBasicInfoSectionState();
}

class _CharacterBasicInfoSectionState extends State<CharacterBasicInfoSection> {
  final characterNameController = TextEditingController();
  final characterAge = TextEditingController();
  final characterHeight = TextEditingController();
  final characterBirthPlace = TextEditingController();
  final characterBounty = TextEditingController();

  BattleStyle selectedBattleStyle = BattleStyle.BODY;
  Race selectedRace = Race.HUMAN;
  String? selectedDay;
  String? selectedMonth;
  bool basicInfoEditable = false;
  String? selectedImage;
  final _basicFormKey = GlobalKey<FormState>();

  CharacterFullView get character => widget.character;

  Locale? _nameLocale;
  final Map<String, String> _nameDrafts = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_nameLocale?.languageCode == locale.languageCode) return;
    if (_nameLocale != null) {
      _nameDrafts[_nameLocale!.languageCode] = characterNameController.text;
    }
    _nameLocale = locale;
    characterNameController.text = _nameDrafts[locale.languageCode] ??
        I18nHelper.getEditableNameFromI18n(character.name, locale);
  }

  @override
  void initState() {
    super.initState();
    _syncFromCharacter();
  }

  @override
  void didUpdateWidget(covariant CharacterBasicInfoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.character.id != widget.character.id) {
      _nameDrafts.clear();
      basicInfoEditable = false;
      selectedImage = null;
      _syncFromCharacter();
    }
  }

  void _syncFromCharacter() {
    characterNameController.text = I18nHelper.getEditableNameFromI18n(
        character.name, _nameLocale ?? const Locale('zh', 'CN'));
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
  }

  @override
  void dispose() {
    characterNameController.dispose();
    characterAge.dispose();
    characterHeight.dispose();
    characterBirthPlace.dispose();
    characterBounty.dispose();
    super.dispose();
  }

  // ── Birthday helpers ───────────────────────────────────────────────

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

  // ── Lookup maps ────────────────────────────────────────────────────

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

  // ── Validation ─────────────────────────────────────────────────────

  bool _basicInfoUpdated() {
    return character.race.toString() != selectedRace.toString() ||
        character.battleStyle.toString() != selectedBattleStyle.toString() ||
        I18nHelper.getEditableNameFromI18n(
                character.name, Localizations.localeOf(context)) !=
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

  // ── Submit / upload ────────────────────────────────────────────────

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
    widget.controller.updateCharacter(updated).then((v) {
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

  void _uploadImage(BuildContext context) {
    if (selectedImage == null) return;
    final router = GoRouter.of(context);
    final alertHint = AppLocalizations.of(context)!.hint;
    final showAlert = OnepieceAlert.createAlertShower(context);
    widget.controller
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

  @override
  Widget build(BuildContext context) =>
      widget.isNarrow ? _buildMobile(context) : _buildDesktop(context);

  // ── Mobile ─────────────────────────────────────────────────────────

  Widget _buildMobile(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMobileHeader(context),
        const SizedBox(height: 12),
        _buildMobileBasicInfo(context),
      ],
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    return Row(children: [
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
                72,
                72,
                1,
                OnepieceColors.liteFancyBlue,
                72,
                Base64Helper.decode(selectedImage!))
            : ImageLazyLoader(
                key: ValueKey(character.imageUri),
                uriProvider: () => character.imageUri ?? '',
                width: 72,
                borderWidth: 1,
                borderRadios: 72,
                fullImage: true),
      ),
      const SizedBox(width: 14),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(I18nHelper.getDisplayNameFromI18n(character.name),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: OnepieceFonts.headerStyle.copyWith(fontSize: 20)),
        if (widget.editButtonVisible) ...[
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
        ],
      ])),
    ]);
  }

  Widget _buildMobileBasicInfo(BuildContext context) {
    if (!basicInfoEditable) {
      final loc = AppLocalizations.of(context)!;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(loc.basicInfo,
              style: OnepieceFonts.headerStyle.copyWith(fontSize: 16)),
          const SizedBox(height: 12),
          DetailFieldGrid(compact: true, fields: [
            DetailValue(loc.bounty, characterBounty.text,
                compact: true,
                valueStyle: OnepieceFonts.bountyStyle.copyWith(fontSize: 15)),
            DetailValue(loc.birthPlace, characterBirthPlace.text,
                compact: true),
            DetailValue(loc.age, characterAge.text, compact: true),
            DetailValue(loc.height, characterHeight.text, compact: true),
            DetailValue(loc.birthDay, character.dateOfBirth ?? '',
                compact: true),
            DetailValue(loc.race, _raceMap(context)[selectedRace] ?? '',
                compact: true),
            DetailValue(
                loc.battleStyle, _bsMap(context)[selectedBattleStyle] ?? '',
                compact: true),
          ]),
        ]),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(AppLocalizations.of(context)!.basicInfo,
            style: OnepieceFonts.headerStyle.copyWith(fontSize: 16)),
        const SizedBox(height: 10),
        mobileField(
            context,
            basicInfoEditable,
            characterNameController,
            AppLocalizations.of(context)!.name,
            'images/character_digits_icon/name.svg'),
        mobileField(
            context,
            basicInfoEditable,
            characterBirthPlace,
            AppLocalizations.of(context)!.birthPlace,
            'images/character_digits_icon/birth_place.svg'),
        mobileField(
            context,
            basicInfoEditable,
            characterBounty,
            AppLocalizations.of(context)!.bounty,
            'images/character_digits_icon/bounty.svg',
            isNum: true),
        mobileField(
            context,
            basicInfoEditable,
            characterAge,
            AppLocalizations.of(context)!.age,
            'images/character_digits_icon/age.svg',
            isNum: true),
        mobileField(
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
      ]),
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

  // ── Desktop ────────────────────────────────────────────────────────

  Widget _buildDesktop(BuildContext context) {
    if (basicInfoEditable) {
      return DetailEditor(child: _buildDesktopEditor(context));
    }
    final loc = AppLocalizations.of(context)!;
    return DetailSection(
        compact: true,
        title: loc.basicInfo,
        action: widget.editButtonVisible
            ? DetailEditButton(
                onPressed: () => setState(() => basicInfoEditable = true))
            : null,
        child: DetailFieldGrid(compact: true, fields: [
          DetailValue(loc.name, characterNameController.text, compact: true),
          DetailValue(loc.age, characterAge.text, compact: true),
          DetailValue(loc.height, characterHeight.text, compact: true),
          DetailValue(loc.birthPlace, characterBirthPlace.text, compact: true),
          DetailValue(loc.birthDay, character.dateOfBirth ?? '', compact: true),
          DetailValue(loc.race, _raceMap(context)[selectedRace] ?? '',
              compact: true),
          DetailValue(
              loc.battleStyle, _bsMap(context)[selectedBattleStyle] ?? '',
              compact: true),
          DetailValue(loc.bounty, characterBounty.text,
              compact: true,
              valueStyle: OnepieceFonts.bountyStyle.copyWith(fontSize: 16)),
        ]));
  }

  Widget _buildDesktopEditor(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(widget.sideWidth, 8, 8, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.basicInfo,
                style: OnepieceFonts.headerStyle,
              ),
              const SizedBox(width: 15),
              if (widget.editButtonVisible)
                Tooltip(
                  message: basicInfoEditable
                      ? AppLocalizations.of(context)!.submitForm
                      : AppLocalizations.of(context)!.editHint,
                  child: InkWell(
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    onTap: () {
                      setState(() {
                        basicInfoEditable = !basicInfoEditable;
                        if (!basicInfoEditable) {
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
            padding: EdgeInsets.fromLTRB(widget.sideWidth, 8, 8, 8),
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
                      Uint8List imageInByte = await pickedImage!.readAsBytes();
                      if (!ImageHelper.isValidImageSize(
                          500 * 1024, imageInByte)) {
                        showAlert(alertTitle, alertMsg);
                        return;
                      }
                      setState(() {
                        selectedImage = Base64Helper.encode(imageInByte);
                      });
                    }
                  : null,
              child: selectedImage == null
                  ? ImageLazyLoader(
                      uriProvider: () => character.imageUri ?? '',
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
                width: widget.dividerWidth,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: widget.sideWidth),
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
                      padding: EdgeInsets.only(right: widget.sideWidth),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: widget.dividerWidth < 700
                                    ? widget.dividerWidth -
                                        widget.sideWidth -
                                        20
                                    : 300,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    ImageHelper.getTextFormFieldIcon(
                                        "images/character_digits_icon/birthday.svg",
                                        true,
                                        null),
                                    const SizedBox(width: 10),
                                    Text(
                                      AppLocalizations.of(context)!.birthDay,
                                      style: OnepieceFonts.deepBlackHintFont,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 3),
                              SizedBox(
                                width: widget.dividerWidth < 700
                                    ? widget.dividerWidth -
                                        widget.sideWidth -
                                        20
                                    : 300,
                                height: 35,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
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
                                                  setState(() {
                                                    selectedMonth = month;
                                                  });
                                                }
                                              : null,
                                          buttonStyleData: ButtonStyleData(
                                            padding: const EdgeInsets.symmetric(
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
                                                    (int index) =>
                                                        (index + 1).toString())
                                                .map((String month) {
                                              return Container(
                                                alignment:
                                                    AlignmentDirectional.center,
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
                                                  setState(() {
                                                    selectedDay = day;
                                                  });
                                                }
                                              : null,
                                          buttonStyleData: ButtonStyleData(
                                            padding: const EdgeInsets.symmetric(
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
                                                    (int index) =>
                                                        (index + 1).toString())
                                                .map((String day) {
                                              return Container(
                                                alignment:
                                                    AlignmentDirectional.center,
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
                          const SizedBox(height: 30),
                          SizedBox(
                            width: widget.dividerWidth < 700
                                ? widget.dividerWidth - widget.sideWidth - 20
                                : 300,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                ImageHelper.getTextFormFieldIcon(
                                    "images/svgs/knife.svg", true, null),
                                const SizedBox(width: 10),
                                Text(
                                  AppLocalizations.of(context)!.battleStyle,
                                  style: OnepieceFonts.deepBlackHintFont,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 3),
                          _getBattleStyle(context),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: widget.dividerWidth < 700
                                ? widget.dividerWidth - widget.sideWidth - 20
                                : 300,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                ImageHelper.getTextFormFieldIcon(
                                    "images/svgs/earth.svg", true, 22),
                                const SizedBox(width: 10),
                                Text(
                                  AppLocalizations.of(context)!.race,
                                  style: OnepieceFonts.deepBlackHintFont,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 3),
                          _getRace(context),
                          const SizedBox(height: 28),
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
  }

  Widget _getBattleStyle(BuildContext context) {
    final battleStyleToDisplayValue = _bsMap(context);
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
                  setState(() {
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
            width: widget.dividerWidth < 700
                ? widget.dividerWidth - widget.sideWidth - 20
                : 300,
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

  Widget _getRace(BuildContext context) {
    final raceEnumToDisplayName = _raceMap(context);
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
                  setState(() {
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
            width: widget.dividerWidth < 700
                ? widget.dividerWidth - widget.sideWidth - 20
                : 300,
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
}
