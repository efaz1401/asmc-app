import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/role_badge.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_models.dart';
import '../application/client_providers.dart';
import '../data/client_repository.dart';
import '../domain/client.dart';

class ClientDetailScreen extends ConsumerWidget {
  const ClientDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(clientDetailProvider(id));
    final history = ref.watch(clientHiringHistoryProvider(id));
    final auth = ref.watch(authControllerProvider);
    final canManage =
        auth.user?.role == AppRole.superAdmin || auth.user?.role == AppRole.hrAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Client'),
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/clients/$id/edit'),
            ),
          if (canManage)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, ref),
            ),
        ],
      ),
      body: AsyncValueView<Client>(
        value: detail,
        onRetry: () => ref.invalidate(clientDetailProvider(id)),
        dataBuilder: (c) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(clientDetailProvider(id));
            ref.invalidate(clientHiringHistoryProvider(id));
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Header(client: c),
              const SizedBox(height: 12),
              _Section(
                title: 'Contact',
                rows: [
                  _Row('Contact person', c.contactPerson ?? '—'),
                  _Row('Email', c.email ?? '—'),
                  _Row('Phone', c.phone ?? '—'),
                  _Row('Address', c.address ?? '—'),
                ],
              ),
              const SizedBox(height: 12),
              _Section(
                title: 'Billing',
                rows: [
                  _Row('Tax ID', c.taxId ?? '—'),
                  _Row('Billing address', c.billingAddress ?? '—'),
                  _Row('Industry', c.industry ?? '—'),
                ],
              ),
              if (c.notes != null && c.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notes', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text(c.notes!),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text('Hiring history',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              AsyncValueView<List<HiringHistoryItem>>(
                value: history,
                dataBuilder: (items) {
                  if (items.isEmpty) {
                    return const EmptyState(
                      title: 'No deployments yet',
                      icon: Icons.history,
                    );
                  }
                  return Column(
                    children: [
                      for (final h in items) _HistoryTile(item: h),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Deactivate client?'),
        content: const Text('Client will be marked inactive.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Deactivate')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(clientRepositoryProvider).delete(id);
      ref.invalidate(clientListProvider);
      if (context.mounted) context.pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.client});
  final Client client;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.emerald600.withOpacity(0.14),
              child: const Icon(Icons.apartment, color: AppColors.emerald600, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(client.companyName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  if (client.industry != null)
                    Text(client.industry!, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      StatusPill(
                        label: '${client.activeManpower} active workforce',
                        color: client.activeManpower > 0 ? AppColors.emerald600 : AppColors.grey400,
                      ),
                      if (!client.isActive)
                        const StatusPill(label: 'Inactive', color: AppColors.danger),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item});
  final HiringHistoryItem item;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.work_outline),
        title: Text(item.projectName),
        subtitle: Text('${item.employeeName} (${item.employeeCode})${item.trade != null ? ' · ${item.trade}' : ''}\n${Formatters.date(item.startDate)} → ${Formatters.date(item.endDate)}'),
        isThreeLine: true,
        trailing: StatusPill(label: item.status, color: _statusColor(item.status)),
        onTap: () => context.push('/deployments/${item.id}'),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'ACTIVE':
        return AppColors.emerald600;
      case 'SCHEDULED':
        return AppColors.info;
      case 'COMPLETED':
        return AppColors.grey700;
      case 'CANCELLED':
        return AppColors.danger;
      default:
        return AppColors.grey400;
    }
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
        SizedBox(width: 130, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
        Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}
