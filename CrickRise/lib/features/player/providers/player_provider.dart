import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/player.dart';

final currentPlayerProvider = Provider<Player>((ref) {
  return SampleData.samplePlayer;
});

final currentPlayerRatingProvider = Provider<PlayerRating>((ref) {
  return SampleData.sampleRating;
});

final currentPlayerStatsProvider = Provider<PlayerStats>((ref) {
  return SampleData.sampleStats;
});

final rivalProvider = Provider<Player>((ref) {
  return SampleData.rival;
});

final rivalRatingProvider = Provider<PlayerRating>((ref) {
  return SampleData.rivalRating;
});

final belowPlayerProvider = Provider<Player>((ref) {
  return SampleData.below;
});

final belowPlayerRatingProvider = Provider<PlayerRating>((ref) {
  return SampleData.belowRating;
});
