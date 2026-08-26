import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

class PlayerSetupScreen extends StatefulWidget {
  const PlayerSetupScreen({super.key});

  @override
  State<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends State<PlayerSetupScreen> {
  final _nameCtrl = TextEditingController();
  String? _selectedRole;
  String _jerseyInput = '';

  // 0 = profile step, 1 = usage / league-role step
  int _step = 0;

  static const _roles = [
    ('🏏', 'BATTER'),
    ('🎳', 'BOWLER'),
    ('⚡', 'ALL-ROUNDER'),
    ('🧤', 'KEEPER'),
    ('💪', 'BAT ALL-ROUNDER'),
  ];

  static const _digits = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _canProceed =>
      _nameCtrl.text.trim().isNotEmpty && _selectedRole != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CR.bg,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _step == 0
              ? _buildProfileStep()
              : _buildUsageStep(),
        ),
      ),
    );
  }

  // ─── Step 0: Profile ────────────────────────────────────────────────────────

  Widget _buildProfileStep() {
    return SingleChildScrollView(
      key: const ValueKey('profile'),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set up your profile',
            style: GoogleFonts.inter(
              color: CR.text1,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 6),
          Text(
            'This is your cricket identity. Make it count.',
            style: GoogleFonts.inter(color: CR.text2, fontSize: 14),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 40),

          const _SectionLabel('YOUR NAME'),
          const SizedBox(height: 10),
          _UnderlineField(
            controller: _nameCtrl,
            hint: 'Roshan Patel',
            onChanged: (_) => setState(() {}),
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 36),

          const _SectionLabel('YOUR ROLE'),
          const SizedBox(height: 12),
          _RoleGrid(
            roles: _roles,
            selected: _selectedRole,
            onSelect: (r) => setState(() => _selectedRole = r),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 36),

          const _SectionLabel('JERSEY NUMBER'),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _jerseyInput.isEmpty ? '--' : _jerseyInput,
              style: GoogleFonts.spaceGrotesk(
                color: _jerseyInput.isEmpty ? CR.text3 : CR.text1,
                fontSize: 64,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ).animate().fadeIn(delay: 250.ms),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _digits.map((d) {
              return GestureDetector(
                onTap: () => setState(() {
                  if (_jerseyInput.length < 2) {
                    _jerseyInput += d;
                  }
                }),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: CR.card,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      d,
                      style: GoogleFonts.spaceGrotesk(
                        color: CR.text2,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList()
              ..add(
                GestureDetector(
                  onTap: () => setState(() {
                    if (_jerseyInput.isNotEmpty) {
                      _jerseyInput =
                          _jerseyInput.substring(0, _jerseyInput.length - 1);
                    }
                  }),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: CR.card,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(Icons.backspace_outlined,
                          color: CR.text2, size: 16),
                    ),
                  ),
                ),
              ),
          ).animate().fadeIn(delay: 280.ms),
          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _canProceed
                  ? () => setState(() => _step = 1)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _canProceed ? CR.green : CR.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Next →',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: _canProceed ? CR.textInv : CR.text3,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  // ─── Step 1: Usage / League role ────────────────────────────────────────────

  Widget _buildUsageStep() {
    return SingleChildScrollView(
      key: const ValueKey('usage'),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _step = 0),
            child: Row(
              children: [
                const Icon(Icons.arrow_back_ios, color: CR.text3, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Back',
                  style: GoogleFonts.inter(color: CR.text3, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          Text(
            'How are you using CrickRise?',
            style: GoogleFonts.inter(
              color: CR.text1,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn(duration: 250.ms),
          const SizedBox(height: 8),
          Text(
            'You can always change this later.',
            style: GoogleFonts.inter(color: CR.text2, fontSize: 14),
          ).animate().fadeIn(delay: 80.ms),
          const SizedBox(height: 32),

          // Joining a league
          _UsageCard(
            emoji: '🏏',
            title: 'JOINING A LEAGUE',
            subtitle: "I'm a player joining an existing league",
            detail: 'Your organizer will add you to their league',
            onTap: () => context.go('/auth/club'),
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 16),

          // Setting up a league
          _UsageCard(
            emoji: '⚙️',
            title: 'SETTING UP A LEAGUE',
            subtitle: "I'm organizing a cricket league",
            detail: 'Create and manage your league, add teams, set fixtures',
            accent: CR.gold,
            onTap: () => context.go('/auth/club'),
          ).animate().fadeIn(delay: 220.ms),
          const SizedBox(height: 32),

          // Spectator entry point
          Center(
            child: GestureDetector(
              onTap: () {
                // V2: navigate to league-search / spectator follow screen
                // Placeholder navigation — functionality is V2
              },
              child: Text(
                'Just watching? Follow a league without an account →',
                style: GoogleFonts.inter(
                  color: CR.text3,
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                  decorationColor: CR.text3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ).animate().fadeIn(delay: 280.ms),
        ],
      ),
    );
  }
}

// ─── Usage Card ───────────────────────────────────────────────────────────────

class _UsageCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String detail;
  final Color accent;
  final VoidCallback onTap;

  const _UsageCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.detail,
    this.accent = CR.green,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CR.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withOpacity(0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: CR.text1,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: GoogleFonts.inter(
                      color: CR.text2,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: accent.withOpacity(0.5), size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Private helpers ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: CR.text3,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _UnderlineField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  const _UnderlineField({
    required this.controller,
    required this.hint,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: GoogleFonts.inter(
        color: CR.text1,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: CR.text3, fontSize: 18),
        border: InputBorder.none,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF2A2A2A), width: 1.5),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: CR.green, width: 2),
        ),
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
      onChanged: onChanged,
    );
  }
}

class _RoleGrid extends StatelessWidget {
  final List<(String, String)> roles;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _RoleGrid({
    required this.roles,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: roles.take(3).map((r) {
            final (icon, name) = r;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _RoleChip(
                  icon: icon,
                  name: name,
                  selected: selected == name,
                  onTap: () => onSelect(name),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ...roles.skip(3).map((r) {
              final (icon, name) = r;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _RoleChip(
                    icon: icon,
                    name: name,
                    selected: selected == name,
                    onTap: () => onSelect(name),
                  ),
                ),
              );
            }),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String icon;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.icon,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 72,
        decoration: BoxDecoration(
          color: selected ? CR.green : CR.card,
          borderRadius: BorderRadius.circular(100),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: CR.green.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: -2,
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              name,
              style: GoogleFonts.inter(
                color: selected ? CR.textInv : CR.text2,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
