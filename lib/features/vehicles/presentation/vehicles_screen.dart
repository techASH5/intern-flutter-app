import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/health_score_gauge.dart';
import '../domain/vehicle_model.dart';
import 'vehicles_provider.dart';

class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vehiclesProvider);

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
                          Text('My Fleet',
                              style: Theme.of(context).textTheme.displaySmall),
                          Text(
                            '${state.vehicles.length} vehicle${state.vehicles.length == 1 ? '' : 's'}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: AppColors.primaryViolet,
                                    fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      // Refresh
                      IconButton(
                        onPressed: () =>
                            ref.read(vehiclesProvider.notifier).loadVehicles(),
                        icon: const Icon(LucideIcons.refreshCw),
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                ),
              ),

              // Error banner
              if (state.errorMessage != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.overdueRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.overdueRed.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.alertCircle,
                              color: AppColors.overdueRed, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(state.errorMessage!,
                                style: const TextStyle(
                                    color: AppColors.overdueRed)),
                          ),
                          TextButton(
                            onPressed: () => ref
                                .read(vehiclesProvider.notifier)
                                .loadVehicles(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Loading shimmer
              if (state.isLoading && state.vehicles.isEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const _VehicleShimmerCard(),
                    childCount: 3,
                  ),
                )
              // Empty state
              else if (state.vehicles.isEmpty)
                SliverFillRemaining(
                  child: _EmptyVehiclesState(
                    onAdd: () => context.push('/vehicles/add'),
                  ),
                )
              // Vehicle list
              else
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final vehicle = state.vehicles[index];
                        return _VehicleCard(vehicle: vehicle);
                      },
                      childCount: state.vehicles.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/vehicles/add'),
        backgroundColor: AppColors.primaryViolet,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus),
        label: const Text('Add Vehicle',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Vehicle card
// ---------------------------------------------------------------------------
class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final score = vehicle.healthScore ?? 0.0;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 14),
      onTap: () => context.push('/vehicles/${vehicle.id}'),
      child: Row(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryViolet.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(LucideIcons.car,
                color: AppColors.primaryViolet, size: 28),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.displayName,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _InfoChip(
                        icon: LucideIcons.gauge,
                        label:
                            '${vehicle.currentOdometer.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} km'),
                    const SizedBox(width: 8),
                    _InfoChip(
                        icon: LucideIcons.zap, label: vehicle.fuelType),
                  ],
                ),
                const SizedBox(height: 6),
                // Alert count
                Builder(builder: (context) {
                  final overdueCount = vehicle.predictions
                          ?.where((p) => p.isOverdue)
                          .length ??
                      0;
                  final dueSoonCount = vehicle.predictions
                          ?.where((p) => p.isDueSoon)
                          .length ??
                      0;
                  if (overdueCount > 0) {
                    return _StatusBadge(
                        label: '$overdueCount Overdue',
                        color: AppColors.overdueRed);
                  } else if (dueSoonCount > 0) {
                    return _StatusBadge(
                        label: '$dueSoonCount Due Soon',
                        color: AppColors.dueSoonOrange);
                  }
                  return _StatusBadge(
                      label: 'All Good', color: AppColors.healthyGreen);
                }),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Health gauge
          HealthScoreGauge(
            score: score,
            size: 72,
            strokeWidth: 7,
            showLabel: false,
          ),
          const SizedBox(width: 4),
          const Icon(LucideIcons.chevronRight, size: 18),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12,
            color: Theme.of(context).textTheme.bodySmall?.color),
        const SizedBox(width: 3),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------
class _EmptyVehiclesState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyVehiclesState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primaryViolet.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.car,
                size: 64, color: AppColors.primaryViolet),
          ),
          const SizedBox(height: 24),
          Text('No vehicles yet',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Add your first vehicle to start\ntracking maintenance',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(LucideIcons.plus),
            label: const Text('Add Vehicle'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer placeholder
// ---------------------------------------------------------------------------
class _VehicleShimmerCard extends StatelessWidget {
  const _VehicleShimmerCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmerColor =
        isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.06);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: GlassCard(
        child: Row(
          children: [
            Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(14))),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 16,
                      width: 140,
                      decoration: BoxDecoration(
                          color: shimmerColor,
                          borderRadius: BorderRadius.circular(8))),
                  const SizedBox(height: 8),
                  Container(
                      height: 12,
                      width: 100,
                      decoration: BoxDecoration(
                          color: shimmerColor,
                          borderRadius: BorderRadius.circular(6))),
                ],
              ),
            ),
            Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                    color: shimmerColor, shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }
}
