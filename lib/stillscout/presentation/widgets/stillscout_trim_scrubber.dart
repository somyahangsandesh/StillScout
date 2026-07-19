import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/stillscout_constants.dart';
import '../theme/stillscout_theme.dart';

/// Lightweight in/out trim range slider for StillScout.
///
/// Shows a two-thumb RangeSlider over a visual timeline, letting the creator
/// narrow a 10-minute clip to "just this 45 seconds" before extraction begins.
/// No FFmpeg or new native dependency — it purely adjusts the start/end
/// timestamps passed to [VideoFrameExtractor].
class StillScoutTrimScrubber extends StatefulWidget {
  const StillScoutTrimScrubber({
    super.key,
    required this.durationMs,
    required this.onTrimChanged,
    this.initialStartMs,
    this.initialEndMs,
    this.maxWindowMs = StillScoutConstants.maxVideoDurationMs,
  });

  final int durationMs;
  final void Function(int startMs, int endMs) onTrimChanged;
  final int? initialStartMs;
  final int? initialEndMs;

  /// Maximum selectable window (product limit: 10 minutes).
  final int maxWindowMs;

  @override
  State<StillScoutTrimScrubber> createState() => _StillScoutTrimScrubberState();
}

class _StillScoutTrimScrubberState extends State<StillScoutTrimScrubber> {
  late RangeValues _values;

  int get _maxWindow =>
      widget.maxWindowMs.clamp(1, widget.durationMs);

  RangeValues _clampWindow(RangeValues values) {
    var start = values.start.clamp(0.0, widget.durationMs.toDouble());
    var end = values.end.clamp(0.0, widget.durationMs.toDouble());
    if (end < start) end = start;
    final maxWindow = _maxWindow.toDouble();
    if (end - start > maxWindow) {
      // Keep the thumb the user most recently moved by preserving the
      // end when the window grows from the left, and start when from the right.
      if ((end - _values.end).abs() >= (start - _values.start).abs()) {
        start = end - maxWindow;
      } else {
        end = start + maxWindow;
      }
    }
    return RangeValues(start.toDouble(), end.toDouble());
  }

  @override
  void initState() {
    super.initState();
    _values = _clampWindow(
      RangeValues(
        (widget.initialStartMs ?? 0).toDouble(),
        (widget.initialEndMs ?? widget.durationMs).toDouble(),
      ),
    );
  }

  String _formatMs(double ms) {
    final total = ms.round();
    final minutes = total ~/ 60000;
    final seconds = (total % 60000) ~/ 1000;
    final tenths = (total % 1000) ~/ 100;
    if (minutes == 0) return '$seconds.${tenths}s';
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: StillScoutSpacing.m),
          child: Row(
            children: [
              const Icon(
                Icons.content_cut_rounded,
                size: 14,
                color: StillScoutColors.accent,
              ),
              const SizedBox(width: StillScoutSpacing.xs),
              Text(
                'Trim range',
                style: StillScoutTextStyles.label.copyWith(
                  color: StillScoutColors.accent,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Text(
                '${_formatMs(_values.start)} → ${_formatMs(_values.end)}',
                style: StillScoutTextStyles.caption.copyWith(
                  color: StillScoutColors.chalk,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (widget.durationMs > _maxWindow)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              StillScoutSpacing.m,
              0,
              StillScoutSpacing.m,
              4,
            ),
            child: Text(
              'Max scout window is 10 minutes',
              style: StillScoutTextStyles.caption.copyWith(
                color: StillScoutColors.silver,
                fontSize: 11,
              ),
            ),
          ),
        SliderTheme(
          data: const SliderThemeData(
            activeTrackColor: StillScoutColors.accent,
            inactiveTrackColor: StillScoutColors.slate,
            thumbColor: StillScoutColors.accent,
            overlayColor: StillScoutColors.accentGlow,
            rangeThumbShape: RoundRangeSliderThumbShape(
              enabledThumbRadius: StillScoutSpacing.s + 2,
            ),
            trackHeight: StillScoutSpacing.xs,
          ),
          child: RangeSlider(
            values: _values,
            min: 0,
            max: widget.durationMs.toDouble(),
            onChanged: (values) {
              HapticFeedback.selectionClick();
              final clamped = _clampWindow(values);
              setState(() => _values = clamped);
              widget.onTrimChanged(
                clamped.start.round(),
                clamped.end.round(),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: StillScoutSpacing.m),
          child: Row(
            children: [
              Text(
                _formatMs(0),
                style: StillScoutTextStyles.caption,
              ),
              const Spacer(),
              Text(
                _formatMs(widget.durationMs.toDouble()),
                style: StillScoutTextStyles.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Pre-flight estimate chip — shows estimated frame count and extraction time.
class StillScoutPreFlightEstimate extends StatelessWidget {
  const StillScoutPreFlightEstimate({
    super.key,
    required this.estimatedFrames,
    required this.durationMs,
  });

  final int estimatedFrames;
  final int durationMs;

  @override
  Widget build(BuildContext context) {
    final durationSec = (durationMs / 1000).round();
    final estimatedSec = (estimatedFrames * 0.3).round();

    return Semantics(
      label: 'Estimated $estimatedFrames frames, about $estimatedSec seconds to process',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: StillScoutSpacing.m,
          vertical: StillScoutSpacing.s,
        ),
        decoration: StillScoutDecorations.surfaceCard(
          borderColor: StillScoutColors.accent.withValues(alpha: 0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Stat(
              value: '~$estimatedFrames',
              label: 'frames',
              icon: Icons.grid_view_rounded,
            ),
            _Divider(),
            _Stat(
              value: _formatDuration(durationSec),
              label: 'clip length',
              icon: Icons.timer_outlined,
            ),
            _Divider(),
            _Stat(
              value: '~${estimatedSec}s',
              label: 'est. time',
              icon: Icons.bolt_rounded,
              accent: true,
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDuration(int totalSec) {
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s}s';
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    required this.icon,
    this.accent = false,
  });

  final String value;
  final String label;
  final IconData icon;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ? StillScoutColors.accent : StillScoutColors.chalk;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color.withValues(alpha: 0.7)),
        const SizedBox(height: 2),
        Text(
          value,
          style: StillScoutTextStyles.subtitle.copyWith(
            color: color,
            fontSize: 15,
          ),
        ),
        Text(label, style: StillScoutTextStyles.caption),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: StillScoutSpacing.xl,
      color: StillScoutColors.silver.withValues(alpha: 0.25),
    );
  }
}
