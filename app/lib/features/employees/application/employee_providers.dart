import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/employee_repository.dart';
import '../domain/employee.dart';

class EmployeeListFilter {
  const EmployeeListFilter({
    this.query = '',
    this.availability,
    this.department,
  });

  final String query;
  final EmployeeAvailability? availability;
  final String? department;

  EmployeeListFilter copyWith({
    String? query,
    EmployeeAvailability? availability,
    String? department,
    bool clearAvailability = false,
    bool clearDepartment = false,
  }) {
    return EmployeeListFilter(
      query: query ?? this.query,
      availability: clearAvailability ? null : (availability ?? this.availability),
      department: clearDepartment ? null : (department ?? this.department),
    );
  }
}

final employeeFilterProvider =
    StateProvider<EmployeeListFilter>((_) => const EmployeeListFilter());

final employeeListProvider = FutureProvider.autoDispose<EmployeePage>((ref) async {
  final repo = ref.watch(employeeRepositoryProvider);
  final filter = ref.watch(employeeFilterProvider);
  return repo.list(
    q: filter.query,
    availability: filter.availability,
    department: filter.department,
    pageSize: 50,
  );
});

final employeeDetailProvider =
    FutureProvider.autoDispose.family<Employee, String>((ref, id) async {
  final repo = ref.watch(employeeRepositoryProvider);
  return repo.getById(id);
});
