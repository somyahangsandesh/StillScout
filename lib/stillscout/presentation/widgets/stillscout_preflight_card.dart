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
    final trialAvailable = !widget.state.isPro &&
        StillScoutAiProTrialTracker.isTrialAvailable;
    final needsCloud = StillScoutAccessPolicy.scoutRequiresNetwork(
      isPro: widget.state.isPro,
      isAiProTrialAvailable: trialAvailable,
    );
    final quotaExhausted = (!needsCloud || online) &&
        !widget.state.isPro &&
        scoutsLeft != null &&
        scoutsLeft <= 0;
    // Free on-device scouts work offline; Pro + AI trial need connectivity.
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

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: StillScoutSpacing.m),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: StillScoutSpacing.xl),
            const Icon(
              Icons.check_circle_rounded,
              color: StillScoutColors.success,
              size: 40,
            ),
            const SizedBox(height: StillScoutSpacing.m),
            Text('Video ready', style: StillScoutTextStyles.title),
            const SizedBox(height: StillScoutSpacing.xs),
            Text(
              'Review the estimate and trim the clip if you like, then start scouting.',
              style: StillScoutTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: StillScoutSpacing.m),
            // Online chip for Pro and free AI Trial — Vision-only scouts work offline.
            if (needsCloud)
              StillScoutOnlineRequirementChip(status: widget.onlineStatus),
            if (trialAvailable) ...[
              const SizedBox(height: StillScoutSpacing.s),
              Text(
                'One-time free Gemini AI trial · internet required',
                style: StillScoutTextStyles.caption.copyWith(
                  color: StillScoutColors.scoutGold,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (!widget.state.isPro) ...[
              const SizedBox(height: StillScoutSpacing.s),
              Text(
                scoutLabel,
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
              ),
              const SizedBox(height: 4),
              Text(
                trialAvailable
                    ? 'Later free scouts work offline with on-device Vision.'
                    : 'Exports are clean — upgrade for unlimited scouts and 4K.',
                style: StillScoutTextStyles.caption.copyWith(
                  color: StillScoutColors.silver.withValues(alpha: 0.75),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: StillScoutSpacing.l),

            // Pre-flight estimate
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
                'Clips longer than 10 minutes are trimmed to the first 10 minutes. Open Trim to pick a different range.',
                style: StillScoutTextStyles.caption.copyWith(
                  color: StillScoutColors.accent,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: StillScoutSpacing.m),

            Text(
              "What's this video?",
              style: StillScoutTextStyles.caption.copyWith(
                color: StillScoutColors.silver,
              ),
            ),
            const SizedBox(height: StillScoutSpacing.s),
            StillScoutContextPicker(
              selected: widget.state.videoContext,
              onChanged: widget.onContextChanged,
            ),

            const SizedBox(height: StillScoutSpacing.m),

            // Trim toggle
            if (durationMs > 5000) // only show trim for clips > 5s
              _TrimToggle(
                expanded: _showTrim,
                onToggle: () => setState(() => _showTrim = !_showTrim),
              ),

            if (_showTrim && durationMs > 5000) ...[
              const SizedBox(height: StillScoutSpacing.m),
              StillScoutTrimScrubber(
                durationMs: durationMs,
                initialStartMs: widget.state.trimStartMs,
                initialEndMs: widget.state.trimEndMs,
                onTrimChanged: widget.onTrimChanged,
              ),
            ],

            const SizedBox(height: StillScoutSpacing.xl),

            // CTA
            SizedBox(
              width: double.infinity,
              child: Semantics(
                label: 'Start scouting frames',
                button: true,
                child: StillScoutPrimaryButton(
                  label: ctaLabel,
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

            const SizedBox(height: StillScoutSpacing.m),

            SizedBox(
              width: double.infinity,
              child: StillScoutSecondaryButton(
                label: 'Pick a different video',
                height: 48,
                onPressed: widget.onPickDifferent,
              ),
            ),

            const SizedBox(height: StillScoutSpacing.xxl),
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
    return GestureDetector(
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
              color:
                  expanded ? StillScoutColors.accent : StillScoutColors.silver,
            ),
            const SizedBox(width: StillScoutSpacing.s),
            Text(
              expanded ? 'Hide trim' : 'Trim clip before scouting',
              style: StillScoutTextStyles.caption.copyWith(
                color:
                    expanded ? StillScoutColors.accent : StillScoutColors.chalk,
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
    );
  }
}
