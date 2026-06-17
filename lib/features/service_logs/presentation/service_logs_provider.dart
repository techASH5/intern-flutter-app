import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/presentation/auth_provider.dart';
import '../data/service_log_repository.dart';
import '../domain/service_log_model.dart';

final serviceLogRepositoryProvider = Provider<ServiceLogRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ServiceLogRepository(dioClient: dioClient);
});

class ServiceLogsState {
  final List<ServiceLog> logs;
  final bool isLoading;
  final String? errorMessage;
  final String? filterVehicleId;
  final String? filterCategory;

  const ServiceLogsState({
    this.logs = const [],
    this.isLoading = false,
    this.errorMessage,
    this.filterVehicleId,
    this.filterCategory,
  });

  ServiceLogsState copyWith({
    List<ServiceLog>? logs,
    bool? isLoading,
    String? errorMessage,
    String? filterVehicleId,
    String? filterCategory,
    bool clearError = false,
    bool clearVehicleFilter = false,
    bool clearCategoryFilter = false,
  }) {
    return ServiceLogsState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      filterVehicleId:
          clearVehicleFilter ? null : (filterVehicleId ?? this.filterVehicleId),
      filterCategory: clearCategoryFilter
          ? null
          : (filterCategory ?? this.filterCategory),
    );
  }

  List<ServiceLog> get filteredLogs {
    var result = logs;
    if (filterVehicleId != null) {
      result = result.where((l) => l.vehicleId == filterVehicleId).toList();
    }
    if (filterCategory != null) {
      result =
          result.where((l) => l.serviceCategory == filterCategory).toList();
    }
    return result..sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
  }
}

class ServiceLogsNotifier extends StateNotifier<ServiceLogsState> {
  final ServiceLogRepository _repo;

  ServiceLogsNotifier(this._repo) : super(const ServiceLogsState()) {
    loadLogs();
  }

  Future<void> loadLogs() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final logs = await _repo.getAllLogs();
      state = state.copyWith(logs: logs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> createLog(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final log = await _repo.createLog(data);
      state = state.copyWith(
          logs: [...state.logs, log], isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteLog(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.deleteLog(id);
      state = state.copyWith(
          logs: state.logs.where((l) => l.id != id).toList(),
          isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  void setVehicleFilter(String? vehicleId) {
    state = vehicleId == null
        ? state.copyWith(clearVehicleFilter: true)
        : state.copyWith(filterVehicleId: vehicleId);
  }

  void setCategoryFilter(String? category) {
    state = category == null
        ? state.copyWith(clearCategoryFilter: true)
        : state.copyWith(filterCategory: category);
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final serviceLogsProvider =
    StateNotifierProvider<ServiceLogsNotifier, ServiceLogsState>((ref) {
  final repo = ref.watch(serviceLogRepositoryProvider);
  return ServiceLogsNotifier(repo);
});
