import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  final _ctrl = TextEditingController();
  bool _hasCode = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final has = _ctrl.text.trim().length >= 4;
      if (has != _hasCode) setState(() => _hasCode = has);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

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
              GestureDetector(
                onTap: () => context.pop(),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back_ios, color: CR.t3, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Back',
                      style: GoogleFonts.inter(color: CR.t3, fontSize: 13),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 200.ms),
              const SizedBox(height: 28),

              Text(
                'Enter your invite code',
                style: GoogleFonts.inter(
                  color: CR.t1,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 8),
              Text(
                'Your organizer will share this with you',
                style: GoogleFonts.inter(color: CR.t2, fontSize: 14),
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 48),

              // Large centered code input
              Center(
                child: SizedBox(
                  width: 240,
                  child: TextField(
                    controller: _ctrl,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    style: GoogleFonts.spaceGrotesk(
                      color: CR.t1,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      hintText: '— — — —',
                      hintStyle: GoogleFonts.spaceGrotesk(
                        color: CR.t3,
                        fontSize: 28,
                        letterSpacing: 4,
                      ),
                      border: InputBorder.none,
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: CR.t3, width: 1.5),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: CR.green, width: 2),
                      ),
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    maxLength: 8,
                    buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _hasCode ? () => context.go('/home') : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasCode ? CR.green : CR.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'JOIN LEAGUE',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: 1,
                      color: _hasCode ? CR.inv : CR.t3,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 16),

              Center(
                child: GestureDetector(
                  onTap: () => context.go('/home'),
                  child: Text(
                    "Skip — I'll join later",
                    style: GoogleFonts.inter(
                      color: CR.t3,
                      fontSize: 14,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 350.ms),
            ],
          ),
        ),
      ),
    );
  }
}
