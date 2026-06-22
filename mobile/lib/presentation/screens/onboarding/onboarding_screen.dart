import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/gradients.dart';
import '../../../config/theme/spacing.dart';
import '../../../config/theme/animations.dart';
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;

  late final AnimationController _floatController;

  static const _pages = [
    _PageData(
      icon: Icons.auto_stories,
      title: 'Import Your Notes',
      description:
          'Upload your markdown or text files, or type notes directly. Your study material stays on your device.',
    ),
    _PageData(
      icon: Icons.psychology,
      title: 'AI-Powered Learning',
      description:
          'Get summaries, ask questions, and generate quizzes & flashcards — powered by AI.',
    ),
    _PageData(
      icon: Icons.vpn_key_rounded,
      title: 'Your Key, Your Control',
      description:
          'Connect your own OpenAI API key. Notes stay on your device; only what is needed is sent to OpenAI.',
    ),
  ];

  static const _gradients = [
    AppGradients.onboarding1,
    AppGradients.onboarding2,
    AppGradients.onboarding3,
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedContainer(
            duration: AppAnimations.durationSlow,
            curve: AppAnimations.easeInOut,
            decoration: BoxDecoration(
              gradient: _gradients[_currentPage],
            ),
          ),

          // Page content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: _pages.length,
                    itemBuilder: (_, i) => _OnboardingPage(
                      data: _pages[i],
                      floatAnimation: _floatController,
                    ),
                  ),
                ),

                // Pagination dots
                Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.lg),
                  child: SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: const WormEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      activeDotColor: Colors.white,
                      dotColor: Colors.white38,
                      spacing: 12,
                    ),
                  ),
                ),

                // Bottom buttons
                Padding(
                  padding: EdgeInsets.only(
                    left: Spacing.screenPaddingH,
                    right: Spacing.screenPaddingH,
                    bottom: Spacing.md +
                        MediaQuery.of(context).padding.bottom.clamp(0, 16),
                  ),
                  child: _currentPage == _pages.length - 1
                      ? SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: _GetStartedButton(
                            onPressed: () =>
                                context.go('${AppRoutes.apiKeySetup}?first=1'),
                          ),
                        )
                      : Row(
                          children: [
                            TextButton(
                              onPressed: () =>
                                  context.go('${AppRoutes.apiKeySetup}?first=1'),
                              child: Text(
                                'Skip',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Spacer(),
                            _NextButton(
                              onPressed: () {
                                _pageController.nextPage(
                                  duration: AppAnimations.durationMedium,
                                  curve: AppAnimations.easeInOut,
                                );
                              },
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Page data ──────────────────────────────────────────────────────────────

class _PageData {
  final IconData icon;
  final String title;
  final String description;

  const _PageData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

// ─── Single onboarding page ─────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  final _PageData data;
  final AnimationController floatAnimation;

  const _OnboardingPage({
    required this.data,
    required this.floatAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.screenPaddingH),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration area
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer dashed ring
                CustomPaint(
                  size: const Size(180, 180),
                  painter: _DashedCirclePainter(
                    color: Colors.white.withValues(alpha: 0.15),
                    strokeWidth: 2,
                  ),
                ),

                // Frosted glass circle
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Icon(data.icon, size: 72, color: Colors.white),
                ),

                // Floating accent dots
                ..._buildFloatingDots(),
              ],
            ),
          ),

          const SizedBox(height: Spacing.xxl),

          // Title
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          )
              .animate(key: ValueKey('title_${data.title}'))
              .fadeIn(duration: 500.ms, curve: Curves.easeOutCubic)
              .slideY(begin: 0.2, end: 0, duration: 500.ms),

          const SizedBox(height: Spacing.md),

          // Description
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              data.description,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          )
              .animate(key: ValueKey('desc_${data.title}'))
              .fadeIn(duration: 500.ms, delay: 150.ms, curve: Curves.easeOutCubic)
              .slideY(begin: 0.2, end: 0, duration: 500.ms, delay: 150.ms),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingDots() {
    final dots = [
      _FloatingDot(size: 12, offset: const Offset(-80, -60), delay: 0.0),
      _FloatingDot(size: 8, offset: const Offset(75, -40), delay: 0.3),
      _FloatingDot(size: 6, offset: const Offset(-60, 70), delay: 0.6),
    ];

    return dots.map((dot) {
      return AnimatedBuilder(
        animation: floatAnimation,
        builder: (_, child) {
          final progress =
              ((floatAnimation.value + dot.delay) % 1.0);
          final yOffset = math.sin(progress * math.pi * 2) * 8;
          return Positioned(
            left: 100 + dot.offset.dx - dot.size / 2,
            top: 100 + dot.offset.dy - dot.size / 2 + yOffset,
            child: child!,
          );
        },
        child: Container(
          width: dot.size,
          height: dot.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.20),
          ),
        ),
      );
    }).toList();
  }
}

class _FloatingDot {
  final double size;
  final Offset offset;
  final double delay;

  const _FloatingDot({
    required this.size,
    required this.offset,
    required this.delay,
  });
}

// ─── Dashed circle painter ──────────────────────────────────────────────────

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _DashedCirclePainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);
    const dashCount = 36;
    const dashArc = (2 * math.pi) / dashCount;
    const gapRatio = 0.4;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashArc;
      final sweepAngle = dashArc * (1 - gapRatio);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter old) =>
      color != old.color || strokeWidth != old.strokeWidth;
}

// ─── Get Started button (white pill) ────────────────────────────────────────

class _GetStartedButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _GetStartedButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(Spacing.radiusPill),
      elevation: 0,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(Spacing.radiusPill),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Get Started',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.primaryDark,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Next button (frosted pill) ─────────────────────────────────────────────

class _NextButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _NextButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(Spacing.radiusPill),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(Spacing.radiusPill),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Spacing.radiusPill),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.20),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: const Text(
            'Next',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
