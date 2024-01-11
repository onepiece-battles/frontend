import 'package:flutter/material.dart';

class GroupDetailView extends StatefulWidget {
  final String groupId;
  const GroupDetailView({super.key, required this.groupId}) ;

  @override
  State<GroupDetailView> createState() => _GroupDetailViewState();
}

class _GroupDetailViewState extends State<GroupDetailView> {
  @override
  Widget build(BuildContext context) {
    return Text("group detail");
  }
}
