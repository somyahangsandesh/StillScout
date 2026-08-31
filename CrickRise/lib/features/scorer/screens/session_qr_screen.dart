import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

class SessionQrScreen extends StatefulWidget {
  const SessionQrScreen({super.key});

  @override
  State<SessionQrScreen> createState() => _SessionQrScreenState();
}

class _SessionQrScreenState extends State<SessionQrScreen> {
  final List<String> _joined = [];

  static const _samplePlayers = [
    'Roshan KC',
    'Bikash Rai',
    'Sandip Gurung',
    'Dev Limbu',
  ];

  @override
  void initState() {
    super.initState();
    _startPlayerJoin();
  }

  Future<void> _startPlayerJoin() async {
    await Future.delayed(const Duration(seconds: 1));
    for (final p in _samplePlayers) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;
      setState(() => _joined.add(p));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CR.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.close, color: CR.t3, size: 22),
                  ),
                  const Spacer(),
                  Text(
                    'SESSION LOBBY',
                    style: GoogleFonts.inter(
                      color: CR.t3,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 22),
                ],
              ).animate().fadeIn(duration: 200.ms),
              const SizedBox(height: 24),

              // Show this to your players label
              Text(
                'SHOW THIS TO YOUR PLAYERS',
                style: GoogleFonts.inter(
                  color: CR.t3,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                ),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 16),

              // QR code placeholder
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: CR.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '▦',
                        style: TextStyle(
                          color: CR.t3,
                          fontSize: 80,
                        ),
                      ),
                      Text(
                        'QR',
                        style: GoogleFonts.spaceGrotesk(
                          color: CR.t3,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 150.ms).scale(begin: const Offset(0.92, 0.92)),
              const SizedBox(height: 24),

              // Players joined list
              Expanded(
                child: _joined.isEmpty
                    ? Center(
                        child: Text(
                          'Waiting for players to scan...',
                          style: GoogleFonts.inter(
                            color: CR.t3,
                            fontSize: 13,
                          ),
                        ).animate().fadeIn(delay: 400.ms),
                      )
                    : ListView.builder(
                        itemCount: _joined.length,
                        itemBuilder: (ctx, i) {
                          return _JoinedRow(name: _joined[i])
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .slideX(begin: -0.05);
                        },
                      ),
              ),

              // Add manually
              GestureDetector(
                onTap: () {},
                child: Text(
                  '+ ADD PLAYER MANUALLY',
                  style: GoogleFonts.inter(
                    color: CR.t3,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Teams Set Up button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _joined.length >= 2
                      ? () => context.push('/session/teams')
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _joined.length >= 2 ? CR.green : CR.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _joined.length >= 2
                        ? 'TEAMS SET UP →  (${_joined.length} players)'
                        : 'WAITING FOR PLAYERS...',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _joined.length >= 2 ? CR.inv : CR.t3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JoinedRow extends StatelessWidget {
  final String name;
  const _JoinedRow({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: CR.green.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: CR.green, size: 14),
          ),
          const SizedBox(width: 12),
          Text(
            '$name joined',
            style: GoogleFonts.inter(
              color: CR.t1,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
