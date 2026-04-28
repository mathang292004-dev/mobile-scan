import 'package:emergex/role/role_manager.dart';

mixin RoleAwareMixin {
  RoleManager get roleManager => RoleManager();

  bool get isAdmin => roleManager.isAdmin;
  bool get isUser => roleManager.isUser;
  bool get isManager => roleManager.isManager;

  bool hasRole(UserRole role) => roleManager.hasRole(role);
  bool hasAnyRole(List<UserRole> roles) => roleManager.hasAnyRole(roles);

  }