import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/models/extracted_frame.dart';
import '../providers/stillscout_notifier.dart';
import '../theme/stillscout_theme.dart';
import 'stillscout_live_strip.dart';

class StillScoutProcessingState extends StatelessWidget {
  const StillScoutProcessingState({
    super.key,
    required this.phase,
    required this.progress,
    required this.message,
    required this.onCancel,
    this.liveFrames = const [],
  });

  final StillScoutPhase phase;
  final double progress;
  final String message;
  final VoidCallback onCancel;
  final List<ExtractedFrame> liveFrames;

  @override
  Widget build(BuildContext context) {
    final percent = (progress.clamp(0, 1) * 100).round();
    final isExtracting = phase == StillScoutPhase.extracting;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(32, 16, 32, 16 + bottomSafe),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StillScoutLiveStrip(frames: liveFrames),
          if (liveFrames.isNotEmpty) const SizedBox(height: StillScoutSpacing.m),
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: progress.clamp(0, 1),
                    strokeWidth: 3,
                    backgroundColor: StillScoutColors.slate,
                    color: StillScoutColors.accent,
                  ),
                ),
                Text(
                  '$percent%',
                  style: StillScoutTextStyles.title.copyWith(
                    fontSize: 28,
                    color: StillScoutColors.accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isExtracting
                ? 'Slicing your clip into candidate frames…'
                : 'AI scoring best candidates first…',
            style: StillScoutTextStyles.title,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          _PhaseSteps(isExtracting: isExtracting),
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
          const _BackgroundScoutTip(),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded, size: 18, color: StillScoutColors.silver),
            label: Text(
              'Cancel',
              style: StillScoutTextStyles.caption.copyWith(color: StillScoutColors.silver),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundScoutTip extends StatelessWidget {
  const _BackgroundScoutTip();

  @override
  Widget build(BuildContext context) {
    final isAndroid = Platform.isAndroid;
    final title = isAndroid
        ? 'Switch apps while we work'
        : 'Keep StillScout nearby';
    final body = isAndroid
        ? 'Scouting continues in the background. Tap the notification to return — cloud AI still needs internet.'
        : 'Cloud AI scouting works best while StillScout stays open. Brief app switches are OK, but don\'t force-quit.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(StillScoutSpacing.m),
      decoration: StillScoutDecorations.glassCard(
        borderColor: StillScoutColors.accent.withValues(alpha: 0.35),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isAndroid ? Icons.notifications_active_outlined : Icons.stay_current_portrait_rounded,
            size: 22,
            color: StillScoutColors.accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: StillScoutTextStyles.subtitle.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
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
    );
  }
}

class _PhaseSteps extends StatelessWidget {
  const _PhaseSteps({required this.isExtracting});

  final bool isExtracting;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepChip(
          label: 'Extracting',
          icon: Icons.movie_filter_outlined,
          state: isExtracting ? _StepState.active : _StepState.done,
        ),
        Container(
          width: 20,
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          color: StillScoutColors.silver.withValues(alpha: 0.3),
        ),
        _StepChip(
          label: 'AI Scoring',
          icon: Icons.auto_awesome,
          state: isExtracting ? _StepState.pending : _StepState.active,
        ),
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
            fontWeight: state == _StepState.active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
