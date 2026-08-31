import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/cr_atmosphere.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CR.bg,
      body: CRAtmosphere(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text('CRICKRISE', style: CRType.label(color: CR.flood, size: 12)),
                const Spacer(flex: 2),
                Text(
                  'YOUR CAREER',
                  style: CRType.display(size: 64, color: CR.cream),
                ),
                Text(
                  'UNDER THE LIGHTS',
                  style: CRType.display(size: 64, color: CR.flood),
                ),
                const SizedBox(height: 24),
                Text(
                  'Every match remembered. Every run counted.\nYour passport follows you everywhere.',
                  style: CRType.body(size: 17, color: CR.mist),
                ),
                const Spacer(flex: 3),
                _FloodlightButton(
                  label: 'ENTER THE GROUND',
                  onTap: () => context.push('/auth/phone'),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => context.push('/auth/phone'),
                  child: Center(
                    child: Text(
                      'Continue with Google',
                      style: CRType.body(size: 15, color: CR.fog, weight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Terms · Privacy',
                    style: CRType.caption(size: 12, color: CR.fog),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FloodlightButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FloodlightButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: CR.floodGradient),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: CR.flood.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(label, style: CRType.headline(size: 22, color: CR.inv)),
        ),
      ),
    );
  }
}
