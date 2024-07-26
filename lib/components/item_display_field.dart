import 'package:flutter/material.dart';
import '../constants/onepiece_fonts.dart';

class ItemDisplayField extends StatelessWidget {
  final Widget icon;
  final String label;
  final String value;
  const ItemDisplayField(
      {super.key,
      required this.icon,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 300,
          height: 30,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              icon,
              Padding(
                padding: const EdgeInsets.only(left: 3),
                child: Text(
                  label,
                  style: OnepieceFonts.deepBlackHintFont,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 300,
          height: 80,
          child: Text(
            value,
            style: OnepieceFonts.contentStyle,
          ),
        ),
      ],
    );
  }
}
