import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RootShell extends StatelessWidget {
  const RootShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  void _onTap(int i) {
    navigationShell.goBranch(
      i,
      // Nếu đang ở đúng tab và muốn về root của tab đó
      initialLocation: i == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: navigationShell), // nội dung tab
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        surfaceTintColor: Colors.white,
        indicatorColor: const Color.fromARGB(255, 84, 178, 255),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Contacts',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            selectedIcon: Icon(
              Icons.qr_code_scanner,
            ), // không có filled → giữ nguyên
            label: 'Scan',
          ),
          NavigationDestination(
            // Nếu muốn badge số lượng thông báo, dùng Badge:
            // icon: Badge(label: Text('3'), child: Icon(Icons.notifications_none)),
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({this.selected = false});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected
            ? Colors.white
            : const Color.fromARGB(255, 255, 255, 255),
        border: Border.all(
          color: selected
              ? Colors.white
              : const Color.fromARGB(0, 96, 183, 255),
          width: 2,
        ),
      ),
    );
  }
}
