import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/role_badge.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_models.dart';
import '../application/employee_providers.dart';
import '../data/employee_repository.dart';
import '../domain/employee.dart';

class EmployeeDetailScreen extends ConsumerWidget {
  const EmployeeDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employee = ref.watch(employeeDetailProvider(id));
    final auth = ref.watch(authControllerProvider);
    final canManage =
        auth.user?.role == AppRole.superAdmin || auth.user?.role == AppRole.hrAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee'),
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/employees/$id/edit'),
            ),
          if (canManage)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, ref),
            ),
        ],
      ),
      body: AsyncValueView<Employee>(
        value: employee,
        onRetry: () => ref.invalidate(employeeDetailProvider(id)),
        dataBuilder: (e) => _Body(employee: e),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Deactivate employee?'),
        content: const Text(
          'This sets the employee as inactive. They will no longer appear in deployment availability.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Deactivate')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(employeeRepositoryProvider).delete(id);
      ref.invalidate(employeeListProvider);
      if (context.mounted) context.pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.employee});
  final Employee employee;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.navy700.withOpacity(0.12),
                  child: Text(
                    _initials(employee.fullName),
                    style: const TextStyle(
                      fontSize: 22,
                      color: AppColors.navy700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.fullName,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(employee.employeeCode,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          StatusPill(
                            label: employee.availability.label,
                            color: _availabilityColor(employee.availability),
                          ),
                          if (employee.trade != null) StatusPill(label: employee.trade!, color: AppColors.navy700),
                          if (employee.department != null) StatusPill(label: employee.department!, color: AppColors.grey700),
                          if (!employee.isActive) const StatusPill(label: 'Inactive', color: AppColors.danger),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Contact',
          rows: [
            _Row('Email', employee.email ?? '—'),
            _Row('Phone', employee.phone ?? '—'),
            _Row('Address', employee.address ?? '—'),
            _Row('Emergency contact', employee.emergencyContact ?? '—'),
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Employment',
          rows: [
            _Row('Department', employee.department ?? '—'),
            _Row('Trade', employee.trade ?? '—'),
            _Row('Skill category', employee.skillCategory ?? '—'),
            _Row('Salary', Formatters.money(employee.salary)),
            _Row('Joining date', Formatters.date(employee.joiningDate)),
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Documents',
          rows: [
            _Row('National ID', employee.nationalId ?? '—'),
            _Row('Visa number', employee.visaNumber ?? '—'),
            _Row('Visa expiry', Formatters.date(employee.visaExpiry)),
            _Row('Work permit', employee.workPermitNumber ?? '—'),
            _Row('Permit expiry', Formatters.date(employee.workPermitExpiry)),
          ],
        ),
      ],
    );
  }

  Color _availabilityColor(EmployeeAvailability a) {
    switch (a) {
      case EmployeeAvailability.available:
        return AppColors.emerald600;
      case EmployeeAvailability.deployed:
        return AppColors.info;
      case EmployeeAvailability.onLeave:
        return AppColors.warning;
      case EmployeeAvailability.inactive:
        return AppColors.danger;
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});
  final String title;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final r in rows) ...[
              const Divider(height: 16),
              r,
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
        ),
        Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}
