import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/health_score_gauge.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../notifications/presentation/notifications_provider.dart';
import '../../vehicles/presentation/vehicles_provider.dart';
import '../../appointments/presentation/appointments_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final vehiclesState = ref.watch(vehiclesProvider);
    final apptState = ref.watch(appointmentsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Compute fleet health score (average of all vehicle scores)
    final vehiclesWithScore = vehiclesState.vehicles
        .where((v) => v.healthScore != null)
        .toList();
    final avgScore = vehiclesWithScore.isEmpty
        ? 0.0
        : vehiclesWithScore
                .map((v) => v.healthScore!)
                .reduce((a, b) => a + b) /
            vehiclesWithScore.length;

    // Gather all prediction alerts across fleet
    final allAlerts = vehiclesState.vehicles
        .where((v) => v.predictions != null)
        .expand((v) => v.predictions!
            .where((p) => p.isOverdue || p.isDueSoon)
            .map((p) => _AlertData(
                  component: p.component,
                  vehicleName: v.displayName,
                  status: p.status,
                  remainingKm: p.remainingKm,
                  color: p.isOverdue
                      ? AppColors.overdueRed
                      : AppColors.dueSoonOrange,
                )))
        .toList();

    final overdueCount =
        allAlerts.where((a) => a.status == 'Overdue').length;
    final upcomingApptCount = apptState.activeAppointments.length;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.darkBackground, AppColors.darkCardBackground]
                : [AppColors.lightBackground1, AppColors.lightBackground2],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                ref.read(vehiclesProvider.notifier).loadVehicles(),
                ref.read(appointmentsProvider.notifier).loadAppointments(),
                ref.read(notificationsProvider.notifier).loadNotifications(),
              ]);
            },
            color: AppColors.primaryViolet,
            child: CustomScrollView(
              slivers: [
                // ── Header ──────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, ${user?.name.split(' ').first ?? "there"} 👋',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Here\'s your fleet overview',
                                style:
                                    Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        // Notifications bell
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              icon: const Icon(LucideIcons.bell),
                              onPressed: () => context.push('/notifications'),
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    AppColors.primaryViolet.withOpacity(0.1),
                              ),
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                right: 4,
                                top: 4,
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: AppColors.overdueRed,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      unreadCount > 9
                                          ? '9+'
                                          : '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Fleet Health Score ───────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GlassCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  const Icon(LucideIcons.activity,
                                      color: AppColors.primaryViolet,
                                      size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Fleet Health',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium,
                                  ),
                                ]),
                                const SizedBox(height: 12),
                                Text(
                                  avgScore >= 75
                                      ? '🟢 Your vehicles are in great condition!'
                                      : avgScore >= 50
                                          ? '🟡 Some maintenance is needed'
                                          : '🔴 Immediate attention required',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                if (vehiclesState.isLoading)
                                  const LinearProgressIndicator(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          HealthScoreGauge(
                            score: avgScore,
                            size: 110,
                            strokeWidth: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ── Quick Summary Grid ───────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildListDelegate([
                      _SummaryCard(
                        icon: LucideIcons.car,
                        title: 'Active Vehicles',
                        value: '${vehiclesState.vehicles.length}',
                        color: AppColors.primaryViolet,
                        onTap: () => context.go('/vehicles'),
                      ),
                      _SummaryCard(
                        icon: LucideIcons.alertCircle,
                        title: 'Overdue Items',
                        value: '$overdueCount',
                        color: AppColors.overdueRed,
                        onTap: () => context.go('/vehicles'),
                      ),
                      _SummaryCard(
                        icon: LucideIcons.calendar,
                        title: 'Appointments',
                        value: '$upcomingApptCount',
                        color: AppColors.dueSoonOrange,
                        onTap: () => context.go('/appointments'),
                      ),
                      _SummaryCard(
                        icon: LucideIcons.clipboardList,
                        title: 'Service Logs',
                        value: '',
                        color: AppColors.healthyGreen,
                        onTap: () => context.push('/service-logs'),
                        showArrow: true,
                      ),
                    ]),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ── Maintenance Alerts ───────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Maintenance Alerts',
                          style:
                              Theme.of(context).textTheme.headlineMedium,
                        ),
                        if (allAlerts.isNotEmpty)
                          TextButton(
                            onPressed: () => context.go('/vehicles'),
                            child: const Text('View All'),
                          ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // Alerts list
                if (vehiclesState.isLoading && allAlerts.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GlassCard(
                        child: const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    ),
                  )
                else if (allAlerts.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GlassCard(
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.healthyGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(LucideIcons.checkCircle2,
                                color: AppColors.healthyGreen, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('All Systems Good!',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                            color: AppColors.healthyGreen,
                                            fontWeight: FontWeight.w700)),
                                Text(
                                  'No overdue or due-soon maintenance.',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      child: GlassCard(
                        child: Column(
                          children: allAlerts
                              .take(5)
                              .map((a) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _AlertRow(alert: a),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ),

                // ── Upcoming Appointments preview ────────────────────────────
                if (apptState.activeAppointments.isNotEmpty) ...[
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Upcoming Appointments',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium),
                          TextButton(
                            onPressed: () => context.go('/appointments'),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GlassCard(
                        child: Column(
                          children: apptState.activeAppointments
                              .take(3)
                              .map((a) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 10),
                                    child: Row(children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryViolet
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                            LucideIcons.calendarCheck,
                                            size: 16,
                                            color: AppColors.primaryViolet),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(a.serviceCategory,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w600)),
                                              Text(
                                                '${a.appointmentDate.day}/${a.appointmentDate.month}/${a.appointmentDate.year}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ]),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.dueSoonOrange
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(a.status,
                                            style: const TextStyle(
                                                color:
                                                    AppColors.dueSoonOrange,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700)),
                                      ),
                                    ]),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary card widget
// ---------------------------------------------------------------------------
class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback? onTap;
  final bool showArrow;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.onTap,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: showArrow
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 6),
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center),
                Icon(LucideIcons.arrowRight, color: color, size: 16),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
                Text(title,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Alert row
// ---------------------------------------------------------------------------
class _AlertData {
  final String component;
  final String vehicleName;
  final String status;
  final int? remainingKm;
  final Color color;

  const _AlertData({
    required this.component,
    required this.vehicleName,
    required this.status,
    required this.remainingKm,
    required this.color,
  });
}

class _AlertRow extends StatelessWidget {
  final _AlertData alert;
  const _AlertRow({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: alert.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              Icon(LucideIcons.alertTriangle, color: alert.color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(alert.component,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
              Text(alert.vehicleName,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: alert.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: alert.color.withOpacity(0.3)),
              ),
              child: Text(alert.status,
                  style: TextStyle(
                      color: alert.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
            if (alert.remainingKm != null)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  alert.remainingKm! >= 0
                      ? '${alert.remainingKm} km left'
                      : '${alert.remainingKm!.abs()} km overdue',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: alert.color),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
