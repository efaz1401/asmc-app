/// Allowed roles. Mirrors the backend Prisma `User.role` enum-string.
enum AppRole {
  superAdmin('SUPER_ADMIN'),
  hrAdmin('HR_ADMIN'),
  supervisor('SUPERVISOR'),
  client('CLIENT'),
  employee('EMPLOYEE');

  const AppRole(this.value);
  final String value;

  static AppRole fromString(String? value) {
    return AppRole.values.firstWhere(
      (r) => r.value == value,
      orElse: () => AppRole.employee,
    );
  }

  String get label {
    switch (this) {
      case AppRole.superAdmin:
        return 'Super Admin';
      case AppRole.hrAdmin:
        return 'HR / Admin';
      case AppRole.supervisor:
        return 'Supervisor';
      case AppRole.client:
        return 'Client';
      case AppRole.employee:
        return 'Employee';
    }
  }
}

/// Authenticated user profile.
class AuthUser {
  AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.isActive = true,
  });

  final String id;
  final String email;
  final String fullName;
  final AppRole role;
  final String? phone;
  final bool isActive;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: (json['fullName'] as String?) ?? '',
      role: AppRole.fromString(json['role'] as String?),
      phone: json['phone'] as String?,
      isActive: (json['isActive'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'role': role.value,
        'phone': phone,
        'isActive': isActive,
      };
}

/// Tokens + user returned from /auth/login or /auth/register.
class AuthSession {
  AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final AuthUser user;
  final String accessToken;
  final String refreshToken;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }
}
