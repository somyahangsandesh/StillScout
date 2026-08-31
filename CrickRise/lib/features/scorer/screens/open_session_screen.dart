import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/cr_matchday.dart';

class OpenSessionScreen extends StatefulWidget {
  const OpenSessionScreen({super.key});

  @override
  State<OpenSessionScreen> createState() => _OpenSessionScreenState();
}

enum _BallType { leather, tennis, tape }

class _OpenSessionScreenState extends State<OpenSessionScreen> {
  int? _overs;
  _BallType _ball = _BallType.leather;
  static const _opts = [5, 10, 15, 20];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CR.bg,
      body: CRProgrammeBg(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Start session', style: CRType.display(size: 34)),
                const SizedBox(height: 6),
                Text('What are you playing today?', style: CRType.caption()),
                const SizedBox(height: 28),
                _TypeCard(
                  stamp: 'OFFICIAL',
                  title: 'League match',
                  sub: 'Fixture from your league · full OVR weight',
                  color: CR.brass,
                  onTap: () => context.push('/session/qr'),
                ),
                const SizedBox(height: 16),
                CRPaper(
                  accent: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CRCricketBall(size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Casual session', style: CRType.headline(size: 20)),
                                Text('Whoever showed up · half OVR weight', style: CRType.caption(size: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text('OVERS', style: CRType.overline()),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: _opts.map((o) {
                          final on = _overs == o;
                          return GestureDetector(
                            onTap: () => setState(() => _overs = o),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: on ? CR.mossLight : CR.cardHigh,
                                border: Border.all(color: on ? CR.mossLight : CR.fog.withValues(alpha: 0.3)),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text('$o', style: CRType.score(size: 16, color: on ? CR.chalk : CR.ink)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Text('BALL', style: CRType.overline()),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _BallChip('Leather', _ball == _BallType.leather, () => setState(() => _ball = _BallType.leather)),
                          const SizedBox(width: 8),
                          _BallChip('Tennis', _ball == _BallType.tennis, () => setState(() => _ball = _BallType.tennis)),
                          const SizedBox(width: 8),
                          _BallChip('Tape', _ball == _BallType.tape, () => setState(() => _ball = _BallType.tape)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      CRProgrammeButton(
                        label: 'Open session',
                        onTap: _overs != null ? () => context.push('/session/qr') : null,
                      ),
                    ],
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

class _TypeCard extends StatelessWidget {
  final String stamp;
  final String title;
  final String sub;
  final Color color;
  final VoidCallback onTap;

  const _TypeCard({
    required this.stamp,
    required this.title,
    required this.sub,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CRPaper(
        child: Row(
          children: [
            CRStamp(line1: stamp, line2: '1.0×', color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: CRType.headline(size: 20)),
                  Text(sub, style: CRType.caption(size: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

class _BallChip extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback tap;
  const _BallChip(this.label, this.on, this.tap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: on ? CR.brass : CR.fog.withValues(alpha: 0.3)),
          color: on ? CR.brassDim.withValues(alpha: 0.4) : null,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(label, style: CRType.overline(size: 8, color: on ? CR.brass : CR.fog)),
      ),
    );
  }
}
