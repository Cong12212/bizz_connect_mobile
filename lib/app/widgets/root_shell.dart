import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/notifications/controller/unread_count_provider.dart';

class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  bool _isNavBarVisible = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_isNavBarVisible) setState(() => _isNavBarVisible = false);
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_isNavBarVisible) setState(() => _isNavBarVisible = true);
    }
  }

  void _onTap(BuildContext context, int i) {
    widget.navigationShell.goBranch(
      i,
      initialLocation: i == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: Container(
        color: Colors.white,
        child: SafeArea(child: widget.navigationShell),
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: _isNavBarVisible ? Offset.zero : const Offset(0, 1),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: widget.navigationShell.currentIndex,
            onDestinationSelected: (i) => _onTap(context, i),
            height: 80,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            indicatorColor: const Color(0xFF60B7FF).withOpacity(0.2),
            indicatorShape: const CircleBorder(),
            elevation: 0,
            destinations: [
              NavigationDestination(
                icon: Icon(
                  Icons.home_outlined,
                  color: widget.navigationShell.currentIndex == 0
                      ? const Color(0xFF60B7FF)
                      : Colors.grey[400],
                ),
                selectedIcon: const Icon(
                  Icons.home_rounded,
                  color: Color(0xFF60B7FF),
                ),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.people_outline,
                  color: widget.navigationShell.currentIndex == 1
                      ? const Color(0xFF60B7FF)
                      : Colors.grey[400],
                ),
                selectedIcon: const Icon(
                  Icons.people,
                  color: Color(0xFF60B7FF),
                ),
                label: 'Contacts',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.qr_code_scanner,
                  color: widget.navigationShell.currentIndex == 2
                      ? const Color(0xFF60B7FF)
                      : Colors.grey[400],
                ),
                selectedIcon: const Icon(
                  Icons.qr_code_scanner,
                  color: Color(0xFF60B7FF),
                ),
                label: 'Scan',
              ),
              NavigationDestination(
                icon: unreadCount.when(
                  data: (count) => count > 0
                      ? Badge(
                          label: Text('$count'),
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                          child: Icon(
                            Icons.notifications_none,
                            color: widget.navigationShell.currentIndex == 3
                                ? const Color(0xFF60B7FF)
                                : Colors.grey[400],
                          ),
                        )
                      : Icon(
                          Icons.notifications_none,
                          color: widget.navigationShell.currentIndex == 3
                              ? const Color(0xFF60B7FF)
                              : Colors.grey[400],
                        ),
                  loading: () => Icon(
                    Icons.notifications_none,
                    color: widget.navigationShell.currentIndex == 3
                        ? const Color(0xFF60B7FF)
                        : Colors.grey[400],
                  ),
                  error: (_, __) => Icon(
                    Icons.notifications_none,
                    color: widget.navigationShell.currentIndex == 3
                        ? const Color(0xFF60B7FF)
                        : Colors.grey[400],
                  ),
                ),
                selectedIcon: unreadCount.when(
                  data: (count) => count > 0
                      ? Badge(
                          label: Text('$count'),
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                          child: const Icon(
                            Icons.notifications,
                            color: Color(0xFF60B7FF),
                          ),
                        )
                      : const Icon(
                          Icons.notifications,
                          color: Color(0xFF60B7FF),
                        ),
                  loading: () =>
                      const Icon(Icons.notifications, color: Color(0xFF60B7FF)),
                  error: (_, __) =>
                      const Icon(Icons.notifications, color: Color(0xFF60B7FF)),
                ),
                label: 'Alerts',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.person_outline,
                  color: widget.navigationShell.currentIndex == 4
                      ? const Color(0xFF60B7FF)
                      : Colors.grey[400],
                ),
                selectedIcon: const Icon(
                  Icons.person,
                  color: Color(0xFF60B7FF),
                ),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
