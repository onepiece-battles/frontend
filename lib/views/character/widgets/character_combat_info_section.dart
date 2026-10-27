import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import '../../../components/resource_detail_layout.dart';
import '../../../components/resource_flip_card.dart';
import 'package:go_router/go_router.dart';
import 'package:openapi/api.dart';

import '../../../components/digit_text_form_field.dart';
import '../../../constants/onepiece_colors.dart';
import '../../../constants/onepiece_fonts.dart';
import '../../../constants/onepiece_tag.dart';
import '../../../l10n/app_localizations.dart';
import '../../../popup/onepiece_alert.dart';
import '../../../utils/data_converter.dart';
import '../../../utils/i18n_helper.dart';
import '../../../utils/image_helper.dart';
import '../character_detail_controller.dart';
import 'character_detail_fields.dart';

/// The "combat info" (battle info) section of the character detail screen:
/// haki, combat power, and the eight combat stats, with an edit mode and a
/// base-value / real-value toggle. Owns its own form state (the eight stat
/// controllers, haki selection, edit flag, base-value flag) and submits through
/// [CharacterDetailController], then navigates to reload the character.
class CharacterCombatInfoSection extends StatefulWidget {
  final CharacterFullView character;
  final bool editButtonVisible;
  final CharacterDetailController controller;
  final bool isNarrow;
  final double dividerWidth;
  final double sideWidth;

  const CharacterCombatInfoSection({
    super.key,
    required this.character,
    required this.editButtonVisible,
    required this.controller,
    required this.isNarrow,
    this.dividerWidth = 860,
    this.sideWidth = 50,
  });

  @override
  State<CharacterCombatInfoSection> createState() =>
      _CharacterCombatInfoSectionState();
}

class _CharacterCombatInfoSectionState
    extends State<CharacterCombatInfoSection> {
  final characterFruitLimitController = TextEditingController();
  final characterGroupGainController = TextEditingController();
  final characterAttackController = TextEditingController();
  final characterDefenseController = TextEditingController();
  final characterIntelligenceController = TextEditingController();
  final characterBloodController = TextEditingController();
  final characterSpeedController = TextEditingController();
  final characterEnergyController = TextEditingController();

  List<Haki> selectedHakis = [];
  bool combatInfoEditable = false;
  bool showBaseValue = false;
  final _digitFormKey = GlobalKey<FormState>();

  CharacterFullView get character => widget.character;

  @override
  void initState() {
    super.initState();
    _syncFromCharacter();
  }

  @override
  void didUpdateWidget(covariant CharacterCombatInfoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.character.id != widget.character.id) {
      combatInfoEditable = false;
      showBaseValue = false;
      _syncFromCharacter();
    }
  }

  void _syncFromCharacter() {
    selectedHakis = character.hakis.toList(growable: true);
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
  void dispose() {
    characterFruitLimitController.dispose();
    characterGroupGainController.dispose();
    characterAttackController.dispose();
    characterDefenseController.dispose();
    characterIntelligenceController.dispose();
    characterBloodController.dispose();
    characterSpeedController.dispose();
    characterEnergyController.dispose();
    super.dispose();
  }

  Map<Haki, String> _hakiMap(BuildContext context) => {
        Haki.busoshoku: AppLocalizations.of(context)!.busoshoku,
        Haki.haoshoku: AppLocalizations.of(context)!.haoshoku,
        Haki.kenbunshoku: AppLocalizations.of(context)!.kenbunshoku,
      };

  ResourceStatBar _bar(
      String label, TextEditingController c, num min, num max) {
    final v = int.tryParse(c.text) ?? 0;
    return ResourceStatBar(label, c.text, statFraction(v, min, max));
  }

  /// The five core combat stats as bars (reads the controllers, so it honours
  /// the base/real toggle), and the three remaining stats as meta chips.
  List<Widget> _statViews(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return [
      ResourceStatBars(labelWidth: 96, gap: 12, bars: [
        _bar(loc.characterAttack, characterAttackController, 10, 1500),
        _bar(loc.characterDefense, characterDefenseController, 10, 1400),
        _bar(loc.characterIntelligence, characterIntelligenceController, 70,
            260),
        _bar(loc.characterBlood, characterBloodController, 100, 10000),
        _bar(loc.characterSpeed, characterSpeedController, 10, 200),
      ]),
      const SizedBox(height: 16),
      ResourceMetaChips(chips: [
        ResourceMetaChip(loc.groupGain, characterGroupGainController.text),
        ResourceMetaChip(loc.fruitLimit, characterFruitLimitController.text),
        ResourceMetaChip(loc.characterEnergy, characterEnergyController.text),
      ]),
    ];
  }

  /// Switch the editable stat fields between the character's base values and
  /// their real (buffed) values.
  void changeValue() {
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
      battleStyle: character.battleStyle,
      name: character.name,
    );
    widget.controller.updateCharacter(updated).then((v) {
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

  @override
  Widget build(BuildContext context) =>
      widget.isNarrow ? _buildMobile(context) : _buildDesktop(context);

  // ── Mobile ─────────────────────────────────────────────────────────

  Widget _buildMobile(BuildContext context) {
    final hakiMap = _hakiMap(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(AppLocalizations.of(context)!.battleInfo,
              style: OnepieceFonts.headerStyle.copyWith(fontSize: 16)),
          if (widget.editButtonVisible) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: () => setState(() {
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
          if (character.fruits.isNotEmpty)
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
                  thumbColor: WidgetStateProperty.all(OnepieceColors.fancyBlue),
                  onChanged: (v) => setState(() {
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
              (h) => setState(() {
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
        if (combatInfoEditable) ...[
          mobileField(
              context,
              combatInfoEditable,
              characterAttackController,
              AppLocalizations.of(context)!.characterAttack,
              'images/character_digits_icon/attack.svg',
              isNum: true),
          mobileField(
              context,
              combatInfoEditable,
              characterDefenseController,
              AppLocalizations.of(context)!.characterDefense,
              'images/character_digits_icon/defense.svg',
              isNum: true),
          mobileField(
              context,
              combatInfoEditable,
              characterBloodController,
              AppLocalizations.of(context)!.characterBlood,
              'images/character_digits_icon/blood.svg',
              isNum: true),
          mobileField(
              context,
              combatInfoEditable,
              characterEnergyController,
              AppLocalizations.of(context)!.characterEnergy,
              'images/character_digits_icon/energy.svg',
              isNum: true),
          mobileField(
              context,
              combatInfoEditable,
              characterSpeedController,
              AppLocalizations.of(context)!.characterSpeed,
              'images/character_digits_icon/speed.svg',
              isNum: true),
          mobileField(
              context,
              combatInfoEditable,
              characterIntelligenceController,
              AppLocalizations.of(context)!.characterIntelligence,
              'images/character_digits_icon/intelligence.svg',
              isNum: true),
          mobileField(
              context,
              combatInfoEditable,
              characterGroupGainController,
              AppLocalizations.of(context)!.groupGain,
              'images/character_digits_icon/group_gain.svg',
              isNum: true),
          mobileField(
              context,
              combatInfoEditable,
              characterFruitLimitController,
              AppLocalizations.of(context)!.fruitLimit,
              'images/character_digits_icon/fruit_limit.svg',
              isNum: true),
        ] else
          ..._statViews(context),
        const SizedBox(height: 8),
        const Divider(),
      ]),
    );
  }

  // ── Desktop ────────────────────────────────────────────────────────

  Widget _buildDesktop(BuildContext context) {
    if (combatInfoEditable) {
      return DetailEditor(child: _buildDesktopEditor(context));
    }
    final loc = AppLocalizations.of(context)!;
    return DetailSection(
        title: loc.battleInfo,
        action: Wrap(spacing: 8, children: [
          if (character.fruits.isNotEmpty)
            TextButton(
                onPressed: () => setState(() {
                      showBaseValue = !showBaseValue;
                      changeValue();
                    }),
                child: Text(showBaseValue ? loc.realValue : loc.basicValue)),
          if (widget.editButtonVisible)
            DetailEditButton(
                onPressed: () => setState(() {
                      combatInfoEditable = true;
                      showBaseValue = true;
                      changeValue();
                    })),
        ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ..._statViews(context),
          if (selectedHakis.isNotEmpty) ...[
            const SizedBox(height: 24),
            Wrap(
                spacing: 6,
                runSpacing: 6,
                children: selectedHakis
                    .map((haki) => OnepieceTag.getHakiTag(
                        haki, _hakiMap(context)[haki] ?? ''))
                    .toList())
          ],
        ]));
  }

  Widget _buildDesktopEditor(BuildContext context) {
    final hakiEnumValueToDisplayValue = _hakiMap(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 3, 0, 0),
          child: SizedBox(
            width: widget.dividerWidth,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.sideWidth),
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
                      const SizedBox(width: 15),
                      if (widget.editButtonVisible)
                        Tooltip(
                          message: combatInfoEditable
                              ? AppLocalizations.of(context)!.submitForm
                              : AppLocalizations.of(context)!.editHint,
                          child: InkWell(
                            hoverColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            onTap: () {
                              setState(() {
                                combatInfoEditable = !combatInfoEditable;
                                if (combatInfoEditable) {
                                  showBaseValue = true;
                                  changeValue();
                                }
                                if (!combatInfoEditable) {
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
                  if (character.fruits.isNotEmpty)
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
                          backgroundColor: OnepieceColors.menuSelectedTileColor,
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
                        onChanged: (b) => setState(() {
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
          width: widget.dividerWidth,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (character.hakis.isNotEmpty && !combatInfoEditable)
                Padding(
                  padding: EdgeInsets.fromLTRB(widget.sideWidth, 0, 0, 0),
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
                  padding: EdgeInsets.fromLTRB(widget.sideWidth, 0, 0, 0),
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
                                  // Rebuild this section to update the button text
                                  setState(() {});
                                  // Rebuild the menu item to update the check mark
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
                padding: EdgeInsets.fromLTRB(
                    widget.sideWidth, 0, widget.sideWidth, 0),
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
        const SizedBox(height: 30),
        Form(
          key: _digitFormKey,
          child: SizedBox(
            width: widget.dividerWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: widget.sideWidth),
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
                  padding: EdgeInsets.only(right: widget.sideWidth),
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
  }
}
