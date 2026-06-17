import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../config/constants.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../vehicles/presentation/vehicles_provider.dart';
import '../domain/service_log_model.dart';
import 'service_logs_provider.dart';

class ServiceLogsScreen extends ConsumerWidget {
  const ServiceLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(serviceLogsProvider);
    final vehiclesState = ref.watch(vehiclesProvider);
    final logs = state.filteredLogs;

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
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Service Logs',
                              style:
                                  Theme.of(context).textTheme.displaySmall),
                          Text(
                            '${logs.length} record${logs.length == 1 ? '' : 's'}',
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
                        onPressed: () =>
                            ref.read(serviceLogsProvider.notifier).loadLogs(),
                      ),
                    ],
                  ),
                ),
              ),

              // Filters
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    children: [
                      // Vehicle filter
                      DropdownButtonFormField<String?>(
                        value: state.filterVehicleId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Filter by Vehicle',
                          prefixIcon: Icon(LucideIcons.car, size: 18),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('All Vehicles')),
                          ...vehiclesState.vehicles.map((v) => DropdownMenuItem(
                                value: v.id,
                                child: Text(v.displayName,
                                    overflow: TextOverflow.ellipsis),
                              )),
                        ],
                        onChanged: (v) => ref
                            .read(serviceLogsProvider.notifier)
                            .setVehicleFilter(v),
                      ),
                      const SizedBox(height: 10),
                      // Category filter
                      DropdownButtonFormField<String?>(
                        value: state.filterCategory,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Filter by Category',
                          prefixIcon: Icon(LucideIcons.tag, size: 18),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('All Categories')),
                          ...AppConstants.serviceCategories
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  )),
                        ],
                        onChanged: (v) => ref
                            .read(serviceLogsProvider.notifier)
                            .setCategoryFilter(v),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // List
              if (state.isLoading && logs.isEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const _LogShimmer(),
                    childCount: 4,
                  ),
                )
              else if (logs.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.clipboardList,
                            size: 56, color: AppColors.primaryViolet),
                        const SizedBox(height: 16),
                        Text('No service logs yet',
                            style:
                                Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 8),
                        Text(
                          'Log your first maintenance record',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _ServiceLogCard(
                        log: logs[i],
                        vehicleName: vehiclesState.vehicles
                                .where((v) => v.id == logs[i].vehicleId)
                                .firstOrNull
                                ?.displayName ??
                            'Unknown Vehicle',
                        onDelete: () => _confirmDelete(context, ref, logs[i]),
                      ),
                      childCount: logs.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/service-logs/add'),
        backgroundColor: AppColors.primaryViolet,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus),
        label: const Text('Log Service',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, ServiceLog log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Log'),
        content: Text(
            'Delete the "${log.serviceCategory}" record from ${DateFormat('MMM dd, yyyy').format(log.serviceDate)}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.overdueRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(serviceLogsProvider.notifier).deleteLog(log.id);
    }
  }
}

// ---------------------------------------------------------------------------
// Log card
// ---------------------------------------------------------------------------
class _ServiceLogCard extends StatelessWidget {
  final ServiceLog log;
  final String vehicleName;
  final VoidCallback onDelete;

  const _ServiceLogCard({
    required this.log,
    required this.vehicleName,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryViolet.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.wrench,
                    color: AppColors.primaryViolet, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log.serviceCategory,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${log.cost.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.healthyGreen,
                        ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon:
                        const Icon(LucideIcons.trash2, size: 16),
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.overdueRed,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Text(log.serviceDescription,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(
            children: [
              _MetaItem(
                  icon: LucideIcons.calendar,
                  label: DateFormat('MMM dd, yyyy').format(log.serviceDate)),
              const SizedBox(width: 16),
              _MetaItem(
                  icon: LucideIcons.gauge,
                  label: '${log.odometerReading} km'),
              if (log.serviceCenter != null) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: _MetaItem(
                      icon: LucideIcons.mapPin,
                      label: log.serviceCenter!),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 12, color: Theme.of(context).textTheme.bodySmall?.color),
        const SizedBox(width: 4),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _LogShimmer extends StatelessWidget {
  const _LogShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c =
        isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.06);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    width: 120,
                    decoration: BoxDecoration(
                        color: c, borderRadius: BorderRadius.circular(7))),
                const SizedBox(height: 6),
                Container(
                    height: 12,
                    width: 80,
                    decoration: BoxDecoration(
                        color: c, borderRadius: BorderRadius.circular(6))),
              ]),
            ]),
            const SizedBox(height: 12),
            Container(
                height: 12,
                width: double.infinity,
                decoration:
                    BoxDecoration(color: c, borderRadius: BorderRadius.circular(6))),
          ],
        ),
      ),
    );
  }
}
