import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';

import '../constants/font_constants.dart';
import '../constants/path_constants.dart';

GetIt getIt = GetIt.instance;

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  // Character character;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _getAvatar(context),
        const Divider(height: 10, thickness: 1,),
        _getLocalization(context)
      ],
    );
  }

  Widget _getAvatar(BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            AppLocalizations.of(context)!.avatarHeader,
            style: FontConstant.headerStyle,
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            AppLocalizations.of(context)!.avatarHeaderDescription,
            style: FontConstant.contentStyle,
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {},
                iconSize: 100,
                splashRadius: 10,
                splashColor: Colors.red,
                icon: Image.asset(
                  PathConstants.loginLuffyImage,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10,),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.uploadNewAvatar,
                    style: const TextStyle(
                        color: FontConstant.headerFontColor,
                        fontSize: FontConstant.contentFontSize,
                        fontWeight: FontConstant.headerFontWeight),
                  ),
                  const SizedBox(height: 10,),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        child: Text(AppLocalizations.of(context)!.chooseFile),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Text(AppLocalizations.of(context)!.noFileChosen, style: FontConstant.contentStyle,)
                    ],
                  ),
                  const SizedBox(height: 10,),
                  Text(AppLocalizations.of(context)!.maxFileSizeDescription,style: FontConstant.contentStyle,)
                ],
              )
            ],
          )
        ]),
      ),
    );
  }

  Widget _getLocalization(BuildContext context) {
    List<String> displayCharacterTypes = [
      AppLocalizations.of(context)!.chinese,
      AppLocalizations.of(context)!.english,
    ];
    String selectedItem = displayCharacterTypes.first;
    return Container(child: Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
        Text(AppLocalizations.of(context)!.localizationHeader,style:  FontConstant.headerStyle,),
        const SizedBox(height: 10,),
        Text(AppLocalizations.of(context)!.localizationDescription,style:  FontConstant.contentStyle,),
        const SizedBox(height: 10,),
        DropdownSearch<String>(
          items: displayCharacterTypes,
          selectedItem: selectedItem,
          onChanged: (value) {
            selectedItem = value!;
          },
        ),
      ]),
    ),);
  }
}
