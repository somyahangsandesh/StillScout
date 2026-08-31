import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/community.dart';
import '../models/sunday_story.dart';

class AppContext {
  final String countryCode;
  final String cityId;
  final SquadInfo squad;
  final String homeCountryCode;

  const AppContext({
    required this.countryCode,
    required this.cityId,
    required this.squad,
    required this.homeCountryCode,
  });

  HostCountry get country => DiasporaData.countryByCode(countryCode)!;
  HostCity get city => DiasporaData.cityById(cityId)!;
  HomeCountry get homeCountry => DiasporaData.homeCountryByCode(homeCountryCode)!;

  int get sundayMatchesNearby => DiasporaData.sundayMatchesInCountry(countryCode);

  AppContext copyWith({
    String? countryCode,
    String? cityId,
    SquadInfo? squad,
    String? homeCountryCode,
  }) {
    return AppContext(
      countryCode: countryCode ?? this.countryCode,
      cityId: cityId ?? this.cityId,
      squad: squad ?? this.squad,
      homeCountryCode: homeCountryCode ?? this.homeCountryCode,
    );
  }
}

class AppContextNotifier extends StateNotifier<AppContext> {
  AppContextNotifier()
      : super(const AppContext(
          countryCode: 'JP',
          cityId: 'okinawa',
          squad: DiasporaData.defaultSquad,
          homeCountryCode: 'NP',
        ));

  void setLocation(String countryCode, String cityId) {
    final country = DiasporaData.countryByCode(countryCode);
    if (country == null || country.cities.isEmpty) return;
    final city = country.cities.any((c) => c.id == cityId)
        ? cityId
        : country.cities.first.id;
    state = state.copyWith(countryCode: countryCode, cityId: city);
  }

  void setCountry(String countryCode) {
    final country = DiasporaData.countryByCode(countryCode);
    if (country == null) return;
    state = state.copyWith(
      countryCode: countryCode,
      cityId: country.cities.first.id,
    );
  }

  void setHomeCountry(String code) {
    state = state.copyWith(homeCountryCode: code);
  }
}

final appContextProvider =
    StateNotifierProvider<AppContextNotifier, AppContext>((ref) {
  return AppContextNotifier();
});

enum PollStatus { in_, maybe, out }

class PollPlayer {
  final String name;
  final PollStatus status;

  const PollPlayer(this.name, this.status);
}

final sundayPollProvider = StateProvider<List<PollPlayer>>((ref) {
  return const [
    PollPlayer('Roshan KC', PollStatus.in_),
    PollPlayer('Bikash Rai', PollStatus.in_),
    PollPlayer('Anil Tamang', PollStatus.in_),
    PollPlayer('Sandip Gurung', PollStatus.maybe),
    PollPlayer('Dev Limbu', PollStatus.in_),
    PollPlayer('Amit KC', PollStatus.out),
    PollPlayer('Prakash Rai', PollStatus.maybe),
    PollPlayer('Suman Thapa', PollStatus.in_),
  ];
});

final lastSundayStoryProvider = Provider<SundayStory>((ref) {
  final ctx = ref.watch(appContextProvider);
  return SundayStory.sample(squad: ctx.squad);
});
