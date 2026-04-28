import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/client_management/client_response.dart';
import 'package:emergex/presentation/emergex_onboarding/model/client_filter_request.dart';
import 'package:emergex/presentation/emergex_onboarding/model/client_request.dart';
import 'package:emergex/domain/repo/client_repo.dart';

class ClientUseCase {
  final ClientRepository _clientRepository;

  ClientUseCase(this._clientRepository);

  Future<ApiResponse<ClientResponse>> getClients({
    ClientFilterRequest? filters,
  }) async {
    try {
      return await _clientRepository.getClients(filters: filters);
    } catch (e) {
      return ApiResponse<ClientResponse>.error(
        'Use case error: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<Client>> addClient(ClientRequest request) async {
    try {
      return await _clientRepository.addClient(request);
    } catch (e) {
      return ApiResponse<Client>.error(
        'Use case error: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<UpdateClientResponse>> updateClient(
    ClientRequest request,
  ) async {
    try {
      return await _clientRepository.updateClient(request);
    } catch (e) {
      return ApiResponse<UpdateClientResponse>.error(
        'Use case error: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<DeleteClientResponse>> deleteClient(
    String clientId,
  ) async {
    try {
      return await _clientRepository.deleteClient(clientId);
    } catch (e) {
      return ApiResponse<DeleteClientResponse>.error(
        'Use case error: ${e.toString()}',
      );
    }
  }
}

