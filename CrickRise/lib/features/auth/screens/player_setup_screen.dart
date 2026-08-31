import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/community.dart';
import '../../../core/providers/app_context_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/cr_matchday.dart';
import '../../../core/widgets/cr_select_sheet.dart';

class PlayerSetupScreen extends ConsumerStatefulWidget {
  const PlayerSetupScreen({super.key});

  @override
  ConsumerState<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends ConsumerState<PlayerSetupScreen> {
  final _name = TextEditingController();
  String? _role;
  String _jersey = '';
  String _hostCountryCode = 'JP';
  String _cityId = 'okinawa';
  String _homeCountryCode = 'NP';

  static const _roles = ['BATTER', 'BOWLER', 'ALL-ROUNDER', 'KEEPER', 'BAT AR'];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _ok => _name.text.trim().isNotEmpty && _role != null;

  HostCountry get _host => DiasporaData.countryByCode(_hostCountryCode)!;
  HostCity get _city => DiasporaData.cityById(_cityId)!;
  HomeCountry get _home => DiasporaData.homeCountryByCode(_homeCountryCode)!;

  Future<void> _pickHostCountry() async {
    final picked = await showCRSelectSheet<String>(
      context: context,
      title: 'Where do you play?',
      selected: _hostCountryCode,
      items: DiasporaData.countries
          .map((c) => CRSelectItem(
                value: c.code,
                label: c.name,
                leading: c.flag,
                subtitle: '${c.cities.length} cities · ${DiasporaData.sundayMatchesInCountry(c.code)} Sunday matches',
              ))
          .toList(),
    );
    if (picked != null) {
      final country = DiasporaData.countryByCode(picked)!;
      setState(() {
        _hostCountryCode = picked;
        _cityId = country.cities.first.id;
      });
    }
  }

  Future<void> _pickCity() async {
    final picked = await showCRSelectSheet<String>(
      context: context,
      title: 'Your city',
      selected: _cityId,
      items: _host.cities
          .map((c) => CRSelectItem(
                value: c.id,
                label: c.name,
                subtitle: '${c.sundayMatchCount} Sunday matches nearby',
              ))
          .toList(),
    );
    if (picked != null) setState(() => _cityId = picked);
  }

  Future<void> _pickHomeCountry() async {
    final picked = await showCRSelectSheet<String>(
      context: context,
      title: 'Your home country',
      selected: _homeCountryCode,
      items: DiasporaData.homeCountries
          .map((c) => CRSelectItem(
                value: c.code,
                label: c.name,
                leading: c.flag,
                subtitle: 'Heritage & identity on your passport',
              ))
          .toList(),
    );
    if (picked != null) setState(() => _homeCountryCode = picked);
  }

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
                Text('Where do you\nplay Sunday?', style: CRType.display(size: 34)),
                const SizedBox(height: 8),
                Text('Diaspora cricket across Japan, Australia, UK, Canada, USA & more.', style: CRType.caption()),
                const SizedBox(height: 24),
                CRSelectField(
                  label: 'Host country',
                  value: _host.name,
                  leading: _host.flag,
                  subtitle: 'Where you live and play cricket abroad',
                  onTap: _pickHostCountry,
                ),
                const SizedBox(height: 12),
                CRSelectField(
                  label: 'City',
                  value: _city.name,
                  subtitle: '${_city.sundayMatchCount} Sunday matches in this city',
                  onTap: _pickCity,
                ),
                const SizedBox(height: 12),
                CRSelectField(
                  label: 'Home country',
                  value: _home.name,
                  leading: _home.flag,
                  subtitle: 'Nepal, India, Pakistan & South Asia',
                  onTap: _pickHomeCountry,
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
                            ..setLocation(_hostCountryCode, _cityId)
                            ..setHomeCountry(_homeCountryCode);
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
