import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/repository/fruit_dao.dart';
import 'package:one_piece_battles_flutter/utils/data_converter.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:openapi/api.dart';
import '../../components/digit_text_form_field.dart';
import '../../components/fruit_digit_text_form_field.dart';
import '../../components/image_lazy_loader.dart';
import '../../components/string_text_form_field.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../constants/onepiece_tag.dart';
import '../../popup/onepiece_alert.dart';
import '../../utils/image_helper.dart';
import '../../utils/nested_scroll_helper.dart';
import '../../utils/permission_check.dart';
import '../../utils/responsive_breakpoints.dart';

GetIt getIt = GetIt.instance;

class FruitDetailView extends StatefulWidget {
  final String fruitId;

  const FruitDetailView({super.key, required this.fruitId});

  @override
  State<FruitDetailView> createState() => _FruitDetailViewState();
}

class _FruitDetailViewState extends State<FruitDetailView> {
  late FruitFullView fruitFullView;
  late FruitType selectedFruitType;
  late Future<FruitFullView?> _fruitFuture;
  String? _hydratedFruitId;
  List<CharacterInFruitView> characters = [];
  final ScrollController horizontalController = ScrollController();
  final ScrollController verticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fruitFuture = _loadData();
  }

  @override
  void didUpdateWidget(covariant FruitDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fruitId != widget.fruitId) {
      _hydratedFruitId = null;
      _fruitFuture = _loadData();
    }
  }

  @override
  void dispose() {
    horizontalController.dispose();
    verticalController.dispose();
    nameController.dispose();
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

  // controllers
  // 1. basic info
  final TextEditingController nameController = TextEditingController();

  // 2. combat info
  final TextEditingController energyConsumeController = TextEditingController();

  final TextEditingController attackSlopeController = TextEditingController();
  final TextEditingController attackInterceptController =
      TextEditingController();
  final TextEditingController defenseSlopeController = TextEditingController();
  final TextEditingController defenseInterceptController =
      TextEditingController();
  final TextEditingController intelligenceSlopeController =
      TextEditingController();
  final TextEditingController intelligenceInterceptController =
      TextEditingController();
  final TextEditingController bloodSlopeController = TextEditingController();
  final TextEditingController bloodInterceptController =
      TextEditingController();
  final TextEditingController speedSlopeController = TextEditingController();
  final TextEditingController speedInterceptController =
      TextEditingController();
  final TextEditingController groupGainSlopeController =
      TextEditingController();
  final TextEditingController groupGainInterceptController =
      TextEditingController();

  final _battleFormKey = GlobalKey<FormState>();
  bool _basicInfoEditable = false;
  bool _combatInfoEditable = false;
  bool _editButtonVisible = false;

  final double divW = 800;
  final double sideW = 50;

  Future<FruitFullView?> _loadData() {
    return getIt<FruitDao>().get(GetFruitRequest(fruitId: widget.fruitId));
  }

  // will be executed every time page refreshes
  void _updateData(FruitFullView fruitFullView) {
    if (_hydratedFruitId == fruitFullView.id) {
      this.fruitFullView = fruitFullView;
      characters = fruitFullView.characters;
      return;
    }
    _hydratedFruitId = fruitFullView.id;
    // 1. update data
    this.fruitFullView = fruitFullView;
    characters = fruitFullView.characters;
    selectedFruitType = fruitFullView.fruitType!;

    // 2. reset state
    _basicInfoEditable = false;
    _combatInfoEditable = false;
    // 3. update controller data
    _updateControllerData();

    // update visibility info
    _editButtonVisible = PermissionCheck.checkPermission(
            getIt<User>().loginRoleResourcesPermissionMap,
            ResourceType.FRUIT,
            Permission.UPDATE) &&
        PermissionCheck.isMyResource(
            fruitFullView.creationRecord!.userId!,
            fruitFullView.creationRecord!.roleId!,
            getIt<User>().id,
            getIt<User>().loginRoleId!);
    // nika role has the edit permission for all resources
    if (getIt<User>().loginRole == UserRole.NIKA) {
      _editButtonVisible = true;
    }
  }

  void _updateControllerData() {
    nameController.text =
        I18nHelper.getDisplayNameFromI18n(fruitFullView.name!);
    energyConsumeController.text = fruitFullView.energyConsume!.toString();

    attackSlopeController.text = fruitFullView.attackSlope.toString();
    attackInterceptController.text = fruitFullView.attackIntercept.toString();
    defenseSlopeController.text = fruitFullView.defenseSlope.toString();
    defenseInterceptController.text = fruitFullView.defenseIntercept.toString();
    bloodSlopeController.text = fruitFullView.bloodSlope.toString();
    bloodInterceptController.text = fruitFullView.bloodIntercept.toString();
    speedSlopeController.text = fruitFullView.speedSlope.toString();
    speedInterceptController.text = fruitFullView.speedIntercept.toString();
    intelligenceSlopeController.text =
        fruitFullView.intelligenceSlope.toString();
    intelligenceInterceptController.text =
        fruitFullView.intelligenceIntercept.toString();
    groupGainSlopeController.text = fruitFullView.groupGainSlope.toString();
    groupGainInterceptController.text =
        fruitFullView.groupGainIntercept.toString();
  }

  // ── Mobile card layout ────────────────────────────────────────────

  Widget _buildMobileLayout(BuildContext context) {
    final fruitMap = <FruitType, String>{
      FruitType.logia: AppLocalizations.of(context)!.logiaFruit,
      FruitType.zoan: AppLocalizations.of(context)!.zoanFruit,
      FruitType.ancientZoan: AppLocalizations.of(context)!.ancientZoanFruit,
      FruitType.mythicalZoan: AppLocalizations.of(context)!.mythicalZoanFruit,
      FruitType.artificialZoan:
          AppLocalizations.of(context)!.artificialZoanFruit,
      FruitType.paramecia: AppLocalizations.of(context)!.parameciaFruit,
    };
    return SingleChildScrollView(
      controller: verticalController,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Center(
            child: Column(children: [
          const SizedBox(height: 8),
          Text(I18nHelper.getDisplayNameFromI18n(fruitFullView.name),
              style: OnepieceFonts.headerStyle.copyWith(fontSize: 20)),
          const SizedBox(height: 4),
          OnepieceTag.getFruitTag(
              fruitFullView.fruitType!, fruitMap[fruitFullView.fruitType]!),
          if (_editButtonVisible) ...[
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              TextButton.icon(
                onPressed: () => setState(() {
                  _basicInfoEditable = !_basicInfoEditable;
                  if (!_basicInfoEditable) _submitBasicInfo();
                }),
                icon: Icon(_basicInfoEditable ? Icons.check : Icons.edit,
                    size: 14, color: OnepieceColors.fancyBlue),
                label: Text(
                    _basicInfoEditable
                        ? AppLocalizations.of(context)!.submitForm
                        : AppLocalizations.of(context)!.editHint,
                    style: const TextStyle(
                        fontSize: 11, color: OnepieceColors.fancyBlue)),
              ),
            ]),
          ],
        ])),
        const SizedBox(height: 16),
        // Basic Info
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppLocalizations.of(context)!.basicInfo,
                  style: OnepieceFonts.headerStyle.copyWith(fontSize: 16)),
              const SizedBox(height: 10),
              _mobileField(context, _basicInfoEditable, nameController,
                  AppLocalizations.of(context)!.name, null),
              _mobileDropdown<FruitType>(
                  _basicInfoEditable,
                  selectedFruitType,
                  FruitType.values,
                  fruitMap,
                  AppLocalizations.of(context)!.fruitType,
                  null,
                  (v) => setState(() => selectedFruitType = v)),
              const Divider(),
            ])),
        const SizedBox(height: 12),
        // Combat Info
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(AppLocalizations.of(context)!.battleInfo,
                    style: OnepieceFonts.headerStyle.copyWith(fontSize: 16)),
                const Spacer(),
                if (_editButtonVisible)
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _combatInfoEditable = !_combatInfoEditable;
                      if (!_combatInfoEditable && _combatInfoUpdated()) {
                        _submitCombatInfo();
                      }
                    }),
                    icon: Icon(_combatInfoEditable ? Icons.check : Icons.edit,
                        size: 14, color: OnepieceColors.fancyBlue),
                    label: Text(
                        _combatInfoEditable
                            ? AppLocalizations.of(context)!.submitForm
                            : AppLocalizations.of(context)!.editHint,
                        style: const TextStyle(
                            fontSize: 11, color: OnepieceColors.fancyBlue)),
                  ),
              ]),
              const SizedBox(height: 10),
              _mobileField(
                  context,
                  _combatInfoEditable,
                  energyConsumeController,
                  AppLocalizations.of(context)!.energyConsume,
                  null,
                  isNum: true),
              _mobileStatPair(
                  context,
                  _combatInfoEditable,
                  attackSlopeController,
                  attackInterceptController,
                  AppLocalizations.of(context)!.characterAttack,
                  'images/character_digits_icon/attack.svg'),
              _mobileStatPair(
                  context,
                  _combatInfoEditable,
                  defenseSlopeController,
                  defenseInterceptController,
                  AppLocalizations.of(context)!.characterDefense,
                  'images/character_digits_icon/defense.svg'),
              _mobileStatPair(
                  context,
                  _combatInfoEditable,
                  bloodSlopeController,
                  bloodInterceptController,
                  AppLocalizations.of(context)!.characterBlood,
                  'images/character_digits_icon/blood.svg'),
              _mobileStatPair(
                  context,
                  _combatInfoEditable,
                  intelligenceSlopeController,
                  intelligenceInterceptController,
                  AppLocalizations.of(context)!.characterIntelligence,
                  'images/character_digits_icon/intelligence.svg'),
              _mobileStatPair(
                  context,
                  _combatInfoEditable,
                  speedSlopeController,
                  speedInterceptController,
                  AppLocalizations.of(context)!.characterSpeed,
                  'images/character_digits_icon/speed.svg'),
              _mobileStatPair(
                  context,
                  _combatInfoEditable,
                  groupGainSlopeController,
                  groupGainInterceptController,
                  AppLocalizations.of(context)!.groupGain,
                  'images/character_digits_icon/group_gain.svg'),
              const Divider(),
            ])),
        // Characters
        if (characters.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.character,
                        style:
                            OnepieceFonts.headerStyle.copyWith(fontSize: 16)),
                    const SizedBox(height: 10),
                    ...characters.map((c) => Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => context.goNamed('characterDetails',
                                extra: c.id,
                                pathParameters: {
                                  'name':
                                      I18nHelper.getDisplayNameFromI18n(c.name)
                                }),
                            child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                child: Row(children: [
                                  ImageLazyLoader(
                                      key: ValueKey(c.imageUri),
                                      uriProvider: () => c.imageUri!,
                                      width: 36,
                                      borderWidth: 1.5,
                                      borderRadios: 36),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: Text(
                                          I18nHelper.getDisplayNameFromI18n(
                                              c.name),
                                          style: OnepieceFonts.contentStyle)),
                                ])),
                          ),
                        )),
                  ])),
        ],
      ]),
    );
  }

  Widget _mobileField(BuildContext context, bool editable,
      TextEditingController ctrl, String label, String? icon,
      {bool isNum = false}) {
    final val = ctrl.text.isNotEmpty ? ctrl.text : '-';
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: editable
            ? SizedBox(
                height: 35,
                child: TextFormField(
                    controller: ctrl,
                    keyboardType:
                        isNum ? TextInputType.number : TextInputType.text,
                    decoration: InputDecoration(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10),
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
                      prefixIcon: icon != null
                          ? ImageHelper.getTextFormFieldIcon(icon, true, 18)
                          : null,
                      labelText: label,
                    )))
            : Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  if (icon != null) ...[
                    ImageHelper.getTextFormFieldIcon(icon, true, 20),
                    const SizedBox(width: 10)
                  ],
                  Text(label, style: OnepieceFonts.deepBlackHintFont),
                  const Spacer(),
                  Text(val,
                      style: OnepieceFonts.contentStyle
                          .copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
                ])));
  }

  Widget _mobileStatPair(
      BuildContext context,
      bool editable,
      TextEditingController slope,
      TextEditingController intercept,
      String label,
      String icon) {
    final sv = slope.text.isNotEmpty ? slope.text : '0';
    final iv = intercept.text.isNotEmpty ? intercept.text : '0';
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: editable
            ? Row(children: [
                Expanded(
                    child: SizedBox(
                        height: 35,
                        child: TextFormField(
                            controller: slope,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.never,
                              disabledBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: OnepieceColors.menuHoverColor)),
                              enabledBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: OnepieceColors.menuHoverColor)),
                              focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: OnepieceColors.fancyGreen)),
                              prefixIcon: ImageHelper.getTextFormFieldIcon(
                                  icon, true, 18),
                              labelText: label,
                            )))),
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text('×', style: TextStyle(fontSize: 16))),
                Expanded(
                    child: SizedBox(
                        height: 35,
                        child: TextFormField(
                            controller: intercept,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 8),
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.never,
                              disabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: OnepieceColors.menuHoverColor)),
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: OnepieceColors.menuHoverColor)),
                              focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: OnepieceColors.fancyGreen)),
                              labelText: '+',
                            )))),
              ])
            : Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  ImageHelper.getTextFormFieldIcon(icon, true, 20),
                  const SizedBox(width: 10),
                  Text(label, style: OnepieceFonts.deepBlackHintFont),
                  const Spacer(),
                  Text('$sv × x + $iv',
                      style: OnepieceFonts.contentStyle
                          .copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
                ])));
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

  void _submitBasicInfo() {
    final router = GoRouter.of(context);
    final showAlert = OnepieceAlert.createAlertShower(context);
    final updated = UpdateFruitRequest(
      id: fruitFullView.id,
      name: I18nHelper.getI18nFromDisplayName(
          fruitFullView.name!, nameController.text),
      fruitType: selectedFruitType,
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
    getIt<FruitDao>().update(updated).then((v) {
      if (!mounted) return;
      showAlert(AppLocalizations.of(context)!.hint,
          I18nHelper.getDisplayNameFromI18n(v!.result));
      if (v.success) {
        router.goNamed('fruitDetails',
            extra: fruitFullView.id,
            pathParameters: {
              'name': I18nHelper.getDisplayNameFromI18n(fruitFullView.name)
            });
      }
    });
  }

  void _submitCombatInfo() => _submitBasicInfo();
  bool _combatInfoUpdated() => true;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FruitFullView?>(
        future: _fruitFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final fruit = snapshot.data;
            if (fruit == null) {
              return Center(
                child: Text(
                  AppLocalizations.of(context)!.loading,
                  style: OnepieceFonts.loadingFont,
                ),
              );
            }
            _updateData(fruit);
            return LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow =
                    ResponsiveBreakpoints.isMobileFromConstraints(constraints);
                final divW = isNarrow ? constraints.maxWidth - 30 : 800.0;
                final sideW = isNarrow ? 8.0 : 50.0;
                return Stack(
                  children: [
                    if (isNarrow)
                      _buildMobileLayout(context)
                    else
                      SingleChildScrollView(
                        controller: verticalController,
                        scrollDirection: Axis.vertical,
                        child: Center(
                          child: NestedHorizontalScrollView(
                            controller: horizontalController,
                            verticalParentController: verticalController,
                            child: SizedBox(
                              width: divW,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _getBasicInfo(context),
                                  const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 8),
                                      child: Divider(
                                          color: Colors.grey, thickness: 1)),
                                  _getCombatInfo(context),
                                  const SizedBox(
                                      height: 30,
                                      child: Divider(
                                          color: Colors.grey, thickness: 1)),
                                  Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: sideW),
                                      child: _getCharacterList(context)),
                                  const SizedBox(height: 60),
                                ],
                              ),
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
                                  message: fruitFullView.previousFruit == null
                                      ? ""
                                      : I18nHelper.getDisplayNameFromI18n(
                                          fruitFullView.previousFruit!.name),
                                  child: ElevatedButton(
                                    onPressed:
                                        fruitFullView.previousFruit == null
                                            ? null
                                            : () {
                                                context.goNamed('fruitDetails',
                                                    extra: fruitFullView
                                                        .previousFruit!.id,
                                                    pathParameters: {
                                                      'name': I18nHelper
                                                          .getDisplayNameFromI18n(
                                                              fruitFullView
                                                                  .previousFruit!
                                                                  .name)
                                                    });
                                              },
                                    child: const Icon(Icons.arrow_back),
                                  ),
                                ),
                                Tooltip(
                                  message: fruitFullView.nextFruit == null
                                      ? ""
                                      : I18nHelper.getDisplayNameFromI18n(
                                          fruitFullView.nextFruit!.name),
                                  child: ElevatedButton(
                                    onPressed: fruitFullView.nextFruit == null
                                        ? null
                                        : () {
                                            context.goNamed('fruitDetails',
                                                extra:
                                                    fruitFullView.nextFruit!.id,
                                                pathParameters: {
                                                  'name': I18nHelper
                                                      .getDisplayNameFromI18n(
                                                          fruitFullView
                                                              .nextFruit!.name)
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
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: sideW),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                    message: _basicInfoEditable
                        ? AppLocalizations.of(context)!.submitForm
                        : AppLocalizations.of(context)!.editHint,
                    child: InkWell(
                      hoverColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      onTap: () {
                        basicState(() {
                          _basicInfoEditable = !_basicInfoEditable;
                          if (!_basicInfoEditable) {
                            var updatedFruit = UpdateFruitRequest(
                                id: widget.fruitId,
                                // basic info
                                name: I18nHelper.getI18nFromDisplayName(
                                    fruitFullView.name!, nameController.text),
                                fruitType: selectedFruitType);
                            final router = GoRouter.of(context);
                            final alertHint =
                                AppLocalizations.of(context)!.hint;
                            final showAlert =
                                OnepieceAlert.createAlertShower(context);
                            getIt<FruitDao>()
                                .update(updatedFruit)
                                .then((value) {
                              if (!mounted) return;
                              showAlert(
                                  alertHint,
                                  I18nHelper.getDisplayNameFromI18n(
                                      value!.result));
                              if (value.success) {
                                router.goNamed('fruitDetails',
                                    extra: widget.fruitId,
                                    pathParameters: {
                                      'name': I18nHelper.getDisplayNameFromI18n(
                                          fruitFullView.name)
                                    });
                              }
                            });
                          }
                        });
                      },
                      child: SizedBox(
                          width: 25,
                          height: 25,
                          child: !_basicInfoEditable
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
            const SizedBox(
              height: 15,
            ),
            StringTextFormField(
                context,
                _basicInfoEditable,
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
                  const SizedBox(
                    width: 10,
                  ),
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
            _getDropDownList(context, basicState),
            DigitTextFormField(
                context,
                _basicInfoEditable,
                energyConsumeController,
                AppLocalizations.of(context)!.energyConsume,
                1,
                10,
                ImageHelper.getTextFormFieldIcon(
                    'images/character_digits_icon/energy.svg', true, 25),
                true),
          ],
        ),
      );
    });
  }

  Widget _getDropDownList(BuildContext context, Function basicInfoState) {
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
            AppLocalizations.of(context)!.groupCategory,
            style: OnepieceFonts.dropDownItemStyle,
          ),
          onChanged: !_basicInfoEditable
              ? null
              : (value) {
                  basicInfoState(() {
                    selectedFruitType = value! as FruitType;
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
              height: 34,
              width: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: OnepieceColors.liteFancyGreen,
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

  Widget _getCombatInfo(BuildContext context) {
    return StatefulBuilder(builder: (context, combatState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: sideW),
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
                if (_editButtonVisible)
                  Tooltip(
                    message: _combatInfoEditable
                        ? AppLocalizations.of(context)!.submitForm
                        : AppLocalizations.of(context)!.editHint,
                    child: InkWell(
                      hoverColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      onTap: () {
                        combatState(() {
                          _combatInfoEditable = !_combatInfoEditable;
                          if (!_combatInfoEditable) {
                            var updatedFruit = UpdateFruitRequest(
                              id: widget.fruitId,
                              // digit info
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
                                  energyConsumeController.text),
                              // basic info
                              name: fruitFullView.name,
                            );
                            final router = GoRouter.of(context);
                            final alertHint =
                                AppLocalizations.of(context)!.hint;
                            final showAlert =
                                OnepieceAlert.createAlertShower(context);
                            getIt<FruitDao>()
                                .update(updatedFruit)
                                .then((value) {
                              if (!mounted) return;
                              showAlert(
                                  alertHint,
                                  I18nHelper.getDisplayNameFromI18n(
                                      value!.result));
                              if (value.success) {
                                router.goNamed('fruitDetails',
                                    extra: widget.fruitId,
                                    pathParameters: {
                                      'name': I18nHelper.getDisplayNameFromI18n(
                                          fruitFullView.name)
                                    });
                              }
                            });
                          }
                        });
                      },
                      child: SizedBox(
                          width: 25,
                          height: 25,
                          child: !_combatInfoEditable
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
          const SizedBox(
            height: 15,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: sideW),
            child: Form(
              key: _battleFormKey,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Column(
                    children: [
                      FruitDigitTextFormField(
                          context,
                          _combatInfoEditable,
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
                          _combatInfoEditable,
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
                          _combatInfoEditable,
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
                          _combatInfoEditable,
                          intelligenceSlopeController,
                          intelligenceInterceptController,
                          AppLocalizations.of(context)!.intelligenceStrengthen,
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
                          _combatInfoEditable,
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
                          _combatInfoEditable,
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
            ),
          )
        ],
      );
    });
  }

  Widget _getCharacterList(BuildContext context) {
    Map<bool, String> wakeUpToDisplayValue = {
      true: AppLocalizations.of(context)!.wakeUp,
      false: AppLocalizations.of(context)!.sleep
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.owner,
          style: OnepieceFonts.headerStyle,
        ),
        if (characters.isEmpty)
          Text(
            AppLocalizations.of(context)!.currentlyNone,
            style: OnepieceFonts.fancyBlueHintFont,
          ),
        const SizedBox(
          height: 30,
        ),
        SizedBox(
          width: 600,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: characters.length,
            itemBuilder: (context, index) {
              var character = characters[index];
              return Material(
                type: MaterialType.transparency,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                  decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(5))),
                  child: ExpansionTile(
                    childrenPadding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                    expandedAlignment: Alignment.centerLeft,
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                              child: InkWell(
                                hoverColor: Colors.transparent,
                                splashColor: Colors.transparent,
                                onTap: () {
                                  context.goNamed('characterDetails',
                                      extra: character.id,
                                      pathParameters: {
                                        'name':
                                            I18nHelper.getDisplayNameFromI18n(
                                                character.name)
                                      });
                                },
                                child: ImageLazyLoader(
                                    key: UniqueKey(),
                                    uriProvider: () => character.imageUri!,
                                    width: 40,
                                    borderWidth: 1.5,
                                    borderRadios: 40),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Text(I18nHelper.getDisplayNameFromI18n(
                                character.name)),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: OnepieceTag.getWakeUpTag(
                            character.wakeUp!,
                            wakeUpToDisplayValue[character.wakeUp!]!,
                          ),
                        ),
                      ],
                    ),
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              ImageHelper.getTextFormFieldIcon(
                                  'images/character_digits_icon/attack.svg',
                                  true,
                                  21),
                              const SizedBox(
                                width: 10,
                              ),
                              SizedBox(
                                  width: 80,
                                  child: Text(
                                    "${character.baseAttack}",
                                    style: OnepieceFonts.boldFancyBlueHintFont,
                                  )),
                              const Padding(
                                padding: EdgeInsets.only(right: 50.0),
                                child: Icon(Icons.arrow_right_alt_outlined),
                              ),
                              SizedBox(
                                  width: 80,
                                  child: Text(
                                    "${character.attack}",
                                    style: OnepieceFonts.boldFancyBlueHintFont,
                                  ))
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              ImageHelper.getTextFormFieldIcon(
                                  'images/character_digits_icon/defense.svg',
                                  true,
                                  22),
                              const SizedBox(
                                width: 10,
                              ),
                              SizedBox(
                                  width: 80,
                                  child: Text(
                                    "${character.baseDefense}",
                                    style: OnepieceFonts.boldFancyBlueHintFont,
                                  )),
                              const Padding(
                                padding: EdgeInsets.only(right: 50.0),
                                child: Icon(Icons.arrow_right_alt_outlined),
                              ),
                              SizedBox(
                                  width: 80,
                                  child: Text(
                                    "${character.defense}",
                                    style: OnepieceFonts.boldFancyBlueHintFont,
                                  ))
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              ImageHelper.getTextFormFieldIcon(
                                  'images/character_digits_icon/intelligence.svg',
                                  true,
                                  22),
                              const SizedBox(
                                width: 10,
                              ),
                              SizedBox(
                                  width: 80,
                                  child: Text(
                                    "${character.baseIntelligence}",
                                    style: OnepieceFonts.boldFancyBlueHintFont,
                                  )),
                              const Padding(
                                padding: EdgeInsets.only(right: 50.0),
                                child: Icon(Icons.arrow_right_alt_outlined),
                              ),
                              SizedBox(
                                  width: 80,
                                  child: Text(
                                    "${character.intelligence}",
                                    style: OnepieceFonts.boldFancyBlueHintFont,
                                  ))
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              ImageHelper.getTextFormFieldIcon(
                                  'images/character_digits_icon/speed.svg',
                                  true,
                                  22),
                              const SizedBox(
                                width: 10,
                              ),
                              SizedBox(
                                  width: 80,
                                  child: Text(
                                    "${character.baseSpeed}",
                                    style: OnepieceFonts.boldFancyBlueHintFont,
                                  )),
                              const Padding(
                                padding: EdgeInsets.only(right: 50.0),
                                child: Icon(Icons.arrow_right_alt_outlined),
                              ),
                              SizedBox(
                                  width: 80,
                                  child: Text(
                                    "${character.speed}",
                                    style: OnepieceFonts.boldFancyBlueHintFont,
                                  ))
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              ImageHelper.getTextFormFieldIcon(
                                  'images/character_digits_icon/blood.svg',
                                  true,
                                  22),
                              const SizedBox(
                                width: 10,
                              ),
                              SizedBox(
                                  width: 80,
                                  child: Text(
                                    "${character.baseBlood}",
                                    style: OnepieceFonts.boldFancyBlueHintFont,
                                  )),
                              const Padding(
                                padding: EdgeInsets.only(right: 50.0),
                                child: Icon(Icons.arrow_right_alt_outlined),
                              ),
                              SizedBox(
                                  width: 80,
                                  child: Text(
                                    "${character.blood}",
                                    style: OnepieceFonts.boldFancyBlueHintFont,
                                  ))
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              ImageHelper.getTextFormFieldIcon(
                                  'images/character_digits_icon/group_gain.svg',
                                  true,
                                  20),
                              const SizedBox(
                                width: 10,
                              ),
                              SizedBox(
                                  width: 80,
                                  child: Text(
                                    "${character.baseGroupGain}",
                                    style: OnepieceFonts.boldFancyBlueHintFont,
                                  )),
                              const Padding(
                                padding: EdgeInsets.only(right: 50.0),
                                child: Icon(Icons.arrow_right_alt_outlined),
                              ),
                              SizedBox(
                                  width: 80,
                                  child: Text(
                                    "${character.groupGain}",
                                    style: OnepieceFonts.boldFancyBlueHintFont,
                                  ))
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
