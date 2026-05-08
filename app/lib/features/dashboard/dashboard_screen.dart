import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/async_value_view.dart';
import '../../core/widgets/role_badge.dart';
import '../auth/application/auth_controller.dart';
import '../auth/domain/auth_models.dart';
import '../deployments/application/deployment_providers.dart';
import '../deployments/domain/deployment.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: RoleBadge(user.role.value)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(deploymentStatsProvider);
          ref.invalidate(deploymentListProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _GreetingCard(user: user),
            const SizedBox(height: 16),
            if (user?.role == AppRole.client)
              const _ClientDashboard()
            else if (user?.role == AppRole.employee)
              const _EmployeeDashboard()
            else if (user?.role == AppRole.supervisor)
              const _SupervisorDashboard()
            else
              const _AdminDashboard(),
          ],
        ),
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({required this.user});
  final AuthUser? user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy900, AppColors.navy700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _greeting(),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            user?.fullName ?? '—',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            user == null
                ? 'Welcome to ASMC.'
                : 'Logged in as ${user!.role.label}.',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 18) return 'Good afternoon,';
    return 'Good evening,';
  }
}

class _AdminDashboard extends ConsumerWidget {
  const _AdminDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(deploymentStatsProvider);
    final list = ref.watch(deploymentListProvider);
    final isWide = Responsive.isTablet(context) || Responsive.isDesktop(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AsyncValueView<DeploymentStats>(
          value: stats,
          dataBuilder: (s) {
            final cards = [
              _StatCard(label: 'Active deployments', value: s.active.toString(), color: AppColors.emerald600, icon: Icons.directions_run),
              _StatCard(label: 'Scheduled', value: s.scheduled.toString(), color: AppColors.info, icon: Icons.event),
              _StatCard(label: 'Available workers', value: s.availableWorkers.toString(), color: AppColors.navy700, icon: Icons.group),
              _StatCard(label: 'Total clients', value: s.totalClients.toString(), color: AppColors.warning, icon: Icons.apartment),
            ];
            return GridView.count(
              crossAxisCount: isWide ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: cards,
            );
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.person_add_alt_1,
                label: 'Add employee',
                color: AppColors.navy700,
                onTap: () => context.push('/employees/new'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAction(
                icon: Icons.add_business,
                label: 'Add client',
                color: AppColors.emerald600,
                onTap: () => context.push('/clients/new'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAction(
                icon: Icons.assignment_ind,
                label: 'Assign worker',
                color: AppColors.warning,
                onTap: () => context.push('/deployments/new'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Recent deployments',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        AsyncValueView<DeploymentPage>(
          value: list,
          dataBuilder: (page) {
            if (page.items.isEmpty) {
              return const EmptyState(title: 'No deployments yet', icon: Icons.assignment_outlined);
            }
            final items = page.items.take(5).toList();
            return Column(
              children: [
                for (final d in items)
                  Card(
                    child: ListTile(
                      title: Text(d.projectName ?? '—'),
                      subtitle: Text('${d.employeeName ?? ''} · ${d.clientName ?? ''}'),
                      trailing: StatusPill(label: d.status.label, color: _statusColor(d.status)),
                      onTap: () => context.push('/deployments/${d.id}'),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
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

class _SupervisorDashboard extends ConsumerWidget {
  const _SupervisorDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(deploymentListProvider);
    return AsyncValueView<DeploymentPage>(
      value: list,
      dataBuilder: (page) {
        final active = page.items.where((d) => d.status == DeploymentStatus.active).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Active deployments under your watch',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (active.isEmpty)
              const EmptyState(title: 'No active deployments', icon: Icons.directions_run),
            for (final d in active)
              Card(
                child: ListTile(
                  title: Text(d.projectName ?? '—'),
                  subtitle: Text('${d.employeeName ?? ''} · ${d.clientName ?? ''}\n${Formatters.date(d.startDate)} → ${Formatters.date(d.endDate)}'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/deployments/${d.id}'),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ClientDashboard extends ConsumerWidget {
  const _ClientDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(deploymentListProvider);
    return AsyncValueView<DeploymentPage>(
      value: list,
      dataBuilder: (page) {
        final active = page.items.where((d) => d.status == DeploymentStatus.active).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Active workforce',
                    value: active.length.toString(),
                    color: AppColors.emerald600,
                    icon: Icons.group,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Total deployments',
                    value: page.total.toString(),
                    color: AppColors.navy700,
                    icon: Icons.assignment_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Currently deployed',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (active.isEmpty)
              const EmptyState(title: 'No active workforce', icon: Icons.engineering),
            for (final d in active)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(d.employeeName ?? '—'),
                  subtitle: Text('${d.employeeTrade ?? ''} · ${d.projectName ?? ''}'),
                  trailing: StatusPill(label: 'Active', color: AppColors.emerald600),
                  onTap: () => context.push('/deployments/${d.id}'),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EmployeeDashboard extends ConsumerWidget {
  const _EmployeeDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(deploymentListProvider);
    return AsyncValueView<DeploymentPage>(
      value: list,
      dataBuilder: (page) {
        final myActive = page.items.where((d) => d.status == DeploymentStatus.active).toList();
        final upcoming = page.items.where((d) => d.status == DeploymentStatus.scheduled).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current assignment',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (myActive.isEmpty)
              const EmptyState(title: 'No active assignment', icon: Icons.beach_access),
            for (final d in myActive)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.work_outline),
                  title: Text(d.projectName ?? '—'),
                  subtitle: Text('${d.clientName ?? ''}\n${Formatters.date(d.startDate)} → ${Formatters.date(d.endDate)}'),
                  isThreeLine: true,
                  trailing: const StatusPill(label: 'Active', color: AppColors.emerald600),
                  onTap: () => context.push('/deployments/${d.id}'),
                ),
              ),
            const SizedBox(height: 16),
            Text('Upcoming',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (upcoming.isEmpty)
              const EmptyState(title: 'No upcoming deployments', icon: Icons.event_note),
            for (final d in upcoming)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.event),
                  title: Text(d.projectName ?? '—'),
                  subtitle: Text('${d.clientName ?? ''} · ${Formatters.date(d.startDate)}'),
                  onTap: () => context.push('/deployments/${d.id}'),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.color, required this.icon});
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.14),
            child: Icon(icon, color: color),
          ),
          Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }
}
