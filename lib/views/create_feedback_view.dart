import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CreateFeedbackView extends StatefulWidget {
  const CreateFeedbackView({super.key});

  @override
  State<CreateFeedbackView> createState() => _CreateFeedbackViewState();
}

class _CreateFeedbackViewState extends State<CreateFeedbackView> {
  @override
  Widget build(BuildContext context) {
    return  Container(
        width: 400,
        height: 400,
        child: Column(
          children: [
            Row(
              children: [
                DropdownButton(items: [], onChanged: (value) {}),
                DropdownButton(items: [], onChanged: (value) {}),
            ],
            ),
            TextField(),
            TextField(),
            Row(children: [
              ElevatedButton(onPressed: (){}, child: Text("")),
              ElevatedButton(onPressed: (){}, child: Text(''))
            ],)
          ],
        ),
      );

  }
}
