import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

// The single valid access code for V1.
// Change this to control who can become an organiser.
const String _kOrganizerAccessCode = 'CRICKRISE-ORG';

class OrganizerAccessScreen extends StatefulWidget {
  const OrganizerAccessScreen({super.key});

  @override
  State<OrganizerAccessScreen> createState() => _OrganizerAccessScreenState();
}

class _OrganizerAccessScreenState extends State<OrganizerAccessScreen> {
  // Tab: 0 = enter code, 1 = apply
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CR.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back
              GestureDetector(
                onTap: () => context.pop(),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back_ios, color: CR.t3, size: 14),
                    const SizedBox(width: 4),
                    Text('Back', style: GoogleFonts.inter(color: CR.t3, fontSize: 13)),
                  ],
                ),
              ).animate().fadeIn(),
              const SizedBox(height: 28),

              Text(
                'Organiser Access',
                style: GoogleFonts.inter(color: CR.t1, fontSize: 24, fontWeight: FontWeight.w700),
              ).animate().fadeIn(delay: 80.ms),
              const SizedBox(height: 8),
              Text(
                'Creating leagues requires approval to keep communities genuine.',
                style: GoogleFonts.inter(color: CR.t2, fontSize: 14, height: 1.4),
              ).animate().fadeIn(delay: 120.ms),
              const SizedBox(height: 28),

              // Tab toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: CR.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _TabBtn(label: 'I have a code', active: _tab == 0, onTap: () => setState(() => _tab = 0)),
                    const SizedBox(width: 4),
                    _TabBtn(label: 'Request access', active: _tab == 1, onTap: () => setState(() => _tab = 1)),
                  ],
                ),
              ).animate().fadeIn(delay: 160.ms),
              const SizedBox(height: 24),

              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _tab == 0
                      ? const _CodeEntryView(key: ValueKey('code'))
                      : const _RequestView(key: ValueKey('req')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tab Button ───────────────────────────────────────────────────────────────

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 40,
          decoration: BoxDecoration(
            color: active ? CR.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: active ? CR.inv : CR.t3,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Code Entry View ──────────────────────────────────────────────────────────

class _CodeEntryView extends StatefulWidget {
  const _CodeEntryView({super.key});
  @override
  State<_CodeEntryView> createState() => _CodeEntryViewState();
}

class _CodeEntryViewState extends State<_CodeEntryView> {
  final _ctrl = TextEditingController();
  bool _wrong = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _ctrl.text.trim().toUpperCase();
    if (code == _kOrganizerAccessCode) {
      context.go('/organizer?new=true');
    } else {
      setState(() => _wrong = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _wrong = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ORGANISER ACCESS CODE',
          style: GoogleFonts.inter(color: CR.t3, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _ctrl,
          style: GoogleFonts.spaceGrotesk(
            color: _wrong ? CR.red : CR.t1,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'CRICKRISE-ORG-XXXX',
            hintStyle: GoogleFonts.spaceGrotesk(color: CR.t3, fontSize: 14, letterSpacing: 1),
            filled: true,
            fillColor: CR.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _wrong ? CR.red : CR.gold, width: 2),
            ),
            errorText: _wrong ? 'Invalid code — check with your CrickRise contact' : null,
            errorStyle: GoogleFonts.inter(color: CR.red, fontSize: 12),
          ),
          onChanged: (_) => setState(() => _wrong = false),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 8),
        Text(
          'Your access code is provided by the CrickRise team.',
          style: GoogleFonts.inter(color: CR.t3, fontSize: 12),
        ),
        const SizedBox(height: 24),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _ctrl,
          builder: (_, val, __) {
            final enabled = val.text.trim().length > 4;
            return SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: enabled ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: enabled ? CR.gold : CR.card,
                  foregroundColor: CR.inv,
                  disabledForegroundColor: CR.t3,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'UNLOCK ORGANISER ACCESS',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: enabled ? CR.inv : CR.t3,
                  ),
                ),
              ),
            );
          },
        ),
        const Spacer(),
        // Hint to request if no code
        Center(
          child: GestureDetector(
            onTap: () {},
            child: Text(
              "Don't have a code? Switch to 'Request access' above.",
              style: GoogleFonts.inter(color: CR.t3, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Request View ─────────────────────────────────────────────────────────────

class _RequestView extends StatefulWidget {
  const _RequestView({super.key});
  @override
  State<_RequestView> createState() => _RequestViewState();
}

class _RequestViewState extends State<_RequestView> {
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nameCtrl.text.trim().length > 2 &&
      _cityCtrl.text.trim().length > 1;

  void _submit() {
    // V1: just show the pending state
    // In production: send request to backend, email to admin
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return const _PendingView();
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Field(label: 'YOUR NAME', hint: 'Roshan KC', ctrl: _nameCtrl),
          const SizedBox(height: 16),
          _Field(label: 'YOUR CITY / COMMUNITY', hint: 'Okinawa, Japan', ctrl: _cityCtrl),
          const SizedBox(height: 16),
          _Field(
            label: 'TELL US ABOUT YOUR LEAGUE (OPTIONAL)',
            hint: 'e.g. We run a Nepali cricket community in Okinawa with 8 teams...',
            ctrl: _reasonCtrl,
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          ListenableBuilder(
            listenable: Listenable.merge([_nameCtrl, _cityCtrl]),
            builder: (_, __) => SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canSubmit ? CR.gold : CR.card,
                  foregroundColor: CR.inv,
                  disabledForegroundColor: CR.t3,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'SEND REQUEST',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _canSubmit ? CR.inv : CR.t3,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We review all requests personally and respond within 24 hours.',
            style: GoogleFonts.inter(color: CR.t3, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Pending State ────────────────────────────────────────────────────────────

class _PendingView extends StatelessWidget {
  const _PendingView();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: CR.gold.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.schedule_rounded, color: CR.gold, size: 36),
        )
            .animate()
            .scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut, duration: 600.ms)
            .fadeIn(),
        const SizedBox(height: 24),
        Text(
          'Request sent.',
          style: GoogleFonts.inter(color: CR.t1, fontSize: 22, fontWeight: FontWeight.w800),
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 8),
        Text(
          'We review every organiser request personally.\nYou\'ll hear back within 24 hours.',
          style: GoogleFonts.inter(color: CR.t2, fontSize: 14, height: 1.5),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 8),
        Text(
          'In the meantime you can join a league as a player.',
          style: GoogleFonts.inter(color: CR.t3, fontSize: 13),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 500.ms),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => context.go('/home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: CR.green,
              foregroundColor: CR.inv,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'ENTER APP AS PLAYER',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: CR.inv),
            ),
          ),
        ).animate().fadeIn(delay: 600.ms),
      ],
    );
  }
}

// ─── Field Helper ─────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController ctrl;
  final int maxLines;

  const _Field({
    required this.label,
    required this.hint,
    required this.ctrl,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: CR.t3, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: GoogleFonts.inter(color: CR.t1, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: CR.t3, fontSize: 14),
            filled: true,
            fillColor: CR.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: CR.gold, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
