import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/presentation/auth_provider.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/dashboard/presentation/main_shell.dart';
import '../features/vehicles/presentation/vehicles_screen.dart';
import '../features/vehicles/presentation/vehicle_detail_screen.dart';
import '../features/vehicles/presentation/add_edit_vehicle_screen.dart';
import '../features/appointments/presentation/appointments_screen.dart';
import '../features/appointments/presentation/add_appointment_screen.dart';
import '../features/analytics/presentation/analytics_screen.dart';
import '../features/service_logs/presentation/service_logs_screen.dart';
import '../features/service_logs/presentation/add_service_log_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/admin/presentation/admin_screen.dart';

/// Router configuration provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final path = state.matchedLocation;
      final isAuthRoute = path == '/login' ||
          path == '/register' ||
          path.startsWith('/forgot-password');

      if (!isAuthenticated && !isAuthRoute) return '/login';
      if (isAuthenticated && isAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
      // ── Auth Routes ────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _fadeTransition(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _slideTransition(
          key: state.pageKey,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => _slideTransition(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
        ),
      ),

      // ── Main Shell ─────────────────────────────────────────────────────────
      ShellRoute(
        pageBuilder: (context, state, child) => NoTransitionPage(
          key: state.pageKey,
          child: MainShell(child: child),
        ),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/vehicles',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const VehiclesScreen(),
            ),
          ),
          GoRoute(
            path: '/appointments',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const AppointmentsScreen(),
            ),
          ),
          GoRoute(
            path: '/analytics',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const AnalyticsScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ProfileScreen(),
            ),
          ),
        ],
      ),

      // ── Vehicles sub-routes ────────────────────────────────────────────────
      GoRoute(
        path: '/vehicles/add',
        pageBuilder: (context, state) => _slideTransition(
          key: state.pageKey,
          child: const AddEditVehicleScreen(),
        ),
      ),
      GoRoute(
        path: '/vehicles/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _slideTransition(
            key: state.pageKey,
            child: VehicleDetailScreen(vehicleId: id),
          );
        },
      ),
      GoRoute(
        path: '/vehicles/:id/edit',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _slideTransition(
            key: state.pageKey,
            child: AddEditVehicleScreen(vehicleId: id),
          );
        },
      ),

      // ── Service Logs sub-routes ────────────────────────────────────────────
      GoRoute(
        path: '/service-logs',
        pageBuilder: (context, state) => _slideTransition(
          key: state.pageKey,
          child: const ServiceLogsScreen(),
        ),
      ),
      GoRoute(
        path: '/service-logs/add',
        pageBuilder: (context, state) => _slideTransition(
          key: state.pageKey,
          child: const AddServiceLogScreen(),
        ),
      ),

      // ── Appointments sub-routes ────────────────────────────────────────────
      GoRoute(
        path: '/appointments/add',
        pageBuilder: (context, state) => _slideTransition(
          key: state.pageKey,
          child: const AddAppointmentScreen(),
        ),
      ),

      // ── Notifications ──────────────────────────────────────────────────────
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => _slideTransition(
          key: state.pageKey,
          child: const NotificationsScreen(),
        ),
      ),

      // ── Admin ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/admin',
        pageBuilder: (context, state) => _slideTransition(
          key: state.pageKey,
          child: const AdminScreen(),
        ),
      ),
    ],
  );
});

// ---------------------------------------------------------------------------
// Custom transitions
// ---------------------------------------------------------------------------
CustomTransitionPage<void> _fadeTransition({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

CustomTransitionPage<void> _slideTransition({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, _, child) =>
        SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
      child: child,
    ),
  );
}
