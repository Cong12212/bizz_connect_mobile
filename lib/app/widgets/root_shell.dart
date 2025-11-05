import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/notifications/controller/unread_count_provider.dart';

class RootShell extends ConsumerWidget {
  const RootShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  void _onTap(BuildContext context, int i) {
    navigationShell.goBranch(
      i,
      initialLocation: i == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: navigationShell),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => _onTap(context, i),
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        surfaceTintColor: Colors.white,
        indicatorColor: const Color.fromARGB(255, 84, 178, 255),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Contacts',
          ),
          const NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            selectedIcon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: unreadCount.when(
              data: (count) => count > 0
                  ? Badge(
                      label: Text('$count'),
                      child: const Icon(Icons.notifications_none),
                    )
                  : const Icon(Icons.notifications_none),
              loading: () => const Icon(Icons.notifications_none),
              error: (_, __) => const Icon(Icons.notifications_none),
            ),
            selectedIcon: unreadCount.when(
              data: (count) => count > 0
                  ? Badge(
                      label: Text('$count'),
                      child: const Icon(Icons.notifications),
                    )
                  : const Icon(Icons.notifications),
              loading: () => const Icon(Icons.notifications),
              error: (_, __) => const Icon(Icons.notifications),
            ),
            label: 'Alerts',
          ),
          const NavigationDestination(
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
