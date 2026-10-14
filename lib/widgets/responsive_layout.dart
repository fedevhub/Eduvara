import 'package:flutter/material.dart';
import '../components/navigation/side_nav.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget desktop;
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) => constraints.maxWidth >= 900 ? desktop : mobile,
  );
}

class DesktopScaffold extends StatelessWidget {
  final String role;
  final Widget body;
  const DesktopScaffold({super.key, required this.role, required this.body});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Row(
      children: [
        SideNav(role: role, selected: 0, onTap: (_) {}),
        Expanded(child: body),
      ],
    ),
  );
}
