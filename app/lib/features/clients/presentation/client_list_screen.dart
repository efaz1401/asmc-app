import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/role_badge.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_models.dart';
import '../application/client_providers.dart';
import '../domain/client.dart';

class ClientListScreen extends ConsumerStatefulWidget {
  const ClientListScreen({super.key});

  @override
  ConsumerState<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends ConsumerState<ClientListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(clientFilterProvider);
    final list = ref.watch(clientListProvider);
    final auth = ref.watch(authControllerProvider);
    final canManage =
        auth.user?.role == AppRole.superAdmin || auth.user?.role == AppRole.hrAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(clientListProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/clients/new'),
              icon: const Icon(Icons.add_business),
              label: const Text('Add'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by company or contact',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) {
                ref.read(clientFilterProvider.notifier).state =
                    filter.copyWith(query: v);
              },
            ),
          ),
          Expanded(
            child: AsyncValueView<ClientPage>(
              value: list,
              onRetry: () => ref.invalidate(clientListProvider),
              dataBuilder: (page) {
                if (page.items.isEmpty) {
                  return const EmptyState(
                    title: 'No clients yet',
                    icon: Icons.apartment_outlined,
                    message: 'Add a client to start deploying workforce.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(clientListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: page.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _ClientRow(client: page.items[i]),
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

class _ClientRow extends StatelessWidget {
  const _ClientRow({required this.client});
  final Client client;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/clients/${client.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.emerald600.withOpacity(0.14),
                child: const Icon(Icons.apartment, color: AppColors.emerald600),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(client.companyName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            )),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (client.contactPerson != null) client.contactPerson,
                        if (client.industry != null) client.industry,
                      ].whereType<String>().join(' · '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: '${client.activeManpower} active',
                color: client.activeManpower > 0 ? AppColors.emerald600 : AppColors.grey400,
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
