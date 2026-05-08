import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/client.dart';

class ClientRepository {
  ClientRepository(this._client);
  final ApiClient _client;

  Future<ClientPage> list({String? q, String? industry, bool? isActive, int page = 1, int pageSize = 50}) async {
    try {
      final resp = await _client.dio.get<Map<String, dynamic>>(
        '/clients',
        queryParameters: {
          if (q != null && q.isNotEmpty) 'q': q,
          if (industry != null) 'industry': industry,
          if (isActive != null) 'isActive': isActive.toString(),
          'page': page,
          'pageSize': pageSize,
        },
      );
      return ClientPage.fromJson(resp.data!);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Client> getById(String id) async {
    try {
      final resp = await _client.dio.get<Map<String, dynamic>>('/clients/$id');
      return Client.fromJson(resp.data!);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<HiringHistoryItem>> hiringHistory(String id) async {
    try {
      final resp = await _client.dio.get<Map<String, dynamic>>('/clients/$id/hiring-history');
      final items = (resp.data!['items'] as List<dynamic>? ?? const [])
          .map((e) => HiringHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
      return items;
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Client> create(Map<String, dynamic> input) async {
    try {
      final resp = await _client.dio.post<Map<String, dynamic>>('/clients', data: input);
      return Client.fromJson(resp.data!);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Client> update(String id, Map<String, dynamic> input) async {
    try {
      final resp = await _client.dio.patch<Map<String, dynamic>>('/clients/$id', data: input);
      return Client.fromJson(resp.data!);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.dio.delete('/clients/$id');
    } catch (e) {
      throw mapDioError(e);
    }
  }
}

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepository(ref.watch(apiClientProvider));
});
