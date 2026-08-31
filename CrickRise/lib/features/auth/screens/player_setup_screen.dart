import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/community.dart';
import '../../../core/providers/app_context_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/cr_matchday.dart';

class PlayerSetupScreen extends ConsumerStatefulWidget {
  const PlayerSetupScreen({super.key});

  @override
  ConsumerState<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends ConsumerState<PlayerSetupScreen> {
  final _name = TextEditingController();
  String? _role;
  String _jersey = '';
  String _countryCode = 'JP';
  String _cityId = 'okinawa';
  HeritageTag _heritage = HeritageTag.nepali;

  static const _roles = ['BATTER', 'BOWLER', 'ALL-ROUNDER', 'KEEPER', 'BAT AR'];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _ok => _name.text.trim().isNotEmpty && _role != null;

  @override
  Widget build(BuildContext context) {
    final country = DiasporaData.countryByCode(_countryCode)!;

    return Scaffold(
      backgroundColor: CR.bg,
      body: CRProgrammeBg(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Where do you\nplay Sunday?', style: CRType.display(size: 34)),
                const SizedBox(height: 8),
                Text('Diaspora cricket — Japan, Australia, Canada & more.', style: CRType.caption()),
                const SizedBox(height: 28),
                Text('HOST COUNTRY', style: CRType.overline()),
                const SizedBox(height: 10),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: DiasporaData.countries.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final c = DiasporaData.countries[i];
                      final on = c.code == _countryCode;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _countryCode = c.code;
                          _cityId = c.cities.first.id;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: on ? CR.terracotta : CR.card,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: on ? CR.terracotta : CR.fog.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '${c.flag} ${c.name}',
                            style: CRType.label(size: 12, color: on ? CR.chalk : CR.ink),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Text('CITY', style: CRType.overline()),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: country.cities.map((city) {
                    final on = city.id == _cityId;
                    return GestureDetector(
                      onTap: () => setState(() => _cityId = city.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: on ? CR.moss : CR.card,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: on ? CR.mossLight : CR.fog.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          city.name,
                          style: CRType.overline(size: 8, color: on ? CR.chalk : CR.ink),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Text('HERITAGE (optional)', style: CRType.overline()),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: HeritageTag.values.map((h) {
                    final on = h == _heritage;
                    return GestureDetector(
                      onTap: () => setState(() => _heritage = h),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: on ? CR.brassDim : CR.card,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: on ? CR.brass : CR.fog.withValues(alpha: 0.3)),
                        ),
                        child: Text(h.label, style: CRType.overline(size: 8, color: on ? CR.brass : CR.ink)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),
                const CRProgrammeRule(label: 'Your passport'),
                const SizedBox(height: 20),
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
                const SizedBox(height: 24),
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
                const SizedBox(height: 24),
                Text('JERSEY (optional)', style: CRType.overline()),
                const SizedBox(height: 8),
                Center(child: Text(_jersey.isEmpty ? '—' : _jersey, style: CRType.score(size: 40))),
                const SizedBox(height: 8),
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
                  label: 'Continue',
                  onTap: _ok
                      ? () {
                          ref.read(appContextProvider.notifier)
                            ..setLocation(_countryCode, _cityId)
                            ..setHeritage(_heritage);
                          context.push('/auth/join-or-build');
                        }
                      : null,
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
