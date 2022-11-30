import 'package:flutter/material.dart';

class OnepieceAlert {
  static Function getBasicAlertDialogFunc(
      BuildContext context, String title, String displayMessage) {
    return () => showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title, style: const TextStyle(fontSize: 22)),
            content: Text(displayMessage),
            actions: [
              TextButton(onPressed: () {}, child: const Text("continue")),
            ],
          );
        });
  }
}
