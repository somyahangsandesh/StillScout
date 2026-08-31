import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/cr_matchday.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CR.bg,
      body: CRProgrammeBg(
        ruled: false,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('CRICKRISE', style: CRType.overline(color: CR.brass)),
                ),
                const Spacer(),
                const CRCricketBall(size: 88, glow: true),
                const SizedBox(height: 32),
                Text(
                  'Every innings\nbelongs to you.',
                  textAlign: TextAlign.center,
                  style: CRType.display(size: 40, style: FontStyle.italic),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your cricket passport. Every match remembered.\nEvery run counted. Wherever you play.',
                  textAlign: TextAlign.center,
                  style: CRType.body(size: 16, color: CR.ink),
                ),
                const Spacer(),
                CRProgrammeButton(
                  label: 'Get your passport',
                  onTap: () => context.push('/auth/phone'),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => context.push('/auth/phone'),
                  child: Text(
                    'Continue with Google',
                    style: CRType.caption(color: CR.fog),
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
