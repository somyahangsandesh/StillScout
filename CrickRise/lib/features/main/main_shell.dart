import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/league')) return 1;
    if (location.startsWith('/match/setup')) return 2;
    if (location.startsWith('/me')) return 3;
    return 0; // /home
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentIndex(context);

    return Scaffold(
      backgroundColor: CR.bg,
      body: child,
      bottomNavigationBar: _CRBottomNav(currentIndex: current),
    );
  }
}

class _CRBottomNav extends StatelessWidget {
  final int currentIndex;
  const _CRBottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CR.bg,
        border: Border(top: BorderSide(color: CR.cardHigh, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: currentIndex == 0,
                onTap: () => context.go('/home'),
              ),
              _NavItem(
                icon: Icons.emoji_events_rounded,
                label: 'League',
                selected: currentIndex == 1,
                onTap: () => context.go('/league'),
              ),
              // Center Play button
              _PlayButton(
                selected: currentIndex == 2,
                onTap: () => context.go('/match/setup'),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Me',
                selected: currentIndex == 3,
                onTap: () => context.go('/me'),
              ),
              // Empty slot to balance layout
              const Expanded(child: SizedBox()),
            ],
          ),
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
    final color = selected ? CR.green : CR.text3;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: CR.green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: CR.green.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.sports_cricket,
              color: CR.textInv,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
