import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/presentation/auth_provider.dart';
import '../data/vehicle_repository.dart';
import '../domain/vehicle_model.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------
final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return VehicleRepository(dioClient: dioClient);
});

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
class VehiclesState {
  final List<Vehicle> vehicles;
  final bool isLoading;
  final String? errorMessage;

  const VehiclesState({
    this.vehicles = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  VehiclesState copyWith({
    List<Vehicle>? vehicles,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return VehiclesState(
      vehicles: vehicles ?? this.vehicles,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------
class VehiclesNotifier extends StateNotifier<VehiclesState> {
  final VehicleRepository _repo;

  VehiclesNotifier(this._repo) : super(const VehiclesState()) {
    loadVehicles();
  }

  Future<void> loadVehicles() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final vehicles = await _repo.getVehicles();
      state = state.copyWith(vehicles: vehicles, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<Vehicle?> getVehicle(String id) async {
    try {
      return await _repo.getVehicleById(id);
    } catch (e) {
      return null;
    }
  }

  Future<bool> createVehicle(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final vehicle = await _repo.createVehicle(data);
      state = state.copyWith(
        vehicles: [...state.vehicles, vehicle],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateVehicle(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _repo.updateVehicle(id, data);
      state = state.copyWith(
        vehicles: state.vehicles
            .map((v) => v.id == id ? updated : v)
            .toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteVehicle(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.deleteVehicle(id);
      state = state.copyWith(
        vehicles: state.vehicles.where((v) => v.id != id).toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateTelemetry(String id, int odometer) async {
    try {
      final updated = await _repo.updateTelemetry(id, odometer);
      state = state.copyWith(
        vehicles: state.vehicles
            .map((v) => v.id == id ? updated : v)
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------
final vehiclesProvider =
    StateNotifierProvider<VehiclesNotifier, VehiclesState>((ref) {
  final repo = ref.watch(vehicleRepositoryProvider);
  return VehiclesNotifier(repo);
});

/// Convenience: single vehicle from local state (fast) or fetch fresh
final selectedVehicleProvider =
    StateNotifierProvider.family<_SelectedVehicleNotifier, Vehicle?, String>(
        (ref, id) {
  final repo = ref.watch(vehicleRepositoryProvider);
  return _SelectedVehicleNotifier(repo, id);
});

class _SelectedVehicleNotifier extends StateNotifier<Vehicle?> {
  final VehicleRepository _repo;

  _SelectedVehicleNotifier(this._repo, String id) : super(null) {
    _load(id);
  }

  Future<void> _load(String id) async {
    try {
      state = await _repo.getVehicleById(id);
    } catch (_) {}
  }

  Future<void> refresh(String id) => _load(id);
}
