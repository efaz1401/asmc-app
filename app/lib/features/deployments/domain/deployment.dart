import '../../../core/utils/formatters.dart';

enum DeploymentStatus {
  scheduled('SCHEDULED'),
  active('ACTIVE'),
  completed('COMPLETED'),
  cancelled('CANCELLED');

  const DeploymentStatus(this.value);
  final String value;

  static DeploymentStatus fromString(String? raw) {
    return DeploymentStatus.values.firstWhere(
      (s) => s.value == raw,
      orElse: () => DeploymentStatus.scheduled,
    );
  }

  String get label {
    switch (this) {
      case DeploymentStatus.scheduled:
        return 'Scheduled';
      case DeploymentStatus.active:
        return 'Active';
      case DeploymentStatus.completed:
        return 'Completed';
      case DeploymentStatus.cancelled:
        return 'Cancelled';
    }
  }
}

enum Shift {
  morning('MORNING'),
  evening('EVENING'),
  night('NIGHT'),
  fullDay('FULL_DAY');

  const Shift(this.value);
  final String value;

  static Shift? fromString(String? raw) {
    if (raw == null) return null;
    for (final s in Shift.values) {
      if (s.value == raw) return s;
    }
    return null;
  }

  String get label {
    switch (this) {
      case Shift.morning:
        return 'Morning';
      case Shift.evening:
        return 'Evening';
      case Shift.night:
        return 'Night';
      case Shift.fullDay:
        return 'Full day';
    }
  }
}

class Deployment {
  Deployment({
    required this.id,
    required this.employeeId,
    required this.clientId,
    this.supervisorId,
    this.projectName,
    required this.startDate,
    this.endDate,
    this.shift,
    required this.status,
    this.notes,
    this.employeeName,
    this.employeeCode,
    this.employeeTrade,
    this.clientName,
  });

  final String id;
  final String employeeId;
  final String clientId;
  final String? supervisorId;
  final String? projectName;
  final DateTime startDate;
  final DateTime? endDate;
  final Shift? shift;
  final DeploymentStatus status;
  final String? notes;
  // Optional eager-loaded relations
  final String? employeeName;
  final String? employeeCode;
  final String? employeeTrade;
  final String? clientName;

  factory Deployment.fromJson(Map<String, dynamic> json) {
    final emp = json['employee'] as Map<String, dynamic>?;
    final cli = json['client'] as Map<String, dynamic>?;
    return Deployment(
      id: json['id'] as String,
      employeeId: (json['employeeId'] as String?) ?? (emp?['id'] as String? ?? ''),
      clientId: (json['clientId'] as String?) ?? (cli?['id'] as String? ?? ''),
      supervisorId: json['supervisorId'] as String?,
      projectName: json['projectName'] as String?,
      startDate: Formatters.tryParseIso(json['startDate']) ?? DateTime.now(),
      endDate: Formatters.tryParseIso(json['endDate']),
      shift: Shift.fromString(json['shift'] as String?),
      status: DeploymentStatus.fromString(json['status'] as String?),
      notes: json['notes'] as String?,
      employeeName: emp?['fullName'] as String?,
      employeeCode: emp?['employeeCode'] as String?,
      employeeTrade: emp?['trade'] as String?,
      clientName: cli?['companyName'] as String?,
    );
  }
}

class DeploymentPage {
  DeploymentPage({required this.items, required this.total, required this.page, required this.pageSize});
  final List<Deployment> items;
  final int total;
  final int page;
  final int pageSize;

  factory DeploymentPage.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] as List<dynamic>? ?? const [])
        .map((e) => Deployment.fromJson(e as Map<String, dynamic>))
        .toList();
    return DeploymentPage(
      items: list,
      total: (json['total'] as int?) ?? list.length,
      page: (json['page'] as int?) ?? 1,
      pageSize: (json['pageSize'] as int?) ?? list.length,
    );
  }
}

class DeploymentStats {
  DeploymentStats({
    required this.total,
    required this.active,
    required this.scheduled,
    required this.completed,
    required this.availableWorkers,
    required this.totalEmployees,
    required this.totalClients,
  });

  final int total;
  final int active;
  final int scheduled;
  final int completed;
  final int availableWorkers;
  final int totalEmployees;
  final int totalClients;

  factory DeploymentStats.fromJson(Map<String, dynamic> json) {
    return DeploymentStats(
      total: (json['total'] as int?) ?? 0,
      active: (json['active'] as int?) ?? 0,
      scheduled: (json['scheduled'] as int?) ?? 0,
      completed: (json['completed'] as int?) ?? 0,
      availableWorkers: (json['availableWorkers'] as int?) ?? 0,
      totalEmployees: (json['totalEmployees'] as int?) ?? 0,
      totalClients: (json['totalClients'] as int?) ?? 0,
    );
  }
}
