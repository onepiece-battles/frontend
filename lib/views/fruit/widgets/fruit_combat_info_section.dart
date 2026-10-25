import 'package:flutter/material.dart';
import '../../../components/resource_detail_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:openapi/api.dart';

import '../../../components/digit_text_form_field.dart';
import '../../../components/fruit_digit_text_form_field.dart';
import '../../../constants/onepiece_colors.dart';
import '../../../constants/onepiece_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../popup/onepiece_alert.dart';
import '../../../utils/data_converter.dart';
import '../../../utils/i18n_helper.dart';
import '../../../utils/image_helper.dart';
import '../fruit_detail_controller.dart';
import 'fruit_detail_fields.dart';

/// The "combat info" (battle info) section of the fruit detail screen: energy
/// consumption and the six strengthen coefficients (slope × x + intercept for
/// attack / defense / blood / intelligence / speed / group-gain). Owns its own
/// form state and submits through [FruitDetailController].
///
/// Submit sends the FULL [UpdateFruitRequest]: the combat fields from this
/// section's controllers, and name / fruitType copied from the loaded [fruit].
/// This both matches the mobile layout's original behaviour and fixes the
/// desktop bug where a partial submit nulled the other columns (see BUG-003).
class FruitCombatInfoSection extends StatefulWidget {
  final FruitFullView fruit;
  final bool editButtonVisible;
  final FruitDetailController controller;
  final bool isNarrow;
  final double sideWidth;

  const FruitCombatInfoSection({
    super.key,
    required this.fruit,
    required this.editButtonVisible,
    required this.controller,
    required this.isNarrow,
    this.sideWidth = 50,
  });

  @override
  State<FruitCombatInfoSection> createState() => _FruitCombatInfoSectionState();
}

class _FruitCombatInfoSectionState extends State<FruitCombatInfoSection> {
  final energyConsumeController = TextEditingController();
  final attackSlopeController = TextEditingController();
  final attackInterceptController = TextEditingController();
  final defenseSlopeController = TextEditingController();
  final defenseInterceptController = TextEditingController();
  final intelligenceSlopeController = TextEditingController();
  final intelligenceInterceptController = TextEditingController();
  final bloodSlopeController = TextEditingController();
  final bloodInterceptController = TextEditingController();
  final speedSlopeController = TextEditingController();
  final speedInterceptController = TextEditingController();
  final groupGainSlopeController = TextEditingController();
  final groupGainInterceptController = TextEditingController();

  bool combatInfoEditable = false;
  final _battleFormKey = GlobalKey<FormState>();

  FruitFullView get fruit => widget.fruit;

  @override
  void initState() {
    super.initState();
    _syncFromFruit();
  }

  @override
  void didUpdateWidget(covariant FruitCombatInfoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fruit.id != widget.fruit.id) {
      combatInfoEditable = false;
      _syncFromFruit();
    }
  }

  void _syncFromFruit() {
    energyConsumeController.text = fruit.energyConsume!.toString();
    attackSlopeController.text = fruit.attackSlope.toString();
    attackInterceptController.text = fruit.attackIntercept.toString();
    defenseSlopeController.text = fruit.defenseSlope.toString();
    defenseInterceptController.text = fruit.defenseIntercept.toString();
    bloodSlopeController.text = fruit.bloodSlope.toString();
    bloodInterceptController.text = fruit.bloodIntercept.toString();
    speedSlopeController.text = fruit.speedSlope.toString();
    speedInterceptController.text = fruit.speedIntercept.toString();
    intelligenceSlopeController.text = fruit.intelligenceSlope.toString();
    intelligenceInterceptController.text =
        fruit.intelligenceIntercept.toString();
    groupGainSlopeController.text = fruit.groupGainSlope.toString();
    groupGainInterceptController.text = fruit.groupGainIntercept.toString();
  }

  @override
  void dispose() {
    energyConsumeController.dispose();
    attackSlopeController.dispose();
    attackInterceptController.dispose();
    defenseSlopeController.dispose();
    defenseInterceptController.dispose();
    intelligenceSlopeController.dispose();
    intelligenceInterceptController.dispose();
    bloodSlopeController.dispose();
    bloodInterceptController.dispose();
    speedSlopeController.dispose();
    speedInterceptController.dispose();
    groupGainSlopeController.dispose();
    groupGainInterceptController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final router = GoRouter.of(context);
    final alertHint = AppLocalizations.of(context)!.hint;
    final showAlert = OnepieceAlert.createAlertShower(context);
    final updated = UpdateFruitRequest(
      id: fruit.id,
      // basic info preserved from the loaded fruit
      name: fruit.name,
      fruitType: fruit.fruitType,
      // combat info from this section
      energyConsume: DataConverter.stringToInt(energyConsumeController.text),
      attackSlope: DataConverter.stringToDouble(attackSlopeController.text),
      attackIntercept:
          DataConverter.stringToInt(attackInterceptController.text),
      defenseSlope: DataConverter.stringToDouble(defenseSlopeController.text),
      defenseIntercept:
          DataConverter.stringToInt(defenseInterceptController.text),
      intelligenceSlope:
          DataConverter.stringToDouble(intelligenceSlopeController.text),
      intelligenceIntercept:
          DataConverter.stringToInt(intelligenceInterceptController.text),
      bloodSlope: DataConverter.stringToDouble(bloodSlopeController.text),
      bloodIntercept: DataConverter.stringToInt(bloodInterceptController.text),
      speedSlope: DataConverter.stringToDouble(speedSlopeController.text),
      speedIntercept: DataConverter.stringToInt(speedInterceptController.text),
      groupGainSlope:
          DataConverter.stringToDouble(groupGainSlopeController.text),
      groupGainIntercept:
          DataConverter.stringToInt(groupGainInterceptController.text),
    );
    widget.controller.update(updated).then((v) {
      if (!mounted) return;
      showAlert(alertHint, I18nHelper.getDisplayNameFromI18n(v!.result));
      if (v.success) {
        router.goNamed('fruitDetails', extra: fruit.id, pathParameters: {
          'name': I18nHelper.getDisplayNameFromI18n(fruit.name)
        });
      }
    });
  }

  void _toggleEdit() {
    setState(() {
      combatInfoEditable = !combatInfoEditable;
      if (!combatInfoEditable) {
        _submit(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) =>
      widget.isNarrow ? _buildMobile(context) : _buildDesktop(context);

  // ── Mobile ─────────────────────────────────────────────────────────

  Widget _buildMobile(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(AppLocalizations.of(context)!.battleInfo,
                style: OnepieceFonts.headerStyle.copyWith(fontSize: 16)),
            const Spacer(),
            if (widget.editButtonVisible)
              TextButton.icon(
                onPressed: _toggleEdit,
                icon: Icon(combatInfoEditable ? Icons.check : Icons.edit,
                    size: 14, color: OnepieceColors.fancyBlue),
                label: Text(
                    combatInfoEditable
                        ? AppLocalizations.of(context)!.submitForm
                        : AppLocalizations.of(context)!.editHint,
                    style: const TextStyle(
                        fontSize: 11, color: OnepieceColors.fancyBlue)),
              ),
          ]),
          const SizedBox(height: 10),
          mobileField(context, combatInfoEditable, energyConsumeController,
              AppLocalizations.of(context)!.energyConsume, null,
              isNum: true),
          mobileStatPair(
              context,
              combatInfoEditable,
              attackSlopeController,
              attackInterceptController,
              AppLocalizations.of(context)!.characterAttack,
              'images/character_digits_icon/attack.svg'),
          mobileStatPair(
              context,
              combatInfoEditable,
              defenseSlopeController,
              defenseInterceptController,
              AppLocalizations.of(context)!.characterDefense,
              'images/character_digits_icon/defense.svg'),
          mobileStatPair(
              context,
              combatInfoEditable,
              bloodSlopeController,
              bloodInterceptController,
              AppLocalizations.of(context)!.characterBlood,
              'images/character_digits_icon/blood.svg'),
          mobileStatPair(
              context,
              combatInfoEditable,
              intelligenceSlopeController,
              intelligenceInterceptController,
              AppLocalizations.of(context)!.characterIntelligence,
              'images/character_digits_icon/intelligence.svg'),
          mobileStatPair(
              context,
              combatInfoEditable,
              speedSlopeController,
              speedInterceptController,
              AppLocalizations.of(context)!.characterSpeed,
              'images/character_digits_icon/speed.svg'),
          mobileStatPair(
              context,
              combatInfoEditable,
              groupGainSlopeController,
              groupGainInterceptController,
              AppLocalizations.of(context)!.groupGain,
              'images/character_digits_icon/group_gain.svg'),
          const Divider(),
        ]));
  }

  // ── Desktop ────────────────────────────────────────────────────────

  Widget _buildDesktop(BuildContext context) {
    if (combatInfoEditable) {
      return DetailEditor(width: 960, child: _buildDesktopEditor(context));
    }
    final loc = AppLocalizations.of(context)!;
    String formula(
        TextEditingController slope, TextEditingController intercept) {
      final addition = num.tryParse(intercept.text) ?? 0;
      return '${slope.text} × ${loc.basicValue} ${addition < 0 ? '−' : '+'} ${addition.abs()}';
    }

    return DetailSection(
        title: loc.battleInfo,
        action: widget.editButtonVisible
            ? DetailEditButton(onPressed: _toggleEdit)
            : null,
        child: DetailFieldGrid(fields: [
          DetailValue(loc.energyConsume, energyConsumeController.text),
          DetailValue(loc.attackStrengthen,
              formula(attackSlopeController, attackInterceptController)),
          DetailValue(loc.defenseStrengthen,
              formula(defenseSlopeController, defenseInterceptController)),
          DetailValue(loc.bloodStrengthen,
              formula(bloodSlopeController, bloodInterceptController)),
          DetailValue(
              loc.intelligenceStrengthen,
              formula(intelligenceSlopeController,
                  intelligenceInterceptController)),
          DetailValue(loc.speedStrengthen,
              formula(speedSlopeController, speedInterceptController)),
          DetailValue(loc.groupStrengthen,
              formula(groupGainSlopeController, groupGainInterceptController)),
        ]));
  }

  Widget _buildDesktopEditor(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.sideWidth),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.battleInfo,
                  style: OnepieceFonts.headerStyle),
              const SizedBox(width: 15),
              if (widget.editButtonVisible)
                Tooltip(
                  message: combatInfoEditable
                      ? AppLocalizations.of(context)!.submitForm
                      : AppLocalizations.of(context)!.editHint,
                  child: InkWell(
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    onTap: _toggleEdit,
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
        ),
        const SizedBox(height: 15),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.sideWidth),
          child: Form(
            key: _battleFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 300,
                  child: DigitTextFormField(
                      context,
                      combatInfoEditable,
                      energyConsumeController,
                      AppLocalizations.of(context)!.energyConsume,
                      1,
                      10,
                      ImageHelper.getTextFormFieldIcon(
                          'images/character_digits_icon/energy.svg', true, 25),
                      true),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Column(
                      children: [
                        FruitDigitTextFormField(
                            context,
                            combatInfoEditable,
                            attackSlopeController,
                            attackInterceptController,
                            AppLocalizations.of(context)!.attackStrengthen,
                            0.8,
                            1.5,
                            -100,
                            300,
                            ImageHelper.getTextFormFieldIcon(
                                'images/character_digits_icon/attack.svg',
                                true,
                                25)),
                        FruitDigitTextFormField(
                            context,
                            combatInfoEditable,
                            defenseSlopeController,
                            defenseInterceptController,
                            AppLocalizations.of(context)!.defenseStrengthen,
                            0.8,
                            1.5,
                            -100,
                            800,
                            ImageHelper.getTextFormFieldIcon(
                                'images/character_digits_icon/defense.svg',
                                true,
                                25)),
                        FruitDigitTextFormField(
                            context,
                            combatInfoEditable,
                            bloodSlopeController,
                            bloodInterceptController,
                            AppLocalizations.of(context)!.bloodStrengthen,
                            0.8,
                            1.5,
                            -1000,
                            3000,
                            ImageHelper.getTextFormFieldIcon(
                                'images/character_digits_icon/blood.svg',
                                true,
                                25)),
                      ],
                    ),
                    Column(
                      children: [
                        FruitDigitTextFormField(
                            context,
                            combatInfoEditable,
                            intelligenceSlopeController,
                            intelligenceInterceptController,
                            AppLocalizations.of(context)!
                                .intelligenceStrengthen,
                            0.8,
                            2,
                            -30,
                            30,
                            ImageHelper.getTextFormFieldIcon(
                                'images/character_digits_icon/intelligence.svg',
                                true,
                                25)),
                        FruitDigitTextFormField(
                            context,
                            combatInfoEditable,
                            speedSlopeController,
                            speedInterceptController,
                            AppLocalizations.of(context)!.speedStrengthen,
                            0.8,
                            3,
                            -10,
                            30,
                            ImageHelper.getTextFormFieldIcon(
                                'images/character_digits_icon/speed.svg',
                                true,
                                25)),
                        FruitDigitTextFormField(
                            context,
                            combatInfoEditable,
                            groupGainSlopeController,
                            groupGainInterceptController,
                            AppLocalizations.of(context)!.groupStrengthen,
                            0.8,
                            2,
                            -10,
                            30,
                            ImageHelper.getTextFormFieldIcon(
                                'images/character_digits_icon/group_gain.svg',
                                true,
                                25)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}
