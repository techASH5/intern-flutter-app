import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../config/constants.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../vehicles/presentation/vehicles_provider.dart';
import 'appointments_provider.dart';

class AddAppointmentScreen extends ConsumerStatefulWidget {
  const AddAppointmentScreen({super.key});

  @override
  ConsumerState<AddAppointmentScreen> createState() =>
      _AddAppointmentScreenState();
}

class _AddAppointmentScreenState
    extends ConsumerState<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedVehicleId;
  String _selectedCategory = AppConstants.serviceCategories.first;
  DateTime _appointmentDate =
      DateTime.now().add(const Duration(days: 1));
  TimeOfDay _appointmentTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isLoading = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _appointmentDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _appointmentDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _appointmentTime,
    );
    if (picked != null) setState(() => _appointmentTime = picked);
  }

  DateTime get _combined => DateTime(
        _appointmentDate.year,
        _appointmentDate.month,
        _appointmentDate.day,
        _appointmentTime.hour,
        _appointmentTime.minute,
      );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a vehicle'),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isLoading = true);
    final data = {
      'vehicleId': _selectedVehicleId,
      'serviceCategory': _selectedCategory,
      'appointmentDate': _combined.toIso8601String(),
    };

    final ok =
        await ref.read(appointmentsProvider.notifier).createAppointment(data);
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment booked! Awaiting approval.'),
          backgroundColor: AppColors.healthyGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } else {
      final err = ref.read(appointmentsProvider).errorMessage ?? 'Failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(err),
            backgroundColor: AppColors.overdueRed,
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesState = ref.watch(vehiclesProvider);
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                      Text('Book Appointment',
                          style: Theme.of(context).textTheme.displaySmall),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SectionLabel('Vehicle'),
                          DropdownButtonFormField<String>(
                            value: _selectedVehicleId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Select Vehicle',
                              prefixIcon: Icon(LucideIcons.car, size: 18),
                            ),
                            items: vehiclesState.vehicles
                                .map((v) => DropdownMenuItem(
                                      value: v.id,
                                      child: Text(v.displayName,
                                          overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedVehicleId = v),
                            validator: (v) =>
                                v == null ? 'Please select a vehicle' : null,
                          ),
                          const SizedBox(height: 20),

                          _SectionLabel('Service Type'),
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              prefixIcon: Icon(LucideIcons.tag, size: 18),
                            ),
                            items: AppConstants.serviceCategories
                                .map((c) => DropdownMenuItem(
                                    value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedCategory = v!),
                          ),
                          const SizedBox(height: 20),

                          _SectionLabel('Date & Time'),
                          Row(children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: _pickDate,
                                child: _DateTimeBox(
                                  icon: LucideIcons.calendarDays,
                                  label: 'Date',
                                  value: DateFormat('MMM dd, yyyy')
                                      .format(_appointmentDate),
                                  isDark: isDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: _pickTime,
                                child: _DateTimeBox(
                                  icon: LucideIcons.clock,
                                  label: 'Time',
                                  value: _appointmentTime.format(context),
                                  isDark: isDark,
                                ),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 16),

                          // Confirmation banner
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.primaryViolet.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      AppColors.primaryViolet.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.info,
                                    color: AppColors.primaryViolet, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Appointment on ${DateFormat('MMM dd, yyyy').format(_appointmentDate)} at ${_appointmentTime.format(context)} will be submitted for approval.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppColors.primaryViolet),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16)),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text('Book Appointment',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateTimeBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  const _DateTimeBox(
      {required this.icon,
      required this.label,
      required this.value,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color:
            isDark ? AppColors.darkCardBackground2 : AppColors.lightCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primaryViolet),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.primaryViolet)),
                Text(value,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.primaryViolet,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}
