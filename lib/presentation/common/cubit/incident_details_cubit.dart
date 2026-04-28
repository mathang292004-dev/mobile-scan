import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/presentation/common/use_cases/get_incident_by_id_use_case.dart';
import 'package:emergex/helpers/widgets/feedback/app_loader.dart';
import '../../../../data/model/incident/incident_detail.dart';
import 'incident_details_state.dart';

// Cubit
class IncidentDetailsCubit extends Cubit<IncidentDetailsState> {
  final GetIncidentByIdUseCase _getIncidentByIdUseCase;

  IncidentDetailsCubit(this._getIncidentByIdUseCase)
    : super(IncidentDetailsInitial());

  Future<void> getIncidentById(String incidentId, {bool showLoader = true}) async {
    if (incidentId.isEmpty) {
      emit(IncidentDetailsError(TextHelper.error));
      return;
    }

    try {
      if (showLoader) loaderService.showLoader();

      final response = await _getIncidentByIdUseCase.execute(incidentId);
      if (response.success == true && response.data != null) {
        if (response.data?.incident == null) {
          response.data?.incident = {
            'incidentOverview': response.data?.emergexCaseSummary,
          };
        } else if (response.data?.emergexCaseSummary != null) {
          final incidentMap = response.data!.incident;
          if (incidentMap is Map) {
            final map = Map<String, dynamic>.from(incidentMap);
            if (map['incidentOverview'] == null) {
              map['incidentOverview'] = response.data?.emergexCaseSummary;
              response.data!.incident = map;
            }
          }
        }
        if (state is IncidentDetailsLoaded) {
          emit(
            (state as IncidentDetailsLoaded).copyWith(incident: response.data!),
          );
        } else {
          emit(IncidentDetailsLoaded(response.data!));
        }
      } else {
        emit(
          IncidentDetailsError(
            response.error ?? 'Failed to load incident details',
          ),
        );
      }
    } catch (e) {
      emit(
        IncidentDetailsError(
          'Failed to load incident details: ${e.toString()}',
        ),
      );
    } finally {
      if (showLoader) loaderService.hideLoader();
    }
  }

  Future<bool> checkDataChanged() async {
    if (state is IncidentDetailsLoaded) {
      final currentState = state as IncidentDetailsLoaded;
      // Check if any edit mode is currently active
      final anyEditActive =
          currentState.observationViewEdit == true ||
          currentState.additionalCommentsEdit == true ||
          currentState.behaviouralFullWidgetEdit == true ||
          currentState.behaviouralSafetyAssessment == true ||
          currentState.behaviouralSafetyAssessmentEdit == true ||
          currentState.emergencyCardEdit == true ||
          currentState.feedbackWidgetEdit == true ||
          currentState.assetsDamageEdit == true ||
          currentState.propertyDamageEdit == true ||
          currentState.incidentOverview == true ||
          currentState.incidentOverEdit == true;

      // Emit with hasDataChanged set to true if any edit mode is active
      emit(currentState.copyWith(hasDataChanged: anyEditActive));
      return anyEditActive;
    } else {
      return false;
    }
  }

  void checkDataInitial() {
    final currentState = state as IncidentDetailsLoaded;
    emit(
      currentState.copyWith(
        behaviouralSafetyAssessmentEdit: false,
        incidentOverEdit: false,
        observationViewEdit: false,
        additionalCommentsEdit: false,
        behaviouralFullWidgetEdit: false,
        emergencyCardEdit: false,
        feedbackWidgetEdit: false,
        assetsDamageEdit: false,
        propertyDamageEdit: false,
      ),
    );
  }

  // Sets whether widget is in edit mode
  Future<void> incidentOverEditMode(bool incidentOverEdit) async {
    if (state is IncidentDetailsLoaded) {
      final currentState = state as IncidentDetailsLoaded;
      emit(currentState.copyWith(incidentOverEdit: incidentOverEdit));
    }
  }

  // Sets whether data has changed (used to enable/disable save button)
  Future<void> incidentOverviewEditMode(bool hasDataChanged) async {
    if (state is IncidentDetailsLoaded) {
      final currentState = state as IncidentDetailsLoaded;
      emit(currentState.copyWith(incidentOverview: hasDataChanged));
    }
  }

  bool getIncidentOverEditMode() {
    if (state is IncidentDetailsLoaded) {
      final currentState = state as IncidentDetailsLoaded;
      return currentState.incidentOverEdit ?? false;
    }
    return false;
  }

  // Sets whether data has changed (used to enable/disable save button)
  Future<void> behaviouralSafetyAssessmentEditMode(bool hasDataChanged) async {
    if (state is IncidentDetailsLoaded) {
      final currentState = state as IncidentDetailsLoaded;
      emit(currentState.copyWith(behaviouralSafetyAssessment: hasDataChanged));
    }
  }

  // Sets whether widget is in edit mode
  Future<void> behaviouralSafetyAssessmentEdit(bool value) async {
    if (state is IncidentDetailsLoaded) {
      final currentState = state as IncidentDetailsLoaded;
      emit(currentState.copyWith(behaviouralSafetyAssessmentEdit: value));
    }
  }

  bool getBehaviouralSafetyAssessmentEdit() {
    if (state is IncidentDetailsLoaded) {
      final currentState = state as IncidentDetailsLoaded;
      return currentState.behaviouralSafetyAssessmentEdit ?? false;
    }
    return false;
  }

  bool getBehaviouralSafetyAssessmentEditMode() {
    if (state is IncidentDetailsLoaded) {
      final currentState = state as IncidentDetailsLoaded;
      return currentState.behaviouralSafetyAssessmentEdit ?? false;
    }
    return false;
  }

  // Separate methods for each widget type
  Future<void> setObservationViewEdit(bool value) async {
    if (state is IncidentDetailsLoaded) {
      final currentState = state as IncidentDetailsLoaded;
      emit(currentState.copyWith(observationViewEdit: value));
    }
  }

  Future<void> setAdditionalCommentsEdit(bool value) async {
    if (state is IncidentDetailsLoaded) {
      final currentState = state as IncidentDetailsLoaded;
      emit(currentState.copyWith(additionalCommentsEdit: value));
    }
  }

  Future<void> setBehaviouralFullWidgetEdit(bool value) async {
    if (state is IncidentDetailsLoaded) {
      final currentState = state as IncidentDetailsLoaded;
      emit(currentState.copyWith(behaviouralFullWidgetEdit: value));
    }
  }

  Future<void> setEmergencyCardEdit(bool value) async {
    if (state is IncidentDetailsLoaded) {
      final currentState = state as IncidentDetailsLoaded;
      emit(currentState.copyWith(emergencyCardEdit: value));
    }
  }

  Future<void> setFeedbackWidgetEdit(bool value) async {
    if (state is IncidentDetailsLoaded) {
      final currentState = state as IncidentDetailsLoaded;
      emit(currentState.copyWith(feedbackWidgetEdit: value));
    }
  }

  Future<void> setAssetsDamageEdit(bool value) async {
    if (state is IncidentDetailsLoaded) {
      final currentState = state as IncidentDetailsLoaded;
      emit(currentState.copyWith(assetsDamageEdit: value));
    }
  }

  Future<void> setPropertyDamageEdit(bool value) async {
    if (state is IncidentDetailsLoaded) {
      final currentState = state as IncidentDetailsLoaded;
      emit(currentState.copyWith(propertyDamageEdit: value));
    }
  }

  /// Clears the error message from the current state
  void clearErrorMessage() {
    if (state is IncidentDetailsLoaded) {
      final currentState = state as IncidentDetailsLoaded;
      emit(currentState.copyWith(errorMessage: null));
    }
  }

  Future<void> updateReportFields(IncidentDetails? incidentData) async {
    if (incidentData == null) {
      if (state is IncidentDetailsLoaded) {
        final currentState = state as IncidentDetailsLoaded;
        emit(
          currentState.copyWith(
            errorMessage: 'Invalid incident data',
            processState: ProcessState.error,
          ),
        );
      } else {
        emit(IncidentDetailsError('Invalid incident data'));
      }
      return;
    }
    // Build a targeted payload from the IncidentDetails, preserving the task
    // from the current cubit state to avoid overwriting task assignments.
    List<dynamic>? taskFromState;
    if (state is IncidentDetailsLoaded) {
      taskFromState = (state as IncidentDetailsLoaded).incident.task;
    }
    final payload = incidentData.toJson();
    payload.remove('task');
    payload['task'] = taskFromState;
    await updateReportFieldsPayload(payload, incidentId: incidentData.incidentId);
  }

  /// Sends a targeted payload directly to the updateReportFields API.
  /// Use this when the widget builds its own precise payload (e.g. assetsDamage,
  /// propertyDamage) rather than serialising the full IncidentDetails object.
  Future<void> updateReportFieldsPayload(
    Map<String, dynamic> payload, {
    String? incidentId,
  }) async {
    final id =
        incidentId ?? payload['caseId']?.toString() ?? payload['incidentId']?.toString() ?? '';
    try {
      loaderService.showLoader();
      final response = await _getIncidentByIdUseCase.updateReportFields(payload);
      if (response.success == true && response.data != null) {
        final id = incidentId ?? payload['caseId']?.toString() ?? '';
        getIncidentById(id);
      } else {
        if (response.statusCode == 400) {
          if (state is IncidentDetailsLoaded) {
            final currentState = state as IncidentDetailsLoaded;
            emit(
              currentState.copyWith(
                errorMessage:
                    response.error ?? 'Failed to update Report Fields',
                processState: ProcessState.error,
              ),
            );
          }
          clearCache();
          if (id.isNotEmpty) {
            getIncidentById(id);
          }
          openScreen(
            Routes.incidentApproval,
            args: {
              'incidentId': id,
              'initialDropdownValue': response.data?.type ?? "Incident",
              'isEditRequired': true,
            },
            clearOldStacks: true,
          );
        } else {
          if (state is IncidentDetailsLoaded) {
            final currentState = state as IncidentDetailsLoaded;
            emit(
              currentState.copyWith(
                errorMessage:
                    response.error ?? 'Failed to update Report Fields',
                processState: ProcessState.error,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (state is IncidentDetailsLoaded) {
        final currentState = state as IncidentDetailsLoaded;
        emit(
          currentState.copyWith(
            errorMessage: e.toString(),
            processState: ProcessState.error,
          ),
        );
      }
    } finally {
      loaderService.hideLoader();
    }
  }

  void reset() {
    emit(IncidentDetailsInitial());
  }

  void clearCache() {
    emit(IncidentDetailsInitial());
  }

  /// Returns true if any section is currently in edit mode
  bool isAnyEditActive() {
    if (state is IncidentDetailsLoaded) {
      final s = state as IncidentDetailsLoaded;
      return (s.observationViewEdit == true ||
          s.additionalCommentsEdit == true ||
          s.behaviouralFullWidgetEdit == true ||
          s.behaviouralSafetyAssessmentEdit == true ||
          s.emergencyCardEdit == true ||
          s.feedbackWidgetEdit == true ||
          s.assetsDamageEdit == true ||
          s.propertyDamageEdit == true ||
          s.incidentOverEdit == true);
    }
    return false;
  }

  bool isDataLoadedForIncident(String incidentId) {
    if (state is IncidentDetailsLoaded) {
      final currentState = state as IncidentDetailsLoaded;
      return currentState.incident.incidentId == incidentId;
    }
    return false;
  }

  Future<bool> updateReport(String incidentId, String type) async {
    IncidentDetailsLoaded? previousState;
    if (state is IncidentDetailsLoaded) {
      previousState = state as IncidentDetailsLoaded;
      emit(IncidentDetailsLoading());
      loaderService.showLoader();
      try {
        final response = await _getIncidentByIdUseCase.updateIncidentApproval(
          incidentId,
          type,
        );

        if (response.success == true && response.data != null) {
          emit(IncidentDetailsLoaded(response.data!));
          return true;
        } else {
          // Restore previous state with error message instead of showing error screen
          emit(
            previousState.copyWith(
              errorMessage: response.error ?? 'Failed to update report',
            ),
          );
          return false;
        }
      } catch (e) {
        // Restore previous state with error message instead of showing error screen
        emit(previousState.copyWith(errorMessage: e.toString()));
        return false;
      } finally {
        loaderService.hideLoader();
      }
    }
    return false;
  }

  Future<bool> incidentApproval(String incidentId, String type) async {
    IncidentDetailsLoaded? previousState;
    if (state is IncidentDetailsLoaded) {
      previousState = state as IncidentDetailsLoaded;
    }
    emit(IncidentDetailsLoading());
    loaderService.showLoader();
    try {
      final response = await _getIncidentByIdUseCase.incidentApproval(
        incidentId,
        type,
      );

      if (response.success == true && response.data != null) {
        getIncidentById(incidentId);
        return true;
      } else {
        if (previousState != null) {
          emit(
            previousState.copyWith(
              errorMessage: response.error ?? 'Failed to approve incident',
              processState: ProcessState.error,
            ),
          );
        }
        return false;
      }
    } catch (e) {
      if (previousState != null) {
        emit(
          previousState.copyWith(
            errorMessage: e.toString(),
            processState: ProcessState.error,
          ),
        );
      }
      return false;
    } finally {
      loaderService.hideLoader();
    }
  }

  Future<dynamic> removeMemberTask(String incidentId, String roleId) async {
    try {
      loaderService.showLoader();

      final response = await _getIncidentByIdUseCase.removeMemberTask(
        incidentId,
        roleId,
      );

      if (response.success == true) {
        getIncidentById(incidentId);
      }

      return response;
    } catch (e) {
      return {'success': false};
    } finally {
      loaderService.hideLoader();
    }
  }

  Future<bool> submitSetup(String incidentId, String type) async {
    loaderService.showLoader();
    try {
      final response = await _getIncidentByIdUseCase.submitSetup(
        incidentId,
        type,
      );
      return response.success == true;
    } catch (e) {
      return false;
    } finally {
      loaderService.hideLoader();
    }
  }

  Future<void> updateMembers(
    String incidentId,
    List<Map<String, dynamic>> members,
  ) async {
    if (state is! IncidentDetailsLoaded) return;

    final previousState = state as IncidentDetailsLoaded;
    loaderService.showLoader();

    try {
      final response = await _getIncidentByIdUseCase.updateMembers(
        incidentId,
        members,
      );

      if (response.success == true && response.data != null) {
        emit(
          previousState.copyWith(
            incident: response.data!,
            emergencyCardEdit: false,
          ),
        );
        getIncidentById(incidentId);
      } else {
        emit(
          previousState.copyWith(
            errorMessage: response.error ?? 'Failed to update members',
            processState: ProcessState.error,
          ),
        );
      }
    } catch (e) {
      emit(
        previousState.copyWith(
          errorMessage: e.toString(),
          processState: ProcessState.error,
        ),
      );
    } finally {
      loaderService.hideLoader();
    }
  }
}
