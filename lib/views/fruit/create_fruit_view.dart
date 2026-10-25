import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:openapi/api.dart';
import '../../components/creation_form_card.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import 'create_fruit_controller.dart';
import '../../utils/data_converter.dart';
import '../../utils/i18n_helper.dart';
import '../../utils/random_string_generator.dart';

GetIt getIt = GetIt.instance;

class CreateFruitView extends StatefulWidget {
  const CreateFruitView({Key? key}) : super(key: key);

  @override
  State<CreateFruitView> createState() => _CreateFruitViewState();
}

class _CreateFruitViewState extends State<CreateFruitView> {
  final ScrollController _pageScrollController = ScrollController();
  final CreateFruitController _controller = CreateFruitController();
  TextEditingController fruitNameEnController = TextEditingController(text: "");
  TextEditingController fruitNameChController = TextEditingController(text: "");
  TextEditingController attackSlopeController = TextEditingController(text: "");
  TextEditingController attackInterceptController =
      TextEditingController(text: "");
  TextEditingController defenseSlopeController =
      TextEditingController(text: "");
  TextEditingController defenseInterceptController =
      TextEditingController(text: "");
  TextEditingController intelligenceSlopeController =
      TextEditingController(text: "");
  TextEditingController intelligenceInterceptController =
      TextEditingController(text: "");
  TextEditingController bloodSlopeController = TextEditingController(text: '');
  TextEditingController bloodInterceptController =
      TextEditingController(text: '');
  TextEditingController speedSlopeController = TextEditingController(text: '');
  TextEditingController speedInterceptController =
      TextEditingController(text: '');
  TextEditingController groupGainSlopeController =
      TextEditingController(text: '');
  TextEditingController groupGainInterceptController =
      TextEditingController(text: '');
  TextEditingController fruitEnergyConsumeController =
      TextEditingController(text: "");

  List<TextEditingController> fruitControllerList() {
    return <TextEditingController>[
      fruitNameEnController,
      fruitNameChController,
      attackSlopeController,
      attackInterceptController,
      bloodInterceptController,
      bloodSlopeController,
      groupGainInterceptController,
      groupGainSlopeController,
      intelligenceInterceptController,
      intelligenceSlopeController,
      speedInterceptController,
      speedSlopeController,
      defenseInterceptController,
      defenseSlopeController,
      fruitEnergyConsumeController,
    ];
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _controller.dispose();
    for (final controller in fruitControllerList()) {
      controller.dispose();
    }
    super.dispose();
  }

  FruitType selectedFruitType = FruitType.paramecia;

  double dividerWidth = 800;
  final _formKey = GlobalKey<FormState>();

  Widget _buildResponsiveLayout(BuildContext context, bool isWide) {
    final localizations = AppLocalizations.of(context)!;
    final basicCard = CreationFormCard(
      icon: Icons.auto_awesome_rounded,
      title: localizations.basicInfo,
      badge: localizations.required,
      child: Column(
        children: [
          _buildStringField(context, fruitNameChController,
              '${localizations.name} (CN)', true),
          if (getIt<User>().loginRole == UserRole.NIKA)
            _buildStringField(context, fruitNameEnController,
                '${localizations.name} (EN)', true),
          _getDropDownList(context),
        ],
      ),
    );

    final battleCard = CreationFormCard(
      icon: Icons.insights_rounded,
      title: localizations.battleInfo,
      badge: localizations.required,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(localizations.statFormulaHint,
                style: OnepieceFonts.smallContentStyle),
          ),
          const SizedBox(height: 20),
          _buildDigitField(context, fruitEnergyConsumeController,
              localizations.energyConsume, 1, 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final pairWidth = constraints.maxWidth >= 480
                  ? (constraints.maxWidth - 14) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _buildStatPair(
                      context,
                      attackSlopeController,
                      attackInterceptController,
                      localizations.attackStrengthen,
                      .8,
                      1.5,
                      -100,
                      300,
                      pairWidth),
                  _buildStatPair(
                      context,
                      defenseSlopeController,
                      defenseInterceptController,
                      localizations.defenseStrengthen,
                      .8,
                      1.5,
                      -100,
                      800,
                      pairWidth),
                  _buildStatPair(
                      context,
                      bloodSlopeController,
                      bloodInterceptController,
                      localizations.bloodStrengthen,
                      .8,
                      1.5,
                      -1000,
                      3000,
                      pairWidth),
                  _buildStatPair(
                      context,
                      intelligenceSlopeController,
                      intelligenceInterceptController,
                      localizations.intelligenceStrengthen,
                      .8,
                      2,
                      -30,
                      30,
                      pairWidth),
                  _buildStatPair(
                      context,
                      speedSlopeController,
                      speedInterceptController,
                      localizations.speedStrengthen,
                      .8,
                      3,
                      -10,
                      30,
                      pairWidth),
                  _buildStatPair(
                      context,
                      groupGainSlopeController,
                      groupGainInterceptController,
                      localizations.groupStrengthen,
                      .8,
                      2,
                      -10,
                      30,
                      pairWidth),
                ],
              );
            },
          ),
        ],
      ),
    );

    return SingleChildScrollView(
      controller: _pageScrollController,
      padding: EdgeInsets.fromLTRB(isWide ? 28 : 12, 18, isWide ? 28 : 12, 100),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                CreationPageHeader(
                  icon: Icons.spa_rounded,
                  title: localizations.createDevilFruit,
                ),
                const SizedBox(height: 18),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 280, child: basicCard),
                      const SizedBox(width: 18),
                      Expanded(child: battleCard),
                    ],
                  )
                else ...[
                  basicCard,
                  const SizedBox(height: 14),
                  battleCard,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStringField(BuildContext context, TextEditingController ctrl,
      String label, bool required) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        textInputAction: TextInputAction.next,
        validator: (value) =>
            required && (value == null || value.trim().isEmpty)
                ? AppLocalizations.of(context)!.requiredField
                : null,
        decoration: _fieldDecoration(label),
      ),
    );
  }

  Widget _buildDigitField(BuildContext context, TextEditingController ctrl,
      String hint, int min, int max) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        validator: (value) => _validateNumber(context, value, min, max, false),
        decoration: _fieldDecoration(hint, hint: '$min – $max'),
      ),
    );
  }

  Widget _buildStatPair(
      BuildContext context,
      TextEditingController slope,
      TextEditingController intercept,
      String label,
      double slopeMin,
      double slopeMax,
      int interceptMin,
      int interceptMax,
      double width) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: OnepieceColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: OnepieceFonts.deepBlackHintFont
                    .copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: TextFormField(
                  controller: slope,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      _validateNumber(context, value, slopeMin, slopeMax, true),
                  decoration: _fieldDecoration(
                      AppLocalizations.of(context)!.statMultiplier,
                      hint: '$slopeMin – $slopeMax'),
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: TextFormField(
                  controller: intercept,
                  keyboardType:
                      const TextInputType.numberWithOptions(signed: true),
                  textInputAction: TextInputAction.next,
                  validator: (value) => _validateNumber(
                      context, value, interceptMin, interceptMax, false),
                  decoration: _fieldDecoration(
                      AppLocalizations.of(context)!.statAdjustment,
                      hint: '$interceptMin – $interceptMax'),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _validateNumber(BuildContext context, String? value, num min, num max,
      bool allowDecimal) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context)!.requiredField;
    }
    final number = allowDecimal
        ? double.tryParse(value.trim())
        : int.tryParse(value.trim());
    if (number == null) {
      return allowDecimal
          ? AppLocalizations.of(context)!.fieldMustBeDigit
          : AppLocalizations.of(context)!.fieldMustBeInt;
    }
    if (number < min || number > max) {
      return AppLocalizations.of(context)!.valueExceedsLimit;
    }
    return null;
  }

  InputDecoration _fieldDecoration(String label, {String? hint}) {
    return creationFieldDecoration(label, hint: hint);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 820;
        return Stack(
          children: [
            ColoredBox(
              color: OnepieceColors.surface,
              child: _buildResponsiveLayout(context, isWide),
            ),
            _getFootBar(context)
          ],
        );
      },
    );
  }

  Widget _getDropDownList(BuildContext context) {
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
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2(
          isExpanded: true,
          value: selectedFruitType,
          hint: Text(
            AppLocalizations.of(context)!.fruitType,
            style: OnepieceFonts.dropDownItemStyle,
          ),
          onChanged: (value) {
            setState(() {
              selectedFruitType = value!;
            });
          },
          selectedItemBuilder: (context) {
            return FruitType.values.map(
              (item) {
                return Container(
                  alignment: AlignmentDirectional.center,
                  child: Text(
                    fruitTypeToDisplayValue[selectedFruitType]!,
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
              height: 46,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: OnepieceColors.surface,
                border: Border.all(color: OnepieceColors.separator),
              )),
          menuItemStyleData: const MenuItemStyleData(
            height: 35,
          ),
          items: FruitType.values.map((FruitType fruitType) {
            return DropdownMenuItem<FruitType>(
              value: fruitType,
              child: Text(
                fruitTypeToDisplayValue[fruitType]!,
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

  Widget _getFootBar(BuildContext context) {
    return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: OnepieceColors.separator)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(AppLocalizations.of(context)!.clearForm),
                  onPressed: () {
                    setState(() {
                      fruitControllerList().forEach((element) {
                        element.clear();
                      });
                    });
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(132, 46),
                    backgroundColor: OnepieceColors.fancyBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 19),
                  onPressed: () {
                    final isValid = validateCreationForm(_formKey);
                    if (!isValid) {
                      return;
                    }
                    CreateFruitRequest addFruitRequest = CreateFruitRequest(
                      name: RandomStringGenerator.generateI18n(
                          fruitNameEnController.text,
                          fruitNameChController.text),
                      fruitType: selectedFruitType,
                      attackSlope: DataConverter.stringToDouble(
                          attackSlopeController.text.trim()),
                      attackIntercept: DataConverter.stringToInt(
                          attackInterceptController.text.trim()),
                      defenseSlope: DataConverter.stringToDouble(
                          defenseSlopeController.text.trim()),
                      defenseIntercept: DataConverter.stringToInt(
                          defenseInterceptController.text.trim()),
                      bloodSlope: DataConverter.stringToDouble(
                          bloodSlopeController.text.trim()),
                      bloodIntercept: DataConverter.stringToInt(
                          bloodInterceptController.text.trim()),
                      groupGainSlope: DataConverter.stringToDouble(
                          groupGainSlopeController.text.trim()),
                      groupGainIntercept: DataConverter.stringToInt(
                          groupGainInterceptController.text.trim()),
                      speedSlope: DataConverter.stringToDouble(
                          speedSlopeController.text.trim()),
                      speedIntercept: DataConverter.stringToInt(
                          speedInterceptController.text.trim()),
                      intelligenceSlope: DataConverter.stringToDouble(
                          intelligenceSlopeController.text.trim()),
                      intelligenceIntercept: DataConverter.stringToInt(
                          intelligenceInterceptController.text.trim()),
                      energyConsume: DataConverter.stringToInt(
                          fruitEnergyConsumeController.text),
                    );

                    final router = GoRouter.of(context);
                    _controller.add(addFruitRequest).then((value) {
                      if (!mounted) return;
                      router.goNamed('fruitDetails',
                          extra: value!.id,
                          pathParameters: {
                            'name':
                                I18nHelper.getDisplayNameFromI18n(value.name!)
                          });
                    });
                  },
                  label: Text(AppLocalizations.of(context)!.submitForm),
                ),
              ],
            ),
          ),
        ));
  }
}
