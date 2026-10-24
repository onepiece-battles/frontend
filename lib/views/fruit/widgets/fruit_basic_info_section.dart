import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openapi/api.dart';

import '../../../components/string_text_form_field.dart';
import '../../../constants/onepiece_colors.dart';
import '../../../constants/onepiece_fonts.dart';
import '../../../constants/onepiece_tag.dart';
import '../../../l10n/app_localizations.dart';
import '../../../popup/onepiece_alert.dart';
import '../../../utils/i18n_helper.dart';
import '../../../utils/image_helper.dart';
import '../fruit_detail_controller.dart';
import 'fruit_detail_fields.dart';

/// The "basic info" section of the fruit detail screen: the fruit name and its
/// type. Owns its own form state (name controller, selected type, edit flag)
/// and submits through [FruitDetailController].
///
/// Submit sends the FULL [UpdateFruitRequest]: name / fruitType from this
/// section, and the combat coefficients copied from the loaded [fruit]. This
/// matches the mobile layout's original behaviour and fixes the desktop bug
/// where a partial submit nulled the other columns (see BUG-003).
class FruitBasicInfoSection extends StatefulWidget {
  final FruitFullView fruit;
  final bool editButtonVisible;
  final FruitDetailController controller;
  final bool isNarrow;
  final double sideWidth;

  const FruitBasicInfoSection({
    super.key,
    required this.fruit,
    required this.editButtonVisible,
    required this.controller,
    required this.isNarrow,
    this.sideWidth = 50,
  });

  @override
  State<FruitBasicInfoSection> createState() => _FruitBasicInfoSectionState();
}

class _FruitBasicInfoSectionState extends State<FruitBasicInfoSection> {
  final nameController = TextEditingController();
  late FruitType selectedFruitType;
  bool basicInfoEditable = false;

  FruitFullView get fruit => widget.fruit;

  @override
  void initState() {
    super.initState();
    _syncFromFruit();
  }

  @override
  void didUpdateWidget(covariant FruitBasicInfoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fruit.id != widget.fruit.id) {
      basicInfoEditable = false;
      _syncFromFruit();
    }
  }

  void _syncFromFruit() {
    nameController.text = I18nHelper.getDisplayNameFromI18n(fruit.name!);
    selectedFruitType = fruit.fruitType!;
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Map<FruitType, String> _typeMap(BuildContext context) => {
        FruitType.logia: AppLocalizations.of(context)!.logiaFruit,
        FruitType.zoan: AppLocalizations.of(context)!.zoanFruit,
        FruitType.ancientZoan: AppLocalizations.of(context)!.ancientZoanFruit,
        FruitType.mythicalZoan: AppLocalizations.of(context)!.mythicalZoanFruit,
        FruitType.artificialZoan:
            AppLocalizations.of(context)!.artificialZoanFruit,
        FruitType.paramecia: AppLocalizations.of(context)!.parameciaFruit,
      };

  void _submit(BuildContext context) {
    final router = GoRouter.of(context);
    final alertHint = AppLocalizations.of(context)!.hint;
    final showAlert = OnepieceAlert.createAlertShower(context);
    final updated = UpdateFruitRequest(
      id: fruit.id,
      // basic info from this section
      name: I18nHelper.getI18nFromDisplayName(fruit.name!, nameController.text),
      fruitType: selectedFruitType,
      // combat info preserved from the loaded fruit
      energyConsume: fruit.energyConsume,
      attackSlope: fruit.attackSlope,
      attackIntercept: fruit.attackIntercept,
      defenseSlope: fruit.defenseSlope,
      defenseIntercept: fruit.defenseIntercept,
      intelligenceSlope: fruit.intelligenceSlope,
      intelligenceIntercept: fruit.intelligenceIntercept,
      bloodSlope: fruit.bloodSlope,
      bloodIntercept: fruit.bloodIntercept,
      speedSlope: fruit.speedSlope,
      speedIntercept: fruit.speedIntercept,
      groupGainSlope: fruit.groupGainSlope,
      groupGainIntercept: fruit.groupGainIntercept,
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
      basicInfoEditable = !basicInfoEditable;
      if (!basicInfoEditable) {
        _submit(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) =>
      widget.isNarrow ? _buildMobile(context) : _buildDesktop(context);

  // ── Mobile ─────────────────────────────────────────────────────────

  Widget _buildMobile(BuildContext context) {
    final typeMap = _typeMap(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
            child: Column(children: [
          const SizedBox(height: 8),
          Text(I18nHelper.getDisplayNameFromI18n(fruit.name),
              style: OnepieceFonts.headerStyle.copyWith(fontSize: 20)),
          const SizedBox(height: 4),
          OnepieceTag.getFruitTag(fruit.fruitType!, typeMap[fruit.fruitType]!),
          if (widget.editButtonVisible) ...[
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              TextButton.icon(
                onPressed: _toggleEdit,
                icon: Icon(basicInfoEditable ? Icons.check : Icons.edit,
                    size: 14, color: OnepieceColors.fancyBlue),
                label: Text(
                    basicInfoEditable
                        ? AppLocalizations.of(context)!.submitForm
                        : AppLocalizations.of(context)!.editHint,
                    style: const TextStyle(
                        fontSize: 11, color: OnepieceColors.fancyBlue)),
              ),
            ]),
          ],
        ])),
        const SizedBox(height: 16),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppLocalizations.of(context)!.basicInfo,
                  style: OnepieceFonts.headerStyle.copyWith(fontSize: 16)),
              const SizedBox(height: 10),
              mobileField(context, basicInfoEditable, nameController,
                  AppLocalizations.of(context)!.name, null),
              mobileDropdown<FruitType>(
                  basicInfoEditable,
                  selectedFruitType,
                  FruitType.values,
                  typeMap,
                  AppLocalizations.of(context)!.fruitType,
                  null,
                  (v) => setState(() => selectedFruitType = v)),
              const Divider(),
            ])),
      ],
    );
  }

  // ── Desktop ────────────────────────────────────────────────────────

  Widget _buildDesktop(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.sideWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.basicInfo,
                  style: OnepieceFonts.headerStyle),
              const SizedBox(width: 15),
              if (widget.editButtonVisible)
                Tooltip(
                  message: basicInfoEditable
                      ? AppLocalizations.of(context)!.submitForm
                      : AppLocalizations.of(context)!.editHint,
                  child: InkWell(
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    onTap: _toggleEdit,
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
          const SizedBox(height: 15),
          StringTextFormField(
              context,
              basicInfoEditable,
              nameController,
              AppLocalizations.of(context)!.name,
              10,
              ImageHelper.getTextFormFieldIcon(
                  'images/character_digits_icon/name.svg', true, 25),
              true),
          Padding(
            padding: const EdgeInsets.only(bottom: 3.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ImageHelper.getTextFormFieldIcon(
                    'images/svgs/type.svg', true, 22),
                const SizedBox(width: 10),
                SizedBox(
                  width: 300,
                  child: Text(
                    AppLocalizations.of(context)!.category,
                    style: OnepieceFonts.deepBlackHintFont,
                  ),
                ),
              ],
            ),
          ),
          _desktopTypeDropdown(context),
        ],
      ),
    );
  }

  Widget _desktopTypeDropdown(BuildContext context) {
    final typeMap = _typeMap(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2(
          isExpanded: true,
          value: selectedFruitType,
          hint: Text(
            AppLocalizations.of(context)!.groupCategory,
            style: OnepieceFonts.dropDownItemStyle,
          ),
          onChanged: !basicInfoEditable
              ? null
              : (value) {
                  setState(() {
                    selectedFruitType = value! as FruitType;
                  });
                },
          selectedItemBuilder: (context) {
            return FruitType.values.map(
              (item) {
                return Container(
                  alignment: AlignmentDirectional.center,
                  child: Text(
                    typeMap[selectedFruitType]!,
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
              width: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: OnepieceColors.surface,
              )),
          menuItemStyleData: const MenuItemStyleData(
            height: 35,
          ),
          items: FruitType.values.map((FruitType fruitType) {
            return DropdownMenuItem<FruitType>(
              value: fruitType,
              child: Text(
                typeMap[fruitType]!,
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
}
