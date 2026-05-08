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
import '../domain/employee.dart';

class EmployeeListScreen extends ConsumerStatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  ConsumerState<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends ConsumerState<EmployeeListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(employeeFilterProvider);
    final list = ref.watch(employeeListProvider);
    final auth = ref.watch(authControllerProvider);
    final canManage =
        auth.user?.role == AppRole.superAdmin || auth.user?.role == AppRole.hrAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(employeeListProvider),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/employees/new'),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name, code, trade…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(employeeFilterProvider.notifier).state =
                                    filter.copyWith(query: '');
                              },
                            ),
                    ),
                    onChanged: (v) {
                      ref.read(employeeFilterProvider.notifier).state =
                          filter.copyWith(query: v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                _AvailabilityFilter(filter: filter),
              ],
            ),
          ),
          Expanded(
            child: AsyncValueView<EmployeePage>(
              value: list,
              onRetry: () => ref.invalidate(employeeListProvider),
              dataBuilder: (page) {
                if (page.items.isEmpty) {
                  return EmptyState(
                    title: 'No employees yet',
                    message: canManage
                        ? 'Create your first employee with the + button.'
                        : 'No employees match the current filters.',
                    icon: Icons.engineering_outlined,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(employeeListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: page.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _EmployeeRow(employee: page.items[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityFilter extends ConsumerWidget {
  const _AvailabilityFilter({required this.filter});
  final EmployeeListFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<EmployeeAvailability?>(
      tooltip: 'Filter availability',
      icon: Icon(Icons.filter_list,
          color: filter.availability != null
              ? Theme.of(context).colorScheme.primary
              : null),
      onSelected: (v) {
        ref.read(employeeFilterProvider.notifier).state = filter.copyWith(
          availability: v,
          clearAvailability: v == null,
        );
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: null, child: Text('All')),
        ...EmployeeAvailability.values.map(
          (a) => PopupMenuItem(value: a, child: Text(a.label)),
        ),
      ],
    );
  }
}

class _EmployeeRow extends StatelessWidget {
  const _EmployeeRow({required this.employee});
  final Employee employee;

  @override
  Widget build(BuildContext context) {
    final color = _availabilityColor(employee.availability);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/employees/${employee.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.navy700.withOpacity(0.12),
                child: Text(
                  _initials(employee.fullName),
                  style: const TextStyle(
                    color: AppColors.navy700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            employee.fullName,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusPill(label: employee.availability.label, color: color),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        employee.employeeCode,
                        if (employee.trade != null && employee.trade!.isNotEmpty) employee.trade,
                        if (employee.department != null && employee.department!.isNotEmpty) employee.department,
                      ].whereType<String>().join(' · '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (employee.salary > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${Formatters.money(employee.salary)} / month',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
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
