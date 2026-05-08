import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/role_badge.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_models.dart';
import '../application/deployment_providers.dart';
import '../domain/deployment.dart';

class DeploymentListScreen extends ConsumerStatefulWidget {
  const DeploymentListScreen({super.key});

  @override
  ConsumerState<DeploymentListScreen> createState() => _DeploymentListScreenState();
}

class _DeploymentListScreenState extends ConsumerState<DeploymentListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(deploymentFilterProvider);
    final list = ref.watch(deploymentListProvider);
    final auth = ref.watch(authControllerProvider);
    final canManage = auth.user?.role == AppRole.superAdmin ||
        auth.user?.role == AppRole.hrAdmin ||
        auth.user?.role == AppRole.supervisor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deployments'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(deploymentListProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/deployments/new'),
              icon: const Icon(Icons.assignment_ind),
              label: const Text('Assign'),
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
                    decoration: const InputDecoration(
                      hintText: 'Search by project / employee / client',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) {
                      ref.read(deploymentFilterProvider.notifier).state =
                          filter.copyWith(query: v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                _StatusFilter(filter: filter),
              ],
            ),
          ),
          Expanded(
            child: AsyncValueView<DeploymentPage>(
              value: list,
              onRetry: () => ref.invalidate(deploymentListProvider),
              dataBuilder: (page) {
                if (page.items.isEmpty) {
                  return const EmptyState(
                    title: 'No deployments yet',
                    icon: Icons.assignment_outlined,
                    message: 'Assign workers to clients with the action button.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(deploymentListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: page.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _DeploymentRow(deployment: page.items[i]),
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

class _StatusFilter extends ConsumerWidget {
  const _StatusFilter({required this.filter});
  final DeploymentListFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<DeploymentStatus?>(
      tooltip: 'Filter status',
      icon: Icon(Icons.filter_list,
          color: filter.status != null
              ? Theme.of(context).colorScheme.primary
              : null),
      onSelected: (v) {
        ref.read(deploymentFilterProvider.notifier).state = filter.copyWith(
          status: v,
          clearStatus: v == null,
        );
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: null, child: Text('All statuses')),
        ...DeploymentStatus.values.map(
          (s) => PopupMenuItem(value: s, child: Text(s.label)),
        ),
      ],
    );
  }
}

class _DeploymentRow extends StatelessWidget {
  const _DeploymentRow({required this.deployment});
  final Deployment deployment;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(deployment.status);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/deployments/${deployment.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      deployment.projectName ?? 'Untitled project',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  StatusPill(label: deployment.status.label, color: color),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      [
                        deployment.employeeName ?? '—',
                        if (deployment.employeeCode != null) deployment.employeeCode,
                      ].whereType<String>().join(' · '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.apartment, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(deployment.clientName ?? '—',
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.event, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${Formatters.date(deployment.startDate)} → ${Formatters.date(deployment.endDate)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  if (deployment.shift != null)
                    StatusPill(label: deployment.shift!.label, color: AppColors.navy700),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(DeploymentStatus s) {
    switch (s) {
      case DeploymentStatus.scheduled:
        return AppColors.info;
      case DeploymentStatus.active:
        return AppColors.emerald600;
      case DeploymentStatus.completed:
        return AppColors.grey700;
      case DeploymentStatus.cancelled:
        return AppColors.danger;
    }
  }
}
