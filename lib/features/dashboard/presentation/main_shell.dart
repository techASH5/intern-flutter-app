import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Main shell with persistent bottom navigation bar
class MainShell extends StatefulWidget {
  final Widget child;
  
  const MainShell({
    super.key,
    required this.child,
  });
  
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  
  final List<NavigationItem> _items = [
    NavigationItem(
      label: 'Dashboard',
      icon: LucideIcons.layoutDashboard,
      path: '/dashboard',
    ),
    NavigationItem(
      label: 'Vehicles',
      icon: LucideIcons.car,
      path: '/vehicles',
    ),
    NavigationItem(
      label: 'Appointments',
      icon: LucideIcons.calendar,
      path: '/appointments',
    ),
    NavigationItem(
      label: 'Analytics',
      icon: LucideIcons.barChart3,
      path: '/analytics',
    ),
    NavigationItem(
      label: 'Profile',
      icon: LucideIcons.user,
      path: '/profile',
    ),
  ];
  
  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    context.go(_items[index].path);
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update current index based on current route
    final location = GoRouterState.of(context).matchedLocation;
    final index = _items.indexWhere((item) => item.path == location);
    if (index != -1 && index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onItemTapped,
        destinations: _items
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}

class NavigationItem {
  final String label;
  final IconData icon;
  final String path;
  
  NavigationItem({
    required this.label,
    required this.icon,
    required this.path,
  });
}
