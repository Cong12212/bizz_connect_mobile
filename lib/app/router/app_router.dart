import 'package:bizz_connect_mobile/features/tags/view/tags_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/controller/auth_controller.dart';
import '../../features/auth/view/login_page.dart';
import '../../features/auth/view/signup_page.dart';
import '../../features/auth/view/verify_email_page.dart';
import '../../features/auth/view/forgot_request_page.dart';
import '../../features/auth/view/forgot_verify_page.dart';

import '../../features/home/view/home_page.dart';
import '../../features/contacts/view/contacts_page.dart';
import '../../features/contacts/view/scan_page.dart';
import '../../features/notifications/view/notifications_page.dart';
import '../../features/settings/view/settings_page.dart';
import '../../features/contacts/view/contacts_page.dart';
import '../../features/reminders/view/reminder_page.dart';
import '../widgets/splash_gate.dart';

import '../widgets/root_shell.dart';
import 'router_notifier.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashGate()),
      // public
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/signup', builder: (_, __) => const SignUpPage()),
      GoRoute(
        path: '/verify',
        builder: (_, st) => VerifyEmailPage(emailArg: st.extra as String?),
      ),
      GoRoute(path: '/forgot', builder: (_, __) => const ForgotRequestPage()),
      GoRoute(path: '/tags', builder: (_, __) => const TagsPage()),
      GoRoute(path: '/reminders', builder: (_, __) => const RemindersPage()),
      GoRoute(
        path: '/reset-verify',
        builder: (_, __) => const ForgotVerifyPage(),
      ),
      // shell tabs...
      StatefulShellRoute.indexedStack(
        builder: (context, state, navShell) =>
            RootShell(navigationShell: navShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, __) => const HomePage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/contacts',
                builder: (_, __) => const ContactsPage(),
                routes: [
                  GoRoute(path: 'tags', builder: (_, __) => const TagsPage()),
                  GoRoute(
                    path: 'reminders',
                    builder: (_, __) => const RemindersPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/scan', builder: (_, __) => const ScanPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notifications',
                builder: (_, __) => const NotificationsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, __) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final path = state.uri.path;
      final auth = ref.read(authControllerProvider);

      // Splash luôn được phép
      if (path == '/splash') return null;

      // Chưa bootstrap xong => không redirect (để Splash tự điều hướng)
      if (!auth.bootstrapped) return null;

      final loggedIn = (auth.token ?? '').isNotEmpty;
      final verified = auth.isVerified == true;
      final isPublic = path == '/login' || path == '/signup';
      final isVerify = path == '/verify';
      final isRecovery = path == '/forgot' || path == '/reset-verify';

      if (!loggedIn) return isPublic || isRecovery ? null : '/login';
      if (loggedIn && !verified && !isVerify) return '/verify';
      if (loggedIn && verified && (isPublic || isVerify)) return '/home';
      return null;
    },
  );
});
