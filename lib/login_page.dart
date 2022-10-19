import 'package:flutter/material.dart';
import 'package:one_piece_battles_flutter/constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_toggle_tab/flutter_toggle_tab.dart';
import 'package:one_piece_battles_flutter/main.dart';

const locales = [Locale('en', 'US'), Locale('zh', 'CN')];

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  var _tabTextIndexSelected = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[300],
        body: SafeArea(
            child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: FlutterToggleTab(
                  width: 5,
                  height: 17,
                  borderRadius: 30,
                  selectedBackgroundColors: const [
                    Color.fromARGB(255, 38, 151, 243),
                    Colors.blueAccent
                  ],
                  labels: const ["A", "文"],
                  selectedLabelIndex: (index) {
                    setState(() {
                      _tabTextIndexSelected = index;
                      Locale locale;
                      if (index == 0) {
                        locale = locales.first;
                      } else {
                        locale = locales.last;
                      }
                      MyApp.setLocale(context, locale);
                    });
                  },
                  selectedTextStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                  unSelectedTextStyle: const TextStyle(
                      color: Colors.black87,
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                  unSelectedBackgroundColors: const [
                    Color.fromARGB(255, 182, 180, 180)
                  ],
                  selectedIndex: _tabTextIndexSelected,
                  isScroll: false,
                ),
              ),
            ),
            const SizedBox(height: 50),
            const Image(
              image: AssetImage(Constants.loginLuffyImage),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.welcome,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.blue),
            ),
            const SizedBox(height: 120),
            SizedBox(
              width: 300,
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)?.userNameLable,
                    hintText: AppLocalizations.of(context)?.userNameHint,
                    prefixIcon: const Icon(Icons.person)),
              ),
            ),
            SizedBox(
              width: 300,
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)?.passwordLable,
                    hintText: AppLocalizations.of(context)?.passWordHint,
                    prefixIcon: const Icon(Icons.lock)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 300,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/');
                },
                child: Text(
                  AppLocalizations.of(context)!.signIn,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 17),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context)!.noAccount,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: Text(
                      AppLocalizations.of(context)!.registerAccount,
                      style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic),
                    ))
              ],
            )
          ],
        )));
  }
}
