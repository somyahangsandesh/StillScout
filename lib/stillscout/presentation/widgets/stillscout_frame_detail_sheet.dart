import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/frame_score_metadata.dart';
import '../../data/models/scored_frame.dart';
import '../../domain/stillscout_access_policy.dart';
import '../../services/stillscout_auto_polish.dart';
import '../../services/stillscout_export_service.dart';
import '../providers/stillscout_repository_providers.dart';
import '../theme/stillscout_theme.dart';
import 'stillscout_crop_picker.dart';
import 'stillscout_polish_compare.dart';

typedef ExportRequestedCallback = Future<void> Function(
  ScoredFrame frame,
  StillScoutExportAction action, {
  required StillScoutCropRatio cropRatio,
  bool applyPolish,
  String? precomputedPolishPath,
});

extension _StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

class StillScoutFrameDetailSheet extends StatefulWidget {
  const StillScoutFrameDetailSheet({
    super.key,
    required this.frame,
    required this.onExportPressed,
    required this.tierLabel,
    required this.isPro,
    required this.rank,
    this.allFrames,
    this.initialIndex,
  });

  final ScoredFrame frame;
  final ExportRequestedCallback onExportPressed;
  final String tierLabel;
  final bool isPro;
  final int rank;
  final List<ScoredFrame>? allFrames;
  final int? initialIndex;

  static Future<void> show(
    BuildContext context, {
    required ScoredFrame frame,
    required ExportRequestedCallback onExportPressed,
    required String tierLabel,
    required bool isPro,
    required int rank,
    List<ScoredFrame>? allFrames,
    int? initialIndex,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: StillScoutColors.filmGray,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StillScoutFrameDetailSheet(
        frame: frame,
        onExportPressed: onExportPressed,
        tierLabel: tierLabel,
        isPro: isPro,
        rank: rank,
        allFrames: allFrames,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  State<StillScoutFrameDetailSheet> createState() =>
      _StillScoutFrameDetailSheetState();
}

class _StillScoutFrameDetailSheetState extends State<StillScoutFrameDetailSheet> {
  late final PageController? _pageController;
  late int _pageIndex;

  List<ScoredFrame> get _frames {
    final all = widget.allFrames;
    if (all != null && all.length > 1) return all;
    return [widget.frame];
  }

  List<int> get _browsableRanks => StillScoutAccessPolicy.browsableRanks(
        totalFrames: _frames.length,
        isPro: widget.isPro,
      );

  bool get _swipeEnabled => _browsableRanks.length > 1;

  int get _currentRank =>
      _browsableRanks[_pageIndex.clamp(0, _browsableRanks.length - 1)];

  ScoredFrame get _currentFrame => _frames[_currentRank];

  String get _pagerLabel {
    if (widget.isPro) {
      return 'Frame ${_currentRank + 1} of ${_frames.length}';
    }
    return '${StillScoutAccessPolicy.rankLabel(_currentRank)} · '
        '${_pageIndex + 1} of ${_browsableRanks.length} unlocked';
  }

  @override
  void initState() {
    super.initState();
    final startRank = widget.initialIndex ?? widget.rank;
    final browsable = _browsableRanks;
    _pageIndex = browsable.indexOf(startRank);
    if (_pageIndex < 0) _pageIndex = 0;
    if (_swipeEnabled) {
      _pageController = PageController(initialPage: _pageIndex);
    } else {
      _pageController = null;
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded,
                          color: StillScoutColors.silver),
                    ),
                    const Spacer(),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: StillScoutColors.silver.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              if (_swipeEnabled)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _pagerLabel,
                    style: StillScoutTextStyles.caption.copyWith(
                      color: StillScoutColors.chalk,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Expanded(
                child: _swipeEnabled
                    ? PageView.builder(
                        controller: _pageController,
                        itemCount: _browsableRanks.length,
                        onPageChanged: (i) => setState(() => _pageIndex = i),
                        itemBuilder: (context, page) {
                          final rank = _browsableRanks[page];
                          return _FrameDetailPage(
                            frame: _frames[rank],
                            rank: rank,
                            scrollController: scrollController,
                            tierLabel: widget.tierLabel,
                            isPro: widget.isPro,
                            onExportPressed: widget.onExportPressed,
                          );
                        },
                      )
                    : _FrameDetailPage(
                        frame: _currentFrame,
                        rank: _currentRank,
                        scrollController: scrollController,
                        tierLabel: widget.tierLabel,
                        isPro: widget.isPro,
                        onExportPressed: widget.onExportPressed,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FrameDetailPage extends ConsumerStatefulWidget {
  const _FrameDetailPage({
    required this.frame,
    required this.rank,
    required this.scrollController,
    required this.tierLabel,
    required this.isPro,
    required this.onExportPressed,
  });

  final ScoredFrame frame;
  final int rank;
  final ScrollController scrollController;
  final String tierLabel;
  final bool isPro;
  final ExportRequestedCallback onExportPressed;

  @override
  ConsumerState<_FrameDetailPage> createState() => _FrameDetailPageState();
}

class _FrameDetailPageState extends ConsumerState<_FrameDetailPage> {
  bool applyPolish = true;
  String? _polishedPath;
  bool _polishLoading = true;
  bool _exportBusy = false;

  @override
  void initState() {
    super.initState();
    _loadPolish();
  }

  @override
  void didUpdateWidget(covariant _FrameDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.frame.frame.filePath != widget.frame.frame.filePath) {
      _loadPolish();
    }
  }

  Future<void> _loadPolish() async {
    setState(() {
      _polishLoading = true;
      _polishedPath = null;
    });
    final detector = ref.read(faceDetectorProvider);
    final polished = await StillScoutAutoPolish.polishWithFaceDetection(
      widget.frame.frame.filePath,
      faceDetector: detector,
    );
    if (!mounted) return;
    setState(() {
      _polishedPath = polished;
      _polishLoading = false;
    });
  }

  String _summaryText(FrameScoreMetadata m) {
    if (m.summary != null && m.summary!.trim().isNotEmpty) {
      return m.summary!.trim();
    }
    return _buildHeuristicSummary(m);
  }

  String _buildHeuristicSummary(FrameScoreMetadata m) {
    final parts = <String>[];
    if (m.blurScore >= 75) {
      parts.add('sharp focus');
    } else if (m.blurScore < 45) {
      parts.add('slightly soft focus');
    }
    if (m.lightingScore >= 75) {
      parts.add('excellent exposure');
    } else if (m.lightingScore < 45) {
      parts.add('challenging lighting');
    }
    if (m.compositionScore >= 75) parts.add('strong composition');
    if (m.openEyesScore >= 80) parts.add('eyes open');
    if (parts.isEmpty) {
      return 'Solid frame — balanced qualities across all axes.';
    }
    return '${parts.join(', ').capitalize()}.';
  }

  Future<void> _handleExport(StillScoutExportAction action) async {
    if (_exportBusy) return;
    if (!StillScoutAccessPolicy.canExportFrame(
      rank: widget.rank,
      isPro: widget.isPro,
    )) {
      return;
    }
    final cropRatio = await StillScoutCropPicker.show(
      context,
      imagePath: widget.frame.frame.filePath,
    );
    if (!mounted || cropRatio == null) return;
    HapticFeedback.lightImpact();
    setState(() => _exportBusy = true);
    try {
      await widget.onExportPressed(
        widget.frame,
        action,
        cropRatio: cropRatio,
        applyPolish: applyPolish,
        precomputedPolishPath:
            applyPolish ? _polishedPath : null,
      );
    } finally {
      if (mounted) setState(() => _exportBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summaryText(widget.frame.metadata);
    final polishedReady =
        _polishedPath != null && _polishedPath != widget.frame.frame.filePath;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return ListView(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(20, 16, 20, 28 + bottomSafe),
      children: [
        if (_polishLoading)
          StillScoutPolishLoadingPreview(imagePath: widget.frame.frame.filePath)
        else if (polishedReady)
          StillScoutPolishCompare(
            beforePath: widget.frame.frame.filePath,
            afterPath: _polishedPath!,
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: Image.file(
                File(widget.frame.frame.filePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
        const SizedBox(height: 12),
        _PolishToggleRow(
          enabled: applyPolish,
          onChanged: (v) => setState(() => applyPolish = v),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (widget.frame.isTopScout)
              Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: StillScoutColors.scoutGold,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('TOP SCOUT', style: StillScoutTextStyles.badge),
              ),
            Text('Score ${widget.frame.score}', style: StillScoutTextStyles.title),
            const Spacer(),
            if (StillScoutAccessPolicy.showTimestamp(isPro: widget.isPro))
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.frame.frame.formattedTimestamp,
                    style: StillScoutTextStyles.caption,
                  ),
                  IconButton(
                    tooltip: 'Copy timecode',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: widget.frame.frame.formattedTimestamp),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text('Timecode copied'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16, color: StillScoutColors.silver),
                  ),
                ],
              )
            else
              Text(
                StillScoutAccessPolicy.rankLabel(widget.rank),
                style: StillScoutTextStyles.caption.copyWith(
                  color: StillScoutColors.accent,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        _ScoreSourceBadge(source: widget.frame.metadata.source),
        const SizedBox(height: 14),
        _AiSummaryCard(summary: summary),
        const SizedBox(height: 20),
        Text('AI Breakdown', style: StillScoutTextStyles.title),
        const SizedBox(height: 12),
        _ScoreBar(
          label: 'Sharpness',
          value: widget.frame.metadata.blurScore,
          icon: Icons.blur_off_outlined,
        ),
        _ScoreBar(
          label: 'Lighting',
          value: widget.frame.metadata.lightingScore,
          icon: Icons.wb_sunny_outlined,
        ),
        _ScoreBar(
          label: 'Open Eyes',
          value: widget.frame.metadata.openEyesScore,
          icon: Icons.remove_red_eye_outlined,
        ),
        _ScoreBar(
          label: 'Composition',
          value: widget.frame.metadata.compositionScore,
          icon: Icons.crop_free_outlined,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Text(widget.tierLabel, style: StillScoutTextStyles.caption),
            if (widget.isPro) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: StillScoutColors.scoutGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: StillScoutColors.scoutGold.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'NATIVE RES',
                  style: StillScoutTextStyles.badge.copyWith(
                    color: StillScoutColors.scoutGold,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: StillScoutColors.chalk,
                    side: const BorderSide(color: StillScoutColors.silver),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: _exportBusy
                      ? null
                      : () => _handleExport(StillScoutExportAction.share),
                  icon: _exportBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.ios_share_rounded, size: 18),
                  label: Text(_exportBusy ? 'Sharing…' : 'Share'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: StillScoutColors.accent,
                    foregroundColor: StillScoutColors.voidBlack,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  onPressed: _exportBusy
                      ? null
                      : () =>
                          _handleExport(StillScoutExportAction.saveToGallery),
                  icon: _exportBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: StillScoutColors.voidBlack,
                          ),
                        )
                      : Icon(
                          applyPolish
                              ? Icons.auto_fix_high_rounded
                              : Icons.download_rounded,
                          size: 20,
                        ),
                  label: Text(
                    _exportBusy
                        ? 'Saving…'
                        : applyPolish
                            ? (widget.isPro ? 'Save 4K' : 'Save Polished')
                            : (widget.isPro ? 'Save Full-Res' : 'Save'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StillScoutTextStyles.title.copyWith(
                      fontSize: 14,
                      color: StillScoutColors.voidBlack,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PolishToggleRow extends StatelessWidget {
  const _PolishToggleRow({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: StillScoutColors.slate.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_fix_high_rounded,
              size: 18,
              color: enabled ? StillScoutColors.accent : StillScoutColors.silver,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Auto Polish',
                    style: StillScoutTextStyles.caption.copyWith(
                      color: StillScoutColors.chalk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Levels, clarity & face-aware exposure',
                    style: StillScoutTextStyles.caption.copyWith(
                      color: StillScoutColors.silver,
                      fontSize: 11,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.92,
              child: Switch.adaptive(
                value: enabled,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeTrackColor: StillScoutColors.accent.withValues(alpha: 0.45),
                thumbColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? StillScoutColors.accent
                      : StillScoutColors.silver,
                ),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreSourceBadge extends StatelessWidget {
  const _ScoreSourceBadge({required this.source});

  final ScoreSource source;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = switch (source) {
      ScoreSource.llm => (Icons.auto_awesome_rounded, StillScoutColors.accent),
      ScoreSource.hybrid => (Icons.face_retouching_natural, StillScoutColors.success),
      ScoreSource.heuristic => (Icons.bolt_outlined, StillScoutColors.silver),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(
          source.label,
          style: StillScoutTextStyles.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AiSummaryCard extends StatelessWidget {
  const _AiSummaryCard({required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StillScoutColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: StillScoutColors.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.format_quote_rounded,
            size: 18,
            color: StillScoutColors.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              summary,
              style: StillScoutTextStyles.subtitle.copyWith(
                color: StillScoutColors.chalk,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: StillScoutColors.silver),
              const SizedBox(width: 8),
              Text(label, style: StillScoutTextStyles.caption),
              const Spacer(),
              Text(
                '$value',
                style: StillScoutTextStyles.caption.copyWith(
                  color: StillScoutColors.chalk,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 6,
              backgroundColor: StillScoutColors.slate,
              color: _colorForScore(value),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorForScore(int score) {
    if (score >= 80) return StillScoutColors.scoutGold;
    if (score >= 60) return StillScoutColors.accent;
    return StillScoutColors.silver;
  }
}
