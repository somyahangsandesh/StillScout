import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/player.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/player_provider.dart';

class PlayerCardScreen extends ConsumerStatefulWidget {
  final String playerId;
  const PlayerCardScreen({super.key, required this.playerId});

  @override
  ConsumerState<PlayerCardScreen> createState() => _PlayerCardScreenState();
}

class _PlayerCardScreenState extends ConsumerState<PlayerCardScreen> {
  bool _showPro = false;
  double _shareScale = 1.0;

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(currentPlayerProvider);
    final rating = ref.watch(currentPlayerRatingProvider);

    return Scaffold(
      backgroundColor: CR.bg,
      appBar: AppBar(
        title: const Text('Share Card'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Toggle — controls which card is shown
            _FreeProToggle(
              showPro: _showPro,
              onToggle: (val) => setState(() => _showPro = val),
            ),
            const SizedBox(height: 24),

            // Animated card switch
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: _showPro
                  ? _ProCard(key: const ValueKey('pro'), player: player, rating: rating)
                  : _FreeCard(key: const ValueKey('free'), player: player, rating: rating),
            ),
            const SizedBox(height: 24),

            // Context label
            if (!_showPro)
              Text(
                'Free card — your OVR number only.',
                style: GoogleFonts.inter(
                  color: CR.text3,
                  fontSize: 12,
                ),
              )
            else
              Text(
                'Pro card — full breakdown + ranking badge.',
                style: GoogleFonts.inter(
                  color: CR.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 20),

            // Primary action — brief pulse then share sheet
            AnimatedScale(
              scale: _shareScale,
              duration: const Duration(milliseconds: 100),
              child: ElevatedButton.icon(
                onPressed: () async {
                  setState(() => _shareScale = 0.95);
                  await Future.delayed(const Duration(milliseconds: 120));
                  if (!mounted) return;
                  setState(() => _shareScale = 1.0);
                  await Future.delayed(const Duration(milliseconds: 80));
                  if (!mounted) return;
                  _showShareSheet();
                },
                icon: const Icon(Icons.share, size: 18),
                label: Text(_showPro ? 'SHARE PRO CARD' : 'SHARE CARD'),
              ),
            ),
            const SizedBox(height: 12),
            if (!_showPro) ...[
              OutlinedButton.icon(
                onPressed: () => _showProUpsell(context),
                icon: const Icon(Icons.star, color: CR.gold, size: 16),
                label: const Text(
                  'SEE PRO CARD — ¥1,980/year',
                  style: TextStyle(color: CR.gold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: CR.gold),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '7-day free trial · No credit card needed',
                style: GoogleFonts.inter(
                  color: CR.text3,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showShareSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: CR.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CR.t3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'SHARE YOUR CARD',
              style: GoogleFonts.inter(
                color: CR.t1,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ShareTarget('📲', 'WhatsApp', CR.green),
                _ShareTarget('📸', 'Instagram', Color(0xFFE1306C)),
                _ShareTarget('🔗', 'Copy Link', CR.t2),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showProUpsell(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: CR.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Go Pro',
              style: GoogleFonts.spaceGrotesk(
                color: CR.text1,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'One price. One year. Everything.',
              style: GoogleFonts.inter(
                color: CR.text2,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            ...const [
              '✓  Pro shareable card (dark, gold OVR)',
              '✓  OVR breakdown — what\'s pulling you up or down',
              '✓  OVR trend graph (career history)',
              '✓  Cross-league ranking',
              '✓  Full career history beyond current season',
            ].map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        f,
                        style: GoogleFonts.inter(
                          color: CR.text1,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: CR.gold,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 52),
              ),
              child: Text(
                'Start 7-day free trial',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '¥1,980/year after trial · Cancel anytime',
              style: GoogleFonts.inter(
                color: CR.text3,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Free Card ───────────────────────────────────────────────────────────────

class _FreeCard extends StatelessWidget {
  final Player player;
  final PlayerRating rating;

  const _FreeCard({super.key, required this.player, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header strip
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF00B4CC),
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            child: Row(
              children: [
                const Text('🏏', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                Text(
                  'CRICKRISE',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${player.jerseyDisplay}  ${player.displayName}',
                      style: GoogleFonts.inter(
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      player.teamName ?? '',
                      style: GoogleFonts.inter(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Season 2026',
                    style: GoogleFonts.inter(
                      color: Colors.black38,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '#3 Okinawa League',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF00B4CC),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'OVR',
            style: GoogleFonts.inter(
              color: Colors.black38,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            rating.ovr.round().toString(),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.black87,
              fontSize: 64,
              fontWeight: FontWeight.w700,
              height: 0.95,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'vs Tokyo Rhinos · WON ✓\n58*(39) · 3/24 · ★ MVP',
            style: GoogleFonts.inter(
              color: Colors.black54,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'crickrise.com/match/preview',
            style: GoogleFonts.inter(
              color: const Color(0xFF00B4CC),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pro Card ─────────────────────────────────────────────────────────────────

class _ProCard extends StatelessWidget {
  final Player player;
  final PlayerRating rating;

  const _ProCard({super.key, required this.player, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A0F1E), Color(0xFF1A2744)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CR.gold.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: CR.gold.withOpacity(0.2),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🏏', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    'CRICKRISE PRO',
                    style: GoogleFonts.spaceGrotesk(
                      color: CR.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              if (rating.hasHotStreak)
                Text(
                  '🔥 ${rating.hotStreakCount} streak',
                  style: GoogleFonts.inter(
                    color: CR.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${player.jerseyDisplay}  ${player.displayName}',
            style: GoogleFonts.inter(
              color: CR.text1,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${player.teamName ?? ''} · ${player.role.displayName}',
            style: GoogleFonts.inter(
              color: CR.text2,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),

          // OVR number — centred
          Center(
            child: Column(
              children: [
                Text(
                  'OVR',
                  style: GoogleFonts.inter(
                    color: CR.text3,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  rating.ovr.round().toString(),
                  style: GoogleFonts.spaceGrotesk(
                    color: CR.gold,
                    fontSize: 72,
                    fontWeight: FontWeight.w700,
                    height: 0.9,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // BAT / BOWL / FIELD
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ProStatCell('BAT', rating.bat.round().toString()),
              _ProStatCell('BOWL', rating.bowl.round().toString()),
              _ProStatCell('FIELD', rating.field.round().toString()),
            ],
          ),
          const SizedBox(height: 16),

          // Rank + matches
          Text(
            '#3 Okinawa  ·  14 Matches  ·  Season 2026',
            style: GoogleFonts.inter(
              color: CR.text2,
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),

          // Match result
          Text(
            'vs Tokyo Rhinos · WON ✓',
            style: GoogleFonts.inter(
              color: CR.text1,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '58*(39)  ·  3/24  ·  ★ MVP',
            style: GoogleFonts.inter(
              color: CR.text2,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'crickrise.com/match/preview',
            style: GoogleFonts.inter(
              color: const Color(0xFF00B4CC),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProStatCell extends StatelessWidget {
  final String label;
  final String value;

  const _ProStatCell(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: const Color(0xFF00B4CC),
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            color: CR.text3,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

// ─── Share Target ─────────────────────────────────────────────────────────────

class _ShareTarget extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  const _ShareTarget(this.emoji, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Opening $label...',
              style: GoogleFonts.inter(fontSize: 13),
            ),
            backgroundColor: CR.cardHigh,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      },
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(color: CR.t2, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _FreeProToggle extends StatelessWidget {
  final bool showPro;
  final void Function(bool) onToggle;

  const _FreeProToggle({required this.showPro, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleBtn(
            label: 'Free',
            active: !showPro,
            onTap: () => onToggle(false),
          ),
          const SizedBox(width: 4),
          _ToggleBtn(
            label: '⭐ Pro',
            active: showPro,
            onTap: () => onToggle(true),
            accent: true,
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final bool accent;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label,
    required this.active,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = accent ? CR.gold : CR.green;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active ? activeColor.withOpacity(0.15) : CR.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? activeColor : CR.cardHigh,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: active ? activeColor : CR.text2,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
