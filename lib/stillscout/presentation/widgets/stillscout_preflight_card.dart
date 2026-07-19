import 'package:flutter/material.dart';

import '../../domain/stillscout_access_policy.dart';
import '../../domain/stillscout_constants.dart';
import '../../domain/stillscout_online_status.dart';
import '../../services/stillscout_scout_quota_tracker.dart';
import '../providers/stillscout_notifier.dart';
import '../theme/stillscout_theme.dart';
import 'stillscout_context_picker.dart';
import 'stillscout_buttons.dart';
import 'stillscout_online_banner.dart';
import 'stillscout_trim_scrubber.dart';

/// Pre-flight review card shown after a video is picked but before the scout
/// starts — estimate, trim, video-context picker, and the Start Scout CTA.
///
/// Extracted from `StillScoutScreen` (W3.2) — behavior unchanged.
class StillScoutPreFlightCard extends StatefulWidget {
  const StillScoutPreFlightCard({
    super.key,
    required this.state,
    required this.onlineStatus,
    this.scoutsRemainingToday,
    required this.onStartScout,
    required this.onTrimChanged,
    required this.onContextChanged,
    required this.onPickDifferent,
  });

  final StillScoutState state;
  final OnlineStatus onlineStatus;
  final int? scoutsRemainingToday;
  final VoidCallback onStartScout;
  final void Function(int start, int end) onTrimChanged;
  final ValueChanged<StillScoutVideoContext> onContextChanged;
  final VoidCallback onPickDifferent;

  @override
  State<StillScoutPreFlightCard> createState() =>
      _StillScoutPreFlightCardState();
}

class _StillScoutPreFlightCardState extends State<StillScoutPreFlightCard> {
  late bool _showTrim;

  @override
  void initState() {
    super.initState();
    final durationMs = widget.state.videoDurationMs ?? 0;
    _showTrim = durationMs > StillScoutConstants.maxVideoDurationMs ||
        widget.state.trimStartMs != null ||
        widget.state.trimEndMs != null;
  }

  @override
  Widget build(BuildContext context) {
    final durationMs = widget.state.videoDurationMs ?? 0;
    final scoutsLeft = widget.scoutsRemainingToday;
    final quotaLoading = !widget.state.isPro && scoutsLeft == null;
    final quotaOk =
        widget.state.isPro || (scoutsLeft != null && scoutsLeft > 0);
    final online = widget.onlineStatus == OnlineStatus.online;
    final trialAvailable =
        !widget.state.isPro && StillScoutAiProTrialTracker.isTrialAvailable;
    final needsCloud = StillScoutAccessPolicy.scoutRequiresNetwork(
      isPro: widget.state.isPro,
      isAiProTrialAvailable: trialAvailable,
    );
    final quotaExhausted = (!needsCloud || online) &&
        !widget.state.isPro &&
        scoutsLeft != null &&
        scoutsLeft <= 0;
    final canPressCta = !quotaLoading &&
        (!needsCloud || online) &&
        (quotaOk || quotaExhausted);
    final scoutLabel = StillScoutAccessPolicy.scoutsAllowanceLabel(
      isPro: widget.state.isPro,
      scoutsRemainingToday: scoutsLeft ?? 0,
      isLoading: quotaLoading,
      isAiProTrialAvailable: trialAvailable,
    );
    final ctaLabel = switch (widget.onlineStatus) {
      OnlineStatus.checking when needsCloud => 'Checking connection…',
      OnlineStatus.offline when needsCloud => trialAvailable
          ? 'Connect for free AI Trial'
          : 'Connect for AI Pro',
      _ => quotaLoading
          ? 'Loading allowance…'
          : (quotaOk
              ? (trialAvailable ? 'Start free AI Trial' : 'Start Scout')
              : 'Upgrade for more scouts'),
    };

    // When trim is open, collapse supporting copy so the stack stays short.
    final stacked = _showTrim && durationMs > 5000;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: StillScoutSpacing.m),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: stacked ? StillScoutSpacing.m : StillScoutSpacing.l,
            ),
            Icon(
              Icons.check_circle_rounded,
              color: StillScoutColors.success,
              size: stacked ? 28 : 36,
            ),
            const SizedBox(height: StillScoutSpacing.s),
            Text('Video ready', style: StillScoutTextStyles.title),
            if (!stacked) ...[
              const SizedBox(height: StillScoutSpacing.xs),
              Text(
                'Trim if needed, pick a scene type, then start.',
                style: StillScoutTextStyles.body,
                textAlign: TextAlign.center,
              ),
            ],
            if (needsCloud) ...[
              const SizedBox(height: StillScoutSpacing.s),
              StillScoutOnlineRequirementChip(status: widget.onlineStatus),
            ],
            if (!widget.state.isPro) ...[
              const SizedBox(height: StillScoutSpacing.s),
              Text(
                trialAvailable
                    ? 'Free Gemini trial · $scoutLabel'
                    : scoutLabel,
                style: StillScoutTextStyles.caption.copyWith(
                  color: quotaLoading
                      ? StillScoutColors.silver
                      : trialAvailable
                          ? StillScoutColors.scoutGold
                          : quotaOk
                              ? StillScoutColors.accent
                              : StillScoutColors.danger,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(
              height: stacked ? StillScoutSpacing.m : StillScoutSpacing.l,
            ),
            StillScoutPreFlightEstimate(
              estimatedFrames: widget.state.estimatedFrameCount,
              durationMs: () {
                final start = widget.state.trimStartMs ?? 0;
                final end = widget.state.trimEndMs ?? durationMs;
                return (end - start).clamp(0, durationMs);
              }(),
            ),
            if (durationMs > StillScoutConstants.maxVideoDurationMs) ...[
              const SizedBox(height: StillScoutSpacing.s),
              Text(
                'Longer than 10 min — open Trim to pick a range.',
                style: StillScoutTextStyles.caption.copyWith(
                  color: StillScoutColors.accent,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: StillScoutSpacing.m),
            StillScoutContextPicker(
              selected: widget.state.videoContext,
              onChanged: widget.onContextChanged,
            ),
            if (durationMs > 5000) ...[
              const SizedBox(height: StillScoutSpacing.s),
              _TrimToggle(
                expanded: _showTrim,
                onToggle: () => setState(() => _showTrim = !_showTrim),
              ),
            ],
            if (_showTrim && durationMs > 5000) ...[
              const SizedBox(height: StillScoutSpacing.s),
              StillScoutTrimScrubber(
                durationMs: durationMs,
                initialStartMs: widget.state.trimStartMs,
                initialEndMs: widget.state.trimEndMs,
                onTrimChanged: widget.onTrimChanged,
              ),
            ],
            SizedBox(
              height: stacked ? StillScoutSpacing.m : StillScoutSpacing.l,
            ),
            SizedBox(
              width: double.infinity,
              child: Semantics(
                label: 'Start scouting frames',
                button: true,
                child: StillScoutPrimaryButton(
                  label: ctaLabel,
                  expand: true,
                  icon: !online
                      ? Icons.wifi_off_rounded
                      : (quotaExhausted
                          ? Icons.bolt_rounded
                          : Icons.search_rounded),
                  onPressed: canPressCta ? widget.onStartScout : null,
                  backgroundColor: canPressCta ? null : StillScoutColors.slate,
                ),
              ),
            ),
            const SizedBox(height: StillScoutSpacing.s),
            SizedBox(
              width: double.infinity,
              child: StillScoutSecondaryButton(
                label: 'Pick a different video',
                height: 44,
                onPressed: widget.onPickDifferent,
              ),
            ),
            SizedBox(
              height: stacked ? StillScoutSpacing.l : StillScoutSpacing.xl,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrimToggle extends StatelessWidget {
  const _TrimToggle({required this.expanded, required this.onToggle});

  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: expanded ? 'Hide trim' : 'Trim clip before scouting',
      child: GestureDetector(
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: StillScoutSpacing.m,
            vertical: StillScoutSpacing.s,
          ),
          decoration: BoxDecoration(
            color: StillScoutColors.filmGray,
            borderRadius: BorderRadius.circular(StillScoutRadius.s),
            border: Border.all(
              color: expanded
                  ? StillScoutColors.accent.withValues(alpha: 0.5)
                  : StillScoutColors.silver.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.content_cut_rounded,
                size: 16,
                color: expanded
                    ? StillScoutColors.accent
                    : StillScoutColors.silver,
              ),
              const SizedBox(width: StillScoutSpacing.s),
              Text(
                expanded ? 'Hide trim' : 'Trim clip',
                style: StillScoutTextStyles.caption.copyWith(
                  color: expanded
                      ? StillScoutColors.accent
                      : StillScoutColors.chalk,
                ),
              ),
              const Spacer(),
              Icon(
                expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 18,
                color: StillScoutColors.silver,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
