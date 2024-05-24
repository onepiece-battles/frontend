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
import '../../components/string_text_form_field.dart';
import '../../constants/onepiece_colors.dart';
import '../../constants/onepiece_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../constants/onepiece_tag.dart';
import '../../popup/onepiece_alert.dart';
import '../../utils/image_helper.dart';
import '../../utils/permission_check.dart';

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
  List<CharacterInFruitView> characters = [];
  ScrollController horizontalController = ScrollController();
  ScrollController verticalController = ScrollController();

  // controllers
  // 1. basic info
  TextEditingController nameController = TextEditingController();
  // 2. combat info
  TextEditingController energyConsumeController = TextEditingController();

  TextEditingController attackSlopeController = TextEditingController();
  TextEditingController attackInterceptController = TextEditingController();
  TextEditingController defenseSlopeController = TextEditingController();
  TextEditingController defenseInterceptController = TextEditingController();
  TextEditingController intelligenceSlopeController = TextEditingController();
  TextEditingController intelligenceInterceptController =
      TextEditingController();
  TextEditingController bloodSlopeController = TextEditingController();
  TextEditingController bloodInterceptController = TextEditingController();
  TextEditingController speedSlopeController = TextEditingController();
  TextEditingController speedInterceptController = TextEditingController();
  TextEditingController groupGainSlopeController = TextEditingController();
  TextEditingController groupGainInterceptController = TextEditingController();

  final _battleFormKey = GlobalKey<FormState>();
  bool _basicInfoEditable = false;
  bool _combatInfoEditable = false;
  bool _editButtonVisible = false;

  final double _dividerWidth = 800;
  final double _sideWidth = 50;

  _loadData() {
    return getIt<FruitDao>().get(GetFruitRequest(fruitId: widget.fruitId));
  }

  // will be executed every time page refreshes
  void _updateData(FruitFullView fruitFullView) {
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _loadData(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            _updateData(snapshot.data);
            return Stack(
              children: [
                SingleChildScrollView(
                  controller: verticalController,
                  scrollDirection: Axis.vertical,
                  child: Center(
                    child: SingleChildScrollView(
                      controller: horizontalController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: _dividerWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _getBasicInfo(context),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Divider(
                                color: Colors.grey,
                                thickness: 1,
                              ),
                            ),
                            _getCombatInfo(context),
                            const SizedBox(
                              height: 30,
                              child: Divider(
                                color: Colors.grey,
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: _sideWidth),
                              child: _getCharacterList(context),
                            ),
                            const SizedBox(
                              height: 60,
                            )
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
                                onPressed: fruitFullView.previousFruit == null
                                    ? null
                                    : () {
                                        context.goNamed('fruitDetails',
                                            extra:
                                                fruitFullView.previousFruit!.id,
                                            pathParameters: {
                                              'name': I18nHelper
                                                  .getDisplayNameFromI18n(
                                                      fruitFullView
                                                          .previousFruit!.name)
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
                                            extra: fruitFullView.nextFruit!.id,
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
        padding: EdgeInsets.symmetric(horizontal: _sideWidth),
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
                      hoverColor: Colors.white,
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
                            getIt<FruitDao>()
                                .update(updatedFruit)
                                .then((value) {
                              OnepieceAlert.getBasicAlertDialogFunc(
                                  context,
                                  AppLocalizations.of(context)!.hint,
                                  I18nHelper.getDisplayNameFromI18n(
                                      value!.result));
                              if (value.success) {
                                context.goNamed('fruitDetails',
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
              padding: const EdgeInsets.only(bottom: 8.0),
              child: SizedBox(
                width: 300,
                child: Text(
                  AppLocalizations.of(context)!.category,
                  style: OnepieceFonts.deepBlackHintFont,
                ),
              ),
            ),
            _getDropDownList(context, basicState),
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
              width: 210,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: OnepieceColors.menuBackgroundColor,
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
            padding: EdgeInsets.symmetric(horizontal: _sideWidth),
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
                      hoverColor: Colors.white,
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
                            getIt<FruitDao>()
                                .update(updatedFruit)
                                .then((value) {
                              OnepieceAlert.getBasicAlertDialogFunc(
                                  context,
                                  AppLocalizations.of(context)!.hint,
                                  I18nHelper.getDisplayNameFromI18n(
                                      value!.result));
                              if (value.success) {
                                context.goNamed('fruitDetails',
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
            padding: EdgeInsets.symmetric(horizontal: _sideWidth),
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
                      DigitTextFormField(
                          context,
                          _combatInfoEditable,
                          energyConsumeController,
                          AppLocalizations.of(context)!.energyConsume,
                          1,
                          10,
                          ImageHelper.getTextFormFieldIcon(
                              'images/character_digits_icon/energy.svg',
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
        Container(
          width: 500,
          decoration: const BoxDecoration(
            color: OnepieceColors.menuBackgroundColor,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
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
                  child: ListTile(
                    minLeadingWidth: 10,
                    contentPadding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    selectedTileColor: OnepieceColors.liteFancyBlue,
                    onTap: () {
                      context.goNamed('characterDetails',
                          extra: character.characterId,
                          pathParameters: {
                            'name': I18nHelper.getDisplayNameFromI18n(
                                character.name!)
                          });
                    },
                    hoverColor: OnepieceColors.liteFancyBlue,
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            I18nHelper.getDisplayNameFromI18n(character.name!)),
                        Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: OnepieceTag.getWakeUpTag(
                            character.wakeUp!,
                            wakeUpToDisplayValue[character.wakeUp!]!,
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
      ],
    );
  }
}
