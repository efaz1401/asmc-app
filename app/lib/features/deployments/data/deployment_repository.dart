import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../employees/domain/employee.dart';
import '../domain/deployment.dart';

class DeploymentRepository {
  DeploymentRepository(this._client);
  final ApiClient _client;

  Future<DeploymentPage> list({
    String? q,
    String? employeeId,
    String? clientId,
    DeploymentStatus? status,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final resp = await _client.dio.get<Map<String, dynamic>>(
        '/deployments',
        queryParameters: {
          if (q != null && q.isNotEmpty) 'q': q,
          if (employeeId != null) 'employeeId': employeeId,
          if (clientId != null) 'clientId': clientId,
          if (status != null) 'status': status.value,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return DeploymentPage.fromJson(resp.data!);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Deployment> getById(String id) async {
    try {
      final resp = await _client.dio.get<Map<String, dynamic>>('/deployments/$id');
      return Deployment.fromJson(resp.data!);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Deployment> create(Map<String, dynamic> input) async {
    try {
      final resp = await _client.dio.post<Map<String, dynamic>>('/deployments', data: input);
      return Deployment.fromJson(resp.data!);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Deployment> update(String id, Map<String, dynamic> input) async {
    try {
      final resp = await _client.dio.patch<Map<String, dynamic>>('/deployments/$id', data: input);
      return Deployment.fromJson(resp.data!);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.dio.delete('/deployments/$id');
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<Employee>> availability({required DateTime startDate, DateTime? endDate}) async {
    try {
      final resp = await _client.dio.get<Map<String, dynamic>>(
        '/deployments/availability',
        queryParameters: {
          'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
        },
      );
      final items = (resp.data!['items'] as List<dynamic>? ?? const [])
          .map((e) => Employee.fromJson(e as Map<String, dynamic>))
          .toList();
      return items;
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<DeploymentStats> stats() async {
    try {
      final resp = await _client.dio.get<Map<String, dynamic>>('/deployments/stats');
      return DeploymentStats.fromJson(resp.data!);
    } catch (e) {
      throw mapDioError(e);
    }
  }
}

final deploymentRepositoryProvider = Provider<DeploymentRepository>((ref) {
  return DeploymentRepository(ref.watch(apiClientProvider));
});
