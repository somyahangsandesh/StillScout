import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/cr_matchday.dart';

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
      backgroundColor: CR.bg,
      body: CRProgrammeBg(
        ruled: false,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(),
                const CRCricketBall(size: 72, glow: true),
                const SizedBox(height: 24),
                Text('PLAYER OF SUNDAY', style: CRType.overline(color: CR.brass)),
                const SizedBox(height: 12),
                Text(playerName, style: CRType.display(size: 36)),
                const SizedBox(height: 8),
                Text(stats, style: CRType.score(size: 22, color: CR.mossLight)),
                const SizedBox(height: 24),
                const CRProgrammeRule(),
                const SizedBox(height: 24),
                Text(
                  'Now share your Sunday Story\nwith the squad and family back home.',
                  textAlign: TextAlign.center,
                  style: CRType.body(color: CR.ink),
                ),
                const Spacer(),
                CRProgrammeButton(
                  label: 'Create Sunday Story',
                  onTap: () => context.go('/story'),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => context.go('/home'),
                  child: Text('Skip to home', style: CRType.caption(color: CR.fog)),
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
