import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../vehicles/presentation/vehicles_provider.dart';
import '../domain/appointment_model.dart';
import 'appointments_provider.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appointmentsProvider);
    final vehiclesState = ref.watch(vehiclesProvider);
    final active = state.activeAppointments;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [AppColors.darkBackground, AppColors.darkCardBackground]
                : [AppColors.lightBackground1, AppColors.lightBackground2],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Appointments',
                              style:
                                  Theme.of(context).textTheme.displaySmall),
                          Text(
                            '${active.length} upcoming',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: AppColors.primaryViolet,
                                    fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.refreshCw),
                        onPressed: () => ref
                            .read(appointmentsProvider.notifier)
                            .loadAppointments(),
                      ),
                    ],
                  ),
                ),
              ),

              if (state.isLoading && active.isEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const _ApptShimmer(),
                    childCount: 3,
                  ),
                )
              else if (active.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.calendarX2,
                            size: 56, color: AppColors.primaryViolet),
                        const SizedBox(height: 16),
                        Text('No upcoming appointments',
                            style:
                                Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 8),
                        Text('Book a service slot to get started',
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () =>
                              context.push('/appointments/add'),
                          icon: const Icon(LucideIcons.plus),
                          label: const Text('Book Appointment'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 4),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final appt = active[i];
                        final vehicleName = vehiclesState.vehicles
                                .where((v) => v.id == appt.vehicleId)
                                .firstOrNull
                                ?.displayName ??
                            'Unknown Vehicle';
                        return _AppointmentCard(
                          appointment: appt,
                          vehicleName: vehicleName,
                          onCancel: () => _cancelConfirm(context, ref, appt),
                          onReschedule: () =>
                              _rescheduleSheet(context, ref, appt),
                        );
                      },
                      childCount: active.length,
                    ),
                  ),
                ),

              // Cancelled / Completed history section
              if (state.appointments.any((a) => a.isCancelled || a.isRejected || a.isCompleted)) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Text('History',
                        style: Theme.of(context).textTheme.headlineMedium),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final past = state.appointments
                            .where((a) =>
                                a.isCancelled ||
                                a.isRejected ||
                                a.isCompleted)
                            .toList()
                          ..sort((a, b) => b.appointmentDate
                              .compareTo(a.appointmentDate));
                        if (i >= past.length) return null;
                        final appt = past[i];
                        final vehicleName = vehiclesState.vehicles
                                .where((v) => v.id == appt.vehicleId)
                                .firstOrNull
                                ?.displayName ??
                            'Unknown';
                        return _AppointmentCard(
                          appointment: appt,
                          vehicleName: vehicleName,
                          onCancel: null,
                          onReschedule: null,
                        );
                      },
                      childCount: state.appointments
                          .where((a) =>
                              a.isCancelled || a.isRejected || a.isCompleted)
                          .length,
                    ),
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/appointments/add'),
        backgroundColor: AppColors.primaryViolet,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus),
        label: const Text('Book Slot',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Future<void> _cancelConfirm(
      BuildContext context, WidgetRef ref, Appointment appt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Text(
            'Cancel the ${appt.serviceCategory} appointment on ${DateFormat('MMM dd, yyyy').format(appt.appointmentDate)}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep it')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.overdueRed),
            child: const Text('Cancel Appointment'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(appointmentsProvider.notifier).cancel(appt.id);
    }
  }

  Future<void> _rescheduleSheet(
      BuildContext context, WidgetRef ref, Appointment appt) async {
    DateTime picked = appt.appointmentDate;
    final newDate = await showDatePicker(
      context: context,
      initialDate: appt.appointmentDate.isAfter(DateTime.now())
          ? appt.appointmentDate
          : DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (newDate != null && context.mounted) {
      picked = newDate;
      ref.read(appointmentsProvider.notifier).reschedule(appt.id, picked);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Rescheduled to ${DateFormat('MMM dd, yyyy').format(picked)}'),
          backgroundColor: AppColors.healthyGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Appointment card
// ---------------------------------------------------------------------------
class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final String vehicleName;
  final VoidCallback? onCancel;
  final VoidCallback? onReschedule;

  const _AppointmentCard({
    required this.appointment,
    required this.vehicleName,
    required this.onCancel,
    required this.onReschedule,
  });

  Color get _statusColor {
    switch (appointment.status) {
      case 'Approved':
        return AppColors.healthyGreen;
      case 'Pending':
        return AppColors.dueSoonOrange;
      case 'Rejected':
      case 'Cancelled':
        return AppColors.overdueRed;
      case 'Completed':
        return AppColors.primaryViolet;
      default:
        return AppColors.primaryViolet;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(LucideIcons.calendar, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appointment.serviceCategory,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(vehicleName,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.primaryViolet)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(appointment.status,
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(LucideIcons.calendarDays,
                  size: 14, color: AppColors.primaryViolet),
              const SizedBox(width: 6),
              Text(
                DateFormat('EEEE, MMM dd, yyyy • hh:mm a')
                    .format(appointment.appointmentDate),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),

          // Actions
          if (onCancel != null || onReschedule != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onReschedule != null)
                  TextButton.icon(
                    onPressed: onReschedule,
                    icon: const Icon(LucideIcons.calendarClock, size: 16),
                    label: const Text('Reschedule'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryViolet),
                  ),
                if (onCancel != null)
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(LucideIcons.x, size: 16),
                    label: const Text('Cancel'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.overdueRed),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ApptShimmer extends StatelessWidget {
  const _ApptShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c =
        isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.06);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: GlassCard(
        child: Column(children: [
          Row(children: [
            Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: c, borderRadius: BorderRadius.circular(10))),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  height: 14,
                  width: 130,
                  decoration: BoxDecoration(
                      color: c, borderRadius: BorderRadius.circular(7))),
              const SizedBox(height: 6),
              Container(
                  height: 12,
                  width: 90,
                  decoration: BoxDecoration(
                      color: c, borderRadius: BorderRadius.circular(6))),
            ]),
          ]),
          const SizedBox(height: 10),
          Container(
              height: 12,
              width: double.infinity,
              decoration:
                  BoxDecoration(color: c, borderRadius: BorderRadius.circular(6))),
        ]),
      ),
    );
  }
}
