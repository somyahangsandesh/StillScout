import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/stillscout_session.dart';
import '../../domain/repositories/session_repository.dart';
import '../screens/stillscout_session_detail_screen.dart';
import '../theme/stillscout_theme.dart';

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
                return const Center(
                  child: CircularProgressIndicator(
                    color: StillScoutColors.accent,
                  ),
                );
              }
              if (snap.hasError) {
                return Center(
                  child: Text(
                    'Could not load history.',
                    style: StillScoutTextStyles.body,
                  ),
                );
              }
              final sessions = snap.data ?? [];
              if (sessions.isEmpty) return const _EmptyHistory();
              return _SessionGrid(
                sessions: sessions,
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

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(StillScoutSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_edu_rounded,
              size: 64,
              color: StillScoutColors.silver.withValues(alpha: 0.5),
            ),
            const SizedBox(height: StillScoutSpacing.m),
            Text('No past scouts yet', style: StillScoutTextStyles.subtitle),
            const SizedBox(height: StillScoutSpacing.s),
            Text(
              'Completed scouts appear here so you can revisit them anytime.',
              style: StillScoutTextStyles.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionGrid extends StatelessWidget {
  const _SessionGrid({required this.sessions, required this.onDelete});

  final List<StillScoutSession> sessions;
  final Future<void> Function(StillScoutSession) onDelete;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        StillScoutSpacing.m,
        StillScoutSpacing.s,
        StillScoutSpacing.m,
        StillScoutSpacing.xxl,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: StillScoutSpacing.m,
        crossAxisSpacing: StillScoutSpacing.m,
        childAspectRatio: 0.8,
      ),
      itemCount: sessions.length,
      itemBuilder: (context, index) => _SessionCard(
        session: sessions[index],
        onDelete: () => onDelete(sessions[index]),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => StillScoutSessionDetailScreen(
                session: sessions[index],
              ),
            ),
          );
        },
      ),
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

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Scout from ${_formatDate(session.createdAt)}, '
          '${session.frameCount} frames, top score ${session.topScore}',
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
  final int score;

  Color get _color {
    if (score >= 80) return StillScoutColors.scoutGold;
    if (score >= 60) return StillScoutColors.accent;
    return StillScoutColors.silver;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(StillScoutRadius.pill),
        border: Border.all(color: _color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '$score',
        style: StillScoutTextStyles.badge.copyWith(color: _color),
      ),
    );
  }
}
