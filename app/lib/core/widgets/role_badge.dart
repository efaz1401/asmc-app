import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Small color-coded chip that renders a user role label.
class RoleBadge extends StatelessWidget {
  const RoleBadge(this.role, {super.key});
  final String role;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _styleFor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  (String, Color) _styleFor(String role) {
    switch (role) {
      case 'SUPER_ADMIN':
        return ('Super Admin', AppColors.navy700);
      case 'HR_ADMIN':
        return ('HR / Admin', AppColors.info);
      case 'SUPERVISOR':
        return ('Supervisor', AppColors.warning);
      case 'CLIENT':
        return ('Client', AppColors.emerald600);
      case 'EMPLOYEE':
        return ('Employee', AppColors.grey700);
      default:
        return (role, AppColors.grey400);
    }
  }
}

/// Status pill for deployment / availability / etc.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
