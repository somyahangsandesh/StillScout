import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

class MvpScreen extends StatelessWidget {
  final String playerName;
  final String stats;

  const MvpScreen({
    super.key,
    this.playerName = 'Roshan KC',
    this.stats = '58*(39)  ·  3/24',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1100),
              Color(0xFF0A0A0A),
              Color(0xFF1A1100),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Star
              const Text(
                '⭐',
                style: TextStyle(fontSize: 64),
              )
                  .animate()
                  .scale(begin: const Offset(0, 0), duration: 500.ms, curve: Curves.elasticOut)
                  .fadeIn(duration: 300.ms),

              const SizedBox(height: 20),

              // MATCH MVP label
              Text(
                'MATCH MVP',
                style: GoogleFonts.inter(
                  color: CR.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                ),
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 400.ms),

              const SizedBox(height: 12),

              // Player name
              Text(
                playerName,
                style: GoogleFonts.inter(
                  color: CR.t1,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 400.ms)
                  .slideY(begin: 0.1),

              const SizedBox(height: 10),

              // Stats line
              Text(
                stats,
                style: GoogleFonts.spaceGrotesk(
                  color: CR.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              )
                  .animate()
                  .fadeIn(delay: 550.ms, duration: 400.ms),

              const SizedBox(height: 48),

              // Share button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CR.gold,
                      foregroundColor: CR.inv,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'SHARE YOUR MOMENT',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.5,
                        color: CR.inv,
                      ),
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 700.ms, duration: 400.ms)
                  .slideY(begin: 0.08),

              const SizedBox(height: 16),

              // Continue
              GestureDetector(
                onTap: () => context.go('/home'),
                child: Text(
                  'CONTINUE',
                  style: GoogleFonts.inter(
                    color: CR.t3,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 800.ms, duration: 300.ms),
            ],
          ),
        ),
      ),
    );
  }
}
