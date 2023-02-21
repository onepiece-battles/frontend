import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/constants/path_constants.dart';
import 'package:one_piece_battles_flutter/repository/character_repository.dart';
import 'package:one_piece_battles_flutter/utils/data_converter.dart';
import 'package:one_piece_battles_flutter/utils/string_extensions.dart';
import 'package:openapi/openapi.dart';
import 'package:dropdown_search/dropdown_search.dart';

class CharacterView extends StatefulWidget {
  const CharacterView({super.key});

  @override
  State<CharacterView> createState() => _CharacterViewState();
}

class _CharacterViewState extends State<CharacterView> {
  TextEditingController characterNameController = TextEditingController();
  TextEditingController characterFruitLimitController = TextEditingController();
  TextEditingController characterGroupGainController = TextEditingController();
  TextEditingController characterAttackController = TextEditingController();
  TextEditingController characterDefenseController = TextEditingController();
  TextEditingController characterIntelligenceController =
      TextEditingController();
  TextEditingController characterBloodController = TextEditingController();
  TextEditingController characterSpeedController = TextEditingController();
  TextEditingController characterEnergyController = TextEditingController();
  CharacterRepository characterRepository = CharacterRepository();

  List<TextEditingController> getCharacterControllerList() {
    return [
      characterNameController,
      characterFruitLimitController,
      characterGroupGainController,
      characterAttackController,
      characterDefenseController,
      characterDefenseController,
      characterIntelligenceController,
      characterBloodController,
      characterSpeedController,
      characterEnergyController
    ];
  }

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    List<String> characterTypes = CharacterType.values
        .map((characterType) => characterType.toString())
        .toList();

    List<String> displayCharacterTypes = [
      AppLocalizations.of(context)!.body,
      AppLocalizations.of(context)!.science,
      AppLocalizations.of(context)!.katana,
      AppLocalizations.of(context)!.shoot,
      AppLocalizations.of(context)!.fist,
      AppLocalizations.of(context)!.leg
    ];

    Map<String, CharacterType> displayValueToEnumValue =
        <String, CharacterType>{
      AppLocalizations.of(context)!.body: CharacterType.body,
      AppLocalizations.of(context)!.leg: CharacterType.foot,
      AppLocalizations.of(context)!.science: CharacterType.science,
      AppLocalizations.of(context)!.fist: CharacterType.fist,
      AppLocalizations.of(context)!.katana: CharacterType.katana,
      AppLocalizations.of(context)!.shoot: CharacterType.shooter,
    };
    String selectedItem = "";

    return Column(
      children: [
        const SizedBox(
          height: 20,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                width: 250,
              ),
              ElevatedButton(
                child: Text(AppLocalizations.of(context)!.createCharacter,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.white)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: ((context) {
                      return AlertDialog(
                        title: Center(
                          child: Text(
                            AppLocalizations.of(context)!.createCharacter,
                            style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 28,
                                fontStyle: FontStyle.normal),
                          ),
                        ),
                        content: Container(
                          width: 800,
                          height: 800,
                          padding: const EdgeInsets.all(100),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: <Widget>[
                                Row(children: [
                                  Flexible(
                                    flex: 1,
                                    fit: FlexFit.tight,
                                    child: Column(
                                      children: [
                                        const Image(
                                          width: 100,
                                          height: 100,
                                          image: AssetImage(
                                              PathConstants.loginLuffyImage),
                                        ),
                                        DropdownSearch<String>(
                                          items: displayCharacterTypes,
                                          selectedItem: selectedItem,
                                          onChanged: (value) {
                                            selectedItem = value!;
                                          },
                                          dropdownDecoratorProps: DropDownDecoratorProps(
                                              dropdownSearchDecoration:
                                                  InputDecoration(
                                                      labelText: AppLocalizations
                                                              .of(context)!
                                                          .characterTypeLable,
                                                      hintText: AppLocalizations
                                                              .of(context)!
                                                          .characterTypeHint)),
                                        )
                                      ],
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 50,
                                  ),
                                  Flexible(
                                    flex: 1,
                                    fit: FlexFit.tight,
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          TextFormField(
                                            controller: characterNameController,
                                            maxLength: 10,
                                            maxLengthEnforcement:
                                                MaxLengthEnforcement.enforced,
                                            decoration: InputDecoration(
                                              labelText:
                                                  AppLocalizations.of(context)!
                                                      .characterName,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 20,
                                          ),
                                          TextFormField(
                                            controller:
                                                characterFruitLimitController,
                                            validator: (value) {
                                              if (value!.isWhiteSpace()) {
                                                return AppLocalizations.of(
                                                        context)!
                                                    .requiredField;
                                              } else if (!value.isValidInt()) {
                                                return AppLocalizations.of(
                                                        context)!
                                                    .fieldMustBeInt;
                                              }
                                              return null;
                                            },
                                            decoration: InputDecoration(
                                                labelText: AppLocalizations.of(
                                                        context)!
                                                    .fruitLimit,
                                                hintStyle: const TextStyle(
                                                    color: Colors.grey),
                                                hintText:
                                                    "${AppLocalizations.of(context)!.valueRange}[1-2]"),
                                          ),
                                          const SizedBox(
                                            height: 30,
                                          ),
                                          TextFormField(
                                            controller:
                                                characterGroupGainController,
                                            validator: (value) {
                                              if (value!.isWhiteSpace()) {
                                                return AppLocalizations.of(
                                                        context)!
                                                    .requiredField;
                                              } else if (!value.isValidInt()) {
                                                return AppLocalizations.of(
                                                        context)!
                                                    .fieldMustBeInt;
                                              }
                                              return null;
                                            },
                                            decoration: InputDecoration(
                                                labelText: AppLocalizations.of(
                                                        context)!
                                                    .groupGain,
                                                hintStyle: const TextStyle(
                                                    color: Colors.grey),
                                                hintText:
                                                    "${AppLocalizations.of(context)!.valueRange}[1-10]"),
                                          ),
                                        ]),
                                  )
                                ]),
                                const SizedBox(
                                  height: 30,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      flex: 1,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          TextFormField(
                                            controller:
                                                characterAttackController,
                                            validator: (value) {
                                              if (value!.isWhiteSpace()) {
                                                return AppLocalizations.of(
                                                        context)!
                                                    .requiredField;
                                              } else if (!value.isValidInt()) {
                                                return AppLocalizations.of(
                                                        context)!
                                                    .fieldMustBeInt;
                                              }
                                              return null;
                                            },
                                            decoration: InputDecoration(
                                              labelText:
                                                  AppLocalizations.of(context)!
                                                      .characterAttack,
                                              hintStyle: const TextStyle(
                                                  color: Colors.grey),
                                              hintText:
                                                  "${AppLocalizations.of(context)!.valueRange}[10-1000]",
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 30,
                                          ),
                                          TextFormField(
                                            controller:
                                                characterDefenseController,
                                            validator: (value) {
                                              if (value!.isWhiteSpace()) {
                                                return AppLocalizations.of(
                                                        context)!
                                                    .requiredField;
                                              } else if (!value.isValidInt()) {
                                                return AppLocalizations.of(
                                                        context)!
                                                    .fieldMustBeInt;
                                              }
                                              return null;
                                            },
                                            decoration: InputDecoration(
                                              hintStyle: const TextStyle(
                                                  color: Colors.grey),
                                              hintText:
                                                  "${AppLocalizations.of(context)!.valueRange}[10-1000]",
                                              labelText:
                                                  AppLocalizations.of(context)!
                                                      .characterDefense,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 30,
                                          ),
                                          TextFormField(
                                            controller:
                                                characterIntelligenceController,
                                            validator: (value) {
                                              if (value!.isWhiteSpace()) {
                                                return AppLocalizations.of(
                                                        context)!
                                                    .requiredField;
                                              } else if (!value.isValidInt()) {
                                                return AppLocalizations.of(
                                                        context)!
                                                    .fieldMustBeInt;
                                              }
                                              return null;
                                            },
                                            decoration: InputDecoration(
                                                labelText: AppLocalizations.of(
                                                        context)!
                                                    .characterIntelligence,
                                                hintStyle: const TextStyle(
                                                    color: Colors.grey),
                                                hintText:
                                                    "${AppLocalizations.of(context)!.valueRange}[70-260]"),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 50,
                                    ),
                                    Flexible(
                                      flex: 1,
                                      fit: FlexFit.tight,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          TextFormField(
                                            controller:
                                                characterBloodController,
                                            validator: (value) {
                                              if (value!.isWhiteSpace()) {
                                                return AppLocalizations.of(
                                                        context)!
                                                    .requiredField;
                                              } else if (!value.isValidInt()) {
                                                return AppLocalizations.of(
                                                        context)!
                                                    .fieldMustBeInt;
                                              }
                                              return null;
                                            },
                                            decoration: InputDecoration(
                                                labelText: AppLocalizations.of(
                                                        context)!
                                                    .characterBlood,
                                                hintStyle: const TextStyle(
                                                    color: Colors.grey),
                                                hintText:
                                                    "${AppLocalizations.of(context)!.valueRange}[100-10000]"),
                                          ),
                                          const SizedBox(
                                            height: 30,
                                          ),
                                          TextFormField(
                                            controller:
                                                characterSpeedController,
                                            validator: (value) {
                                              if (value!.isWhiteSpace()) {
                                                return AppLocalizations.of(
                                                        context)!
                                                    .requiredField;
                                              } else if (!value.isValidInt()) {
                                                return AppLocalizations.of(
                                                        context)!
                                                    .fieldMustBeInt;
                                              }
                                              return null;
                                            },
                                            decoration: InputDecoration(
                                                labelText: AppLocalizations.of(
                                                        context)!
                                                    .characterSpeed,
                                                hintStyle: const TextStyle(
                                                    color: Colors.grey),
                                                hintText:
                                                    "${AppLocalizations.of(context)!.valueRange}[10-200]"),
                                          ),
                                          const SizedBox(
                                            height: 30,
                                          ),
                                          TextFormField(
                                            controller:
                                                characterEnergyController,
                                            validator: (value) {
                                              if (value!.isWhiteSpace()) {
                                                return AppLocalizations.of(
                                                        context)!
                                                    .requiredField;
                                              } else if (!value.isValidInt()) {
                                                return AppLocalizations.of(
                                                        context)!
                                                    .fieldMustBeInt;
                                              }
                                              return null;
                                            },
                                            decoration: InputDecoration(
                                                labelText: AppLocalizations.of(
                                                        context)!
                                                    .characterEnergy,
                                                hintStyle: const TextStyle(
                                                    color: Colors.grey),
                                                hintText:
                                                    "${AppLocalizations.of(context)!.valueRange}[10-50]"),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            child:
                                Text(AppLocalizations.of(context)!.cancelPopUp),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                          TextButton(
                            child:
                                Text(AppLocalizations.of(context)!.clearForm),
                            onPressed: () {
                              getCharacterControllerList().forEach((element) {
                                element.clear();
                              });
                            },
                          ),
                          TextButton(
                            child:
                                Text(AppLocalizations.of(context)!.submitForm),
                            onPressed: () {
                              final isValid = _formKey.currentState!.validate();
                              if (isValid) {
                                AddCharacterRequest addCharacterRequest =
                                    AddCharacterRequest((builder) => {
                                          builder
                                            ..attack =
                                                DataConverter.stringToInt(
                                                    characterAttackController
                                                        .text)
                                            ..characterType =
                                                displayValueToEnumValue[
                                                    selectedItem]
                                            ..speed = DataConverter.stringToInt(
                                                characterSpeedController.text)
                                            ..blood = DataConverter.stringToInt(
                                                characterBloodController.text)
                                            ..defense =
                                                DataConverter.stringToInt(
                                                    characterDefenseController
                                                        .text)
                                            ..fruitLimit =
                                                DataConverter.stringToInt(
                                                    characterFruitLimitController
                                                        .text)
                                            ..groupGain =
                                                DataConverter.stringToInt(
                                                    characterGroupGainController
                                                        .text)
                                            ..intelligence =
                                                DataConverter.stringToInt(
                                                    characterIntelligenceController
                                                        .text)
                                            ..magic = DataConverter.stringToInt(
                                                characterEnergyController.text)
                                            ..name =
                                                characterNameController.text
                                        });

                                characterRepository
                                    .addCharacter(addCharacterRequest);
                              } else {
                                print("Form is valid: $isValid");
                              }
                            },
                          ),
                        ],
                      );
                    }),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        Container(
          color: Colors.white,
          child: DataTable(
            border: const TableBorder(
                top: BorderSide(color: Colors.blue),
                left: BorderSide(color: Colors.blue)),
            columnSpacing: 10.0,
            columns: [
              const DataColumn(label: Text('')),
              DataColumn(
                  label: Text(AppLocalizations.of(context)!.characterName)),
              DataColumn(label: Text(AppLocalizations.of(context)!.fruitLimit)),
              DataColumn(label: Text(AppLocalizations.of(context)!.groupGain)),
              DataColumn(
                  label: Text(AppLocalizations.of(context)!.characterAttack)),
              DataColumn(
                  label: Text(AppLocalizations.of(context)!.characterDefense)),
              DataColumn(
                  label: Text(
                      AppLocalizations.of(context)!.characterIntelligence)),
              DataColumn(
                  label: Text(AppLocalizations.of(context)!.characterBlood)),
              DataColumn(
                  label: Text(AppLocalizations.of(context)!.characterSpeed)),
              DataColumn(
                  label: Text(AppLocalizations.of(context)!.characterFruits)),
            ],
            rows: const [
              DataRow(
                cells: [
                  DataCell(
                    Padding(
                      padding:
                          EdgeInsets.only(top: 8.0, bottom: 8.0, right: 6.0),
                      child: Image(
                        image: AssetImage(PathConstants.loginLuffyImage),
                        width: 30,
                      ),
                      // child: Text("aa"),
                    ),
                  ),
                  DataCell(Text("aa")),
                  DataCell(Text("aa")),
                  DataCell(Text("aa")),
                  DataCell(Text("aa")),
                  DataCell(Text("aa")),
                  DataCell(Text("aa")),
                  DataCell(Text("aa")),
                  DataCell(Text("aa")),
                  DataCell(Text("aa"))
                ],
              ),
            ],
          ),
        ),
        // PaginatedDataTable(columns: [
        //   const DataColumn(label: Text('')),
        //   DataColumn(label: Text(AppLocalizations.of(context)!.characterName)),
        //   DataColumn(label: Text(AppLocalizations.of(context)!.fruitLimit)),
        //   DataColumn(label: Text(AppLocalizations.of(context)!.groupGain)),
        //   DataColumn(
        //       label: Text(AppLocalizations.of(context)!.characterAttack)),
        //   DataColumn(
        //       label: Text(AppLocalizations.of(context)!.characterDefense)),
        //   DataColumn(
        //       label: Text(AppLocalizations.of(context)!.characterIntelligence)),
        //   DataColumn(label: Text(AppLocalizations.of(context)!.characterBlood)),
        //   DataColumn(label: Text(AppLocalizations.of(context)!.characterSpeed)),
        //   DataColumn(
        //       label: Text(AppLocalizations.of(context)!.characterFruits)),
        // ], source: source)
      ],
    );
  }

  void validateFunction() {}

  void onChangeFunction(value) {
    validateFunction();
  }
}

class MyData extends DataTableSource {
  @override
  DataRow? getRow(int index) {
    // TODO: implement getRow
    throw UnimplementedError();
  }

  @override
  // TODO: implement isRowCountApproximate
  bool get isRowCountApproximate => throw UnimplementedError();

  @override
  // TODO: implement rowCount
  int get rowCount => throw UnimplementedError();

  @override
  // TODO: implement selectedRowCount
  int get selectedRowCount => throw UnimplementedError();
}
