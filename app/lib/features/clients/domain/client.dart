import '../../../core/utils/formatters.dart';

class Client {
  Client({
    required this.id,
    required this.companyName,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    this.industry,
    this.billingAddress,
    this.taxId,
    this.notes,
    this.isActive = true,
    this.activeManpower = 0,
    this.createdAt,
  });

  final String id;
  final String companyName;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final String? industry;
  final String? billingAddress;
  final String? taxId;
  final String? notes;
  final bool isActive;
  final int activeManpower;
  final DateTime? createdAt;

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as String,
      companyName: (json['companyName'] as String?) ?? '',
      contactPerson: json['contactPerson'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      industry: json['industry'] as String?,
      billingAddress: json['billingAddress'] as String?,
      taxId: json['taxId'] as String?,
      notes: json['notes'] as String?,
      isActive: (json['isActive'] as bool?) ?? true,
      activeManpower: (json['activeManpower'] as int?) ?? 0,
      createdAt: Formatters.tryParseIso(json['createdAt']),
    );
  }
}

class ClientPage {
  ClientPage({required this.items, required this.total, required this.page, required this.pageSize});
  final List<Client> items;
  final int total;
  final int page;
  final int pageSize;

  factory ClientPage.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] as List<dynamic>? ?? const [])
        .map((e) => Client.fromJson(e as Map<String, dynamic>))
        .toList();
    return ClientPage(
      items: list,
      total: (json['total'] as int?) ?? list.length,
      page: (json['page'] as int?) ?? 1,
      pageSize: (json['pageSize'] as int?) ?? list.length,
    );
  }
}

class HiringHistoryItem {
  HiringHistoryItem({
    required this.id,
    required this.projectName,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    this.trade,
  });

  final String id;
  final String projectName;
  final String status;
  final DateTime startDate;
  final DateTime? endDate;
  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final String? trade;

  factory HiringHistoryItem.fromJson(Map<String, dynamic> json) {
    final emp = json['employee'] as Map<String, dynamic>?;
    return HiringHistoryItem(
      id: json['id'] as String,
      projectName: (json['projectName'] as String?) ?? '—',
      status: (json['status'] as String?) ?? 'SCHEDULED',
      startDate: Formatters.tryParseIso(json['startDate']) ?? DateTime.now(),
      endDate: Formatters.tryParseIso(json['endDate']),
      employeeId: (emp?['id'] as String?) ?? '',
      employeeName: (emp?['fullName'] as String?) ?? '—',
      employeeCode: (emp?['employeeCode'] as String?) ?? '',
      trade: emp?['trade'] as String?,
    );
  }
}
