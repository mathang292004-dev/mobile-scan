import 'dart:async';

import 'package:emergex/data/model/user_management/get_users_request.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/domain/repo/user_management_repo.dart';
import 'package:emergex/presentation/user_onboarding/cubit/user_management_state.dart';
import 'package:emergex/presentation/user_onboarding/use_cases/get_users_use_case.dart';
import 'package:emergex/presentation/user_onboarding/model/user_management_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserManagementCubit extends Cubit<UserManagementState> {
  final GetUsersUseCase _getUsersUseCase;
  final UserManagementRepo _repo;

  UserManagementCubit(this._getUsersUseCase, this._repo)
      : super(const UserManagementState());

  final searchController = TextEditingController();
  Timer? _debounceTimer;

  String get _clientId =>
      AppDI.emergexAppCubit.state.userPermissions?.permissions
          .firstOrNull?.clientId ??
      '';

  Future<void> loadUsers({int page = 1}) async {
    if (page == 1) {
      emit(state.copyWith(
        processState: UserManagementProcessState.loading,
        errorMessage: null,
      ));
    } else {
      emit(state.copyWith(isPaginationLoading: true));
    }

    try {
      String startDate = '';
      String endDate = '';
      if (state.fromDate != null && state.toDate != null) {
        startDate =
            '${state.fromDate!.year}-${state.fromDate!.month.toString().padLeft(2, '0')}-${state.fromDate!.day.toString().padLeft(2, '0')}T00:00:00.000Z';
        endDate =
            '${state.toDate!.year}-${state.toDate!.month.toString().padLeft(2, '0')}-${state.toDate!.day.toString().padLeft(2, '0')}T23:59:59.999Z';
      }

      final request = GetUsersRequest(
        clientId: _clientId,
        page: page,
        limit: state.itemsPerPage,
        search: state.searchQuery,
        status: state.statusFilter ?? '',
        startDate: startDate,
        endDate: endDate,
        filterName: state.filterName,
        filterRole: state.filterRole,
        filterEmail: state.filterEmail,
        filterProject: state.filterProject,
      );

      final response = await _getUsersUseCase.execute(request);

      if (response.success == true && response.data != null) {
        final data = response.data!;
        emit(state.copyWith(
          processState: UserManagementProcessState.loaded,
          users: data.users,
          stats: data.stats,
          currentPage: data.page,
          totalPages: data.totalPages,
          isPaginationLoading: false,
          errorMessage: null,
        ));
      } else {
        emit(state.copyWith(
          processState: UserManagementProcessState.error,
          isPaginationLoading: false,
          stats: const UserStatsModel(
            totalUsers: 0,
            activeUsers: 0,
            inactiveUsers: 0,
          ),
          errorMessage:
              response.error ?? response.message ?? 'Failed to load users',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        processState: UserManagementProcessState.error,
        isPaginationLoading: false,
        errorMessage: 'Network error: ${e.toString()}',
      ));
    }
  }

  void onSearchChanged(String query) {
    emit(state.copyWith(searchQuery: query));

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      loadUsers(page: 1);
    });
  }

  void goToPage(int page) {
    if (page >= 1 && page <= state.totalPages) {
      loadUsers(page: page);
    }
  }

  void onMetricTap(int index) {
    if (state.selectedMetricIndex == index) return;
    emit(state.copyWith(selectedMetricIndex: index));
    loadUsers(page: 1);
  }

  /// Called from DateRangePicker when dates are selected.
  void onDateRangeSelected(
    Map<String, String>? dateRange,
    String? searchText,
  ) {
    if (dateRange != null &&
        dateRange['from'] != null &&
        dateRange['to'] != null &&
        dateRange['from']!.isNotEmpty &&
        dateRange['to']!.isNotEmpty) {
      final from = DateTime.tryParse(dateRange['from']!);
      final to = DateTime.tryParse(dateRange['to']!);
      emit(state.copyWith(fromDate: from, toDate: to));
    } else {
      emit(state.copyWith(clearDates: true));
    }
    loadUsers(page: 1);
  }

  /// Clears date filter and reloads.
  void clearDateFilter() {
    emit(state.copyWith(clearDates: true));
    loadUsers(page: 1);
  }

  /// Pull-to-refresh: reset to page 1 and reload fresh data.
  Future<void> refreshUsers() async {
    emit(state.copyWith(
      processState: UserManagementProcessState.loading,
      errorMessage: null,
    ));
    await loadUsers(page: 1);
  }

  void applyAdvancedFilters({
    required String userName,
    required String role,
    required String email,
    required String project,
  }) {
    emit(state.copyWith(
      filterName: userName,
      filterRole: role,
      filterEmail: email,
      filterProject: project,
    ));
    loadUsers(page: 1);
  }

  void clearAdvancedFilters() {
    emit(state.copyWith(clearFilters: true));
    loadUsers(page: 1);
  }

  Future<bool> deleteUser(String userId) async {
    try {
      final response = await _repo.deleteUser(userId: userId);
      if (response.success == true) {
        // Reload the list to get fresh data from server
        await loadUsers(page: state.currentPage);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Cancel any pending timers and clear search on logout/session-expiry.
  /// Does NOT emit a new state — emitting `initial` here would cause
  /// GoRouter's route teardown to briefly remount the screen and re-trigger
  /// loadUsers() via the initState guard, which is what we want to avoid.
  void reset() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    searchController.clear();
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    searchController.dispose();
    return super.close();
  }
}
