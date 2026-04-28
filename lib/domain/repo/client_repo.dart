import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/data/model/client_management/client_response.dart';
import 'package:emergex/presentation/emergex_onboarding/model/client_filter_request.dart';
import 'package:emergex/presentation/emergex_onboarding/model/client_request.dart';

abstract class ClientRepository {
  Future<ApiResponse<ClientResponse>> getClients({
    ClientFilterRequest? filters,
  });

  Future<ApiResponse<Client>> addClient(ClientRequest request);

  Future<ApiResponse<UpdateClientResponse>> updateClient(ClientRequest request);

  Future<ApiResponse<DeleteClientResponse>> deleteClient(String clientId);
}
