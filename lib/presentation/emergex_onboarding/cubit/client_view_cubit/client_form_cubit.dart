import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

class ClientFormState extends Equatable {
  final String name;
  final String email;
  final String industry;
  final String location;
  final String status;
  final String? nameError;
  final String? emailError;
  final String? industryError;
  final String? locationError;

  const ClientFormState({
    this.name = '',
    this.email = '',
    this.industry = '',
    this.location = '',
    this.status = 'Active',
    this.nameError,
    this.emailError,
    this.industryError,
    this.locationError,
  });

  ClientFormState copyWith({
    String? name,
    String? email,
    String? industry,
    String? location,
    String? status,
    String? nameError,
    String? emailError,
    String? industryError,
    String? locationError,
    bool clearNameError = false,
    bool clearEmailError = false,
    bool clearIndustryError = false,
    bool clearLocationError = false,
  }) {
    return ClientFormState(
      name: name ?? this.name,
      email: email ?? this.email,
      industry: industry ?? this.industry,
      location: location ?? this.location,
      status: status ?? this.status,
      nameError: clearNameError ? null : (nameError ?? this.nameError),
      emailError: clearEmailError ? null : (emailError ?? this.emailError),
      industryError:
          clearIndustryError ? null : (industryError ?? this.industryError),
      locationError:
          clearLocationError ? null : (locationError ?? this.locationError),
    );
  }

  @override
  List<Object?> get props => [
        name,
        email,
        industry,
        location,
        status,
        nameError,
        emailError,
        industryError,
        locationError,
      ];
}

class ClientFormCubit extends Cubit<ClientFormState> {
  ClientFormCubit({
    String? initialName,
    String? initialEmail,
    String? initialIndustry,
    String? initialLocation,
    String? initialStatus,
  }) : super(ClientFormState(
          name: initialName ?? '',
          email: initialEmail ?? '',
          industry: initialIndustry ?? '',
          location: initialLocation ?? '',
          status: normalizeStatus(initialStatus),
        ));

  /// Normalize incoming status string to display label
  static String normalizeStatus(String? status) {
    if (status == null || status.isEmpty) return 'Active';
    final lower = status.toLowerCase();
    if (lower == 'inactive') return 'Inactive';
    if (lower == 'archived') return 'Archived';
    return 'Active';
  }

  void updateName(String name) {
    emit(state.copyWith(name: name, clearNameError: true));
  }

  void updateEmail(String email) {
    emit(state.copyWith(email: email, clearEmailError: true));
  }

  void updateIndustry(String industry) {
    emit(state.copyWith(industry: industry, clearIndustryError: true));
  }

  void updateLocation(String location) {
    emit(state.copyWith(location: location, clearLocationError: true));
  }

  void updateStatus(String status) {
    emit(state.copyWith(status: status));
  }

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  bool validateForm() {
    bool isValid = true;
    String? nameError;
    String? emailError;
    String? industryError;
    String? locationError;

    if (state.name.trim().isEmpty) {
      nameError = 'Client Name is required';
      isValid = false;
    }

    if (state.email.trim().isEmpty) {
      emailError = 'Email is required';
      isValid = false;
    } else if (!_emailRegex.hasMatch(state.email.trim())) {
      emailError = 'Please enter a valid email address';
      isValid = false;
    }

    if (state.industry.trim().isEmpty) {
      industryError = 'Industry is required';
      isValid = false;
    }

    if (state.location.trim().isEmpty) {
      locationError = 'Location is required';
      isValid = false;
    }

    emit(state.copyWith(
      nameError: nameError,
      emailError: emailError,
      industryError: industryError,
      locationError: locationError,
    ));

    return isValid;
  }
}
