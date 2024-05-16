import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:one_piece_battles_flutter/repository/fruit_dao.dart';
import 'package:one_piece_battles_flutter/utils/data_converter.dart';
import 'package:one_piece_battles_flutter/utils/i18n_helper.dart';
import 'package:openapi/api.dart';
import '../../components/digit_text_form_field.dart';
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
  TextEditingController attackController = TextEditingController();
  TextEditingController defenseController = TextEditingController();
  TextEditingController intelligenceController = TextEditingController();
  TextEditingController bloodController = TextEditingController();
  TextEditingController speedController = TextEditingController();
  TextEditingController groupGainController = TextEditingController();

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
    attackController.text = fruitFullView.attackStrengthen!.toString();
    defenseController.text = fruitFullView.defenseStrengthen!.toString();
    intelligenceController.text =
        fruitFullView.intelligenceStrengthen!.toString();
    bloodController.text = fruitFullView.bloodStrengthen!.toString();
    speedController.text = fruitFullView.speedStrengthen!.toString();
    groupGainController.text = fruitFullView.groupGainStrengthen!.toString();
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
                    'images/character_digits_icon/name.svg', true),
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
                              groupGainStrengthen: DataConverter.stringToInt(
                                  groupGainController.text),
                              attackStrengthen: DataConverter.stringToInt(
                                  attackController.text),
                              defenseStrengthen: DataConverter.stringToInt(
                                  defenseController.text),
                              intelligenceStrengthen: DataConverter.stringToInt(
                                  intelligenceController.text),
                              bloodStrengthen: DataConverter.stringToInt(
                                  bloodController.text),
                              speedStrengthen: DataConverter.stringToInt(
                                  speedController.text),
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
                      DigitTextFormField(
                          context,
                          _combatInfoEditable,
                          attackController,
                          AppLocalizations.of(context)!.attackStrengthen,
                          1,
                          5,
                          ImageHelper.getTextFormFieldIcon(
                              'images/character_digits_icon/attack.svg', true)),
                      DigitTextFormField(
                          context,
                          _combatInfoEditable,
                          defenseController,
                          AppLocalizations.of(context)!.defenseStrengthen,
                          1,
                          5,
                          ImageHelper.getTextFormFieldIcon(
                              'images/character_digits_icon/defense.svg',
                              true)),
                      DigitTextFormField(
                          context,
                          _combatInfoEditable,
                          bloodController,
                          AppLocalizations.of(context)!.bloodStrengthen,
                          1,
                          5,
                          ImageHelper.getTextFormFieldIcon(
                              'images/character_digits_icon/blood.svg', true)),
                      DigitTextFormField(
                          context,
                          _combatInfoEditable,
                          energyConsumeController,
                          AppLocalizations.of(context)!.energyConsume,
                          1,
                          10,
                          ImageHelper.getTextFormFieldIcon(
                              'images/character_digits_icon/energy.svg', true)),
                    ],
                  ),
                  Column(
                    children: [
                      DigitTextFormField(
                          context,
                          _combatInfoEditable,
                          intelligenceController,
                          AppLocalizations.of(context)!.intelligenceStrengthen,
                          1,
                          5,
                          ImageHelper.getTextFormFieldIcon(
                              'images/character_digits_icon/intelligence.svg',
                              true)),
                      DigitTextFormField(
                          context,
                          _combatInfoEditable,
                          speedController,
                          AppLocalizations.of(context)!.speedStrengthen,
                          1,
                          8,
                          ImageHelper.getTextFormFieldIcon(
                              'images/character_digits_icon/speed.svg', true)),
                      DigitTextFormField(
                          context,
                          _combatInfoEditable,
                          groupGainController,
                          AppLocalizations.of(context)!.groupStrengthen,
                          1,
                          5,
                          ImageHelper.getTextFormFieldIcon(
                              'images/character_digits_icon/group_gain.svg', true)),
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
        const SizedBox(height: 30,),
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
                        Text(I18nHelper.getDisplayNameFromI18n(
                            character.name!)),
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
