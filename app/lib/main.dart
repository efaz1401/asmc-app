import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/application/auth_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: AsmcApp()));
}

class AsmcApp extends ConsumerStatefulWidget {
  const AsmcApp({super.key});

  @override
  ConsumerState<AsmcApp> createState() => _AsmcAppState();
}

class _AsmcAppState extends ConsumerState<AsmcApp> {
  @override
  void initState() {
    super.initState();
    // Hydrate auth state from secure storage so the splash screen can
    // resolve to either /login or /dashboard.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = buildRouter(ref);
    return MaterialApp.router(
      title: 'ASMC Workforce',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
