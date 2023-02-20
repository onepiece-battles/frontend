import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:one_piece_battles_flutter/repository/account_repository.dart';
import 'package:one_piece_battles_flutter/utils/I18n_helper.dart';
import 'package:openapi/openapi.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  AccountRepository accountRepository = AccountRepository();
  bool _isPasswordHidden = true;
  bool _isConfirmedPasswordHidden = true;
  bool _bottonEnabled = false;
  String verificationMessage = "";
  TextEditingController userNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmedPasswordController = TextEditingController();
  TextEditingController orgnizationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: SafeArea(
          child: Padding(
              padding: const EdgeInsets.fromLTRB(130, 150, 130, 60),
              child: ColoredBox(
                color: const Color.fromARGB(255, 163, 207, 243),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 100,
                    ),
                    Text(
                      AppLocalizations.of(context)!.signUpHeadLine,
                      style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      width: 300,
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            if (userNameController.text != "" &&
                                emailController.text != "" &&
                                passwordController.text != "" &&
                                confirmedPasswordController.text != "" &&
                                orgnizationController.text != "") {
                              _bottonEnabled = true;
                            } else {
                              _bottonEnabled = false;
                            }
                          });
                        },
                        controller: userNameController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)?.userNameHint,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            if (userNameController.text != "" &&
                                emailController.text != "" &&
                                passwordController.text != "" &&
                                confirmedPasswordController.text != "" &&
                                orgnizationController.text != "") {
                              _bottonEnabled = true;
                            } else {
                              _bottonEnabled = false;
                            }
                          });
                        },
                        autofocus: true,
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)?.emailAddress,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            if (userNameController.text != "" &&
                                emailController.text != "" &&
                                passwordController.text != "" &&
                                confirmedPasswordController.text != "" &&
                                orgnizationController.text != "") {
                              _bottonEnabled = true;
                            } else {
                              _bottonEnabled = false;
                            }
                          });
                        },
                        autofocus: true,
                        controller: orgnizationController,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)?.organization,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      child: TextFormField(
                        onChanged: (value) {
                          setState(() {
                            if (userNameController.text != "" &&
                                emailController.text != "" &&
                                passwordController.text != "" &&
                                confirmedPasswordController.text != "" &&
                                orgnizationController.text != "") {
                              _bottonEnabled = true;
                            } else {
                              _bottonEnabled = false;
                            }
                          });
                        },
                        controller: passwordController,
                        keyboardType: TextInputType.text,
                        obscureText: _isPasswordHidden,
                        decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)
                                ?.registerPasswordHint,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordHidden
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Theme.of(context).primaryColorDark,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordHidden = !_isPasswordHidden;
                                });
                              },
                            )),
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      child: TextFormField(
                        onChanged: (value) {
                          setState(() {
                            if (userNameController.text != "" &&
                                emailController.text != "" &&
                                passwordController.text != "" &&
                                confirmedPasswordController.text != "" &&
                                orgnizationController.text != "") {
                              _bottonEnabled = true;
                            } else {
                              _bottonEnabled = false;
                            }
                          });
                        },
                        controller: confirmedPasswordController,
                        keyboardType: TextInputType.text,
                        obscureText: _isConfirmedPasswordHidden,
                        decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)
                                ?.registerPasswordHint2,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmedPasswordHidden
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Theme.of(context).primaryColorDark,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isConfirmedPasswordHidden =
                                      !_isConfirmedPasswordHidden;
                                });
                              },
                            )),
                      ),
                    ),
                    Text(
                      verificationMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 10),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    SizedBox(
                      width: 300,
                      child: ElevatedButton(
                        onPressed: !_bottonEnabled
                            ? null
                            : () {
                                RegisterRequest request = RegisterRequest(
                                    (builder) => builder
                                      ..userName = userNameController.text
                                      ..email = emailController.text
                                      ..organization =
                                          orgnizationController.text
                                      ..password = passwordController.text
                                      ..confirmedPassword =
                                          confirmedPasswordController.text);
                                Future<RegisterResponse> response =
                                    accountRepository.register(request);
                                response.then((value) => {
                                      if (value.registerResult)
                                        {Navigator.pushNamed(context, '/')}
                                      else
                                        {
                                          setState(() {
                                            Locale myLocale =
                                                Localizations.localeOf(context);
                                            verificationMessage =
                                                I18nHelper.getI18nByLocale(
                                                    value.verification,
                                                    myLocale);
                                          })
                                        }
                                    });
                              },
                        child: Text(
                          AppLocalizations.of(context)!.signUp,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 17),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.accountCheck,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/login');
                          },
                          child: Text(
                            AppLocalizations.of(context)!.backToRegister,
                            style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ))),
    );
  }
}
