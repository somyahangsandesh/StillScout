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

/// Player's home country (heritage).
class HomeCountry {
  final String code;
  final String name;
  final String flag;

  const HomeCountry({required this.code, required this.name, required this.flag});
}

class SquadInfo {
  final String id;
  final String name;
  final String cityId;
  final String countryCode;
  final String homeCountryCode;
  final String venue;
  final String inviteSlug;

  const SquadInfo({
    required this.id,
    required this.name,
    required this.cityId,
    required this.countryCode,
    required this.homeCountryCode,
    required this.venue,
    required this.inviteSlug,
  });

  String get locationLabel {
    final country = DiasporaData.countryByCode(countryCode);
    final city = DiasporaData.cityById(cityId);
    if (country == null || city == null) return '';
    return '${city.name}, ${country.name}';
  }

  String get heritageLabel {
    return DiasporaData.homeCountryByCode(homeCountryCode)?.name ?? 'Open';
  }
}

class DiasporaData {
  DiasporaData._();

  static const homeCountries = [
    HomeCountry(code: 'NP', name: 'Nepal', flag: '🇳🇵'),
    HomeCountry(code: 'IN', name: 'India', flag: '🇮🇳'),
    HomeCountry(code: 'PK', name: 'Pakistan', flag: '🇵🇰'),
    HomeCountry(code: 'BD', name: 'Bangladesh', flag: '🇧🇩'),
    HomeCountry(code: 'LK', name: 'Sri Lanka', flag: '🇱🇰'),
    HomeCountry(code: 'AF', name: 'Afghanistan', flag: '🇦🇫'),
    HomeCountry(code: 'BT', name: 'Bhutan', flag: '🇧🇹'),
    HomeCountry(code: 'MV', name: 'Maldives', flag: '🇲🇻'),
    HomeCountry(code: 'OTHER', name: 'Other', flag: '🏏'),
  ];

  static const countries = [
    HostCountry(
      code: 'JP',
      name: 'Japan',
      flag: '🇯🇵',
      cities: [
        HostCity(id: 'tokyo', name: 'Tokyo', sundayMatchCount: 18),
        HostCity(id: 'yokohama', name: 'Yokohama', sundayMatchCount: 8),
        HostCity(id: 'osaka', name: 'Osaka', sundayMatchCount: 9),
        HostCity(id: 'nagoya', name: 'Nagoya', sundayMatchCount: 6),
        HostCity(id: 'fukuoka', name: 'Fukuoka', sundayMatchCount: 7),
        HostCity(id: 'sapporo', name: 'Sapporo', sundayMatchCount: 4),
        HostCity(id: 'hiroshima', name: 'Hiroshima', sundayMatchCount: 5),
        HostCity(id: 'kobe', name: 'Kobe', sundayMatchCount: 6),
        HostCity(id: 'kyoto', name: 'Kyoto', sundayMatchCount: 4),
        HostCity(id: 'okinawa', name: 'Okinawa', sundayMatchCount: 11),
        HostCity(id: 'sano', name: 'Sano', sundayMatchCount: 5),
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
        HostCity(id: 'perth', name: 'Perth', sundayMatchCount: 12),
        HostCity(id: 'adelaide', name: 'Adelaide', sundayMatchCount: 9),
        HostCity(id: 'canberra', name: 'Canberra', sundayMatchCount: 5),
        HostCity(id: 'gold_coast', name: 'Gold Coast', sundayMatchCount: 8),
        HostCity(id: 'darwin', name: 'Darwin', sundayMatchCount: 3),
        HostCity(id: 'hobart', name: 'Hobart', sundayMatchCount: 4),
        HostCity(id: 'newcastle_au', name: 'Newcastle', sundayMatchCount: 6),
      ],
    ),
    HostCountry(
      code: 'CA',
      name: 'Canada',
      flag: '🇨🇦',
      cities: [
        HostCity(id: 'toronto', name: 'Toronto', sundayMatchCount: 22),
        HostCity(id: 'mississauga', name: 'Mississauga', sundayMatchCount: 14),
        HostCity(id: 'brampton', name: 'Brampton', sundayMatchCount: 12),
        HostCity(id: 'vancouver', name: 'Vancouver', sundayMatchCount: 11),
        HostCity(id: 'surrey', name: 'Surrey', sundayMatchCount: 9),
        HostCity(id: 'montreal', name: 'Montreal', sundayMatchCount: 8),
        HostCity(id: 'calgary', name: 'Calgary', sundayMatchCount: 7),
        HostCity(id: 'edmonton', name: 'Edmonton', sundayMatchCount: 6),
        HostCity(id: 'ottawa', name: 'Ottawa', sundayMatchCount: 5),
        HostCity(id: 'winnipeg', name: 'Winnipeg', sundayMatchCount: 4),
        HostCity(id: 'halifax', name: 'Halifax', sundayMatchCount: 3),
      ],
    ),
    HostCountry(
      code: 'GB',
      name: 'United Kingdom',
      flag: '🇬🇧',
      cities: [
        HostCity(id: 'london', name: 'London', sundayMatchCount: 41),
        HostCity(id: 'manchester', name: 'Manchester', sundayMatchCount: 19),
        HostCity(id: 'birmingham', name: 'Birmingham', sundayMatchCount: 16),
        HostCity(id: 'leeds', name: 'Leeds', sundayMatchCount: 12),
        HostCity(id: 'leicester', name: 'Leicester', sundayMatchCount: 14),
        HostCity(id: 'bradford', name: 'Bradford', sundayMatchCount: 11),
        HostCity(id: 'glasgow', name: 'Glasgow', sundayMatchCount: 8),
        HostCity(id: 'edinburgh', name: 'Edinburgh', sundayMatchCount: 5),
        HostCity(id: 'cardiff', name: 'Cardiff', sundayMatchCount: 4),
        HostCity(id: 'bristol', name: 'Bristol', sundayMatchCount: 6),
        HostCity(id: 'nottingham', name: 'Nottingham', sundayMatchCount: 7),
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
        HostCity(id: 'new_york', name: 'New York', sundayMatchCount: 14),
        HostCity(id: 'new_jersey', name: 'New Jersey', sundayMatchCount: 11),
        HostCity(id: 'chicago', name: 'Chicago', sundayMatchCount: 10),
        HostCity(id: 'los_angeles', name: 'Los Angeles', sundayMatchCount: 8),
        HostCity(id: 'seattle', name: 'Seattle', sundayMatchCount: 6),
        HostCity(id: 'atlanta', name: 'Atlanta', sundayMatchCount: 7),
        HostCity(id: 'phoenix', name: 'Phoenix', sundayMatchCount: 5),
        HostCity(id: 'boston', name: 'Boston', sundayMatchCount: 4),
        HostCity(id: 'austin', name: 'Austin', sundayMatchCount: 5),
      ],
    ),
    HostCountry(
      code: 'AE',
      name: 'UAE',
      flag: '🇦🇪',
      cities: [
        HostCity(id: 'dubai', name: 'Dubai', sundayMatchCount: 52),
        HostCity(id: 'abu_dhabi', name: 'Abu Dhabi', sundayMatchCount: 24),
        HostCity(id: 'sharjah', name: 'Sharjah', sundayMatchCount: 18),
        HostCity(id: 'ajman', name: 'Ajman', sundayMatchCount: 8),
        HostCity(id: 'al_ain', name: 'Al Ain', sundayMatchCount: 6),
      ],
    ),
    HostCountry(
      code: 'QA',
      name: 'Qatar',
      flag: '🇶🇦',
      cities: [
        HostCity(id: 'doha', name: 'Doha', sundayMatchCount: 22),
        HostCity(id: 'al_wakrah', name: 'Al Wakrah', sundayMatchCount: 6),
      ],
    ),
    HostCountry(
      code: 'MY',
      name: 'Malaysia',
      flag: '🇲🇾',
      cities: [
        HostCity(id: 'kuala_lumpur', name: 'Kuala Lumpur', sundayMatchCount: 18),
        HostCity(id: 'penang', name: 'Penang', sundayMatchCount: 8),
        HostCity(id: 'johor', name: 'Johor Bahru', sundayMatchCount: 6),
      ],
    ),
    HostCountry(
      code: 'SG',
      name: 'Singapore',
      flag: '🇸🇬',
      cities: [
        HostCity(id: 'singapore', name: 'Singapore', sundayMatchCount: 12),
      ],
    ),
    HostCountry(
      code: 'NZ',
      name: 'New Zealand',
      flag: '🇳🇿',
      cities: [
        HostCity(id: 'auckland', name: 'Auckland', sundayMatchCount: 14),
        HostCity(id: 'wellington', name: 'Wellington', sundayMatchCount: 6),
        HostCity(id: 'christchurch', name: 'Christchurch', sundayMatchCount: 5),
      ],
    ),
    HostCountry(
      code: 'SA',
      name: 'Saudi Arabia',
      flag: '🇸🇦',
      cities: [
        HostCity(id: 'riyadh', name: 'Riyadh', sundayMatchCount: 10),
        HostCity(id: 'jeddah', name: 'Jeddah', sundayMatchCount: 12),
        HostCity(id: 'dammam', name: 'Dammam', sundayMatchCount: 6),
      ],
    ),
  ];

  static const defaultSquad = SquadInfo(
    id: 'warriors',
    name: 'Okinawa Warriors',
    cityId: 'okinawa',
    countryCode: 'JP',
    homeCountryCode: 'NP',
    venue: 'Yomitan Ground',
    inviteSlug: 'warriors-okinawa',
  );

  static HomeCountry? homeCountryByCode(String code) {
    for (final c in homeCountries) {
      if (c.code == code) return c;
    }
    return null;
  }

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
