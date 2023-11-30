import 'package:flutter/material.dart';

class UserDetailView extends StatefulWidget {
  final String userId;
  const UserDetailView({super.key, required this.userId});

  @override
  State<UserDetailView> createState() => _UserDetailViewState();
}

class _UserDetailViewState extends State<UserDetailView> {
  @override
  Widget build(BuildContext context) {
    return  Container(color: Colors.yellow,child: const Text("this is user detail"),);
  }
}
