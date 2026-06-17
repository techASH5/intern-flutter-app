import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/presentation/auth_provider.dart';
import '../data/analytics_repository.dart';
import '../domain/analytics_model.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AnalyticsRepository(dioClient: dioClient);
});

class AnalyticsState {
  final AnalyticsDashboard? dashboard;
  final bool isLoading;
  final String? errorMessage;

  const AnalyticsState({
    this.dashboard,
    this.isLoading = false,
    this.errorMessage,
  });

  AnalyticsState copyWith({
    AnalyticsDashboard? dashboard,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AnalyticsState(
      dashboard: dashboard ?? this.dashboard,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final AnalyticsRepository _repo;

  AnalyticsNotifier(this._repo) : super(const AnalyticsState()) {
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await _repo.getDashboard();
      state = state.copyWith(dashboard: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  final repo = ref.watch(analyticsRepositoryProvider);
  return AnalyticsNotifier(repo);
});
