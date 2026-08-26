import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

class ClubSetupScreen extends StatefulWidget {
  const ClubSetupScreen({super.key});

  @override
  State<ClubSetupScreen> createState() => _ClubSetupScreenState();
}

class _ClubSetupScreenState extends State<ClubSetupScreen> {
  _ClubAction? _action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CR.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'Your club',
                style: GoogleFonts.inter(
                  color: CR.text1,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 6),
              Text(
                'Join an existing club or create your own.',
                style: GoogleFonts.inter(color: CR.text2, fontSize: 14),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 40),

              // Cards
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _action == null
                    ? _ClubChoiceCards(
                        key: const ValueKey('choice'),
                        onJoin: () => setState(() => _action = _ClubAction.join),
                        onCreate: () =>
                            setState(() => _action = _ClubAction.create),
                      )
                    : _action == _ClubAction.join
                        ? _JoinClubForm(
                            key: const ValueKey('join'),
                            onBack: () => setState(() => _action = null),
                          )
                        : _CreateClubForm(
                            key: const ValueKey('create'),
                            onBack: () => setState(() => _action = null),
                          ),
              ),

              const Spacer(),

              // Skip link
              Center(
                child: GestureDetector(
                  onTap: () => context.go('/home'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Skip for now',
                      style: GoogleFonts.inter(
                        color: CR.text3,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: CR.text3,
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ClubAction { join, create }

class _ClubChoiceCards extends StatelessWidget {
  final VoidCallback onJoin;
  final VoidCallback onCreate;

  const _ClubChoiceCards({
    super.key,
    required this.onJoin,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ClubCard(
          icon: '🔗',
          title: 'Join a club',
          subtitle: 'Enter the invite code your organizer shared',
          buttonLabel: 'JOIN',
          onTap: onJoin,
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),
        const SizedBox(height: 12),
        _ClubCard(
          icon: '⚡',
          title: 'Create a club',
          subtitle: 'Start fresh. Invite your teammates.',
          buttonLabel: 'CREATE',
          onTap: onCreate,
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),
      ],
    );
  }
}

class _ClubCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;

  const _ClubCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: CR.text1,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(color: CR.text2, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: CR.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                buttonLabel,
                style: GoogleFonts.inter(
                  color: CR.textInv,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JoinClubForm extends StatelessWidget {
  final VoidCallback onBack;
  const _JoinClubForm({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          style: GoogleFonts.spaceGrotesk(
            color: CR.text1,
            fontSize: 18,
            letterSpacing: 4,
          ),
          decoration: InputDecoration(
            hintText: 'INVITE CODE',
            hintStyle: GoogleFonts.inter(color: CR.text3, fontSize: 14),
            filled: true,
            fillColor: CR.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => context.go('/home'),
            child: Text(
              'Join Club',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: CR.textInv,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onBack,
          child: Text(
            '← Back',
            style: GoogleFonts.inter(color: CR.text2, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _CreateClubForm extends StatelessWidget {
  final VoidCallback onBack;
  const _CreateClubForm({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          style: GoogleFonts.inter(color: CR.text1, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Club name',
            hintStyle: GoogleFonts.inter(color: CR.text3, fontSize: 16),
            filled: true,
            fillColor: CR.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => context.go('/home'),
            child: Text(
              'Create Club',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: CR.textInv,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onBack,
          child: Text(
            '← Back',
            style: GoogleFonts.inter(color: CR.text2, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
