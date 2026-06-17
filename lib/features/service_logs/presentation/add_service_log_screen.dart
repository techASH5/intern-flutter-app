import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../config/constants.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../vehicles/presentation/vehicles_provider.dart';
import 'service_logs_provider.dart';

class AddServiceLogScreen extends ConsumerStatefulWidget {
  const AddServiceLogScreen({super.key});

  @override
  ConsumerState<AddServiceLogScreen> createState() =>
      _AddServiceLogScreenState();
}

class _AddServiceLogScreenState extends ConsumerState<AddServiceLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _odometerController = TextEditingController();
  final _serviceCenterController = TextEditingController();

  String? _selectedVehicleId;
  String _selectedCategory = AppConstants.serviceCategories.first;
  DateTime _serviceDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _costController.dispose();
    _odometerController.dispose();
    _serviceCenterController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _serviceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _serviceDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a vehicle'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'vehicleId': _selectedVehicleId,
      'serviceDate': DateFormat(AppConstants.apiDateFormat).format(_serviceDate),
      'odometerReading': int.parse(_odometerController.text.trim()),
      'serviceCategory': _selectedCategory,
      'serviceDescription': _descriptionController.text.trim(),
      'cost': double.parse(_costController.text.trim()),
      if (_serviceCenterController.text.trim().isNotEmpty)
        'serviceCenter': _serviceCenterController.text.trim(),
    };

    final ok =
        await ref.read(serviceLogsProvider.notifier).createLog(data);

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service log created!'),
          backgroundColor: AppColors.healthyGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } else {
      final err =
          ref.read(serviceLogsProvider).errorMessage ?? 'Failed to create log';
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
                      Text('Log Service',
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

                          _SectionLabel('Service Details'),
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
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              prefixIcon: Icon(LucideIcons.fileText, size: 18),
                              alignLabelWithHint: true,
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Please enter a description'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          Row(children: [
                            Expanded(
                              child: TextFormField(
                                controller: _costController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Cost (₹)',
                                  prefixIcon:
                                      Icon(LucideIcons.indianRupee, size: 18),
                                ),
                                validator: (v) {
                                  if (double.tryParse(v ?? '') == null) {
                                    return 'Enter valid amount';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _odometerController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Odometer (km)',
                                  prefixIcon:
                                      Icon(LucideIcons.gauge, size: 18),
                                ),
                                validator: (v) {
                                  if (int.tryParse(v ?? '') == null) {
                                    return 'Enter valid reading';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ]),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _serviceCenterController,
                            decoration: const InputDecoration(
                              labelText: 'Service Center (optional)',
                              prefixIcon: Icon(LucideIcons.mapPin, size: 18),
                            ),
                          ),
                          const SizedBox(height: 20),

                          _SectionLabel('Service Date'),
                          GestureDetector(
                            onTap: _pickDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkCardBackground2
                                    : AppColors.lightCardBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.calendarDays,
                                      size: 18,
                                      color: AppColors.primaryViolet),
                                  const SizedBox(width: 12),
                                  Text(
                                    DateFormat('MMM dd, yyyy')
                                        .format(_serviceDate),
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  const Spacer(),
                                  const Icon(LucideIcons.chevronRight,
                                      size: 16),
                                ],
                              ),
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
                                : const Text('Save Log',
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
