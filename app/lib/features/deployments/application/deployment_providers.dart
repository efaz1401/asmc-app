import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../employees/domain/employee.dart';
import '../data/deployment_repository.dart';
import '../domain/deployment.dart';

class DeploymentListFilter {
  const DeploymentListFilter({
    this.query = '',
    this.status,
    this.employeeId,
    this.clientId,
  });

  final String query;
  final DeploymentStatus? status;
  final String? employeeId;
  final String? clientId;

  DeploymentListFilter copyWith({
    String? query,
    DeploymentStatus? status,
    String? employeeId,
    String? clientId,
    bool clearStatus = false,
    bool clearEmployee = false,
    bool clearClient = false,
  }) {
    return DeploymentListFilter(
      query: query ?? this.query,
      status: clearStatus ? null : (status ?? this.status),
      employeeId: clearEmployee ? null : (employeeId ?? this.employeeId),
      clientId: clearClient ? null : (clientId ?? this.clientId),
    );
  }
}

final deploymentFilterProvider = StateProvider<DeploymentListFilter>((_) => const DeploymentListFilter());

final deploymentListProvider = FutureProvider.autoDispose<DeploymentPage>((ref) async {
  final repo = ref.watch(deploymentRepositoryProvider);
  final filter = ref.watch(deploymentFilterProvider);
  return repo.list(
    q: filter.query,
    status: filter.status,
    employeeId: filter.employeeId,
    clientId: filter.clientId,
  );
});

final deploymentDetailProvider = FutureProvider.autoDispose.family<Deployment, String>((ref, id) async {
  return ref.watch(deploymentRepositoryProvider).getById(id);
});

final deploymentStatsProvider = FutureProvider.autoDispose<DeploymentStats>((ref) async {
  return ref.watch(deploymentRepositoryProvider).stats();
});

class AvailabilityArgs {
  const AvailabilityArgs({required this.startDate, this.endDate});
  final DateTime startDate;
  final DateTime? endDate;

  @override
  bool operator ==(Object other) =>
      other is AvailabilityArgs &&
      other.startDate == startDate &&
      other.endDate == endDate;
  @override
  int get hashCode => Object.hash(startDate, endDate);
}

final availableEmployeesProvider =
    FutureProvider.autoDispose.family<List<Employee>, AvailabilityArgs>((ref, args) async {
  return ref.watch(deploymentRepositoryProvider).availability(
        startDate: args.startDate,
        endDate: args.endDate,
      );
});
