import 'package:flutter/material.dart';
import '../ui/kit.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavigationDestination>? items;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items,
  });

  @override
  Widget build(BuildContext context) => NavigationBar(
    height: 68,
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    selectedIndex: currentIndex,
    onDestinationSelected: onTap,
    backgroundColor: Colors.white,
    indicatorColor: const Color(0xFFDDF7E8),
    destinations:
        items ??
        const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Course',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'Notif',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
  );
}

/// Bottom navigation shared by every primary page for a role.
class RoleBottomNav extends StatelessWidget {
  final String role;
  final int currentIndex;

  const RoleBottomNav({
    super.key,
    required this.role,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) =>
      EduBottomNav(role: role, current: currentIndex);
}
