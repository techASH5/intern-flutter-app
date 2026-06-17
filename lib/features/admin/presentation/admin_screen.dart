import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../features/appointments/domain/appointment_model.dart';
import '../../../features/appointments/presentation/appointments_provider.dart';
import '../domain/admin_model.dart';
import 'admin_provider.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final apptState = ref.watch(appointmentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(LucideIcons.arrowLeft),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              AppColors.primaryViolet.withOpacity(0.1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Admin Dashboard',
                                style:
                                    Theme.of(context).textTheme.displaySmall),
                            Text('Platform overview',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: AppColors.primaryViolet)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.refreshCw),
                        onPressed: () {
                          ref.read(adminProvider.notifier).loadAll();
                          ref
                              .read(appointmentsProvider.notifier)
                              .loadAppointments();
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Stats cards
              if (adminState.stats != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _StatsGrid(stats: adminState.stats!),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Tabs
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassCard(
                    padding: const EdgeInsets.all(4),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppColors.primaryViolet,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.users, size: 16),
                              const SizedBox(width: 6),
                              Text('Users (${adminState.users.length})'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.calendar, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                  'Appointments (${apptState.appointments.where((a) => a.isPending).length})'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Tab content
              SliverToBoxAdapter(
                child: animatedTabContent(adminState, apptState),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }

  Widget animatedTabContent(
      AdminState adminState, AppointmentsState apptState) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        return _tabController.index == 0
            ? _UsersTab(
                users: adminState.users,
                isLoading: adminState.isLoading,
                onToggleRole: (user) async {
                  await ref
                      .read(adminProvider.notifier)
                      .toggleRole(user.id, !user.isAdmin);
                },
                onDelete: (user) => _confirmDelete(user),
              )
            : _AppointmentsTab(
                appointments: apptState.appointments,
                isLoading: apptState.isLoading,
                onStatusUpdate: (id, status) => ref
                    .read(appointmentsProvider.notifier)
                    .updateStatus(id, status),
              );
      },
    );
  }

  Future<void> _confirmDelete(AdminUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
            'Permanently delete ${user.name} (${user.email}) from the platform?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.overdueRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(adminProvider.notifier).deleteUser(user.id);
    }
  }
}

// ---------------------------------------------------------------------------
// Stats grid
// ---------------------------------------------------------------------------
class _StatsGrid extends StatelessWidget {
  final AdminStats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem(
          label: 'Users',
          value: '${stats.totalUsers}',
          icon: LucideIcons.users,
          color: AppColors.primaryViolet),
      _StatItem(
          label: 'Vehicles',
          value: '${stats.totalVehicles}',
          icon: LucideIcons.car,
          color: AppColors.healthyGreen),
      _StatItem(
          label: 'Appointments',
          value: '${stats.totalAppointments}',
          icon: LucideIcons.calendar,
          color: AppColors.dueSoonOrange),
      _StatItem(
          label: 'Pending',
          value: '${stats.pendingAppointments}',
          icon: LucideIcons.clock,
          color: AppColors.overdueRed),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: items
          .map((item) => GlassCard(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, color: item.color, size: 28),
                    const SizedBox(height: 6),
                    Text(item.value,
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: item.color)),
                    Text(item.label,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
}

// ---------------------------------------------------------------------------
// Users tab
// ---------------------------------------------------------------------------
class _UsersTab extends StatelessWidget {
  final List<AdminUser> users;
  final bool isLoading;
  final void Function(AdminUser) onToggleRole;
  final void Function(AdminUser) onDelete;

  const _UsersTab({
    required this.users,
    required this.isLoading,
    required this.onToggleRole,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: users
            .map((user) => GlassCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryViolet.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.primaryViolet,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text(user.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                          fontWeight: FontWeight.w600)),
                              if (user.isAdmin) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryViolet
                                        .withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('Admin',
                                      style: TextStyle(
                                          color: AppColors.primaryViolet,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ]),
                            Text(user.email,
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      // Role toggle
                      IconButton(
                        onPressed: () => onToggleRole(user),
                        icon: Icon(
                          user.isAdmin
                              ? LucideIcons.shieldOff
                              : LucideIcons.shieldCheck,
                          size: 18,
                          color: user.isAdmin
                              ? AppColors.dueSoonOrange
                              : AppColors.primaryViolet,
                        ),
                        tooltip:
                            user.isAdmin ? 'Remove Admin' : 'Make Admin',
                      ),
                      // Delete
                      IconButton(
                        onPressed: () => onDelete(user),
                        icon: const Icon(LucideIcons.trash2,
                            size: 16, color: AppColors.overdueRed),
                        tooltip: 'Delete User',
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Appointments tab (admin)
// ---------------------------------------------------------------------------
class _AppointmentsTab extends StatelessWidget {
  final List<Appointment> appointments;
  final bool isLoading;
  final Future<bool> Function(String id, String status) onStatusUpdate;

  const _AppointmentsTab({
    required this.appointments,
    required this.isLoading,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ));
    }

    final pending =
        appointments.where((a) => a.isPending).toList()
          ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

    if (pending.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(LucideIcons.calendarCheck,
                  size: 48, color: AppColors.healthyGreen),
              SizedBox(height: 16),
              Text('No pending appointments',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: pending
            .map((a) => GlassCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                AppColors.dueSoonOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(LucideIcons.calendar,
                              size: 18,
                              color: AppColors.dueSoonOrange),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.serviceCategory,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                          fontWeight: FontWeight.w700)),
                              Text(
                                DateFormat('MMM dd, yyyy • hh:mm a')
                                    .format(a.appointmentDate),
                                style:
                                    Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                AppColors.dueSoonOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: AppColors.dueSoonOrange
                                    .withOpacity(0.3)),
                          ),
                          child: const Text('Pending',
                              style: TextStyle(
                                  color: AppColors.dueSoonOrange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () =>
                                onStatusUpdate(a.id, 'Rejected'),
                            icon: const Icon(LucideIcons.x, size: 14),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.overdueRed,
                              side: const BorderSide(
                                  color: AppColors.overdueRed),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () =>
                                onStatusUpdate(a.id, 'Approved'),
                            icon: const Icon(LucideIcons.check, size: 14),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.healthyGreen,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () =>
                                onStatusUpdate(a.id, 'Completed'),
                            icon: const Icon(
                                LucideIcons.checkCircle2,
                                size: 14),
                            label: const Text('Complete'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}
