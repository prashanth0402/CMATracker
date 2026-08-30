import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/providers/providers.dart';
import 'router.dart';
import 'theme.dart';

class CmaTrackerApp extends ConsumerStatefulWidget {
  const CmaTrackerApp({super.key});

  @override
  ConsumerState<CmaTrackerApp> createState() => _CmaTrackerAppState();
}

class _CmaTrackerAppState extends ConsumerState<CmaTrackerApp> {
  final _router = AppRouter.build();

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}
