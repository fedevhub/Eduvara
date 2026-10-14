import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SideNav extends StatelessWidget {
  final String role;
  final int selected;
  final ValueChanged<int> onTap;

  const SideNav({
    super.key,
    required this.role,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => NavigationRail(
    selectedIndex: selected,
    onDestinationSelected: onTap,
    labelType: NavigationRailLabelType.all,
    backgroundColor: Colors.white,
    indicatorColor: AppColors.primarySoft,
    leading: Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(role, style: const TextStyle(fontWeight: FontWeight.w800)),
    ),
    destinations: const [
      NavigationRailDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: Text('Home'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.menu_book_outlined),
        selectedIcon: Icon(Icons.menu_book),
        label: Text('Course'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: Text('Profile'),
      ),
    ],
  );
}
