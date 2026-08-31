import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/league')) return 1;
    if (location.startsWith('/play') || location.startsWith('/session')) return 2;
    if (location.startsWith('/community')) return 3;
    if (location.startsWith('/me')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CR.bg,
      extendBody: true,
      body: child,
      bottomNavigationBar: _FloatingNav(currentIndex: _currentIndex(context)),
    );
  }
}

class _FloatingNav extends StatelessWidget {
  final int currentIndex;
  const _FloatingNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final nav = Container(
      height: 72,
      decoration: BoxDecoration(
        color: kIsWeb ? CR.card : CR.card.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: CR.cream.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            selected: currentIndex == 0,
            onTap: () => context.go('/home'),
          ),
          _NavItem(
            icon: Icons.emoji_events_outlined,
            label: 'League',
            selected: currentIndex == 1,
            onTap: () => context.go('/league'),
          ),
          _PlayButton(
            selected: currentIndex == 2,
            onTap: () => context.go('/play'),
          ),
          _NavItem(
            icon: Icons.groups_outlined,
            label: 'Club',
            selected: currentIndex == 3,
            onTap: () => context.go('/community'),
          ),
          _NavItem(
            icon: Icons.person_outline_rounded,
            label: 'Me',
            selected: currentIndex == 4,
            onTap: () => context.go('/me'),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: kIsWeb
          ? nav
          : ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: nav,
              ),
            ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? CR.flood : CR.fog;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: CRType.caption(
                size: 10,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _PlayButton({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Center(
          child: Container(
            width: 52,
            height: 52,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: CR.floodGradient,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: CR.flood.withValues(alpha: selected ? 0.5 : 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.sports_cricket, color: CR.inv, size: 24),
          ),
        ),
      ),
    );
  }
}
