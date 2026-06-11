import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/onepiece_fonts.dart';

class ICP extends StatelessWidget {
  const ICP({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 35,
      width: 200,
      color: Colors.black45,
      child: TextButton(
          onPressed: () {
            _launchURL("https://beian.miit.gov.cn/");
          },
          child: Text(
            "沪ICP备2024075390号",
            style: OnepieceFonts.superSmallContentStyleWhite,
          )),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw 'Could not launch $url';
    }
  }
}
