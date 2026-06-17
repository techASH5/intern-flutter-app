import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/presentation/auth_provider.dart';
import '../data/appointments_repository.dart';
import '../domain/appointment_model.dart';

final appointmentsRepositoryProvider =
    Provider<AppointmentsRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AppointmentsRepository(dioClient: dioClient);
});

class AppointmentsState {
  final List<Appointment> appointments;
  final bool isLoading;
  final String? errorMessage;

  const AppointmentsState({
    this.appointments = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  AppointmentsState copyWith({
    List<Appointment>? appointments,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AppointmentsState(
      appointments: appointments ?? this.appointments,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  List<Appointment> get activeAppointments => appointments
      .where((a) => !a.isCancelled && !a.isRejected)
      .toList()
    ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
}

class AppointmentsNotifier extends StateNotifier<AppointmentsState> {
  final AppointmentsRepository _repo;

  AppointmentsNotifier(this._repo) : super(const AppointmentsState()) {
    loadAppointments();
  }

  Future<void> loadAppointments() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repo.getAppointments();
      state = state.copyWith(appointments: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> createAppointment(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final appt = await _repo.createAppointment(data);
      state = state.copyWith(
          appointments: [...state.appointments, appt], isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> reschedule(String id, DateTime newDate) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _repo.reschedule(id, newDate);
      state = state.copyWith(
        appointments: state.appointments
            .map((a) => a.id == id ? updated : a)
            .toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> cancel(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _repo.cancel(id);
      state = state.copyWith(
        appointments: state.appointments
            .map((a) => a.id == id ? updated : a)
            .toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateStatus(String id, String status) async {
    try {
      final updated = await _repo.updateStatus(id, status);
      state = state.copyWith(
        appointments: state.appointments
            .map((a) => a.id == id ? updated : a)
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

final appointmentsProvider =
    StateNotifierProvider<AppointmentsNotifier, AppointmentsState>((ref) {
  final repo = ref.watch(appointmentsRepositoryProvider);
  return AppointmentsNotifier(repo);
});
