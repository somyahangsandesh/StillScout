import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CR.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 64),

              // Hero headline
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your cricket career.',
                    style: GoogleFonts.inter(
                      color: CR.text1,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'Finally official.',
                    style: GoogleFonts.inter(
                      color: CR.green,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, curve: Curves.easeOut),

              const SizedBox(height: 32),

              // Feature lines — with green dot bullets
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FeatureLine('Every match you play, remembered forever.'),
                  SizedBox(height: 10),
                  _FeatureLine('Live OVR rating that rises with your form.'),
                  SizedBox(height: 10),
                  _FeatureLine('Your career follows you across every team.'),
                ],
              ).animate().fadeIn(delay: 400.ms),

              const Spacer(),

              // Bottom CTA section
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => context.push('/auth/phone'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CR.green,
                        foregroundColor: CR.textInv,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Continue with Phone',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: CR.textInv,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'or',
                    style: GoogleFonts.inter(
                      color: CR.text3,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: () => context.push('/auth/phone'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CR.text1,
                        side: const BorderSide(color: Color(0xFF2A2A2A)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Continue with Google',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: CR.text1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'By continuing you agree to our Terms',
                    style: GoogleFonts.inter(
                      color: CR.text3,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ],
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.05, curve: Curves.easeOut),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  final String text;
  const _FeatureLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: CR.green,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: CR.text2,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
