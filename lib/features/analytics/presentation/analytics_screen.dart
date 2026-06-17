import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../domain/analytics_model.dart';
import 'analytics_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsProvider);

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
                      Text('Analytics',
                          style: Theme.of(context).textTheme.displaySmall),
                      IconButton(
                        icon: const Icon(LucideIcons.refreshCw),
                        onPressed: () =>
                            ref.read(analyticsProvider.notifier).loadDashboard(),
                      ),
                    ],
                  ),
                ),
              ),

              if (state.isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.errorMessage != null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.wifiOff,
                            size: 48, color: AppColors.overdueRed),
                        const SizedBox(height: 16),
                        Text(state.errorMessage!,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => ref
                              .read(analyticsProvider.notifier)
                              .loadDashboard(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (state.dashboard != null)
                SliverList(
                  delegate: SliverChildListDelegate([
                    // Summary cards
                    _SummaryRow(dashboard: state.dashboard!),
                    const SizedBox(height: 16),

                    // Line chart — monthly cost
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _MonthlyLineChart(
                          monthlyCosts: state.dashboard!.monthlyCosts),
                    ),
                    const SizedBox(height: 16),

                    // Pie chart — category breakdown
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _CategoryPieChart(
                          categoryCosts: state.dashboard!.categoryCosts),
                    ),
                    const SizedBox(height: 16),

                    // Upcoming alerts list
                    if (state.dashboard!.upcomingAlerts.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _UpcomingAlertsList(
                            alerts: state.dashboard!.upcomingAlerts),
                      ),

                    const SizedBox(height: 100),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary row
// ---------------------------------------------------------------------------
class _SummaryRow extends StatelessWidget {
  final AnalyticsDashboard dashboard;
  const _SummaryRow({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: GlassCard(
              child: Column(
                children: [
                  const Icon(LucideIcons.indianRupee,
                      color: AppColors.healthyGreen, size: 28),
                  const SizedBox(height: 8),
                  Text('₹${dashboard.totalSpent.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.healthyGreen,
                          )),
                  Text('Total Spent',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GlassCard(
              child: Column(
                children: [
                  const Icon(LucideIcons.wrench,
                      color: AppColors.primaryViolet, size: 28),
                  const SizedBox(height: 8),
                  Text('${dashboard.totalServices}',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryViolet,
                          )),
                  Text('Services Done',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Monthly line chart
// ---------------------------------------------------------------------------
class _MonthlyLineChart extends StatelessWidget {
  final List<MonthlyCost> monthlyCosts;
  const _MonthlyLineChart({required this.monthlyCosts});

  @override
  Widget build(BuildContext context) {
    if (monthlyCosts.isEmpty) return const SizedBox.shrink();

    final spots = monthlyCosts.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.amount);
    }).toList();

    final maxY = (monthlyCosts.map((c) => c.amount).reduce(max) * 1.3)
        .ceilToDouble();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(LucideIcons.trendingUp,
                color: AppColors.primaryViolet, size: 20),
            const SizedBox(width: 8),
            Text('Monthly Maintenance Cost',
                style: Theme.of(context).textTheme.headlineSmall),
          ]),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: AppColors.primaryViolet.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (v, _) => Text(
                        '₹${(v / 1000).toStringAsFixed(0)}k',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= monthlyCosts.length) {
                          return const SizedBox.shrink();
                        }
                        final label = monthlyCosts[idx].month;
                        final parts = label.split(' ');
                        return Text(
                          parts.isNotEmpty ? parts[0] : label,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primaryViolet,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.primaryViolet,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primaryViolet.withOpacity(0.3),
                          AppColors.primaryViolet.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category pie chart
// ---------------------------------------------------------------------------
class _CategoryPieChart extends StatefulWidget {
  final List<CategoryCost> categoryCosts;
  const _CategoryPieChart({required this.categoryCosts});

  @override
  State<_CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<_CategoryPieChart> {
  int _touchedIndex = -1;

  static const _colors = [
    AppColors.primaryViolet,
    AppColors.healthyGreen,
    AppColors.dueSoonOrange,
    AppColors.overdueRed,
    Color(0xFF06B6D4),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.categoryCosts.isEmpty) return const SizedBox.shrink();

    final total =
        widget.categoryCosts.fold<double>(0, (s, c) => s + c.amount);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(LucideIcons.pieChart,
                color: AppColors.primaryViolet, size: 20),
            const SizedBox(width: 8),
            Text('Cost by Category',
                style: Theme.of(context).textTheme.headlineSmall),
          ]),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, resp) {
                        setState(() {
                          _touchedIndex =
                              resp?.touchedSection?.touchedSectionIndex ??
                                  -1;
                        });
                      },
                    ),
                    sections: widget.categoryCosts
                        .asMap()
                        .entries
                        .map((e) {
                      final isTouched = e.key == _touchedIndex;
                      final color = _colors[e.key % _colors.length];
                      return PieChartSectionData(
                        value: e.value.amount,
                        color: color,
                        radius: isTouched ? 70 : 60,
                        title: isTouched
                            ? '${(e.value.amount / total * 100).toStringAsFixed(1)}%'
                            : '',
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                    centerSpaceRadius: 30,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.categoryCosts
                      .asMap()
                      .entries
                      .map((e) {
                    final color = _colors[e.key % _colors.length];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              e.value.category,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '₹${e.value.amount.toStringAsFixed(0)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Upcoming alerts list
// ---------------------------------------------------------------------------
class _UpcomingAlertsList extends StatelessWidget {
  final List<UpcomingAlert> alerts;
  const _UpcomingAlertsList({required this.alerts});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(LucideIcons.alertTriangle,
                color: AppColors.dueSoonOrange, size: 20),
            const SizedBox(width: 8),
            Text('Upcoming Maintenance',
                style: Theme.of(context).textTheme.headlineSmall),
          ]),
          const SizedBox(height: 16),
          ...alerts.map((a) {
            final isOverdue = a.status == 'Overdue';
            final color =
                isOverdue ? AppColors.overdueRed : AppColors.dueSoonOrange;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(LucideIcons.wrench, color: color, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.component,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        Text(a.vehicleName,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Text(
                      a.remainingKm != null
                          ? '${a.remainingKm} km'
                          : a.status,
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
