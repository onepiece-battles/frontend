import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/constants/path_constants.dart';

class CharacterView extends StatefulWidget {
  const CharacterView({super.key});

  @override
  State<CharacterView> createState() => _CharacterViewState();
}

class _CharacterViewState extends State<CharacterView> {
  @override
  Widget build(BuildContext context) {
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
                onPressed: () {},
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
                          EdgeInsets.only(top: 8.0, bottom: 8.0, left: 10.0),
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
