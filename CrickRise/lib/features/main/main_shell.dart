import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/cr_matchday.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _index(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith('/league')) return 1;
    if (loc.startsWith('/play') || loc.startsWith('/session')) return 2;
    if (loc.startsWith('/community')) return 3;
    if (loc.startsWith('/me')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final i = _index(context);
    return Scaffold(
      backgroundColor: CR.bg,
      extendBody: true,
      body: child,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: CR.inkDeep,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: CR.chalk.withValues(alpha: 0.08)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              _Tab(Icons.home_outlined, 'Home', i == 0, () => context.go('/home')),
              _Tab(Icons.emoji_events_outlined, 'League', i == 1, () => context.go('/league')),
              _Play(i == 2, () => context.go('/play')),
              _Tab(Icons.people_outline, 'Club', i == 3, () => context.go('/community')),
              _Tab(Icons.person_outline, 'Passport', i == 4, () => context.go('/me')),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback tap;
  const _Tab(this.icon, this.label, this.on, this.tap);

  @override
  Widget build(BuildContext context) {
    final c = on ? CR.brass : CR.fog;
    return Expanded(
      child: GestureDetector(
        onTap: tap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: c, size: 20),
            const SizedBox(height: 2),
            Text(label, style: CRType.overline(size: 8, color: c)),
          ],
        ),
      ),
    );
  }
}

class _Play extends StatelessWidget {
  final bool on;
  final VoidCallback tap;
  const _Play(this.on, this.tap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: tap,
        child: Center(
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: on ? CR.brass : CR.fog.withValues(alpha: 0.3), width: 1.5),
            ),
            child: const CRCricketBall(size: 36, glow: true),
          ),
        ),
      ),
    );
  }
}
