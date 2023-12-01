import 'package:flutter/material.dart';

import '../constants/path_constants.dart';

class PendingAnimation extends StatefulWidget {
  const PendingAnimation({Key? key}) : super(key: key);

  @override
  State<PendingAnimation> createState() => _PendingAnimationState();
}

class _PendingAnimationState extends State<PendingAnimation> with TickerProviderStateMixin{
  late final AnimationController _animationController;
  late final Animation<double> _animation;
  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat();
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: RotationTransition(
          turns: _animation,
          child: const Image(
            width: 150,
            height: 150,
            image: AssetImage(PathConstants.sunnyHead),
          ),
        ),
      ),
    );
  }
}
