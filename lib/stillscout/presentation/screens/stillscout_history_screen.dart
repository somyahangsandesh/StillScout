import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/stillscout_session.dart';
import '../../domain/repositories/session_repository.dart';
import '../screens/stillscout_session_detail_screen.dart';
import '../theme/stillscout_theme.dart';
import '../widgets/stillscout_skeleton.dart';
import '../widgets/stillscout_status_view.dart';

class StillScoutHistoryScreen extends StatefulWidget {
  const StillScoutHistoryScreen({
    super.key,
    required this.sessionRepository,
  });

  final SessionRepository sessionRepository;

  @override
  State<StillScoutHistoryScreen> createState() =>
      _StillScoutHistoryScreenState();
}

class _StillScoutHistoryScreenState extends State<StillScoutHistoryScreen> {
  late Future<List<StillScoutSession>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = widget.sessionRepository.getSessions();
  }

  void _reload() {
    setState(
      () => _sessionsFuture = widget.sessionRepository.getSessions(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StillScoutColors.voidBlack,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: StillScoutColors.chalk),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Past Scouts', style: StillScoutTextStyles.title),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: StillScoutColors.vignette),
        child: SafeArea(
          child: FutureBuilder<List<StillScoutSession>>(
            future: _sessionsFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const StillScoutHistorySkeleton();
              }
              if (snap.hasError) {
                return _ErrorHistory(onRetry: _reload);
              }
              final sessions = snap.data ?? [];
              if (sessions.isEmpty) return const _EmptyHistory();
              return _SessionGrid(
                sessions: sessions,
                onRefresh: _reload,
                onDelete: (session) async {
                  await widget.sessionRepository.deleteSession(session.id);
                  _reload();
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ErrorHistory extends StatelessWidget {
  const _ErrorHistory({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return StillScoutStatusView(
      icon: Icons.error_outline_rounded,
      iconColor: StillScoutColors.danger,
      title: 'Could not load history',
      body: 'Check your storage and try again.',
      primaryLabel: 'Try again',
      primaryIcon: Icons.refresh_rounded,
      onPrimary: onRetry,
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const StillScoutStatusView(
      icon: Icons.history_edu_rounded,
      iconColor: StillScoutColors.silver,
      title: 'No past scouts yet',
      body: 'Completed scouts appear here so you can revisit them anytime.',
    );
  }
}

class _SessionGrid extends StatelessWidget {
  const _SessionGrid({
    required this.sessions,
    required this.onDelete,
    required this.onRefresh,
  });

  final List<StillScoutSession> sessions;
  final Future<void> Function(StillScoutSession) onDelete;
  final VoidCallback onRefresh;

  /// Groups sessions into ordered date buckets (today, yesterday, or "MMM d").
  List<({String label, List<StillScoutSession> sessions})> _grouped() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final groups = <String, List<StillScoutSession>>{};
    for (final s in sessions) {
      final d = DateTime(s.createdAt.year, s.createdAt.month, s.createdAt.day);
      String label;
      if (d == today) {
        label = 'Today';
      } else if (d == yesterday) {
        label = 'Yesterday';
      } else {
        // e.g. "Jul 12" or "Jun 3"
        final months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];
        label = '${months[s.createdAt.month - 1]} ${s.createdAt.day}';
        if (s.createdAt.year != now.year) label += ' ${s.createdAt.year}';
      }
      (groups[label] ??= []).add(s);
    }

    // Preserve the original chronological-descending order.
    return groups.entries
        .map((e) => (label: e.key, sessions: e.value))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final groups = _grouped();

    return CustomScrollView(
      slivers: [
        for (final group in groups) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                StillScoutSpacing.m,
                StillScoutSpacing.l,
                StillScoutSpacing.m,
                StillScoutSpacing.s,
              ),
              child: Text(
                group.label,
                style: StillScoutTextStyles.caption.copyWith(
                  color: StillScoutColors.silver,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: StillScoutSpacing.m,
            ),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final session = group.sessions[index];
                  return _SessionCard(
                    session: session,
                    onDelete: () => onDelete(session),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              StillScoutSessionDetailScreen(session: session),
                        ),
                      );
                      onRefresh();
                    },
                  );
                },
                childCount: group.sessions.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: StillScoutSpacing.m,
                crossAxisSpacing: StillScoutSpacing.m,
                childAspectRatio: 0.8,
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: StillScoutSpacing.xxl)),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.onDelete,
    required this.onTap,
  });

  final StillScoutSession session;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  void _handleSwipeDismiss(BuildContext context) {
    HapticFeedback.mediumImpact();

    // Show a brief confirmation snackbar. The actual delete has already
    // happened via onDelete() (called by onDismissed) before this runs.
    // Undo is not possible once Dismissible commits, so we simply inform.
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          backgroundColor: StillScoutColors.slate,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          content: Text(
            'Scout deleted',
            style: StillScoutTextStyles.caption.copyWith(
              color: StillScoutColors.chalk,
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(session.id),
      direction: DismissDirection.endToStart,
      // confirmDismiss lets us show a dialog before the item is removed.
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: StillScoutColors.slate,
            title: Text(
              'Delete scout?',
              style: StillScoutTextStyles.title.copyWith(fontSize: 16),
            ),
            content: Text(
              'This scout and its frame data will be permanently removed.',
              style: StillScoutTextStyles.bodySmall,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  'Cancel',
                  style: StillScoutTextStyles.caption
                      .copyWith(color: StillScoutColors.silver),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  'Delete',
                  style: StillScoutTextStyles.caption
                      .copyWith(color: StillScoutColors.danger),
                ),
              ),
            ],
          ),
        );
        return confirm ?? false;
      },
      onDismissed: (_) {
        onDelete();
        _handleSwipeDismiss(context);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: StillScoutSpacing.m),
        decoration: BoxDecoration(
          color: StillScoutColors.danger.withValues(alpha: 0.85),
          borderRadius: StillScoutRadius.card,
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 28),
      ),
      child: Semantics(
        label: 'Scout from ${_formatDate(session.createdAt)}, '
            '${session.frameCount} frames, top score ${session.topScore >= 10.0 ? '10' : session.topScore.toStringAsFixed(1)}',
        button: true,
        child: GestureDetector(
          onTap: onTap,
          onLongPress: () {
            HapticFeedback.mediumImpact();
            _showDeleteConfirm(context);
          },
          child: Container(
            decoration: StillScoutDecorations.surfaceCard(),
            clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _Thumbnail(path: session.topFrameThumbPath)),
              Padding(
                padding: const EdgeInsets.all(StillScoutSpacing.s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatDate(session.createdAt),
                            style: StillScoutTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _ScoreBadge(score: session.topScore),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: StillScoutColors.silver.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${session.frameCount} frames'
                      '${session.videoDurationMs != null ? ' · ${_formatDuration(session.videoDurationMs!)}' : ''}',
                      style: StillScoutTextStyles.caption.copyWith(
                        color:
                            StillScoutColors.silver.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }

  void _showDeleteConfirm(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: StillScoutColors.slate,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(StillScoutRadius.xl)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            StillScoutSpacing.m,
            StillScoutSpacing.s,
            StillScoutSpacing.m,
            StillScoutSpacing.m,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: StillScoutColors.silver.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: StillScoutSpacing.m),
              Text('Delete this scout?', style: StillScoutTextStyles.subtitle),
              const SizedBox(height: StillScoutSpacing.s),
              Text(
                'The session and its cached frames will be permanently removed.',
                style: StillScoutTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: StillScoutSpacing.l),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: StillScoutColors.chalk,
                        side: const BorderSide(
                            color: StillScoutColors.slateLight),
                        minimumSize: const Size(0, 48),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: StillScoutSpacing.m),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: StillScoutColors.danger,
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        onDelete();
                      },
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today ${_time(dt)}';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  static String _time(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'pm' : 'am';
    return '$h:$m $period';
  }

  static String _formatDuration(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    final rem = s % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${rem}s';
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({this.path});
  final String? path;

  @override
  Widget build(BuildContext context) {
    if (path == null) {
      return const _Placeholder(icon: Icons.image_not_supported_outlined);
    }
    final file = File(path!);
    if (!file.existsSync()) {
      return const _Placeholder(icon: Icons.broken_image_outlined);
    }
    return Image.file(file, fit: BoxFit.cover, gaplessPlayback: true);
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: StillScoutColors.filmGray,
      child: Center(
        child: Icon(icon, color: StillScoutColors.silver, size: 32),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});
  final double score;

  Color get _color {
    if (score >= 8.0) return StillScoutColors.scoutGold;
    if (score >= 6.0) return StillScoutColors.accent;
    return StillScoutColors.silver;
  }

  @override
  Widget build(BuildContext context) {
    final label = score >= 10.0 ? '10' : score.toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(StillScoutRadius.pill),
        border: Border.all(color: _color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: StillScoutTextStyles.badge.copyWith(color: _color),
      ),
    );
  }
}
