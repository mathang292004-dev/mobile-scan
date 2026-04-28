import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

class ProjectFormState extends Equatable {
  final String projectName;
  final String location;
  final String workSites;
  final String description;
  final String? projectNameError;
  final String? locationError;
  final String? workSitesError;
  final String? descriptionError;

  const ProjectFormState({
    this.projectName = '',
    this.location = '',
    this.workSites = '',
    this.description = '',
    this.projectNameError,
    this.locationError,
    this.workSitesError,
    this.descriptionError,
  });

  ProjectFormState copyWith({
    String? projectName,
    String? location,
    String? workSites,
    String? description,
    String? projectNameError,
    String? locationError,
    String? workSitesError,
    String? descriptionError,
    bool clearProjectNameError = false,
    bool clearLocationError = false,
    bool clearWorkSitesError = false,
    bool clearDescriptionError = false,
  }) {
    return ProjectFormState(
      projectName: projectName ?? this.projectName,
      location: location ?? this.location,
      workSites: workSites ?? this.workSites,
      description: description ?? this.description,
      projectNameError: clearProjectNameError
          ? null
          : (projectNameError ?? this.projectNameError),
      locationError:
          clearLocationError ? null : (locationError ?? this.locationError),
      workSitesError: clearWorkSitesError
          ? null
          : (workSitesError ?? this.workSitesError),
      descriptionError: clearDescriptionError
          ? null
          : (descriptionError ?? this.descriptionError),
    );
  }

  @override
  List<Object?> get props => [
        projectName,
        location,
        workSites,
        description,
        projectNameError,
        locationError,
        workSitesError,
        descriptionError,
      ];
}

class ProjectFormCubit extends Cubit<ProjectFormState> {
  ProjectFormCubit({
    String? initialProjectName,
    String? initialLocation,
    String? initialWorkSites,
    String? initialDescription,
  }) : super(
         ProjectFormState(
           projectName: initialProjectName ?? '',
           location: initialLocation ?? '',
           workSites: initialWorkSites ?? '',
           description: initialDescription ?? '',
         ),
       );

  void updateProjectName(String projectName) {
    emit(state.copyWith(
      projectName: projectName,
      clearProjectNameError: true,
    ));
  }

  void updateLocation(String location) {
    emit(state.copyWith(
      location: location,
      clearLocationError: true,
    ));
  }

  void updateWorkSites(String workSites) {
    emit(state.copyWith(
      workSites: workSites,
      clearWorkSitesError: true,
    ));
  }

  void updateDescription(String description) {
    emit(state.copyWith(
      description: description,
      clearDescriptionError: true,
    ));
  }

  bool validateForm() {
    bool isValid = true;
    String? projectNameError;
    String? locationError;
    String? workSitesError;
    String? descriptionError;

    if (state.projectName.trim().isEmpty) {
      projectNameError = 'Project Title is required';
      isValid = false;
    }

    if (state.location.trim().isEmpty) {
      locationError = 'Project Location is required';
      isValid = false;
    }

    if (state.workSites.trim().isEmpty) {
      workSitesError = 'Work Site is required';
      isValid = false;
    }

    if (state.description.trim().isEmpty) {
      descriptionError = 'Description is required';
      isValid = false;
    }

    emit(state.copyWith(
      projectNameError: projectNameError,
      locationError: locationError,
      workSitesError: workSitesError,
      descriptionError: descriptionError,
    ));

    return isValid;
  }
}
