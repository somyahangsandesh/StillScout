import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/cr_matchday.dart';

class JoinOrBuildScreen extends StatelessWidget {
  const JoinOrBuildScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CR.bg,
      body: CRProgrammeBg(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_back, color: CR.fog, size: 16),
                      const SizedBox(width: 6),
                      Text('Back', style: CRType.caption()),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text('Join your\nSunday squad', style: CRType.display(size: 34)),
                const SizedBox(height: 8),
                Text(
                  'Most players join via a WhatsApp invite from their captain.',
                  style: CRType.caption(),
                ),
                const SizedBox(height: 32),
                _OptionCard(
                  stamp: 'JOIN',
                  title: 'I have a squad invite',
                  body: 'Paste your invite link or code from WhatsApp, Facebook, or your captain.',
                  cta: 'Enter invite code',
                  accent: true,
                  onTap: () => context.push('/auth/invite'),
                ),
                const SizedBox(height: 16),
                _OptionCard(
                  stamp: 'NEW',
                  title: 'Start a new squad',
                  body: 'Create a Sunday crew for your city. Share the link in your group chat.',
                  cta: 'Create squad',
                  accent: false,
                  onTap: () => context.go('/home'),
                ),
                const Spacer(),
                Center(
                  child: GestureDetector(
                    onTap: () => context.go('/home'),
                    child: Text(
                      'Browse matches in my city →',
                      style: CRType.caption(color: CR.brass),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String stamp;
  final String title;
  final String body;
  final String cta;
  final bool accent;
  final VoidCallback onTap;

  const _OptionCard({
    required this.stamp,
    required this.title,
    required this.body,
    required this.cta,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CRPaper(
        accent: accent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CRStamp(line1: stamp, line2: 'SQUAD', color: accent ? CR.brass : CR.fog),
                const Spacer(),
                const CRCricketBall(size: 28),
              ],
            ),
            const SizedBox(height: 16),
            Text(title, style: CRType.headline(size: 22)),
            const SizedBox(height: 8),
            Text(body, style: CRType.body(size: 14, color: CR.ink)),
            const SizedBox(height: 16),
            Text('$cta →', style: CRType.overline(color: accent ? CR.brass : CR.ink)),
          ],
        ),
      ),
    );
  }
}
