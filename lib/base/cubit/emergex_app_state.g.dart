// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emergex_app_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmergexAppState _$EmergexAppStateFromJson(Map<String, dynamic> json) =>
    EmergexAppState(
      onboardingState:
          $enumDecodeNullable(_$ProcessStateEnumMap, json['onboardingState']) ??
          ProcessState.none,
      profile: json['profile'] == null
          ? null
          : LoginUser.fromJson(json['profile'] as Map<String, dynamic>),
      userToken: json['userToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      isPasswordVisible: json['isPasswordVisible'] as bool? ?? true,
      isOnline: json['isOnline'] as bool? ?? true,
      userPermissions: json['userPermissions'] == null
          ? null
          : UserPermissionsResponse.fromJson(
              json['userPermissions'] as Map<String, dynamic>,
            ),
      selectedProjectId: json['selectedProjectId'] as String?,
      permissionLoadingState:
          $enumDecodeNullable(
            _$ProcessStateEnumMap,
            json['permissionLoadingState'],
          ) ??
          ProcessState.none,
    );

Map<String, dynamic> _$EmergexAppStateToJson(EmergexAppState instance) =>
    <String, dynamic>{
      'onboardingState': _$ProcessStateEnumMap[instance.onboardingState]!,
      'profile': instance.profile,
      'userToken': instance.userToken,
      'refreshToken': instance.refreshToken,
      'isPasswordVisible': instance.isPasswordVisible,
      'isOnline': instance.isOnline,
      'userPermissions': instance.userPermissions,
      'selectedProjectId': instance.selectedProjectId,
      'permissionLoadingState':
          _$ProcessStateEnumMap[instance.permissionLoadingState]!,
    };

const _$ProcessStateEnumMap = {
  ProcessState.none: 'none',
  ProcessState.loading: 'loading',
  ProcessState.done: 'done',
  ProcessState.error: 'error',
};

ProfileInitial _$ProfileInitialFromJson(Map<String, dynamic> json) =>
    ProfileInitial();

Map<String, dynamic> _$ProfileInitialToJson(ProfileInitial instance) =>
    <String, dynamic>{};

ProfileLoading _$ProfileLoadingFromJson(Map<String, dynamic> json) =>
    ProfileLoading();

Map<String, dynamic> _$ProfileLoadingToJson(ProfileLoading instance) =>
    <String, dynamic>{};

ProfileLoaded _$ProfileLoadedFromJson(Map<String, dynamic> json) =>
    ProfileLoaded(
      LoginUser.fromJson(json['profile'] as Map<String, dynamic>),
      message: json['message'] as String?,
    );

Map<String, dynamic> _$ProfileLoadedToJson(ProfileLoaded instance) =>
    <String, dynamic>{'profile': instance.profile, 'message': instance.message};

ProfileError _$ProfileErrorFromJson(Map<String, dynamic> json) =>
    ProfileError(json['error'] as String);

Map<String, dynamic> _$ProfileErrorToJson(ProfileError instance) =>
    <String, dynamic>{'error': instance.error};
