import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

class JoinOrBuildScreen extends StatelessWidget {
  const JoinOrBuildScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CR.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back_ios, color: CR.t3, size: 14),
                    const SizedBox(width: 4),
                    Text('Back', style: GoogleFonts.inter(color: CR.t3, fontSize: 13)),
                  ],
                ),
              ).animate().fadeIn(duration: 200.ms),
              const SizedBox(height: 28),

              Text(
                'How will you use CrickRise?',
                style: GoogleFonts.inter(color: CR.t1, fontSize: 24, fontWeight: FontWeight.w700),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 8),
              Text(
                'You can always change this later.',
                style: GoogleFonts.inter(color: CR.t2, fontSize: 14),
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 32),

              // PLAYER CARD
              _UsageCard(
                emoji: '🏏',
                title: "I'm a player",
                subtitle: 'Someone will add me to their league',
                buttonLabel: 'JOIN A COMMUNITY →',
                accent: CR.green,
                onTap: () => context.push('/auth/invite'),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),

              // ORGANIZER CARD — requires approval
              _UsageCard(
                emoji: '⚙️',
                title: "I want to organise a league",
                subtitle: 'Requires organiser access — apply or enter your access code',
                buttonLabel: 'APPLY FOR ACCESS →',
                accent: CR.gold,
                outlined: true,
                onTap: () => context.push('/auth/organizer-access'),
              ).animate().fadeIn(delay: 280.ms),

              const Spacer(),

              Center(
                child: GestureDetector(
                  onTap: () => context.go('/home'),
                  child: Text(
                    'Just watching? Follow without playing →',
                    style: GoogleFonts.inter(color: CR.t3, fontSize: 13),
                  ),
                ),
              ).animate().fadeIn(delay: 360.ms),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Usage Card ───────────────────────────────────────────────────────────────

class _UsageCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final Color accent;
  final bool outlined;
  final VoidCallback onTap;

  const _UsageCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.accent,
    this.outlined = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(color: CR.t1, fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(color: CR.t2, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: outlined
                ? OutlinedButton(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accent,
                      side: BorderSide(color: accent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(buttonLabel,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: accent)),
                  )
                : ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: CR.inv,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(buttonLabel,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: CR.inv)),
                  ),
          ),
        ],
      ),
    );
  }
}
