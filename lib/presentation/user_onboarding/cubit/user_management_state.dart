import 'package:equatable/equatable.dart';
import 'package:emergex/presentation/user_onboarding/model/user_management_model.dart';

enum UserManagementProcessState { initial, loading, loaded, error }

class UserManagementState extends Equatable {
  final UserManagementProcessState processState;
  final List<UserModel> users;
  final UserStatsModel stats;
  final int currentPage;
  final int totalPages;
  final int itemsPerPage;
  final String searchQuery;
  final int selectedMetricIndex;
  final bool isPaginationLoading;
  final String? errorMessage;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String filterName;
  final String filterRole;
  final String filterEmail;
  final String filterProject;

  const UserManagementState({
    this.processState = UserManagementProcessState.initial,
    this.users = const [],
    this.stats = const UserStatsModel(
      totalUsers: 0,
      activeUsers: 0,
      inactiveUsers: 0,
    ),
    this.currentPage = 1,
    this.totalPages = 1,
    this.itemsPerPage = 10,
    this.searchQuery = '',
    this.selectedMetricIndex = 0,
    this.isPaginationLoading = false,
    this.errorMessage,
    this.fromDate,
    this.toDate,
    this.filterName = '',
    this.filterRole = '',
    this.filterEmail = '',
    this.filterProject = '',
  });

  /// Returns the status filter string for the API based on selected metric.
  String? get statusFilter {
    switch (selectedMetricIndex) {
      case 1:
        return 'Active';
      case 2:
        return 'Inactive';
      default:
        return null; // Total Users — no filter
    }
  }

  UserManagementState copyWith({
    UserManagementProcessState? processState,
    List<UserModel>? users,
    UserStatsModel? stats,
    int? currentPage,
    int? totalPages,
    int? itemsPerPage,
    String? searchQuery,
    int? selectedMetricIndex,
    bool? isPaginationLoading,
    String? errorMessage,
    DateTime? fromDate,
    DateTime? toDate,
    bool clearDates = false,
    String? filterName,
    String? filterRole,
    String? filterEmail,
    String? filterProject,
    bool clearFilters = false,
  }) {
    return UserManagementState(
      processState: processState ?? this.processState,
      users: users ?? this.users,
      stats: stats ?? this.stats,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedMetricIndex: selectedMetricIndex ?? this.selectedMetricIndex,
      isPaginationLoading: isPaginationLoading ?? this.isPaginationLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      fromDate: clearDates ? null : (fromDate ?? this.fromDate),
      toDate: clearDates ? null : (toDate ?? this.toDate),
      filterName: clearFilters ? '' : (filterName ?? this.filterName),
      filterRole: clearFilters ? '' : (filterRole ?? this.filterRole),
      filterEmail: clearFilters ? '' : (filterEmail ?? this.filterEmail),
      filterProject: clearFilters ? '' : (filterProject ?? this.filterProject),
    );
  }

  @override
  List<Object?> get props => [
    processState,
    users,
    stats,
    currentPage,
    totalPages,
    itemsPerPage,
    searchQuery,
    selectedMetricIndex,
    isPaginationLoading,
    errorMessage,
    fromDate,
    toDate,
    filterName,
    filterRole,
    filterEmail,
    filterProject,
  ];
}
