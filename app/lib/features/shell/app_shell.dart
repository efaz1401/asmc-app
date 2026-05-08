import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../auth/application/auth_controller.dart';
import '../auth/domain/auth_models.dart';

class NavItem {
  const NavItem({
    required this.label,
    required this.icon,
    required this.path,
    required this.allowedRoles,
  });

  final String label;
  final IconData icon;
  final String path;
  final Set<AppRole> allowedRoles;
}

const _allRoles = <AppRole>{
  AppRole.superAdmin,
  AppRole.hrAdmin,
  AppRole.supervisor,
  AppRole.client,
  AppRole.employee,
};

const _adminRoles = <AppRole>{AppRole.superAdmin, AppRole.hrAdmin};
const _adminAndSupervisor = <AppRole>{AppRole.superAdmin, AppRole.hrAdmin, AppRole.supervisor};

const navItems = <NavItem>[
  NavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, path: '/dashboard', allowedRoles: _allRoles),
  NavItem(label: 'Employees', icon: Icons.badge_outlined, path: '/employees', allowedRoles: _adminAndSupervisor),
  NavItem(label: 'Clients', icon: Icons.apartment_outlined, path: '/clients', allowedRoles: _adminAndSupervisor),
  NavItem(label: 'Deployments', icon: Icons.assignment_outlined, path: '/deployments', allowedRoles: _allRoles),
  NavItem(label: 'Attendance', icon: Icons.fact_check_outlined, path: '/attendance', allowedRoles: _allRoles),
  NavItem(label: 'Payroll', icon: Icons.payments_outlined, path: '/payroll', allowedRoles: _adminRoles),
  NavItem(label: 'Invoices', icon: Icons.receipt_long_outlined, path: '/invoices', allowedRoles: _adminAndSupervisor),
  NavItem(label: 'Contracts', icon: Icons.assignment_turned_in_outlined, path: '/contracts', allowedRoles: _allRoles),
  NavItem(label: 'Reports', icon: Icons.insights_outlined, path: '/reports', allowedRoles: _adminRoles),
  NavItem(label: 'Notifications', icon: Icons.notifications_outlined, path: '/notifications', allowedRoles: _allRoles),
  NavItem(label: 'Settings', icon: Icons.settings_outlined, path: '/settings', allowedRoles: _allRoles),
];

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child, required this.location});
  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final role = user?.role ?? AppRole.employee;
    final items = navItems.where((i) => i.allowedRoles.contains(role)).toList();
    final selectedIndex = _selectedIndex(items, location);
    final isWide = Responsive.isTablet(context) || Responsive.isDesktop(context);

    if (isWide) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              _SideNav(
                items: items,
                selectedIndex: selectedIndex,
                user: user,
                onLogout: () async {
                  await ref.read(authControllerProvider.notifier).logout();
                },
              ),
              const VerticalDivider(width: 1),
              Expanded(child: child),
            ],
          ),
        ),
      );
    }

    final mobileItems = items.take(5).toList();
    final mobileIndex = _selectedIndex(mobileItems, location).clamp(0, mobileItems.isEmpty ? 0 : mobileItems.length - 1);
    return Scaffold(
      body: child,
      drawer: _MobileDrawer(
        items: items,
        selectedIndex: selectedIndex,
        user: user,
        onLogout: () async {
          await ref.read(authControllerProvider.notifier).logout();
        },
      ),
      bottomNavigationBar: mobileItems.isEmpty
          ? null
          : NavigationBar(
              selectedIndex: mobileIndex,
              onDestinationSelected: (i) => context.go(mobileItems[i].path),
              destinations: [
                for (final item in mobileItems)
                  NavigationDestination(icon: Icon(item.icon), label: item.label),
              ],
            ),
    );
  }

  int _selectedIndex(List<NavItem> items, String location) {
    int best = 0;
    int bestLen = 0;
    for (var i = 0; i < items.length; i++) {
      final p = items[i].path;
      if (location.startsWith(p) && p.length > bestLen) {
        best = i;
        bestLen = p.length;
      }
    }
    return best;
  }
}

class _SideNav extends StatelessWidget {
  const _SideNav({
    required this.items,
    required this.selectedIndex,
    required this.user,
    required this.onLogout,
  });
  final List<NavItem> items;
  final int selectedIndex;
  final AuthUser? user;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.navy700,
                  child: const Icon(Icons.engineering, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ASMC',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      Text(
                        user?.fullName ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 8),
          Expanded(
            child: ListView(
              children: [
                for (var i = 0; i < items.length; i++)
                  _NavTile(
                    item: items[i],
                    selected: i == selectedIndex,
                  ),
              ],
            ),
          ),
          const Divider(height: 8),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async => onLogout(),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _MobileDrawer extends StatelessWidget {
  const _MobileDrawer({
    required this.items,
    required this.selectedIndex,
    required this.user,
    required this.onLogout,
  });
  final List<NavItem> items;
  final int selectedIndex;
  final AuthUser? user;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.navy700,
                    child: const Icon(Icons.engineering, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ASMC',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                        Text(
                          user?.fullName ?? '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 8),
            Expanded(
              child: ListView(
                children: [
                  for (var i = 0; i < items.length; i++)
                    _NavTile(
                      item: items[i],
                      selected: i == selectedIndex,
                      onTap: () => Navigator.pop(context),
                    ),
                ],
              ),
            ),
            const Divider(height: 8),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                await onLogout();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.item, required this.selected, this.onTap});
  final NavItem item;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: selected,
      selectedTileColor: AppColors.navy700.withOpacity(0.08),
      leading: Icon(item.icon, color: selected ? AppColors.navy700 : null),
      title: Text(
        item.label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          color: selected ? AppColors.navy700 : null,
        ),
      ),
      onTap: () {
        if (onTap != null) onTap!();
        GoRouter.of(context).go(item.path);
      },
    );
  }
}
