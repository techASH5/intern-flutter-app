import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/presentation/auth_provider.dart';
import '../data/admin_repository.dart';
import '../domain/admin_model.dart';

// Re-export appointments provider for admin use
export '../../../features/appointments/presentation/appointments_provider.dart'
    show appointmentsProvider, AppointmentsNotifier;

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AdminRepository(dioClient: dioClient);
});

class AdminState {
  final AdminStats? stats;
  final List<AdminUser> users;
  final bool isLoading;
  final String? errorMessage;

  const AdminState({
    this.stats,
    this.users = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  AdminState copyWith({
    AdminStats? stats,
    List<AdminUser>? users,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AdminState(
      stats: stats ?? this.stats,
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AdminNotifier extends StateNotifier<AdminState> {
  final AdminRepository _repo;

  AdminNotifier(this._repo) : super(const AdminState()) {
    loadAll();
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _repo.getStats(),
        _repo.getUsers(),
      ]);
      state = state.copyWith(
        stats: results[0] as AdminStats,
        users: results[1] as List<AdminUser>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> toggleRole(String id, bool makeAdmin) async {
    try {
      await _repo.toggleUserRole(id, makeAdmin ? 'admin' : 'user');
      state = state.copyWith(
        users: state.users
            .map((u) => u.id == id
                ? AdminUser(
                    id: u.id,
                    name: u.name,
                    email: u.email,
                    isAdmin: makeAdmin,
                    createdAt: u.createdAt,
                  )
                : u)
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      await _repo.deleteUser(id);
      state = state.copyWith(
          users: state.users.where((u) => u.id != id).toList());
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final adminProvider =
    StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return AdminNotifier(repo);
});
