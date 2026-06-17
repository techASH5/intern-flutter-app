import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../config/constants.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../domain/vehicle_model.dart';
import 'vehicles_provider.dart';

class AddEditVehicleScreen extends ConsumerStatefulWidget {
  /// If null, we're creating. If set, we're editing.
  final String? vehicleId;

  const AddEditVehicleScreen({super.key, this.vehicleId});

  @override
  ConsumerState<AddEditVehicleScreen> createState() =>
      _AddEditVehicleScreenState();
}

class _AddEditVehicleScreenState extends ConsumerState<AddEditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _regNumberController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _odometerController = TextEditingController();

  String _selectedFuelType = AppConstants.fuelTypes.first;
  String _selectedVehicleType = AppConstants.vehicleTypes.first;
  DateTime _purchaseDate = DateTime.now();
  bool _isLoading = false;
  bool _populated = false;

  bool get _isEditing => widget.vehicleId != null;

  @override
  void dispose() {
    _regNumberController.dispose();
    _manufacturerController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  void _populateFromVehicle(Vehicle v) {
    if (_populated) return;
    _populated = true;
    _regNumberController.text = v.registrationNumber;
    _manufacturerController.text = v.manufacturer;
    _modelController.text = v.model;
    _yearController.text = v.year.toString();
    _odometerController.text = v.currentOdometer.toString();
    _purchaseDate = v.purchaseDate;
    _selectedFuelType = v.fuelType;
    _selectedVehicleType = v.vehicleType;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'registrationNumber': _regNumberController.text.trim().toUpperCase(),
      'manufacturer': _manufacturerController.text.trim(),
      'model': _modelController.text.trim(),
      'year': int.parse(_yearController.text.trim()),
      'fuelType': _selectedFuelType,
      'vehicleType': _selectedVehicleType,
      'purchaseDate': DateFormat(AppConstants.apiDateFormat).format(_purchaseDate),
      'currentOdometer': int.parse(_odometerController.text.trim()),
    };

    bool ok;
    if (_isEditing) {
      ok = await ref
          .read(vehiclesProvider.notifier)
          .updateVehicle(widget.vehicleId!, data);
    } else {
      ok = await ref.read(vehiclesProvider.notifier).createVehicle(data);
    }

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(_isEditing ? 'Vehicle updated!' : 'Vehicle added to fleet!'),
          backgroundColor: AppColors.healthyGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } else {
      final err = ref.read(vehiclesProvider).errorMessage ?? 'Operation failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppColors.overdueRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesState = ref.watch(vehiclesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // If editing, find existing vehicle and pre-fill form
    if (_isEditing) {
      final existing = vehiclesState.vehicles
          .where((v) => v.id == widget.vehicleId)
          .firstOrNull;
      if (existing != null) _populateFromVehicle(existing);
    }

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
                      Text(
                        _isEditing ? 'Edit Vehicle' : 'Add Vehicle',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
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
                          _SectionLabel('Registration'),
                          TextFormField(
                            controller: _regNumberController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Registration Number',
                              prefixIcon:
                                  Icon(LucideIcons.hash, size: 18),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 20),

                          _SectionLabel('Vehicle Details'),
                          Row(children: [
                            Expanded(
                              child: TextFormField(
                                controller: _manufacturerController,
                                decoration: const InputDecoration(
                                  labelText: 'Manufacturer',
                                  prefixIcon:
                                      Icon(LucideIcons.factory, size: 18),
                                ),
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _modelController,
                                decoration: const InputDecoration(
                                  labelText: 'Model',
                                  prefixIcon:
                                      Icon(LucideIcons.car, size: 18),
                                ),
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ),
                          ]),
                          const SizedBox(height: 16),

                          Row(children: [
                            Expanded(
                              child: TextFormField(
                                controller: _yearController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Year',
                                  prefixIcon:
                                      Icon(LucideIcons.calendar, size: 18),
                                ),
                                validator: (v) {
                                  final y = int.tryParse(v ?? '');
                                  if (y == null || y < 1980 || y > DateTime.now().year + 1) {
                                    return 'Invalid year';
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
                                    return 'Enter a valid number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ]),
                          const SizedBox(height: 20),

                          _SectionLabel('Type & Fuel'),
                          DropdownButtonFormField<String>(
                            value: _selectedVehicleType,
                            items: AppConstants.vehicleTypes
                                .map((t) => DropdownMenuItem(
                                    value: t, child: Text(t)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedVehicleType = v!),
                            decoration: const InputDecoration(
                              labelText: 'Vehicle Type',
                              prefixIcon:
                                  Icon(LucideIcons.tag, size: 18),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedFuelType,
                            items: AppConstants.fuelTypes
                                .map((f) => DropdownMenuItem(
                                    value: f, child: Text(f)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedFuelType = v!),
                            decoration: const InputDecoration(
                              labelText: 'Fuel Type',
                              prefixIcon:
                                  Icon(LucideIcons.zap, size: 18),
                            ),
                          ),
                          const SizedBox(height: 20),

                          _SectionLabel('Purchase Date'),
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
                                        .format(_purchaseDate),
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

                          // Submit
                          ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white))
                                : Text(
                                    _isEditing
                                        ? 'Save Changes'
                                        : 'Add to Fleet',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
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
