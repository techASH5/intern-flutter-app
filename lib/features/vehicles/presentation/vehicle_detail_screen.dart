import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/health_score_gauge.dart';
import '../domain/vehicle_model.dart';
import 'vehicles_provider.dart';

class VehicleDetailScreen extends ConsumerStatefulWidget {
  final String vehicleId;
  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  ConsumerState<VehicleDetailScreen> createState() =>
      _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends ConsumerState<VehicleDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _odometerController = TextEditingController();
  bool _updatingOdometer = false;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTab = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  Future<void> _updateOdometer(Vehicle vehicle) async {
    final val = int.tryParse(_odometerController.text.trim());
    if (val == null || val <= vehicle.currentOdometer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid odometer reading higher than current'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _updatingOdometer = true);
    final ok = await ref
        .read(vehiclesProvider.notifier)
        .updateTelemetry(widget.vehicleId, val);
    // Refresh selected vehicle
    ref.read(selectedVehicleProvider(widget.vehicleId).notifier).refresh(widget.vehicleId);
    setState(() => _updatingOdometer = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Odometer updated!' : 'Update failed'),
        backgroundColor: ok ? AppColors.healthyGreen : AppColors.overdueRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (ok) _odometerController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final vehicleAsync = ref.watch(selectedVehicleProvider(widget.vehicleId));
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
        child: vehicleAsync == null
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  // Hero AppBar
                  SliverToBoxAdapter(
                    child: _HeroHeader(
                      vehicle: vehicleAsync,
                      onBack: () => context.pop(),
                      onEdit: () =>
                          context.push('/vehicles/${widget.vehicleId}/edit'),
                      onDelete: () => _confirmDelete(vehicleAsync),
                    ),
                  ),

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
                          unselectedLabelColor:
                              isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(text: 'Diagnostics'),
                            Tab(text: 'Service History'),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // Tab content
                  SliverToBoxAdapter(
                    child: _selectedTab == 0
                        ? _DiagnosticsTab(
                            vehicle: vehicleAsync,
                            odometerController: _odometerController,
                            isUpdating: _updatingOdometer,
                            onUpdateOdometer: () =>
                                _updateOdometer(vehicleAsync),
                          )
                        : _ServiceHistoryTab(vehicleId: widget.vehicleId),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
      ),
    );
  }

  Future<void> _confirmDelete(Vehicle vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content:
            Text('Remove ${vehicle.displayName} from your fleet? This cannot be undone.'),
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
    if (confirmed == true && mounted) {
      final ok = await ref
          .read(vehiclesProvider.notifier)
          .deleteVehicle(widget.vehicleId);
      if (ok && mounted) context.pop();
    }
  }
}

// ---------------------------------------------------------------------------
// Hero header panel
// ---------------------------------------------------------------------------
class _HeroHeader extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HeroHeader({
    required this.vehicle,
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
      child: GlassCard(
        child: Column(
          children: [
            // Top bar
            Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(LucideIcons.arrowLeft),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primaryViolet.withOpacity(0.1),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(LucideIcons.pencil),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primaryViolet.withOpacity(0.1),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(LucideIcons.trash2,
                      color: AppColors.overdueRed),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.overdueRed.withOpacity(0.1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Vehicle icon + info + gauge
            Row(
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryViolet.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(LucideIcons.car,
                      size: 40, color: AppColors.primaryViolet),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.displayName,
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 6),
                      _LabelChip(
                          label: vehicle.registrationNumber,
                          icon: LucideIcons.hash),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _LabelChip(
                              label: vehicle.vehicleType,
                              icon: LucideIcons.tag),
                          const SizedBox(width: 8),
                          _LabelChip(
                              label: vehicle.fuelType,
                              icon: LucideIcons.zap),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _LabelChip(
                          label:
                              '${vehicle.currentOdometer.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} km',
                          icon: LucideIcons.gauge),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Health gauge
                HealthScoreGauge(
                  score: vehicle.healthScore ?? 0,
                  size: 90,
                  strokeWidth: 9,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _LabelChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: AppColors.primaryViolet),
      const SizedBox(width: 4),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Diagnostics tab
// ---------------------------------------------------------------------------
class _DiagnosticsTab extends StatelessWidget {
  final Vehicle vehicle;
  final TextEditingController odometerController;
  final bool isUpdating;
  final VoidCallback onUpdateOdometer;

  const _DiagnosticsTab({
    required this.vehicle,
    required this.odometerController,
    required this.isUpdating,
    required this.onUpdateOdometer,
  });

  @override
  Widget build(BuildContext context) {
    final predictions = vehicle.predictions ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick telemetry update
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(LucideIcons.gauge,
                      color: AppColors.primaryViolet, size: 20),
                  const SizedBox(width: 8),
                  Text('Update Odometer',
                      style: Theme.of(context).textTheme.headlineSmall),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: odometerController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText:
                            'Current: ${vehicle.currentOdometer} km',
                        suffixText: 'km',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: isUpdating ? null : onUpdateOdometer,
                    child: isUpdating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Update'),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Component list
          Text('Component Health',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),

          if (predictions.isEmpty)
            GlassCard(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No prediction data available.\nUpdate odometer to generate predictions.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            ...predictions.map((p) => _ComponentRow(prediction: p)),
        ],
      ),
    );
  }
}

class _ComponentRow extends StatelessWidget {
  final ComponentPrediction prediction;
  const _ComponentRow({required this.prediction});

  Color get _statusColor {
    if (prediction.isOverdue) return AppColors.overdueRed;
    if (prediction.isDueSoon) return AppColors.dueSoonOrange;
    return AppColors.healthyGreen;
  }

  IconData get _componentIcon {
    switch (prediction.component.toLowerCase()) {
      case 'engine oil':
        return LucideIcons.droplets;
      case 'brake system':
        return LucideIcons.disc;
      case 'battery':
        return LucideIcons.battery;
      case 'coolant':
        return LucideIcons.thermometer;
      case 'air filter':
        return LucideIcons.wind;
      case 'tires':
        return LucideIcons.circle;
      default:
        return LucideIcons.settings;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;
    final progress = prediction.progressPercentage;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Column(
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
                      Icon(_componentIcon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prediction.component,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        prediction.remainingKm != null
                            ? prediction.remainingKm! >= 0
                                ? '${prediction.remainingKm} km remaining'
                                : '${prediction.remainingKm!.abs()} km overdue'
                            : prediction.remainingDays != null
                                ? '${prediction.remainingDays} days remaining'
                                : 'Check service records',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: color),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(
                    prediction.status,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Service History tab (placeholder, wired later)
// ---------------------------------------------------------------------------
class _ServiceHistoryTab extends StatelessWidget {
  final String vehicleId;
  const _ServiceHistoryTab({required this.vehicleId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Icon(LucideIcons.clipboardList,
                    size: 48, color: AppColors.primaryViolet),
                const SizedBox(height: 16),
                Text('Service History',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'View in the Service Logs section\nfor full history.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
