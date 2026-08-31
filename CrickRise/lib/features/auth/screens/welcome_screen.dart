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
                  'Every Sunday,\na story worth\nsending home.',
                  textAlign: TextAlign.center,
                  style: CRType.display(size: 38, style: FontStyle.italic),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cricket abroad for Nepal, India & Pakistan.\nJoin your squad. Share your Sunday.',
                  textAlign: TextAlign.center,
                  style: CRType.body(size: 16, color: CR.ink),
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: ['🇯🇵', '🇦🇺', '🇨🇦', '🇬🇧', '🇺🇸', '🇦🇪']
                      .map((f) => Text(f, style: const TextStyle(fontSize: 22)))
                      .toList(),
                ),
                const Spacer(),
                CRProgrammeButton(
                  label: 'Join your Sunday squad',
                  onTap: () => context.push('/auth/phone'),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => context.push('/auth/phone'),
                  child: Text(
                    'Already have a squad invite?',
                    style: CRType.caption(color: CR.brass),
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
