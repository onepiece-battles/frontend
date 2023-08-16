import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:one_piece_battles_flutter/components/add_character_view.dart';
import 'package:one_piece_battles_flutter/repository/character_dao.dart';
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
        SizedBox(
          height: 20,
          child: Text(currentCharacterList.toString()),
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
      ],
    );
  }

  void validateFunction() {}

  void onChangeFunction(value) {
    validateFunction();
  }
}
