import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/presentation/emergex_onboarding/model/client_filter_request.dart';
import 'package:emergex/presentation/emergex_onboarding/model/client_request.dart';
import 'package:emergex/presentation/emergex_onboarding/use_cases/client_use_case/client_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:emergex/data/model/client_management/client_response.dart';
import 'package:emergex/helpers/auth_guard.dart';

class ClientState extends Equatable {
  final List<Client> clients;
  final ProcessState processState;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final ClientResponse? response;
  final List<String> locations;
  final List<String> industries;
  final ClientFilterRequest? appliedFilters;

  const ClientState({
    this.clients = const [],
    this.processState = ProcessState.none,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.response,
    this.locations = const [],
    this.industries = const [],
    this.appliedFilters,
  });

  factory ClientState.initial() =>
      const ClientState(processState: ProcessState.none);

  ClientState copyWith({
    List<Client>? clients,
    ProcessState? processState,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    ClientResponse? response,
    List<String>? locations,
    List<String>? industries,
    ClientFilterRequest? appliedFilters,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearAppliedFilters = false,
  }) {
    return ClientState(
      clients: clients ?? this.clients,
      processState: processState ?? this.processState,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      response: response ?? this.response,
      locations: locations ?? this.locations,
      industries: industries ?? this.industries,
      appliedFilters: clearAppliedFilters
          ? null
          : (appliedFilters ?? this.appliedFilters),
    );
  }

  @override
  List<Object?> get props => [
    clients,
    processState,
    isLoading,
    errorMessage,
    successMessage,
    response,
    locations,
    industries,
    appliedFilters,
  ];
}

class ClientCubit extends Cubit<ClientState> {
  final ClientUseCase _clientUseCase;

  ClientCubit(this._clientUseCase) : super(ClientState.initial());

  /// Clear cache and reset to initial state
  void clearCache() {
    emit(ClientState.initial());
  }

  /// Fetch clients with optional filters
  Future<void> getClients({ClientFilterRequest? filters}) async {
    if (!await AuthGuard.canProceed()) return;

    try {
      emit(
        state.copyWith(
          processState: ProcessState.loading,
          isLoading: true,
          errorMessage: null,
          successMessage: null,
          clearError: true,
          clearSuccess: true,
        ),
      );

      final response = await _clientUseCase.getClients(filters: filters);

      if (response.success == true && response.data != null) {
        final clientResponse = response.data!;

        emit(
          state.copyWith(
            processState: ProcessState.done,
            isLoading: false,
            response: clientResponse,
            clients: clientResponse.clients ?? [],
            locations: clientResponse.locations ?? [],
            industries: clientResponse.industries ?? [],
            appliedFilters: filters,
            clearAppliedFilters: filters == null,
            errorMessage: null,
            clearError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            processState: ProcessState.error,
            isLoading: false,
            errorMessage:
                response.error ?? response.message ?? 'Failed to fetch clients',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.error,
          isLoading: false,
          errorMessage: 'Failed to fetch clients: ${e.toString()}',
        ),
      );
    }
  }

  /// Refresh clients with current filters
  Future<void> refreshClients() async {
    await getClients(filters: state.appliedFilters);
  }

  /// Clear error and success messages
  void clearError() {
    emit(state.copyWith(
      errorMessage: null,
      successMessage: null,
      clearError: true,
      clearSuccess: true,
    ));
  }

  /// Add new client
  Future<void> addClient(ClientRequest request) async {
    try {
      emit(
        state.copyWith(
          processState: ProcessState.loading,
          isLoading: true,
          errorMessage: null,
          clearError: true,
          clearSuccess: true,
        ),
      );

      final response = await _clientUseCase.addClient(request);

      if (response.success == true && response.data != null) {
        // Emit success message before refreshing
        emit(
          state.copyWith(
            processState: ProcessState.done,
            isLoading: false,
            successMessage: 'Client created successfully',
          ),
        );
        // Refresh clients list after successful add
        await refreshClients();
      } else {
        emit(
          state.copyWith(
            processState: ProcessState.error,
            isLoading: false,
            errorMessage:
                response.error ?? response.message ?? 'Failed to add client',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.error,
          isLoading: false,
          errorMessage: 'Failed to add client: ${e.toString()}',
        ),
      );
    }
  }

  /// Update existing client
  Future<void> updateClient(ClientRequest request) async {
    try {
      emit(
        state.copyWith(
          processState: ProcessState.loading,
          isLoading: true,
          errorMessage: null,
          clearError: true,
          clearSuccess: true,
        ),
      );

      final response = await _clientUseCase.updateClient(request);

      if (response.success == true && response.data != null) {
        // Emit success message before refreshing
        emit(
          state.copyWith(
            processState: ProcessState.done,
            isLoading: false,
            successMessage: 'Client updated successfully',
          ),
        );
        // Refresh clients list after successful update
        await refreshClients();
      } else {
        emit(
          state.copyWith(
            processState: ProcessState.error,
            isLoading: false,
            errorMessage:
                response.error ?? response.message ?? 'Failed to update client',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.error,
          isLoading: false,
          errorMessage: 'Failed to update client: ${e.toString()}',
        ),
      );
    }
  }

  /// Delete client
  Future<void> deleteClient(String clientId) async {
    try {
      emit(
        state.copyWith(
          processState: ProcessState.loading,
          isLoading: true,
          errorMessage: null,
          clearError: true,
          clearSuccess: true,
        ),
      );

      final response = await _clientUseCase.deleteClient(clientId);

      if (response.success == true) {
        // Emit success message before refreshing
        emit(
          state.copyWith(
            processState: ProcessState.done,
            isLoading: false,
            successMessage: 'Client deleted successfully',
          ),
        );
        // Refresh clients list after successful delete
        await refreshClients();
      } else {
        emit(
          state.copyWith(
            processState: ProcessState.error,
            isLoading: false,
            errorMessage:
                response.error ?? response.message ?? 'Failed to delete client',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.error,
          isLoading: false,
          errorMessage: 'Failed to delete client: ${e.toString()}',
        ),
      );
    }
  }
}
