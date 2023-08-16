import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:one_piece_battles_flutter/components/add_character_view.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
import 'package:one_piece_battles_flutter/utils/base64_helper.dart';
import 'package:openapi/api.dart';

GetIt getIt = GetIt.instance;

class CharacterView extends StatefulWidget {
  const CharacterView({super.key});

  @override
  State<CharacterView> createState() => _CharacterViewState();
}

class _CharacterViewState extends State<CharacterView> {
  Logger logger = Logger('_CharacterViewState');
  List<Character> currentCharacterList = [];

  @override
  void initState() {
    super.initState();
    ListCharacterRequest listCharacterRequest =
        ListCharacterRequest(pageSize: 10, pageIndex: 1);
    Future<ListCharacterResponse?> listCharacterResponse =
        getIt<CharacterDao>().listCharacter(listCharacterRequest);

    listCharacterResponse.then((value) {
      setState(() {
        currentCharacterList = value!.characters;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
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
                      return const AddCharacterView();
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
        _createDataTable()
      ],
    );
  }

  DataTable _createDataTable() {
    return DataTable(
      columns: _createColumns(),
      rows: _createRows(),
      columnSpacing: 30,
    );
  }

  List<DataColumn> _createColumns() {
    return [
      const DataColumn(label: Text('')),
      DataColumn(label: Text(AppLocalizations.of(context)!.characterName)),
      DataColumn(label: Text(AppLocalizations.of(context)!.fruitLimit)),
      DataColumn(label: Text(AppLocalizations.of(context)!.groupGain)),
      DataColumn(label: Text(AppLocalizations.of(context)!.characterAttack)),
      DataColumn(label: Text(AppLocalizations.of(context)!.characterDefense)),
      DataColumn(
          label: Text(AppLocalizations.of(context)!.characterIntelligence)),
      DataColumn(label: Text(AppLocalizations.of(context)!.characterBlood)),
      DataColumn(label: Text(AppLocalizations.of(context)!.characterSpeed)),
      DataColumn(label: Text(AppLocalizations.of(context)!.characterFruits)),
    ];
  }

  List<DataRow> _createRows() {
    return currentCharacterList
        .map((character) => DataRow(cells: [
              DataCell(
                  Image.memory(Base64Helper.decode(character.profileImage!))),
              DataCell(Text(character.name.toString())),
              DataCell(Text(character.fruitLimit.toString())),
              DataCell(Text(character.groupGain.toString())),
              DataCell(Text(character.attack.toString())),
              DataCell(Text(character.defense.toString())),
              DataCell(Text(character.intelligence.toString())),
              DataCell(Text(character.blood.toString())),
              DataCell(Text(character.speed.toString())),
              DataCell(Text(character.fruits.toString())),
            ]))
        .toList();
  }
}
