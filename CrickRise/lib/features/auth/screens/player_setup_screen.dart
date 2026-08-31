import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/cr_matchday.dart';

class PlayerSetupScreen extends StatefulWidget {
  const PlayerSetupScreen({super.key});

  @override
  State<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends State<PlayerSetupScreen> {
  final _name = TextEditingController();
  String? _role;
  String _jersey = '';

  static const _roles = ['BATTER', 'BOWLER', 'ALL-ROUNDER', 'KEEPER', 'BAT AR'];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _ok => _name.text.trim().isNotEmpty && _role != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CR.bg,
      body: CRProgrammeBg(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Issue your\npassport.', style: CRType.display(size: 36)),
                const SizedBox(height: 8),
                Text('This is your permanent cricket identity.', style: CRType.caption()),
                const SizedBox(height: 32),
                Text('FULL NAME', style: CRType.overline()),
                const SizedBox(height: 8),
                TextField(
                  controller: _name,
                  onChanged: (_) => setState(() {}),
                  style: CRType.body(size: 18, weight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Roshan KC',
                    hintStyle: CRType.caption(color: CR.fog),
                    border: UnderlineInputBorder(borderSide: BorderSide(color: CR.chalk.withValues(alpha: 0.2))),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: CR.chalk.withValues(alpha: 0.2))),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: CR.brass, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 28),
                Text('ROLE', style: CRType.overline()),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _roles.map((r) {
                    final on = _role == r;
                    return GestureDetector(
                      onTap: () => setState(() => _role = r),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: on ? CR.terracotta : CR.card,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: on ? CR.terracotta : CR.fog.withValues(alpha: 0.3)),
                        ),
                        child: Text(r, style: CRType.overline(size: 8, color: on ? CR.chalk : CR.ink)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),
                Text('JERSEY (optional)', style: CRType.overline()),
                const SizedBox(height: 12),
                Center(child: Text(_jersey.isEmpty ? '—' : _jersey, style: CRType.score(size: 48))),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    ...['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'].map((d) => _Digit(d, () {
                          if (_jersey.length < 2) setState(() => _jersey += d);
                        })),
                    _Digit('⌫', () {
                      if (_jersey.isNotEmpty) setState(() => _jersey = _jersey.substring(0, _jersey.length - 1));
                    }),
                  ],
                ),
                const SizedBox(height: 36),
                CRProgrammeButton(
                  label: 'Create passport',
                  onTap: _ok ? () => context.push('/auth/join-or-build') : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Digit extends StatelessWidget {
  final String d;
  final VoidCallback tap;
  const _Digit(this.d, this.tap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: tap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: CR.card,
          border: Border.all(color: CR.chalk.withValues(alpha: 0.08)),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(d, style: CRType.score(size: 16, color: CR.ink)),
      ),
    );
  }
}
