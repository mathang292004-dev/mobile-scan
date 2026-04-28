import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:equatable/equatable.dart';
import 'package:emergex/data/model/incident/incident_detail.dart';

// States
abstract class IncidentDetailsState extends Equatable {
  const IncidentDetailsState();

  @override
  List<Object?> get props => [];
}

class IncidentDetailsInitial extends IncidentDetailsState {}

class IncidentDetailsLoading extends IncidentDetailsState {}

class IncidentDetailsLoaded extends IncidentDetailsState {
  final IncidentDetails incident;
  final bool? hasDataChanged;
  final bool? incidentOverEdit;
  final ProcessState processState;
  final String? errorMessage;
  final bool? behaviouralSafetyAssessmentEdit;
  final bool? observationViewEdit;
  final bool? additionalCommentsEdit;
  final bool? behaviouralFullWidgetEdit;
  final bool? emergencyCardEdit;
  final bool? feedbackWidgetEdit;
  final bool? assetsDamageEdit;
  final bool? propertyDamageEdit;
  final bool? behaviouralSafetyAssessment;
  final bool? incidentOverview;

  const IncidentDetailsLoaded(
    this.incident, {
    this.hasDataChanged = false,
    this.processState = ProcessState.none,
    this.errorMessage,
    this.behaviouralSafetyAssessmentEdit = false,
    this.incidentOverEdit = false,
    this.observationViewEdit = false,
    this.additionalCommentsEdit = false,
    this.behaviouralFullWidgetEdit = false,
    this.emergencyCardEdit = false,
    this.feedbackWidgetEdit = false,
    this.assetsDamageEdit = false,
    this.propertyDamageEdit = false,
    this.behaviouralSafetyAssessment = false,
    this.incidentOverview = false,
  });

  @override
  List<Object?> get props => [
    incident, 
    hasDataChanged, 
    processState, 
    errorMessage, 
    incidentOverEdit, 
    behaviouralSafetyAssessmentEdit,
    observationViewEdit,
    additionalCommentsEdit,
    behaviouralFullWidgetEdit,
    emergencyCardEdit,
    feedbackWidgetEdit,
    assetsDamageEdit,
    propertyDamageEdit,
    behaviouralSafetyAssessment,
    incidentOverview,
  ];

  IncidentDetailsLoaded copyWith({
    IncidentDetails? incident,
    bool? hasDataChanged,
    ProcessState? processState,
    String? errorMessage,
    bool? incidentOverEdit,
    bool? behaviouralSafetyAssessmentEdit,
    bool? observationViewEdit,
    bool? additionalCommentsEdit,
    bool? behaviouralFullWidgetEdit,
    bool? emergencyCardEdit,
    bool? feedbackWidgetEdit,
    bool? assetsDamageEdit,
    bool? propertyDamageEdit,
    bool? behaviouralSafetyAssessment,
    bool? incidentOverview,
  }) {
    return IncidentDetailsLoaded(
      incident ?? this.incident,
      hasDataChanged: hasDataChanged ?? this.hasDataChanged,
      processState: processState ?? this.processState,
      errorMessage: errorMessage,
      behaviouralSafetyAssessmentEdit: behaviouralSafetyAssessmentEdit ?? this.behaviouralSafetyAssessmentEdit,
      incidentOverEdit: incidentOverEdit ?? this.incidentOverEdit,
      observationViewEdit: observationViewEdit ?? this.observationViewEdit,
      additionalCommentsEdit: additionalCommentsEdit ?? this.additionalCommentsEdit,
      behaviouralFullWidgetEdit: behaviouralFullWidgetEdit ?? this.behaviouralFullWidgetEdit,
      emergencyCardEdit: emergencyCardEdit ?? this.emergencyCardEdit,
      feedbackWidgetEdit: feedbackWidgetEdit ?? this.feedbackWidgetEdit,
      assetsDamageEdit: assetsDamageEdit ?? this.assetsDamageEdit,
      propertyDamageEdit: propertyDamageEdit ?? this.propertyDamageEdit,
      behaviouralSafetyAssessment: behaviouralSafetyAssessment ?? this.behaviouralSafetyAssessment,
      incidentOverview: incidentOverview ?? this.incidentOverview,
    );
  }
}

class IncidentDetailsError extends IncidentDetailsState {
  final String message;
  final ProcessState? processState;

  const IncidentDetailsError(this.message, {this.processState});

  @override
  List<Object?> get props => [message, processState];
}
