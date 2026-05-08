import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/clients/presentation/client_detail_screen.dart';
import '../../features/clients/presentation/client_form_screen.dart';
import '../../features/clients/presentation/client_list_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/deployments/presentation/deployment_detail_screen.dart';
import '../../features/deployments/presentation/deployment_form_screen.dart';
import '../../features/deployments/presentation/deployment_list_screen.dart';
import '../../features/employees/presentation/employee_detail_screen.dart';
import '../../features/employees/presentation/employee_form_screen.dart';
import '../../features/employees/presentation/employee_list_screen.dart';
import '../../features/placeholder/placeholder_screen.dart';
import '../../features/shell/app_shell.dart';

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._read) {
    _last = _read();
  }
  final AuthState Function() _read;
  AuthState? _last;
  void update() {
    final current = _read();
    if (_last == null || current.status != _last!.status) {
      _last = current;
      notifyListeners();
    }
  }
}

GoRouter buildRouter(WidgetRef ref) {
  final listenable = _AuthListenable(() => ref.read(authControllerProvider));
  ref.listen(authControllerProvider, (_, __) => listenable.update());

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: listenable,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;

      const publicRoutes = {
        '/splash',
        '/login',
        '/register',
        '/forgot-password',
        '/verify-otp',
      };

      if (auth.status == AuthStatus.unknown) {
        return loc == '/splash' ? null : '/splash';
      }
      if (auth.status == AuthStatus.unauthenticated) {
        if (publicRoutes.contains(loc)) return null;
        return '/login';
      }
      // authenticated
      if (publicRoutes.contains(loc)) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return OtpScreen(email: email);
        },
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(
            path: '/employees',
            builder: (_, __) => const EmployeeListScreen(),
            routes: [
              GoRoute(path: 'new', builder: (_, __) => const EmployeeFormScreen()),
              GoRoute(
                path: ':id',
                builder: (_, s) => EmployeeDetailScreen(id: s.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, s) => EmployeeFormScreen(id: s.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/clients',
            builder: (_, __) => const ClientListScreen(),
            routes: [
              GoRoute(path: 'new', builder: (_, __) => const ClientFormScreen()),
              GoRoute(
                path: ':id',
                builder: (_, s) => ClientDetailScreen(id: s.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, s) => ClientFormScreen(id: s.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/deployments',
            builder: (_, __) => const DeploymentListScreen(),
            routes: [
              GoRoute(path: 'new', builder: (_, __) => const DeploymentFormScreen()),
              GoRoute(
                path: ':id',
                builder: (_, s) => DeploymentDetailScreen(id: s.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, s) => DeploymentFormScreen(id: s.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/attendance',
            builder: (_, __) => const PlaceholderScreen(
              title: 'Attendance',
              icon: Icons.fact_check_outlined,
              message: 'QR / GPS attendance and supervisor approvals are part of the next milestone.',
            ),
          ),
          GoRoute(
            path: '/payroll',
            builder: (_, __) => const PlaceholderScreen(
              title: 'Payroll',
              icon: Icons.payments_outlined,
              message: 'Payroll, bonuses, and payslip generation are part of the next milestone.',
            ),
          ),
          GoRoute(
            path: '/invoices',
            builder: (_, __) => const PlaceholderScreen(
              title: 'Invoices',
              icon: Icons.receipt_long_outlined,
              message: 'Invoice generation, payments, and PDF export are part of the next milestone.',
            ),
          ),
          GoRoute(
            path: '/contracts',
            builder: (_, __) => const PlaceholderScreen(
              title: 'Contracts',
              icon: Icons.assignment_turned_in_outlined,
              message: 'Employee and client contracts with expiry alerts are part of the next milestone.',
            ),
          ),
          GoRoute(
            path: '/reports',
            builder: (_, __) => const PlaceholderScreen(
              title: 'Reports',
              icon: Icons.insights_outlined,
              message: 'Attendance, payroll, and revenue dashboards are part of the next milestone.',
            ),
          ),
          GoRoute(
            path: '/notifications',
            builder: (_, __) => const PlaceholderScreen(
              title: 'Notifications',
              icon: Icons.notifications_outlined,
              message: 'Push, email, and FCM-driven notifications are part of the next milestone.',
            ),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const PlaceholderScreen(
              title: 'Settings',
              icon: Icons.settings_outlined,
              message: 'Profile, biometric, theme, and language settings are part of the next milestone.',
            ),
          ),
        ],
      ),
    ],
  );
}
