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
import '../data/deployment_repository.dart';
import '../domain/deployment.dart';

class DeploymentDetailScreen extends ConsumerWidget {
  const DeploymentDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(deploymentDetailProvider(id));
    final auth = ref.watch(authControllerProvider);
    final canManage = auth.user?.role == AppRole.superAdmin ||
        auth.user?.role == AppRole.hrAdmin ||
        auth.user?.role == AppRole.supervisor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deployment'),
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/deployments/$id/edit'),
            ),
        ],
      ),
      body: AsyncValueView<Deployment>(
        value: detail,
        onRetry: () => ref.invalidate(deploymentDetailProvider(id)),
        dataBuilder: (d) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.projectName ?? 'Untitled project',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        StatusPill(label: d.status.label, color: _statusColor(d.status)),
                        if (d.shift != null) StatusPill(label: d.shift!.label, color: AppColors.navy700),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(d.employeeName ?? '—'),
                subtitle: Text([
                  if (d.employeeCode != null) d.employeeCode,
                  if (d.employeeTrade != null) d.employeeTrade,
                ].whereType<String>().join(' · ')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/employees/${d.employeeId}'),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.apartment),
                title: Text(d.clientName ?? '—'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/clients/${d.clientId}'),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Schedule',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text('Start: ${Formatters.date(d.startDate)}'),
                    Text('End: ${Formatters.date(d.endDate)}'),
                  ],
                ),
              ),
            ),
            if (d.notes != null && d.notes!.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notes',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(d.notes!),
                    ],
                  ),
                ),
              ),
            if (canManage) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _confirmCancel(context, ref),
                icon: const Icon(Icons.cancel_outlined, color: AppColors.danger),
                label: const Text('Cancel deployment'),
              ),
            ],
          ],
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

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel deployment?'),
        content: const Text('The worker will return to the available pool.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, cancel')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(deploymentRepositoryProvider).delete(id);
      ref.invalidate(deploymentListProvider);
      ref.invalidate(deploymentStatsProvider);
      if (context.mounted) context.pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}
