import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_config.dart';
import '../../../config/routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/spacing.dart';
import '../../../config/theme/shadows.dart';
import '../../../config/theme/gradients.dart';
import '../../../config/theme/animations.dart';
import '../../providers/theme_provider.dart';
import '../../../core/ai/ai_config.dart';
import '../../../core/openai/openai_client.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);
    final hasApiKey = OpenAiClient.instance.hasKey;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: theme.textTheme.titleLarge),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          Spacing.screenPaddingH,
          Spacing.lg,
          Spacing.screenPaddingH,
          Spacing.lg + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          // ── User Avatar Section ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(Spacing.cardPaddingLarge),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: Spacing.borderRadiusMd,
              boxShadow: isDark ? AppShadows.level1Dark : AppShadows.level1,
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.primary,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: Spacing.md),
                // Name and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Student',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: Spacing.xxs),
                      Text(
                        'StudyCompanion',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Edit button
                IconButton(
                  icon: Icon(
                    Icons.edit_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  onPressed: () {
                    // Future: edit profile
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: Spacing.lg),

          // ── Appearance Section ──────────────────────────────────
          _SectionHeader(label: 'APPEARANCE', theme: theme),
          const SizedBox(height: Spacing.sm),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: Spacing.borderRadiusMd,
              boxShadow: isDark ? AppShadows.level1Dark : AppShadows.level1,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.xs,
              ),
              leading: _buildThemeIcon(themeMode, isDark),
              title: Text('Theme', style: theme.textTheme.titleSmall),
              subtitle: Text(
                _themeModeName(themeMode),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: _ThemeToggle(
                currentMode: themeMode,
                isDark: isDark,
                onChanged: (mode) {
                  ref.read(themeModeProvider.notifier).setThemeMode(mode);
                },
              ),
            ),
          ),

          const SizedBox(height: Spacing.lg),

          // ── AI Section ─────────────────────────────────────────
          _SectionHeader(label: 'AI', theme: theme),
          const SizedBox(height: Spacing.sm),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: Spacing.borderRadiusMd,
              boxShadow: isDark ? AppShadows.level1Dark : AppShadows.level1,
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.xs,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary,
                      borderRadius: Spacing.borderRadiusSm,
                    ),
                    child: const Icon(
                      Icons.key_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  title:
                      Text('OpenAI API Key', style: theme.textTheme.titleSmall),
                  subtitle: Text(
                    hasApiKey
                        ? 'Configured · ${AiConfig.instance.chatModel}'
                        : 'Not set — tap to add',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: hasApiKey
                          ? theme.colorScheme.onSurfaceVariant
                          : AppColors.error,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onTap: () => context.push(AppRoutes.apiKeySetup),
                ),
                Divider(
                  height: 1,
                  indent: Spacing.md,
                  endIndent: Spacing.md,
                  color: isDark
                      ? AppColors.outlineVariantDark
                      : AppColors.outlineVariantLight,
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.xs,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: Spacing.borderRadiusSm,
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text('AI Settings', style: theme.textTheme.titleSmall),
                  subtitle: Text(
                    'Models, prompts & token limits',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onTap: () => context.push(AppRoutes.aiPrompts),
                ),
              ],
            ),
          ),

          const SizedBox(height: Spacing.lg),

          // ── About Section ──────────────────────────────────────
          _SectionHeader(label: 'ABOUT', theme: theme),
          const SizedBox(height: Spacing.sm),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: Spacing.borderRadiusMd,
              boxShadow: isDark ? AppShadows.level1Dark : AppShadows.level1,
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.xs,
                  ),
                  leading: Icon(
                    Icons.school_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    'Study Companion',
                    style: theme.textTheme.titleSmall,
                  ),
                  subtitle: Text(
                    'v${AppConfig.appVersion}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  indent: Spacing.md,
                  endIndent: Spacing.md,
                  color: isDark
                      ? AppColors.outlineVariantDark
                      : AppColors.outlineVariantLight,
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.xs,
                  ),
                  leading: Icon(
                    Icons.shield_rounded,
                    color: AppColors.success,
                  ),
                  title: Text(
                    'Privacy',
                    style: theme.textTheme.titleSmall,
                  ),
                  subtitle: Text(
                    'Notes stay on device; AI requests use OpenAI',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  indent: Spacing.md,
                  endIndent: Spacing.md,
                  color: isDark
                      ? AppColors.outlineVariantDark
                      : AppColors.outlineVariantLight,
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.xs,
                  ),
                  leading: Icon(
                    Icons.description_rounded,
                    color: AppColors.info,
                  ),
                  title: Text(
                    'Licenses',
                    style: theme.textTheme.titleSmall,
                  ),
                  subtitle: Text(
                    'Open source licenses',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: AppConfig.appName,
                      applicationVersion: AppConfig.appVersion,
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: Spacing.xl),
        ],
      ),
    );
  }

  Widget _buildThemeIcon(ThemeMode mode, bool isDark) {
    IconData iconData;
    Color iconColor;

    switch (mode) {
      case ThemeMode.light:
        iconData = Icons.light_mode_rounded;
        iconColor = AppColors.warning;
        break;
      case ThemeMode.dark:
        iconData = Icons.dark_mode_rounded;
        iconColor = AppColors.info;
        break;
      case ThemeMode.system:
        iconData = Icons.brightness_auto_rounded;
        iconColor = isDark
            ? AppColors.onSurfaceVariantDark
            : AppColors.onSurfaceVariantLight;
        break;
    }

    return Icon(iconData, color: iconColor);
  }

  String _themeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
}

// ─── Section Header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final ThemeData theme;

  const _SectionHeader({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: theme.textTheme.labelSmall?.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ─── Theme Toggle (3-state pill: Sun | Auto | Moon) ──────────────────────────

class _ThemeToggle extends StatelessWidget {
  final ThemeMode currentMode;
  final bool isDark;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeToggle({
    required this.currentMode,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final modes = [ThemeMode.light, ThemeMode.system, ThemeMode.dark];
    final icons = [
      Icons.light_mode_rounded,
      Icons.brightness_auto_rounded,
      Icons.dark_mode_rounded,
    ];
    final selectedIndex = modes.indexOf(currentMode);

    return Container(
      width: 108,
      height: 36,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceContainerDark
            : AppColors.surfaceContainerLight,
        borderRadius: Spacing.borderRadiusPill,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth =
              (constraints.maxWidth) / modes.length;

          return Stack(
            children: [
              // Sliding thumb
              AnimatedPositioned(
                duration: AppAnimations.durationFast,
                curve: AppAnimations.easeInOut,
                left: selectedIndex * segmentWidth,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: Spacing.borderRadiusPill,
                  ),
                ),
              ),
              // Icons
              Row(
                children: List.generate(modes.length, (i) {
                  final isSelected = i == selectedIndex;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(modes[i]),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: AppAnimations.durationFast,
                          style: const TextStyle(),
                          child: Icon(
                            icons[i],
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? AppColors.onSurfaceVariantDark
                                    : AppColors.onSurfaceVariantLight)
                                    .withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
