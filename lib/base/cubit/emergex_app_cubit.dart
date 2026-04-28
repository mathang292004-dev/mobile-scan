import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/services/connectivity_service.dart';
import 'package:emergex/data/model/user_role_permission/user_permissions_response.dart';
import 'package:emergex/data/remote_data_source/login_remote_data_source.dart';
import 'package:emergex/data/model/upload_doc/upload_doc_onboarding.dart';

class EmergexAppCubit extends Cubit<EmergexAppState> {
  final ConnectivityService _connectivityService;
  final LoginRemoteDataSource _loginRemoteDataSource;
  StreamSubscription<bool>? _connectivitySubscription;

  EmergexAppCubit(this._connectivityService, this._loginRemoteDataSource)
    : super(const EmergexAppState()) {
    _initializeConnectivity();
  }

  void _initializeConnectivity() {
    // Set initial connectivity state
    emit(state.copyWith(isOnline: _connectivityService.isConnected));

    // Listen to connectivity changes
    _connectivitySubscription = _connectivityService.connectivityStream.listen((
      isConnected,
    ) {
      if (state.isOnline != isConnected) {
        updateIsOnline(isConnected);
      }
    });
  }

  void updateIsOnline(bool isOnline) {
    if (state.isOnline != isOnline) {
      emit(state.copyWith(isOnline: isOnline));
    }
  }

  /// Called on logout — clears all user-specific state, preserves connectivity
  void clearSession() {
    _lastPermissionFetchTime = null;
    _permissionsFuture = null;
    emit(EmergexAppState(isOnline: state.isOnline));
  }

  DateTime? _lastPermissionFetchTime;
  static const Duration _permissionTTL = Duration(minutes: 2);

  /// Future to track in-flight permission requests
  Future<void>? _permissionsFuture;

  /// Centralized method to get permissions with caching and deduplication
  Future<void> getPermissions() async {
    // If already fetching, wait for same future
    if (_permissionsFuture != null) {
      return _permissionsFuture!;
    }

    if (state.selectedProjectId != null) {
      _permissionsFuture = _silentPermissionRefresh(state.selectedProjectId!);
    } else {
      _permissionsFuture = fetchUserPermissions();
    }

    try {
      await _permissionsFuture;
    } finally {
      _permissionsFuture = null;
    }
  }

  Future<void> _silentPermissionRefresh(String projectId) async {
    try {
      final response = await _loginRemoteDataSource.getUserPermissionsByProject(
        projectId,
      );
      if (response.success == true && response.data != null) {
        emit(state.copyWith(userPermissions: response.data));
      }
    } catch (_) {}
  }

  Future<void> _executePermissionFetch() async {
    await fetchUserPermissions();
    _lastPermissionFetchTime = DateTime.now();
  }

  /// Fetch user permissions from API
  Future<void> fetchUserPermissions() async {
    try {
      final response = await _loginRemoteDataSource.getUserPermissions();
      if (response.success == true && response.data != null) {
        // 1. Get the list of projects from the initial response
        final projects = response.data!.projects;

        if (projects.isNotEmpty) {
          // 2. Select the FIRST project explicitly
          final firstProjectId = projects.first.projectId;

          // 3. Fetch permissions SPECIFIC to this project immediately
          // This ensures the app starts with the correct project context
          try {
            final projectPermResponse = await _loginRemoteDataSource
                .getUserPermissionsByProject(firstProjectId);

            if (projectPermResponse.success == true &&
                projectPermResponse.data != null) {
              // 4. Emit state with project-specific permissions and ID
              emit(
                state.copyWith(
                  userPermissions: projectPermResponse.data,
                  selectedProjectId: firstProjectId,
                  permissionLoadingState: ProcessState.done,
                ),
              );
              return;
            }
          } catch (e) {
            // Fallback if specific fetch fails, but log it
            // Proceed to default behavior below
          }
        }

        // Fallback: Use the initial response data
        String? initialProjectId;
        if (response.data!.projects.isNotEmpty) {
          initialProjectId = response.data!.projects.first.projectId;
        }

        emit(
          state.copyWith(
            userPermissions: response.data,
            selectedProjectId: initialProjectId,
            permissionLoadingState: ProcessState.done,
          ),
        );
      } else {
        // If API fails, emit null or handle error
        emit(
          state.copyWith(
            userPermissions: null,
            permissionLoadingState: ProcessState.error,
          ),
        );
      }
    } catch (e) {
      // Handle error - emit null or log error
      emit(
        state.copyWith(
          userPermissions: null,
          permissionLoadingState: ProcessState.error,
        ),
      );
    }
  }

  /// Update user permissions (for when API is ready)
  void updateUserPermissions(UserPermissionsResponse? userPermissions) {
    emit(state.copyWith(userPermissions: userPermissions));
  }

  /// Set all permissions to true
  /// This method creates a new UserPermissionsResponse with all permission flags set to true
  void setAllPermissionsToTrue() {
    final currentPermissions = state.userPermissions;

    if (currentPermissions == null) {
      // If no permissions exist, create a minimal structure
      final defaultPermissions = UserPermissionsResponse(
        email: '',
        name: '',
        roleIds: [],
        profile: '',
        projects: [],
        permissions: [],
      );

      emit(state.copyWith(userPermissions: defaultPermissions));
      return;
    }

    // Create a deep copy with all permissions set to true
    final updatedPermissions = _createPermissionsWithAllTrue(
      currentPermissions,
    );
    emit(state.copyWith(userPermissions: updatedPermissions));
  }

  /// Helper method to create a UserPermissionsResponse with all permissions set to true
  UserPermissionsResponse _createPermissionsWithAllTrue(
    UserPermissionsResponse original,
  ) {
    // Create PermissionActions with all fields set to true
    const allTrueActions = PermissionActions(
      create: true,
      read: true,
      update: true,
      delete: true,
      view: true,
      edit: true,
      fullAccess: true,
    );

    // Map through all role permissions and update feature permissions
    final updatedRolePermissions = original.permissions.map((rolePermission) {
      final updatedModulePermissions = rolePermission.permissions.map((
        modulePermission,
      ) {
        final updatedFeatures = modulePermission.features.map((feature) {
          return UserFeaturePermission(
            name: feature.name,
            featureId: feature.featureId,
            desc: feature.desc,
            permissions: allTrueActions,
          );
        }).toList();

        return UserModulePermission(
          module: modulePermission.module,
          moduleId: modulePermission.moduleId,
          features: updatedFeatures,
        );
      }).toList();

      return UserRolePermission(
        roleId: rolePermission.roleId,
        roleName: rolePermission.roleName,
        clientId: rolePermission.clientId,
        permissions: updatedModulePermissions,
      );
    }).toList();

    return UserPermissionsResponse(
      email: original.email,
      name: original.name,
      roleIds: original.roleIds,
      profile: original.profile,
      projectIds: original.projectIds,
      projects: original.projects,
      permissions: updatedRolePermissions,
    );
  }

  /// Update selected project and fetch permissions for the new project
  Future<bool> updateSelectedProject(String projectId) async {
    // Update the selected project ID and set loading state
    emit(
      state.copyWith(
        selectedProjectId: projectId,
        permissionLoadingState: ProcessState.loading,
      ),
    );

    // Fetch permissions for the new project
    try {
      final response = await _loginRemoteDataSource.getUserPermissionsByProject(
        projectId,
      );
      if (response.success == true && response.data != null) {
        emit(
          state.copyWith(
            userPermissions: response.data,
            permissionLoadingState: ProcessState.done,
          ),
        );
        return true;
      } else {
        emit(state.copyWith(permissionLoadingState: ProcessState.error));
        return false;
      }
    } catch (e) {
      emit(state.copyWith(permissionLoadingState: ProcessState.error));
      return false;
    }
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
