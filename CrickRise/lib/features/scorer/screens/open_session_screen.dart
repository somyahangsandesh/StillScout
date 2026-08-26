import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

class OpenSessionScreen extends StatefulWidget {
  const OpenSessionScreen({super.key});

  @override
  State<OpenSessionScreen> createState() => _OpenSessionScreenState();
}

enum _BallType { leather, tennis, tape }

class _OpenSessionScreenState extends State<OpenSessionScreen> {
  int? _casualOvers;
  _BallType _ballType = _BallType.leather;
  static const _overOptions = [5, 10, 15, 20];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CR.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'START SESSION',
                style: GoogleFonts.inter(
                  color: CR.t3,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ).animate().fadeIn(duration: 200.ms),
              const SizedBox(height: 8),
              Text(
                'What kind of session?',
                style: GoogleFonts.inter(
                  color: CR.t1,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ).animate().fadeIn(delay: 80.ms),
              const SizedBox(height: 32),

              // LEAGUE MATCH card
              _SessionTypeCard(
                emoji: '🏆',
                label: 'LEAGUE MATCH',
                labelColor: CR.gold,
                title: 'Official league match',
                subtitle: 'Select from pre-created fixtures in your league',
                badge: 'OVR 1.0×',
                badgeColor: CR.gold,
                onTap: () => context.push('/session/qr'),
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 16),

              // CASUAL SESSION card
              _SessionTypeCard(
                emoji: '🏏',
                label: 'CASUAL SESSION',
                labelColor: CR.green,
                title: 'Casual game today',
                subtitle: 'Quick match with whoever showed up',
                badge: 'OVR 0.5×',
                badgeColor: CR.text3,
                expanded: true,
                expandedContent: _CasualOversSelector(
                  selected: _casualOvers,
                  options: _overOptions,
                  onSelect: (v) => setState(() => _casualOvers = v),
                  onCustom: () => setState(() => _casualOvers = 0),
                  ballType: _ballType,
                  onBallType: (t) => setState(() => _ballType = t),
                  onStart: _casualOvers != null
                      ? () => context.push('/session/qr')
                      : null,
                ),
                onTap: () {},
              ).animate().fadeIn(delay: 230.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Session Type Card ────────────────────────────────────────────────────────

class _SessionTypeCard extends StatelessWidget {
  final String emoji;
  final String label;
  final Color labelColor;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final bool expanded;
  final Widget? expandedContent;
  final VoidCallback onTap;

  const _SessionTypeCard({
    required this.emoji,
    required this.label,
    required this.labelColor,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    this.expanded = false,
    this.expandedContent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: expanded ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CR.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          color: labelColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          color: CR.t1,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          color: CR.t2,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.inter(
                      color: badgeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (expanded && expandedContent != null) ...[
              const SizedBox(height: 20),
              expandedContent!,
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Casual Overs Selector ────────────────────────────────────────────────────

class _CasualOversSelector extends StatelessWidget {
  final int? selected;
  final List<int> options;
  final ValueChanged<int> onSelect;
  final VoidCallback onCustom;
  final VoidCallback? onStart;
  final _BallType ballType;
  final ValueChanged<_BallType> onBallType;

  const _CasualOversSelector({
    required this.selected,
    required this.options,
    required this.onSelect,
    required this.onCustom,
    required this.onStart,
    required this.ballType,
    required this.onBallType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HOW MANY OVERS?',
          style: GoogleFonts.inter(
            color: CR.t3,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ...options.map((o) {
              final sel = selected == o;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onSelect(o),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 48,
                      decoration: BoxDecoration(
                        color: sel ? CR.green : CR.cardHigh,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '$o',
                          style: GoogleFonts.spaceGrotesk(
                            color: sel ? CR.inv : CR.t2,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
            Expanded(
              child: GestureDetector(
                onTap: onCustom,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 48,
                  decoration: BoxDecoration(
                    color: selected == 0 ? CR.green : CR.cardHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'CUST',
                      style: GoogleFonts.inter(
                        color: selected == 0 ? CR.inv : CR.t2,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Ball type selector
        Text(
          'BALL TYPE',
          style: GoogleFonts.inter(
            color: CR.t3,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _BallTypeButton(
              emoji: '🔴',
              label: 'LEATHER',
              weight: '1.0×',
              selected: ballType == _BallType.leather,
              onTap: () => onBallType(_BallType.leather),
            ),
            const SizedBox(width: 8),
            _BallTypeButton(
              emoji: '🎾',
              label: 'TENNIS',
              weight: '0.8×',
              selected: ballType == _BallType.tennis,
              onTap: () => onBallType(_BallType.tennis),
            ),
            const SizedBox(width: 8),
            _BallTypeButton(
              emoji: '⬛',
              label: 'TAPE',
              weight: '0.7×',
              selected: ballType == _BallType.tape,
              onTap: () => onBallType(_BallType.tape),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: onStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: onStart != null ? CR.green : CR.cardHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              onStart != null ? 'START CASUAL SESSION →' : 'SELECT OVERS FIRST',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: onStart != null ? CR.inv : CR.t3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Ball Type Button ─────────────────────────────────────────────────────────

class _BallTypeButton extends StatelessWidget {
  final String emoji;
  final String label;
  final String weight;
  final bool selected;
  final VoidCallback onTap;

  const _BallTypeButton({
    required this.emoji,
    required this.label,
    required this.weight,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? CR.green.withOpacity(0.12) : CR.cardHigh,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? CR.green : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: selected ? CR.green : CR.t2,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'OVR $weight',
                style: GoogleFonts.inter(
                  color: CR.t3,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
