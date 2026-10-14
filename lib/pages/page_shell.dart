import 'package:flutter/material.dart';
import '../components/navigation/bottom_nav.dart';
import '../components/navigation/app_bar.dart';

class MobilePageShell extends StatelessWidget {
  final String title;
  final Widget body;
  final int index;
  final ValueChanged<int>? onNav;
  final List<Widget>? actions;

  const MobilePageShell({
    super.key,
    required this.title,
    required this.body,
    this.index = 0,
    this.onNav,
    this.actions,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: EduvaraAppBar(title: title, actions: actions),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: body,
      ),
    ),
    bottomNavigationBar: BottomNav(currentIndex: index, onTap: onNav ?? (_) {}),
  );
}
