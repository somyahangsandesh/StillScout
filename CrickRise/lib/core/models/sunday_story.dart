import 'community.dart';

/// Post-match share artifact — the core viral unit of CrickRise.
class SundayStory {
  final String id;
  final DateTime matchDate;
  final String squadName;
  final String opponentName;
  final String winnerName;
  final String margin;
  final String squadScore;
  final String opponentScore;
  final String playerOfSunday;
  final String playerStats;
  final String? captainQuote;
  final String cityName;
  final String countryName;
  final String countryFlag;
  final String homeCountryName;
  final String homeCountryFlag;
  final String shareUrl;
  final int storyNumber;

  const SundayStory({
    required this.id,
    required this.matchDate,
    required this.squadName,
    required this.opponentName,
    required this.winnerName,
    required this.margin,
    required this.squadScore,
    required this.opponentScore,
    required this.playerOfSunday,
    required this.playerStats,
    this.captainQuote,
    required this.cityName,
    required this.countryName,
    required this.countryFlag,
    required this.homeCountryName,
    required this.homeCountryFlag,
    required this.shareUrl,
    required this.storyNumber,
  });

  String get headline => '$winnerName beat $opponentName by $margin';

  String get locationLine => '$cityName · $countryName';

  String whatsappCaption() =>
      'Sunday done 🏏 $headline. $playerOfSunday — Player of Sunday ($playerStats). $locationLine · CrickRise';

  String instagramCaption() =>
      'Player of Sunday 🏏 $playerOfSunday — $playerStats\n$headline\n#DiasporaCricket #SundayCricket #CrickRise';

  String facebookCaption() =>
      '$squadName vs $opponentName — $headline\n\n⭐ Player of Sunday: $playerOfSunday ($playerStats)\n📍 $locationLine\n\n$captainQuote';

  static SundayStory sample({SquadInfo? squad}) {
    final s = squad ?? DiasporaData.defaultSquad;
    final country = DiasporaData.countryByCode(s.countryCode)!;
    final city = DiasporaData.cityById(s.cityId)!;
    final home = DiasporaData.homeCountryByCode(s.homeCountryCode)!;
    return SundayStory(
      id: 'story-12',
      matchDate: DateTime.now(),
      squadName: s.name,
      opponentName: 'Tokyo Rhinos',
      winnerName: s.name,
      margin: '4 wickets',
      squadScore: '142/6 (18.2)',
      opponentScore: '138/8 (20)',
      playerOfSunday: 'Roshan KC',
      playerStats: '47*(31)',
      captainQuote: 'Roshan took us home in the 18th over. Proper Sunday.',
      cityName: city.name,
      countryName: country.name,
      countryFlag: country.flag,
      homeCountryName: home.name,
      homeCountryFlag: home.flag,
      shareUrl: 'https://crickrise.app/s/${s.inviteSlug}',
      storyNumber: 12,
    );
  }
}
