import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/scorer_provider.dart';

class InningsTransitionScreen extends ConsumerWidget {
  const InningsTransitionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scorerProvider);

    if (state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: CR.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: CR.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: CR.green,
                  size: 36,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'INNINGS COMPLETE',
                style: GoogleFonts.inter(
                  color: CR.text2,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                state.teamAName,
                style: GoogleFonts.inter(
                  color: CR.text1,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${state.runs}/${state.wickets}',
                style: GoogleFonts.spaceGrotesk(
                  color: CR.text1,
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '(${state.totalOvers} overs)',
                style: const TextStyle(color: CR.text2),
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: CR.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CR.gold.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      'TARGET',
                      style: GoogleFonts.inter(
                        color: CR.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${state.runs + 1} runs off ${state.totalOvers} overs',
                      style: GoogleFonts.spaceGrotesk(
                        color: CR.text1,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/match/scorer'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: const Text('BEGIN 2ND INNINGS →'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
