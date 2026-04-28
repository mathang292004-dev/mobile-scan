import 'package:emergex/helpers/preference_helper.dart';

enum UserRole { user, admin, manager }

class RoleManager {
  static final RoleManager _instance = RoleManager._internal();
  factory RoleManager() => _instance;
  RoleManager._internal();

  UserRole _currentRole = UserRole.user;
  final PreferenceHelper _preferenceHelper = PreferenceHelper();

  UserRole get currentRole => _currentRole;

  /// Initialize role from preferences
  Future<void> initializeRole() async {
    final roleString = await _preferenceHelper.getRole();
    _currentRole = _parseRole(roleString);
  }

  /// Set current role and persist it
  Future<void> setRole(UserRole role) async {
    _currentRole = role;
    await _preferenceHelper.setRole(_roleToString(role));
  }

  /// Check if current user has specific role
  bool hasRole(UserRole role) => _currentRole == role;

  /// Check if current user has any of the specified roles
  bool hasAnyRole(List<UserRole> roles) => roles.contains(_currentRole);

  /// Check if current user is admin
  bool get isAdmin => _currentRole == UserRole.admin;

  /// Check if current user is regular user
  bool get isUser => _currentRole == UserRole.user;

  /// Check if current user is manager
  bool get isManager => _currentRole == UserRole.manager;

  /// Get role display name
  String get roleDisplayName {
    switch (_currentRole) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.user:
        return 'User';
      case UserRole.manager:
        return 'Manager';
    }
  }

  /// Get current role as string
  String get roleString => _roleToString(_currentRole);

  /// Parse role string to enum
  UserRole _parseRole(String roleString) {
    switch (roleString.toLowerCase()) {

      case 'er team manager (landfall site manager)' || 'global crewing manager' || 'project manager':
        return UserRole.admin;
      case 'manager':
        return UserRole.manager;
      case 'user':
      default:
        return UserRole.user;
    }
  }

  /// Convert role enum to string
  String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.user:
        return 'user';
      case UserRole.manager:
        return 'manager';
    }
  }

  /// Clear role (logout)
  Future<void> clearRole() async {
    _currentRole = UserRole.user;
    await _preferenceHelper.removeRole();
  }
}
