import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/extracted_frame.dart';
import '../providers/stillscout_notifier.dart';
import '../theme/stillscout_theme.dart';
import 'stillscout_glass_surface.dart';
import 'stillscout_live_strip.dart';

/// Presentational split of the 0.60–1.0 "scoring" progress range into two
/// readable sub-stages, so the flow reads as Extract → Analyze →
/// Score & critique rather than a flat "AI Scoring" step. Purely cosmetic —
/// no backend change backs this, it's just a fixed point along the existing
/// `progress` value already emitted by the scoring pipeline.
const double _kAnalyzingToScoringProgress = 0.80;

enum _ScoutStage { extracting, analyzing, scoringAndCritiquing }

class StillScoutProcessingState extends StatelessWidget {
  const StillScoutProcessingState({
    super.key,
    required this.phase,
    required this.progress,
    required this.message,
    required this.onCancel,
    this.liveFrames = const [],
    this.framesExtracted = 0,
    this.totalFrames = 0,
    this.isAiProTrial = false,
    this.isPro = false,
  });

  final StillScoutPhase phase;
  final double progress;
  final String message;
  final VoidCallback onCancel;
  final List<ExtractedFrame> liveFrames;

  /// Frames extracted so far — powers the "N of M frames scouted" caption.
  final int framesExtracted;

  /// Total frames expected for this extraction pass, once known.
  final int totalFrames;

  /// When true, the user is using their one-time complimentary AI Pro trial.
  final bool isAiProTrial;

  /// Whether the user has AI Pro — determines which tips to show.
  final bool isPro;

  _ScoutStage get _stage {
    if (phase == StillScoutPhase.extracting) return _ScoutStage.extracting;
    return progress < _kAnalyzingToScoringProgress
        ? _ScoutStage.analyzing
        : _ScoutStage.scoringAndCritiquing;
  }

  String _titleFor(_ScoutStage stage) => switch (stage) {
        _ScoutStage.extracting => 'Slicing your clip into candidate frames…',
        _ScoutStage.analyzing =>
          'Analyzing each frame for sharpness & framing…',
        _ScoutStage.scoringAndCritiquing =>
          'Scoring & critiquing your best candidates…',
      };

  @override
  Widget build(BuildContext context) {
    final percent = (progress.clamp(0, 1) * 100).round();
    final isExtracting = phase == StillScoutPhase.extracting;
    final stage = _stage;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return Stack(
      children: [
        const Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(painter: _ScoutingGrainPainter()),
            ),
          ),
        ),
      SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(32, 16, 32, 16 + bottomSafe),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isAiProTrial) ...[
              Container(
                margin: const EdgeInsets.only(bottom: StillScoutSpacing.m),
                padding: const EdgeInsets.symmetric(
                  horizontal: StillScoutSpacing.m,
                  vertical: StillScoutSpacing.s,
                ),
                decoration: BoxDecoration(
                  color: StillScoutColors.scoutGold.withValues(alpha: 0.12),
                  borderRadius: StillScoutRadius.badge,
                  border: Border.all(
                    color: StillScoutColors.scoutGold.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      color: StillScoutColors.scoutGold,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'One-time AI Trial — Gemini Flash running',
                      style: StillScoutTextStyles.caption.copyWith(
                        color: StillScoutColors.scoutGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            StillScoutLiveStrip(frames: liveFrames),
              if (liveFrames.isNotEmpty)
                const SizedBox(height: StillScoutSpacing.m),
              _ScoutProgressRing(
                progress: progress.clamp(0.0, 1.0),
                percentLabel: '$percent%',
              ),
              const SizedBox(height: 24),
              Text(
                _titleFor(stage),
                style: StillScoutTextStyles.title,
                textAlign: TextAlign.center,
              ),
              if (isExtracting && totalFrames > 0) ...[
                const SizedBox(height: 6),
                Text(
                  '$framesExtracted of $totalFrames frames scouted',
                  style: StillScoutTextStyles.caption.copyWith(
                    color: StillScoutColors.silver.withValues(alpha: 0.8),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _PhaseSteps(stage: stage),
              const SizedBox(height: 14),
              Text(
                message,
                style: StillScoutTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0, 1),
                  minHeight: 4,
                  backgroundColor: StillScoutColors.slate,
                  color: StillScoutColors.scoutGold,
                ),
              ),
              const SizedBox(height: 20),
              _BackgroundScoutTipCarousel(isCloudScout: isPro || isAiProTrial),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.close_rounded,
                    size: 18, color: StillScoutColors.silver),
                label: Text(
                  'Cancel',
                  style: StillScoutTextStyles.caption
                      .copyWith(color: StillScoutColors.silver),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Gradient sweep ring (accent → scoutGold) tracking [progress], with a
/// slow pulsing outer glow so the screen keeps "breathing" between ticks.
class _ScoutProgressRing extends StatefulWidget {
  const _ScoutProgressRing(
      {required this.progress, required this.percentLabel});

  final double progress;
  final String percentLabel;

  @override
  State<_ScoutProgressRing> createState() => _ScoutProgressRingState();
}

class _ScoutProgressRingState extends State<_ScoutProgressRing>
    with SingleTickerProviderStateMixin {
  static const _pulseDuration = Duration(milliseconds: 1800);

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: _pulseDuration,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glow = StillScoutMotion.toggle.transform(_pulseController.value);
        return Container(
          width: 132,
          height: 132,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: StillScoutColors.accentGlow
                    .withValues(alpha: 0.16 + glow * 0.22),
                blurRadius: 22 + glow * 20,
                spreadRadius: 1 + glow * 3,
              ),
            ],
          ),
          child: child,
        );
      },
      child: SizedBox(
        width: 120,
        height: 120,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(120, 120),
              painter: _ScoutRingPainter(progress: widget.progress),
            ),
            Text(
              widget.percentLabel,
              style: StillScoutTextStyles.title.copyWith(
                fontSize: 28,
                color: StillScoutColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoutRingPainter extends CustomPainter {
  const _ScoutRingPainter({required this.progress});

  final double progress;

  static const double _strokeWidth = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - _strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = StillScoutColors.slate
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    canvas.drawCircle(center, radius, track);

    final sweep = progress.clamp(0.0, 1.0) * 2 * math.pi;
    if (sweep <= 0) return;

    final gradient = SweepGradient(
      startAngle: 0,
      endAngle: sweep,
      transform: const GradientRotation(-math.pi / 2),
      colors: const [StillScoutColors.accent, StillScoutColors.scoutGold],
    );
    final arcPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, sweep, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _ScoutRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ScoutTip {
  const _ScoutTip(
      {required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;
}

/// Rotates through a handful of scouting/AI tips with a cross-fade, instead
/// of showing one static tip for the whole processing screen.
class _BackgroundScoutTipCarousel extends StatefulWidget {
  const _BackgroundScoutTipCarousel({this.isCloudScout = false});

  /// Whether the current scout uses cloud AI. When false the cloud-specific
  /// tip ("Keep StillScout nearby") is omitted.
  final bool isCloudScout;

  @override
  State<_BackgroundScoutTipCarousel> createState() =>
      _BackgroundScoutTipCarouselState();
}

class _BackgroundScoutTipCarouselState
    extends State<_BackgroundScoutTipCarousel> {
  static const _rotateInterval = Duration(seconds: 3);

  late final List<_ScoutTip> _tips = _buildTips();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_rotateInterval, (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _tips.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<_ScoutTip> _buildTips() {
    return [
      if (widget.isCloudScout)
        const _ScoutTip(
          icon: Icons.stay_current_portrait_rounded,
          title: 'Keep StillScout nearby',
          body:
              'Cloud AI scouting works best while StillScout stays open. Brief app switches are OK, but don\'t force-quit.',
        ),
      const _ScoutTip(
        icon: Icons.center_focus_strong_outlined,
        title: 'Steadier footage scores higher',
        body:
            'A few seconds of tripod-still or gimbal footage gives the AI scout sharper candidates to choose from.',
      ),
      const _ScoutTip(
        icon: Icons.auto_awesome_outlined,
        title: 'It judges more than brightness',
        body:
            'Composition, expression, and sharpness all factor into every frame\'s score — not just exposure.',
      ),
      const _ScoutTip(
        icon: Icons.grid_view_rounded,
        title: 'Every frame gets a look',
        body:
            'We sample the whole clip, not just keyframes — great stills often hide mid-motion.',
      ),
      const _ScoutTip(
        icon: Icons.emoji_events_outlined,
        title: 'Top picks balance variety',
        body:
            'Your best shots are chosen for a mix of angles and moments, not just the single highest score.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tip = _tips[_index];
    return StillScoutGlassSurface(
      width: double.infinity,
      padding: const EdgeInsets.all(StillScoutSpacing.m),
      borderColor: StillScoutColors.accent.withValues(alpha: 0.35),
      child: AnimatedSwitcher(
        duration: StillScoutMotion.base,
        switchInCurve: StillScoutMotion.entrance,
        switchOutCurve: StillScoutMotion.entrance,
        child: Row(
          key: ValueKey(_index),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(tip.icon, size: 22, color: StillScoutColors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tip.title,
                    style: StillScoutTextStyles.subtitle.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tip.body,
                    style: StillScoutTextStyles.caption.copyWith(
                      color: StillScoutColors.silver.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhaseSteps extends StatelessWidget {
  const _PhaseSteps({required this.stage});

  final _ScoutStage stage;

  _StepState _stateFor(_ScoutStage chipStage) {
    const order = _ScoutStage.values;
    final current = order.indexOf(stage);
    final target = order.indexOf(chipStage);
    if (target < current) return _StepState.done;
    if (target == current) return _StepState.active;
    return _StepState.pending;
  }

  @override
  Widget build(BuildContext context) {
    final chips = [
      _StepChip(
        label: 'Extracting',
        icon: Icons.movie_filter_outlined,
        state: _stateFor(_ScoutStage.extracting),
      ),
      _StepChip(
        label: 'Analyzing',
        icon: Icons.visibility_outlined,
        state: _stateFor(_ScoutStage.analyzing),
      ),
      _StepChip(
        label: 'Scoring & critiquing',
        icon: Icons.auto_awesome,
        state: _stateFor(_ScoutStage.scoringAndCritiquing),
      ),
    ];
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 8,
      children: [
        for (var i = 0; i < chips.length; i++) ...[
          if (i > 0)
            Container(
              width: 16,
              height: 1,
              color: StillScoutColors.silver.withValues(alpha: 0.3),
            ),
          chips[i],
        ],
      ],
    );
  }
}

enum _StepState { pending, active, done }

class _StepChip extends StatelessWidget {
  const _StepChip({
    required this.label,
    required this.state,
    required this.icon,
  });

  final String label;
  final _StepState state;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _StepState.pending => StillScoutColors.silver.withValues(alpha: 0.5),
      _StepState.active => StillScoutColors.accent,
      _StepState.done => StillScoutColors.scoutGold,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          state == _StepState.done ? Icons.check_circle : icon,
          size: state == _StepState.done ? 14 : 16,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: StillScoutTextStyles.caption.copyWith(
            color: color,
            fontWeight:
                state == _StepState.active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Same faint dot-grain texture as [StillScoutSplashScreen]'s
/// `_SplashGrainPainter`, duplicated here for visual continuity. That
/// painter is a private class in `stillscout_splash_screen.dart` (a file
/// outside this task's scope, owned by a parallel redesign phase), so it
/// can't be imported directly without exporting it — reproducing the same
/// tiny, static painter here is simpler and avoids merge conflicts there.
class _ScoutingGrainPainter extends CustomPainter {
  const _ScoutingGrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.018);
    const step = 18.0;
    for (var y = 0.0; y < size.height; y += step) {
      for (var x = 0.0; x < size.width; x += step) {
        if (((x + y) / step).round().isOdd) {
          canvas.drawCircle(Offset(x, y), 0.6, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
