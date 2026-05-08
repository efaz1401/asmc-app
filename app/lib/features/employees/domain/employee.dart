import '../../../core/utils/formatters.dart';

enum EmployeeAvailability {
  available('AVAILABLE'),
  deployed('DEPLOYED'),
  onLeave('ON_LEAVE'),
  inactive('INACTIVE');

  const EmployeeAvailability(this.value);
  final String value;

  static EmployeeAvailability fromString(String? raw) {
    return EmployeeAvailability.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => EmployeeAvailability.available,
    );
  }

  String get label {
    switch (this) {
      case EmployeeAvailability.available:
        return 'Available';
      case EmployeeAvailability.deployed:
        return 'Deployed';
      case EmployeeAvailability.onLeave:
        return 'On leave';
      case EmployeeAvailability.inactive:
        return 'Inactive';
    }
  }
}

class Employee {
  Employee({
    required this.id,
    required this.employeeCode,
    required this.fullName,
    this.email,
    this.phone,
    this.address,
    this.nationalId,
    this.emergencyContact,
    this.department,
    this.trade,
    this.skillCategory,
    this.salary = 0,
    this.joiningDate,
    this.availability = EmployeeAvailability.available,
    this.isActive = true,
    this.profilePhotoUrl,
    this.visaNumber,
    this.visaExpiry,
    this.workPermitNumber,
    this.workPermitExpiry,
  });

  final String id;
  final String employeeCode;
  final String fullName;
  final String? email;
  final String? phone;
  final String? address;
  final String? nationalId;
  final String? emergencyContact;
  final String? department;
  final String? trade;
  final String? skillCategory;
  final num salary;
  final DateTime? joiningDate;
  final EmployeeAvailability availability;
  final bool isActive;
  final String? profilePhotoUrl;
  final String? visaNumber;
  final DateTime? visaExpiry;
  final String? workPermitNumber;
  final DateTime? workPermitExpiry;

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      employeeCode: (json['employeeCode'] as String?) ?? '',
      fullName: (json['fullName'] as String?) ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      nationalId: json['nationalId'] as String?,
      emergencyContact: json['emergencyContact'] as String?,
      department: json['department'] as String?,
      trade: json['trade'] as String?,
      skillCategory: json['skillCategory'] as String?,
      salary: (json['salary'] as num?) ?? 0,
      joiningDate: Formatters.tryParseIso(json['joiningDate']),
      availability: EmployeeAvailability.fromString(json['availability'] as String?),
      isActive: (json['isActive'] as bool?) ?? true,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      visaNumber: json['visaNumber'] as String?,
      visaExpiry: Formatters.tryParseIso(json['visaExpiry']),
      workPermitNumber: json['workPermitNumber'] as String?,
      workPermitExpiry: Formatters.tryParseIso(json['workPermitExpiry']),
    );
  }
}

class EmployeePage {
  EmployeePage({required this.items, required this.total, required this.page, required this.pageSize});
  final List<Employee> items;
  final int total;
  final int page;
  final int pageSize;

  factory EmployeePage.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] as List<dynamic>? ?? const [])
        .map((e) => Employee.fromJson(e as Map<String, dynamic>))
        .toList();
    return EmployeePage(
      items: list,
      total: (json['total'] as int?) ?? list.length,
      page: (json['page'] as int?) ?? 1,
      pageSize: (json['pageSize'] as int?) ?? list.length,
    );
  }
}
