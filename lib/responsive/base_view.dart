import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';

abstract class BaseView<T extends StatefulWidget> extends State<T> {
  var pageController = PageController(initialPage: 0);
}
