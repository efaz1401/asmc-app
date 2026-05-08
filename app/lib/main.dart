import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

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
