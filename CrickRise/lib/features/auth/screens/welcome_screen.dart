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

              // Feature lines
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FeatureLine('Verified match stats for every game you play.'),
                  SizedBox(height: 8),
                  _FeatureLine('Live OVR rating that rises with your form.'),
                  SizedBox(height: 8),
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
                        side: const BorderSide(color: Color(0xFF333333)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('G', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(width: 10),
                          Text(
                            'Sign in with Google',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: CR.text1,
                            ),
                          ),
                        ],
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
    return Text(
      text,
      style: GoogleFonts.inter(
        color: CR.text2,
        fontSize: 14,
        height: 1.4,
      ),
    );
  }
}
