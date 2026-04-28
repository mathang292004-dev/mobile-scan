import 'package:emergex/data/model/user_role_permission/user_permissions_response.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../data/model/onboarding/user_profile.dart';

part 'emergex_app_state.g.dart';

@JsonSerializable()
class EmergexAppState extends Equatable {
  final ProcessState onboardingState;
  final LoginUser? profile;
  final String? userToken;
  final String? refreshToken;
  final bool isPasswordVisible;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool rememberMe;
  final bool isOnline;
  final UserPermissionsResponse? userPermissions;
  final String? selectedProjectId;
  final ProcessState permissionLoadingState;

  const EmergexAppState({
    this.onboardingState = ProcessState.none,
    this.profile,
    this.userToken,
    this.refreshToken,
    this.isPasswordVisible = true,
    this.rememberMe = false,
    this.isOnline = true,
    this.userPermissions,
    this.selectedProjectId,
    this.permissionLoadingState = ProcessState.none,
  });

  EmergexAppState copyWith({
    ProcessState? onboardingState,
    LoginUser? profile,
    String? userToken,
    String? refreshToken,
    bool? isPasswordVisible,
    bool? rememberMe,
    bool? isOnline,
    UserPermissionsResponse? userPermissions,
    String? selectedProjectId,
    ProcessState? permissionLoadingState,
  }) {
    return EmergexAppState(
      onboardingState: onboardingState ?? this.onboardingState,
      profile: profile ?? this.profile,
      userToken: userToken ?? this.userToken,
      refreshToken: refreshToken ?? this.refreshToken,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      rememberMe: rememberMe ?? this.rememberMe,
      isOnline: isOnline ?? this.isOnline,
      userPermissions: userPermissions ?? this.userPermissions,
      selectedProjectId: selectedProjectId ?? this.selectedProjectId,
      permissionLoadingState: permissionLoadingState ?? this.permissionLoadingState,
    );
  }

  factory EmergexAppState.fromJson(Map<String, dynamic> json) =>
      _$EmergexAppStateFromJson(json);
  Map<String, dynamic> toJson() => _$EmergexAppStateToJson(this);

  @override
  List<Object?> get props => [
    onboardingState,
    profile,
    userToken,
    refreshToken,
    isPasswordVisible,
    rememberMe,
    isOnline,
    userPermissions,
    selectedProjectId,
    permissionLoadingState,
  ];
}

enum ProcessState {
  @JsonValue('none')
  none,
  @JsonValue('loading')
  loading,
  @JsonValue('done')
  done,
  @JsonValue('error')
  error,
}

abstract class ProfileState extends Equatable {
  const ProfileState();
}

@JsonSerializable()
class ProfileInitial extends ProfileState {
  const ProfileInitial() : super();

  factory ProfileInitial.fromJson(Map<String, dynamic> json) =>
      _$ProfileInitialFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileInitialToJson(this);

  @override
  List<Object?> get props => [];
}

@JsonSerializable()
class ProfileLoading extends ProfileState {
  const ProfileLoading() : super();

  factory ProfileLoading.fromJson(Map<String, dynamic> json) =>
      _$ProfileLoadingFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileLoadingToJson(this);

  @override
  List<Object?> get props => [];
}

@JsonSerializable()
class ProfileLoaded extends ProfileState {
  final LoginUser profile;
  final String? message;

  const ProfileLoaded(this.profile, {this.message}) : super();

  factory ProfileLoaded.fromJson(Map<String, dynamic> json) =>
      _$ProfileLoadedFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileLoadedToJson(this);

  @override
  List<Object?> get props => [profile, message];
}

@JsonSerializable()
class ProfileError extends ProfileState {
  final String error;

  const ProfileError(this.error) : super();

  factory ProfileError.fromJson(Map<String, dynamic> json) =>
      _$ProfileErrorFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileErrorToJson(this);

  @override
  List<Object?> get props => [error];
}
