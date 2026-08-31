/// Diaspora cricket geography — host country → city → squad.
class HostCountry {
  final String code;
  final String name;
  final String flag;
  final List<HostCity> cities;

  const HostCountry({
    required this.code,
    required this.name,
    required this.flag,
    required this.cities,
  });
}

class HostCity {
  final String id;
  final String name;
  final int sundayMatchCount;

  const HostCity({
    required this.id,
    required this.name,
    this.sundayMatchCount = 0,
  });
}

enum HeritageTag { nepali, indian, pakistani, mixed, open }

extension HeritageTagLabel on HeritageTag {
  String get label => switch (this) {
        HeritageTag.nepali => 'Nepali',
        HeritageTag.indian => 'Indian',
        HeritageTag.pakistani => 'Pakistani',
        HeritageTag.mixed => 'Mixed',
        HeritageTag.open => 'Open',
      };
}

class SquadInfo {
  final String id;
  final String name;
  final String cityId;
  final String countryCode;
  final HeritageTag heritage;
  final String venue;
  final String inviteSlug;

  const SquadInfo({
    required this.id,
    required this.name,
    required this.cityId,
    required this.countryCode,
    required this.heritage,
    required this.venue,
    required this.inviteSlug,
  });

  String get locationLabel {
    final country = DiasporaData.countryByCode(countryCode);
    final city = DiasporaData.cityById(cityId);
    if (country == null || city == null) return '';
    return '${city.name}, ${country.name}';
  }
}

class DiasporaData {
  DiasporaData._();

  static const countries = [
    HostCountry(
      code: 'JP',
      name: 'Japan',
      flag: '🇯🇵',
      cities: [
        HostCity(id: 'okinawa', name: 'Okinawa', sundayMatchCount: 11),
        HostCity(id: 'tokyo', name: 'Tokyo', sundayMatchCount: 18),
        HostCity(id: 'osaka', name: 'Osaka', sundayMatchCount: 9),
      ],
    ),
    HostCountry(
      code: 'AU',
      name: 'Australia',
      flag: '🇦🇺',
      cities: [
        HostCity(id: 'sydney', name: 'Sydney', sundayMatchCount: 34),
        HostCity(id: 'melbourne', name: 'Melbourne', sundayMatchCount: 28),
        HostCity(id: 'brisbane', name: 'Brisbane', sundayMatchCount: 14),
      ],
    ),
    HostCountry(
      code: 'CA',
      name: 'Canada',
      flag: '🇨🇦',
      cities: [
        HostCity(id: 'toronto', name: 'Toronto', sundayMatchCount: 22),
        HostCity(id: 'vancouver', name: 'Vancouver', sundayMatchCount: 11),
      ],
    ),
    HostCountry(
      code: 'GB',
      name: 'United Kingdom',
      flag: '🇬🇧',
      cities: [
        HostCity(id: 'london', name: 'London', sundayMatchCount: 41),
        HostCity(id: 'manchester', name: 'Manchester', sundayMatchCount: 19),
      ],
    ),
    HostCountry(
      code: 'US',
      name: 'United States',
      flag: '🇺🇸',
      cities: [
        HostCity(id: 'houston', name: 'Houston', sundayMatchCount: 16),
        HostCity(id: 'dallas', name: 'Dallas', sundayMatchCount: 12),
        HostCity(id: 'bay_area', name: 'Bay Area', sundayMatchCount: 9),
      ],
    ),
    HostCountry(
      code: 'AE',
      name: 'UAE',
      flag: '🇦🇪',
      cities: [
        HostCity(id: 'dubai', name: 'Dubai', sundayMatchCount: 52),
        HostCity(id: 'abu_dhabi', name: 'Abu Dhabi', sundayMatchCount: 24),
      ],
    ),
  ];

  static const defaultSquad = SquadInfo(
    id: 'warriors',
    name: 'Okinawa Warriors',
    cityId: 'okinawa',
    countryCode: 'JP',
    heritage: HeritageTag.nepali,
    venue: 'Yomitan Ground',
    inviteSlug: 'warriors-okinawa',
  );

  static HostCountry? countryByCode(String code) {
    for (final c in countries) {
      if (c.code == code) return c;
    }
    return null;
  }

  static HostCity? cityById(String id) {
    for (final c in countries) {
      for (final city in c.cities) {
        if (city.id == id) return city;
      }
    }
    return null;
  }

  static int sundayMatchesInCountry(String code) {
    final country = countryByCode(code);
    if (country == null) return 0;
    return country.cities.fold(0, (sum, c) => sum + c.sundayMatchCount);
  }
}
