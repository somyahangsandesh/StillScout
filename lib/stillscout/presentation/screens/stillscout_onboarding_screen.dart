import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/stillscout_constants.dart';
import '../theme/stillscout_theme.dart';
import '../widgets/stillscout_buttons.dart';
import '../widgets/stillscout_logo.dart';
import '../widgets/stillscout_paywall_sheet.dart';

/// Key stored in SharedPreferences after the user completes or skips onboarding.
const _kOnboardingDoneKey = 'onboarding_complete_v1';

/// Returns true if the user has already seen onboarding.
Future<bool> stillScoutOnboardingComplete() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingDoneKey) ?? false;
}

/// Marks onboarding as complete — call after "Start Scouting" or "Skip".
Future<void> _markOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingDoneKey, true);
}

/// 4-step interactive first-run walkthrough.
///
/// Steps 1–3 explain the core flow.  Step 4 is a full-screen AI Pro upsell
/// that converts curious users before they ever open the main screen.
class StillScoutOnboardingScreen extends StatefulWidget {
  const StillScoutOnboardingScreen({
    super.key,
    required this.onFinished,
  });

  /// Called when the user finishes or skips — navigate to main screen here.
  final VoidCallback onFinished;

  @override
  State<StillScoutOnboardingScreen> createState() =>
      _StillScoutOnboardingScreenState();
}

class _StillScoutOnboardingScreenState
    extends State<StillScoutOnboardingScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  int _page = 0;
  static const _totalPages = 4;

  late final List<AnimationController> _stepControllers;
  late final List<Animation<double>> _stepFades;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: StillScoutColors.voidBlack,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _stepControllers = List.generate(
      _totalPages,
      (i) => AnimationController(
        vsync: this,
        duration: StillScoutMotion.slow,
      ),
    );
    _stepFades = _stepControllers
        .map(
          (c) => CurvedAnimation(parent: c, curve: StillScoutMotion.entrance),
        )
        .toList();

    _stepControllers[0].forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _stepControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _goToPage(int index) async {
    HapticFeedback.selectionClick();
    await _pageController.animateToPage(
      index,
      duration: StillScoutMotion.slow,
      curve: StillScoutMotion.toggle,
    );
  }

  Future<void> _next() async {
    if (_page < _totalPages - 1) {
      await _goToPage(_page + 1);
    } else {
      await _finish();
    }
  }

  Future<void> _finish() async {
    HapticFeedback.lightImpact();
    await _markOnboardingDone();
    widget.onFinished();
  }

  /// Shows the paywall over the onboarding screen, then navigates to the main
  /// screen regardless of the purchase outcome (user can always upgrade later).
  Future<void> _tryPro() async {
    HapticFeedback.mediumImpact();
    await _markOnboardingDone();
    if (!mounted) return;
    await StillScoutPaywallSheet.show(
      context,
      exportsRemaining: StillScoutConstants.freeExportsPerScout,
      reason:
          'Scout smarter. No daily cap, ${StillScoutConstants.proKeeperLimit} keepers per scout, native 4K exports.',
      onPurchased: () {}, // Subscription state refreshes on main screen load.
    );
    if (!mounted) return;
    widget.onFinished();
  }

  void _onPageChanged(int index) {
    setState(() => _page = index);
    _stepControllers[index].forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StillScoutColors.voidBlack,
      body: Stack(
        children: [
          // Ambient background glow — shifts colour per page
          _AmbientGlow(page: _page),

          // Page content
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [
              _OnboardingStep(
                stepIndex: 0,
                fade: _stepFades[0],
                brandFirst: true,
                illustration: const _PickIllustration(),
                headline: 'Drop any clip.',
                subline: 'Even 4K.',
                body:
                    'Pick a video from your library or record straight from the camera — StillScout handles the rest.',
              ),
              _OnboardingStep(
                stepIndex: 1,
                fade: _stepFades[1],
                illustration: const _ScoutIllustration(),
                headline: 'AI ranks\nevery frame.',
                subline: 'You pick your best.',
                body:
                    'Apple Vision scores sharpness, open eyes, and composition — instantly, on-device. No waiting.',
              ),
              _OnboardingStep(
                stepIndex: 2,
                fade: _stepFades[2],
                illustration: const _SaveIllustration(),
                headline: 'Export in\nseconds.',
                subline: 'On-device scouting works offline.',
                body:
                    'Includes a one-time free Gemini AI trial (internet required). Later free scouts run fully on-device. Upgrade to AI Pro for unlimited Gemini and native 4K.',
              ),
              _ProUpsellStep(fade: _stepFades[3]),
            ],
          ),

          // Bottom navigation — dots + buttons
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomNav(
              page: _page,
              totalPages: _totalPages,
              onNext: _next,
              onSkip: _finish,
              onProTap: _tryPro,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step layout ───────────────────────────────────────────────────────────────

class _OnboardingStep extends StatelessWidget {
  const _OnboardingStep({
    required this.stepIndex,
    required this.fade,
    required this.illustration,
    required this.headline,
    required this.subline,
    required this.body,
    this.brandFirst = false,
  });

  final int stepIndex;
  final Animation<double> fade;
  final Widget illustration;
  final String headline;
  final String subline;
  final String body;
  final bool brandFirst;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      bottom: false,
      child: FadeTransition(
        opacity: fade,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: StillScoutSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: brandFirst ? StillScoutSpacing.m : StillScoutSpacing.xl,
              ),
              if (brandFirst) ...[
                Semantics(
                  header: true,
                  label: 'StillScout',
                  child: const Center(
                    child: StillScoutLogo(
                      size: 44,
                      showWordmark: true,
                      animateGlow: true,
                      glowStrength: 0.22,
                    ),
                  ),
                ),
                const SizedBox(height: StillScoutSpacing.m),
              ],
              Expanded(
                flex: brandFirst ? 4 : 5,
                child: Center(child: illustration),
              ),
              const SizedBox(height: StillScoutSpacing.l),
              Semantics(
                label: 'Step ${stepIndex + 1} of 3',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: StillScoutSpacing.s, vertical: 3),
                  decoration: BoxDecoration(
                    color: StillScoutColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(StillScoutRadius.pill),
                    border: Border.all(
                      color: StillScoutColors.accent.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    'STEP ${stepIndex + 1} OF 3',
                    style: StillScoutTextStyles.badge.copyWith(
                      color: StillScoutColors.accent,
                      fontSize: 10,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: StillScoutSpacing.m),
              Text(
                headline,
                style: StillScoutTextStyles.display.copyWith(
                  fontSize: brandFirst ? 36 : 38,
                  height: 1.05,
                  color: StillScoutColors.chalk,
                ),
              ),
              Text(
                subline,
                style: StillScoutTextStyles.display.copyWith(
                  fontSize: 26,
                  color: StillScoutColors.scoutGold,
                ),
              ),
              const SizedBox(height: StillScoutSpacing.m),
              Text(
                body,
                style: StillScoutTextStyles.body.copyWith(
                  color: StillScoutColors.silver,
                  height: 1.55,
                ),
              ),
              SizedBox(height: 120 + bottomInset),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pro upsell step (page 4) ──────────────────────────────────────────────────

final _kProFeatures = [
  ('Unlimited scouts — no daily cap', Icons.all_inclusive_rounded),
  ('Gemini scores your best frames', Icons.psychology_rounded),
  (
    '${StillScoutConstants.proKeeperLimit} keepers unlocked per scout',
    Icons.workspace_premium_rounded,
  ),
  ('Auto-polish at export', Icons.auto_fix_high_rounded),
  ('4K export at full quality', Icons.hd_rounded),
];

class _ProUpsellStep extends StatelessWidget {
  const _ProUpsellStep({required this.fade});

  final Animation<double> fade;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      bottom: false,
      child: FadeTransition(
        opacity: fade,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: StillScoutSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: StillScoutSpacing.xl),
              const Expanded(
                flex: 4,
                child: Center(child: _ProIllustration()),
              ),
              const SizedBox(height: StillScoutSpacing.m),
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: StillScoutSpacing.s, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      StillScoutColors.accent.withValues(alpha: 0.25),
                      StillScoutColors.secondaryAccent.withValues(alpha: 0.18),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(StillScoutRadius.pill),
                  border: Border.all(
                    color: StillScoutColors.accent.withValues(alpha: 0.55),
                  ),
                ),
                child: Text(
                  'AI PRO',
                  style: StillScoutTextStyles.badge.copyWith(
                    color: StillScoutColors.accent,
                    fontSize: 10,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              const SizedBox(height: StillScoutSpacing.m),
              Text(
                'Go further.',
                style: StillScoutTextStyles.display.copyWith(
                  fontSize: 38,
                  height: 1.05,
                  color: StillScoutColors.chalk,
                ),
              ),
              Text(
                'Unlock every feature.',
                style: StillScoutTextStyles.display.copyWith(
                  fontSize: 26,
                  color: StillScoutColors.accent,
                ),
              ),
              const SizedBox(height: StillScoutSpacing.l),
              // Feature list
              ..._kProFeatures.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: StillScoutColors.accent.withValues(alpha: 0.12),
                        ),
                        child: Icon(f.$2,
                            color: StillScoutColors.accent, size: 15),
                      ),
                      const SizedBox(width: StillScoutSpacing.m),
                      Text(
                        f.$1,
                        style: StillScoutTextStyles.body.copyWith(
                          color: StillScoutColors.chalk,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 120 + bottomInset),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom navigation ─────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.page,
    required this.totalPages,
    required this.onNext,
    required this.onSkip,
    this.onProTap,
  });

  final int page;
  final int totalPages;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  /// When set, the Pro upsell page shows a "Try AI Pro" button that calls
  /// this instead of [onNext].
  final VoidCallback? onProTap;

  bool get _isLast => page == totalPages - 1;
  bool get _isProPage => _isLast; // page 4 is the Pro upsell

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            StillScoutSpacing.xl,
            StillScoutSpacing.m,
            StillScoutSpacing.xl,
            StillScoutSpacing.m + bottomInset,
          ),
          decoration: BoxDecoration(
            color: StillScoutColors.voidBlack.withValues(alpha: 0.75),
            border: Border(
              top: BorderSide(
                color: StillScoutColors.slateLight.withValues(alpha: 0.35),
              ),
            ),
          ),
          child: _isProPage ? _proLayout() : _standardLayout(),
        ),
      ),
    );
  }

  Widget _standardLayout() {
    return Row(
      children: [
        // Page dots
        _PageDots(page: page, totalPages: totalPages),
        const Spacer(),
        // Skip (hidden on last page)
        if (!_isLast) ...[
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor:
                  StillScoutColors.silver.withValues(alpha: 0.7),
              padding: const EdgeInsets.symmetric(
                  horizontal: StillScoutSpacing.m),
              minimumSize: const Size(44, 44),
            ),
            child: const Text('Skip'),
          ),
          const SizedBox(width: StillScoutSpacing.s),
        ],
        StillScoutPrimaryButton(
          label: _isLast ? 'Start Scouting' : 'Next',
          icon: _isLast
              ? Icons.search_rounded
              : Icons.arrow_forward_rounded,
          height: 48,
          onPressed: onNext,
        ),
      ],
    );
  }

  Widget _proLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row: dots + "Start Free"
        Row(
          children: [
            _PageDots(page: page, totalPages: totalPages),
            const Spacer(),
            TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                foregroundColor:
                    StillScoutColors.silver.withValues(alpha: 0.65),
                padding: const EdgeInsets.symmetric(
                    horizontal: StillScoutSpacing.m),
                minimumSize: const Size(44, 44),
              ),
              child: const Text('Start free'),
            ),
          ],
        ),
        const SizedBox(height: StillScoutSpacing.s),
        // Full-width "Try AI Pro" CTA — opens paywall, then navigates
        SizedBox(
          width: double.infinity,
          child: StillScoutPrimaryButton(
            label: 'Try AI Pro',
            icon: Icons.stars_rounded,
            height: 54,
            onPressed: onProTap ?? onNext,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Cancel anytime',
          textAlign: TextAlign.center,
          style: StillScoutTextStyles.caption.copyWith(
            color: StillScoutColors.silver.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ── Page dots (extracted) ─────────────────────────────────────────────────────

class _PageDots extends StatelessWidget {
  const _PageDots({required this.page, required this.totalPages});

  final int page;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalPages, (i) {
        final isActive = i == page;
        return AnimatedContainer(
          duration: StillScoutMotion.base,
          curve: StillScoutMotion.toggle,
          margin: const EdgeInsets.only(right: 6),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? StillScoutColors.accent
                : StillScoutColors.slateLight,
            borderRadius:
                BorderRadius.circular(StillScoutRadius.pill),
          ),
        );
      }),
    );
  }
}

// ── Ambient background ────────────────────────────────────────────────────────

class _AmbientGlow extends StatefulWidget {
  const _AmbientGlow({required this.page});
  final int page;

  @override
  State<_AmbientGlow> createState() => _AmbientGlowState();
}

class _AmbientGlowState extends State<_AmbientGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat(reverse: true);

  static const _pageColors = [
    StillScoutColors.scoutGold,
    StillScoutColors.accent,
    StillScoutColors.success,
    StillScoutColors.scoutGold,
  ];

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _pageColors[widget.page.clamp(0, _pageColors.length - 1)];
    return AnimatedBuilder(
      animation: _drift,
      builder: (context, _) {
        final t = _drift.value;
        return IgnorePointer(
          child: CustomPaint(
            painter: _GlowPainter(color: color, t: t),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter({required this.color, required this.t});
  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * (0.3 + 0.4 * t);
    final cy = size.height * (0.15 + 0.1 * math.sin(t * math.pi));
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.14), Colors.transparent],
      ).createShader(Rect.fromCircle(
        center: Offset(cx, cy),
        radius: size.width * 0.65,
      ));
    canvas.drawCircle(Offset(cx, cy), size.width * 0.65, paint);
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.t != t || old.color != color;
}

// ── Illustrations ─────────────────────────────────────────────────────────────

/// Step 1: A stylised phone outline with a video frame sliding in.
class _PickIllustration extends StatefulWidget {
  const _PickIllustration();

  @override
  State<_PickIllustration> createState() => _PickIllustrationState();
}

class _PickIllustrationState extends State<_PickIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.4),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

  late final Animation<double> _fade =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 140,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: StillScoutColors.slateLight,
                width: 2.5,
              ),
            ),
          ),
          SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _fade,
              child: Container(
                width: 110,
                height: 75,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      StillScoutColors.scoutGold.withValues(alpha: 0.22),
                      StillScoutColors.accent.withValues(alpha: 0.08),
                    ],
                  ),
                  border: Border.all(
                    color: StillScoutColors.scoutGold.withValues(alpha: 0.5),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.movie_creation_outlined,
                    color: StillScoutColors.scoutGold,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            child: FadeTransition(
              opacity: _fade,
              child: Icon(
                Icons.upload_rounded,
                color: StillScoutColors.silver.withValues(alpha: 0.5),
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Step 2: An animated score ring counting up on a demo frame card.
class _ScoutIllustration extends StatefulWidget {
  const _ScoutIllustration();

  @override
  State<_ScoutIllustration> createState() => _ScoutIllustrationState();
}

class _ScoutIllustrationState extends State<_ScoutIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  late final Animation<double> _ring = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0.2, 1.0, curve: StillScoutMotion.entrance),
  );

  late final Animation<double> _fade =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    StillScoutColors.accent.withValues(alpha: 0.12),
                    StillScoutColors.filmGray.withValues(alpha: 0.5),
                  ],
                ),
                border: Border.all(
                  color: StillScoutColors.accent.withValues(alpha: 0.25),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _ring,
              builder: (context, _) {
                final score = (_ring.value * 8.7).clamp(0.0, 10.0);
                return SizedBox(
                  width: 90,
                  height: 90,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: _ring.value * 0.87,
                        strokeWidth: 6,
                        backgroundColor:
                            StillScoutColors.accent.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation(
                          StillScoutColors.accent,
                        ),
                      ),
                      Text(
                        score >= 10 ? '10' : score.toStringAsFixed(1),
                        style: StillScoutTextStyles.numeric.copyWith(
                          fontSize: 22,
                          color: StillScoutColors.accent,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Icon(
                Icons.auto_fix_high_rounded,
                color: StillScoutColors.accent.withValues(alpha: 0.6),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Step 3: An animated checkmark on a frame card representing export.
class _SaveIllustration extends StatefulWidget {
  const _SaveIllustration();

  @override
  State<_SaveIllustration> createState() => _SaveIllustrationState();
}

class _SaveIllustrationState extends State<_SaveIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();

  late final Animation<double> _scale = Tween<double>(begin: 0.5, end: 1.0)
      .animate(CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack)));

  late final Animation<double> _fade =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    StillScoutColors.success.withValues(alpha: 0.12),
                    StillScoutColors.filmGray.withValues(alpha: 0.5),
                  ],
                ),
                border: Border.all(
                  color: StillScoutColors.success.withValues(alpha: 0.45),
                  width: 1.5,
                ),
              ),
            ),
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: StillScoutColors.success.withValues(alpha: 0.15),
                  border: Border.all(
                    color: StillScoutColors.success.withValues(alpha: 0.7),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: StillScoutColors.success,
                  size: 36,
                ),
              ),
            ),
            Positioned(
              bottom: 14,
              child: ScaleTransition(
                scale: _scale,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: StillScoutSpacing.s, vertical: 3),
                  decoration: BoxDecoration(
                    color: StillScoutColors.success.withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(StillScoutRadius.pill),
                    border: Border.all(
                      color: StillScoutColors.success.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        size: 11,
                        color: StillScoutColors.success.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'OFFLINE OK',
                        style: StillScoutTextStyles.badge.copyWith(
                          color: StillScoutColors.success,
                          fontSize: 10,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Step 4: Animated Pro badge with orbiting feature icons.
class _ProIllustration extends StatefulWidget {
  const _ProIllustration();

  @override
  State<_ProIllustration> createState() => _ProIllustrationState();
}

class _ProIllustrationState extends State<_ProIllustration>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  late final AnimationController _fadeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  late final Animation<double> _fade =
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

  @override
  void dispose() {
    _ctrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  static const _orbitIcons = [
    Icons.psychology_rounded,
    Icons.auto_fix_high_rounded,
    Icons.hd_rounded,
    Icons.face_retouching_natural_rounded,
    Icons.all_inclusive_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SizedBox(
      width: 240,
      height: 240,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Orbit ring
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: StillScoutColors.accent.withValues(alpha: 0.12),
                    width: 1.5,
                  ),
                ),
              ),
              // Orbiting icons
              for (int i = 0; i < _orbitIcons.length; i++)
                _orbitingIcon(i),
              // Central gold badge
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      StillScoutColors.accent.withValues(alpha: 0.28),
                      StillScoutColors.accent.withValues(alpha: 0.05),
                    ],
                  ),
                  border: Border.all(
                    color: StillScoutColors.accent.withValues(alpha: 0.6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: StillScoutColors.accent.withValues(alpha: 0.22),
                      blurRadius: 28,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      color: StillScoutColors.accent,
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PRO',
                      style: StillScoutTextStyles.badge.copyWith(
                        color: StillScoutColors.accent,
                        fontSize: 13,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }

  Widget _orbitingIcon(int i) {
    const orbitRadius = 100.0;
    final offset = i / _orbitIcons.length;
    final angle = (_ctrl.value + offset) * 2 * math.pi;
    final x = math.cos(angle) * orbitRadius;
    final y = math.sin(angle) * orbitRadius;

    return Transform.translate(
      offset: Offset(x, y),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: StillScoutColors.filmGray,
          border: Border.all(
            color: StillScoutColors.accent.withValues(alpha: 0.35),
          ),
        ),
        child: Icon(
          _orbitIcons[i],
          color: StillScoutColors.accent.withValues(alpha: 0.8),
          size: 16,
        ),
      ),
    );
  }
}
