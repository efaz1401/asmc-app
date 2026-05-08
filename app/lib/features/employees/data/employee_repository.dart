import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/employee.dart';

class EmployeeRepository {
  EmployeeRepository(this._client);
  final ApiClient _client;

  Future<EmployeePage> list({
    String? q,
    String? department,
    EmployeeAvailability? availability,
    bool? isActive,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final resp = await _client.dio.get<Map<String, dynamic>>(
        '/employees',
        queryParameters: {
          if (q != null && q.isNotEmpty) 'q': q,
          if (department != null) 'department': department,
          if (availability != null) 'availability': availability.value,
          if (isActive != null) 'isActive': isActive.toString(),
          'page': page,
          'pageSize': pageSize,
        },
      );
      return EmployeePage.fromJson(resp.data!);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Employee> getById(String id) async {
    try {
      final resp = await _client.dio.get<Map<String, dynamic>>('/employees/$id');
      return Employee.fromJson(resp.data!);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Employee> create(Map<String, dynamic> input) async {
    try {
      final resp = await _client.dio.post<Map<String, dynamic>>('/employees', data: input);
      return Employee.fromJson(resp.data!);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Employee> update(String id, Map<String, dynamic> input) async {
    try {
      final resp = await _client.dio.patch<Map<String, dynamic>>('/employees/$id', data: input);
      return Employee.fromJson(resp.data!);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.dio.delete('/employees/$id');
    } catch (e) {
      throw mapDioError(e);
    }
  }
}

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository(ref.watch(apiClientProvider));
});
