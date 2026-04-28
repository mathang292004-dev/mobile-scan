import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/client_management/client_response.dart';
import 'package:emergex/presentation/emergex_onboarding/model/client_filter_request.dart';
import 'package:emergex/presentation/emergex_onboarding/model/client_request.dart';
import 'package:emergex/data/remote_data_source/client_remote_data_source.dart';
import 'package:emergex/domain/repo/client_repo.dart';

class ClientRepositoryImpl implements ClientRepository {
  final ClientRemoteDataSource _remoteDataSource;

  ClientRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResponse<ClientResponse>> getClients({
    ClientFilterRequest? filters,
  }) async {
    try {
      return await _remoteDataSource.getClients(filters: filters);
    } catch (e) {
      return ApiResponse<ClientResponse>.error(
        'Failed to get clients: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<Client>> addClient(ClientRequest request) async {
    try {
      return await _remoteDataSource.addClient(request);
    } catch (e) {
      return ApiResponse<Client>.error(
        'Failed to add client: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<UpdateClientResponse>> updateClient(
    ClientRequest request,
  ) async {
    try {
      return await _remoteDataSource.updateClient(request);
    } catch (e) {
      return ApiResponse<UpdateClientResponse>.error(
        'Failed to update client: ${e.toString()}',
      );
    }
  }

  @override
  Future<ApiResponse<DeleteClientResponse>> deleteClient(
    String clientId,
  ) async {
    try {
      return await _remoteDataSource.deleteClient(clientId);
    } catch (e) {
      return ApiResponse<DeleteClientResponse>.error(
        'Failed to delete client: ${e.toString()}',
      );
    }
  }
}

