import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SEASON AWARDS SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class SeasonAwardsScreen extends StatelessWidget {
  const SeasonAwardsScreen({super.key});

  static const _awards = [
    _AwardData(
      emoji: '🏏',
      title: 'GOLDEN BAT',
      subtitle: 'Most Runs',
      player: 'Roshan KC',
      team: 'Warriors',
      jersey: 7,
      statLine: '487 runs · avg 48.7 · SR 142',
      color: Color(0xFFFFD700),
    ),
    _AwardData(
      emoji: '🎳',
      title: 'GOLDEN BALL',
      subtitle: 'Most Wickets',
      player: 'Bikash Rai',
      team: 'Warriors',
      jersey: 23,
      statLine: '21 wickets · econ 5.8 · avg 14.2',
      color: Color(0xFFE53935),
    ),
    _AwardData(
      emoji: '🧤',
      title: 'GOLDEN GLOVES',
      subtitle: 'Most Catches',
      player: 'Sandip Thapa',
      team: 'Warriors',
      jersey: 18,
      statLine: '13 catches',
      color: Color(0xFF40C4FF),
    ),
    _AwardData(
      emoji: '⭐',
      title: 'MOST VALUABLE PLAYER',
      subtitle: 'Season MVP',
      player: 'Roshan KC',
      team: 'Warriors',
      jersey: 7,
      statLine: '3 MVP awards · OVR 72→86',
      color: Color(0xFFFFD700),
    ),
    _AwardData(
      emoji: '📈',
      title: 'MOST IMPROVED',
      subtitle: 'Biggest OVR rise',
      player: 'Dev Shrestha',
      team: 'Warriors',
      jersey: 4,
      statLine: 'OVR +14 this season',
      color: Color(0xFF00E676),
    ),
    _AwardData(
      emoji: '🌟',
      title: 'ROOKIE OF THE SEASON',
      subtitle: 'Highest OVR — under 10 career matches',
      player: 'Amit KC',
      team: 'Tokyo Rhinos',
      jersey: 9,
      statLine: 'OVR 68 · 8 matches',
      color: Color(0xFFFF8F00),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CR.bg,
      appBar: AppBar(
        backgroundColor: CR.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: CR.t2, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SEASON 2026',
              style: GoogleFonts.oswald(
                  color: CR.gold, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w500),
            ),
            Text(
              'Awards',
              style: GoogleFonts.oswald(
                  color: CR.t1, fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        itemCount: _awards.length + 1, // +1 for share button
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) {
          if (i == _awards.length) {
            return Padding(
              padding: const EdgeInsets.only(top: 20),
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('Share image — coming soon'),
                      behavior: SnackBarBehavior.floating,
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CR.gold,
                    foregroundColor: CR.inv,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.share_outlined, color: CR.inv, size: 20),
                  label: Text(
                    'SHARE SEASON AWARDS →',
                    style: GoogleFonts.oswald(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: CR.inv),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms),
            );
          }

          final award = _awards[i];
          return _AwardCard(award: award)
              .animate()
              .fadeIn(delay: (i * 80).ms)
              .slideY(begin: 0.2, delay: (i * 80).ms);
        },
      ),
    );
  }
}

// ─── Award Card ───────────────────────────────────────────────────────────────

class _AwardData {
  final String emoji;
  final String title;
  final String subtitle;
  final String player;
  final String team;
  final int jersey;
  final String statLine;
  final Color color;

  const _AwardData({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.player,
    required this.team,
    required this.jersey,
    required this.statLine,
    required this.color,
  });
}

class _AwardCard extends StatelessWidget {
  final _AwardData award;
  const _AwardCard({required this.award});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: award.color.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: award.color.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Text(award.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      award.title,
                      style: GoogleFonts.oswald(
                        color: award.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      award.subtitle,
                      style: GoogleFonts.inter(color: CR.t3, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: CR.cardHigh),
          const SizedBox(height: 14),

          // Player row
          Row(
            children: [
              // Jersey badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: award.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: award.color.withOpacity(0.3)),
                ),
                child: Center(
                  child: Text(
                    '#${award.jersey}',
                    style: GoogleFonts.spaceGrotesk(
                        color: award.color, fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      award.player,
                      style: GoogleFonts.inter(
                        color: CR.t1,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      award.team,
                      style: GoogleFonts.inter(color: CR.t3, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stat line
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: award.color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              award.statLine,
              style: GoogleFonts.spaceGrotesk(
                color: award.color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
