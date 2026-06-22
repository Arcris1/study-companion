import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/routes.dart';
import 'config/theme/app_theme.dart';
import 'presentation/providers/theme_provider.dart';

final routerProvider = Provider<bool>((ref) => false);

class StudyCompanionApp extends ConsumerStatefulWidget {
  final bool showOnboarding;

  const StudyCompanionApp({super.key, this.showOnboarding = false});

  @override
  ConsumerState<StudyCompanionApp> createState() => _StudyCompanionAppState();
}

class _StudyCompanionAppState extends ConsumerState<StudyCompanionApp> {
  /// Router is created once and reused across rebuilds to prevent
  /// navigation state loss when the theme or other providers change.
  late final _router = createRouter(showOnboarding: widget.showOnboarding);

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Study Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}
