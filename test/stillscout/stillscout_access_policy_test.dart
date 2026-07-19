import 'package:flutter_test/flutter_test.dart';
import 'package:stillscout/stillscout/data/models/extracted_frame.dart';
import 'package:stillscout/stillscout/data/models/frame_score_metadata.dart';
import 'package:stillscout/stillscout/data/models/scored_frame.dart';
import 'package:stillscout/stillscout/domain/stillscout_access_policy.dart';
import 'package:stillscout/stillscout/domain/stillscout_constants.dart';

void main() {
  group('StillScoutAccessPolicy', () {
    test('keeper limits differ by tier', () {
      expect(
        StillScoutAccessPolicy.keeperLimit(isPro: false),
        StillScoutConstants.freeKeeperLimit,
      );
      expect(
        StillScoutAccessPolicy.keeperLimit(isPro: true),
        StillScoutConstants.proKeeperLimit,
      );
    });

    test('first-scout bonus unlocks 8 keepers for free users', () {
      expect(
        StillScoutAccessPolicy.keeperLimit(isPro: false, isFirstScout: true),
        StillScoutConstants.freeKeeperLimit +
            StillScoutConstants.firstScoutBonusKeepers,
      );
      expect(
        StillScoutAccessPolicy.canViewFrame(
          rank: 7,
          isPro: false,
          isFirstScout: true,
        ),
        isTrue,
      );
      expect(
        StillScoutAccessPolicy.canViewFrame(
          rank: 8,
          isPro: false,
          isFirstScout: true,
        ),
        isFalse,
      );
      expect(
        StillScoutAccessPolicy.browsableRanks(
          totalFrames: 20,
          isPro: false,
          isFirstScout: true,
        ).length,
        8,
      );
      // First-scout bonus never exceeds Pro visibility.
      expect(
        StillScoutAccessPolicy.keeperLimit(isPro: false, isFirstScout: true),
        lessThanOrEqualTo(StillScoutConstants.proKeeperLimit),
      );
    });

    test('AI polish is Pro-only — free AI trial does not unlock it', () {
      expect(
        StillScoutAccessPolicy.canUseAiPolish(isPro: true),
        isTrue,
      );
      expect(
        StillScoutAccessPolicy.canUseAiPolish(isPro: false),
        isFalse,
      );
      expect(
        StillScoutAccessPolicy.canUseAiPolish(
          isPro: false,
          isAiProTrial: true,
        ),
        isFalse,
        reason: 'trial is scoring-only; polish stays behind paid Pro',
      );
    });

    test('freePlanLimitsSummary matches constants', () {
      expect(
        StillScoutAccessPolicy.freePlanLimitsSummary,
        '${StillScoutConstants.freeScoutsPerDay} free scouts/day · '
        '${StillScoutConstants.freeKeeperLimit} keepers '
        '(${StillScoutConstants.freeKeeperLimit + StillScoutConstants.firstScoutBonusKeepers} on first scout) · '
        '${StillScoutConstants.freeExportsPerScout} exports',
      );
    });

    test('cloud AI gate is Pro-only (trial is granted separately)', () {
      expect(StillScoutAccessPolicy.canUseCloudAi(isPro: true), isTrue);
      expect(StillScoutAccessPolicy.canUseCloudAi(isPro: false), isFalse);
    });

    test('export rank gate follows keeper visibility including first scout', () {
      expect(
        StillScoutAccessPolicy.canExportFrame(
          rank: 7,
          isPro: false,
          isFirstScout: true,
        ),
        isTrue,
      );
      expect(
        StillScoutAccessPolicy.canExportFrame(rank: 7, isPro: false),
        isFalse,
      );
      // Per-scout save cap is independent of keeper visibility.
      expect(
        StillScoutAccessPolicy.canExportThisSession(
          isPro: false,
          exportsUsedThisSession: StillScoutConstants.freeExportsPerScout,
        ),
        isFalse,
      );
    });

    test('free users cannot view frames beyond rank 4 (limit is now 5)', () {
      expect(StillScoutAccessPolicy.canViewFrame(rank: 0, isPro: false), isTrue);
      expect(StillScoutAccessPolicy.canViewFrame(rank: 4, isPro: false), isTrue);
      expect(StillScoutAccessPolicy.canViewFrame(rank: 5, isPro: false), isFalse);
    });

    test('pro users can view up to 20 keepers', () {
      expect(StillScoutAccessPolicy.canViewFrame(rank: 19, isPro: true), isTrue);
      expect(StillScoutAccessPolicy.canViewFrame(rank: 20, isPro: true), isFalse);
    });

    test('timestamps hidden for free tier', () {
      expect(StillScoutAccessPolicy.showTimestamp(isPro: false), isFalse);
      expect(StillScoutAccessPolicy.showTimestamp(isPro: true), isTrue);
      expect(StillScoutAccessPolicy.rankLabel(0), 'Top Pick #1');
      expect(
        StillScoutAccessPolicy.frameFooterLabel(
          rank: 1,
          isPro: false,
          formattedTimestamp: '1:23',
        ),
        'Top Pick #2',
      );
    });

    test('semantics omit timecodes for free users', () {
      expect(
        StillScoutAccessPolicy.semanticsLabel(rank: 0, isPro: false, score: 8.8),
        'Top Pick #1, score 8.8',
      );
    });

    test('session export cap is per scout for free users', () {
      expect(
        StillScoutAccessPolicy.canExportThisSession(
          isPro: false,
          exportsUsedThisSession: 2,
        ),
        isTrue,
      );
      expect(
        StillScoutAccessPolicy.canExportThisSession(
          isPro: false,
          exportsUsedThisSession: 3,
        ),
        isFalse,
      );
      expect(
        StillScoutAccessPolicy.canExportThisSession(
          isPro: true,
          exportsUsedThisSession: 99,
        ),
        isTrue,
      );
    });

    test('pro users show unlimited exports remaining', () {
      expect(
        StillScoutAccessPolicy.exportsRemainingThisScout(
          isPro: true,
          exportsUsedThisSession: 50,
        ),
        StillScoutConstants.unlimitedExportsSentinel,
      );
      expect(
        StillScoutAccessPolicy.exportsAllowanceLabel(
          isPro: true,
          exportsUsedThisSession: 0,
        ),
        'Unlimited saves',
      );
    });

    test('displayExportsRemaining clamps sentinel for UI', () {
      expect(
        StillScoutAccessPolicy.displayExportsRemaining(
          exportsRemaining: StillScoutConstants.unlimitedExportsSentinel,
        ),
        StillScoutConstants.freeExportsPerScout,
      );
      expect(
        StillScoutAccessPolicy.displayExportsRemaining(exportsRemaining: 2),
        2,
      );
      expect(
        StillScoutAccessPolicy.displayExportsRemaining(exportsRemaining: -1),
        0,
      );
    });

    test('browsable ranks exclude locked free frames', () {
      expect(
        StillScoutAccessPolicy.browsableRanks(totalFrames: 12, isPro: false),
        [0, 1, 2, 3, 4],
      );
      expect(
        StillScoutAccessPolicy.browsableRanks(totalFrames: 12, isPro: true).length,
        12, // capped by available frames
      );
      expect(
        StillScoutAccessPolicy.browsableRanks(totalFrames: 25, isPro: true).length,
        StillScoutConstants.proKeeperLimit,
      );
    });

    test('scouts allowance label reflects loading and remaining', () {
      expect(
        StillScoutAccessPolicy.scoutsAllowanceLabel(
          isPro: true,
          scoutsRemainingToday: 0,
        ),
        'Unlimited AI Pro scouts',
      );
      expect(
        StillScoutAccessPolicy.scoutsAllowanceLabel(
          isPro: false,
          scoutsRemainingToday: 0,
          isLoading: true,
        ),
        'Checking daily allowance…',
      );
      expect(
        StillScoutAccessPolicy.scoutsAllowanceLabel(
          isPro: false,
          scoutsRemainingToday: StillScoutConstants.freeScoutsPerDay,
        ),
        '${StillScoutConstants.freeScoutsPerDay} free scouts left today',
      );
      expect(
        StillScoutAccessPolicy.scoutsAllowanceLabel(
          isPro: false,
          scoutsRemainingToday: 0,
        ),
        'No free scouts left today',
      );
      expect(
        StillScoutAccessPolicy.scoutsAllowanceLabel(
          isPro: false,
          scoutsRemainingToday: 2,
          isAiProTrialAvailable: true,
        ),
        'Free AI Trial ready · needs internet',
      );
      expect(
        StillScoutAccessPolicy.scoutRequiresNetwork(
          isPro: false,
          isAiProTrialAvailable: true,
        ),
        isTrue,
      );
      expect(
        StillScoutAccessPolicy.scoutRequiresNetwork(isPro: false),
        isFalse,
      );
    });

    test('persisted json redacts locked free frames', () {
      const frame = ScoredFrame(
        frame: ExtractedFrame(
          id: 'f1',
          filePath: '/cache/frame.jpg',
          timestampMs: 12500,
          width: 1280,
          height: 720,
          sourceVideoPath: '/videos/clip.mp4',
        ),
        score: 8.0,
        metadata: FrameScoreMetadata(
          blurScore: 80,
          lightingScore: 70,
          openEyesScore: 75,
          compositionScore: 72,
        ),
      );

      final lockedJson = StillScoutAccessPolicy.toPersistedJson(
        frame: frame,
        rank: 5,
        isPro: false,
      );
      expect(lockedJson['timestampMs'], 12500);
      expect(lockedJson['sourceVideoPath'], '/videos/clip.mp4');
      expect(lockedJson['persistedLocked'], isTrue);

      final unlockedJson = StillScoutAccessPolicy.toPersistedJson(
        frame: frame,
        rank: 5,
        isPro: false,
        isFirstScout: true,
      );
      expect(unlockedJson['timestampMs'], 12500);
      expect(unlockedJson['sourceVideoPath'], '/videos/clip.mp4');
      expect(unlockedJson['persistedLocked'], isFalse);

      // rank 5 is still locked (freeKeeperLimit = 5, so ranks 0-4 are unlocked).
      final lockedView = StillScoutAccessPolicy.fromPersistedJson(
        lockedJson,
        isPro: false,
        rank: 5,
      );
      expect(lockedView.frame.timestampMs, 0);
      expect(lockedView.frame.sourceVideoPath, isEmpty);

      // First-scout bonus unlocks ranks up through freeKeeperLimit + bonus - 1.
      final firstScoutView = StillScoutAccessPolicy.fromPersistedJson(
        lockedJson,
        isPro: false,
        rank: 5,
        isFirstScout: true,
      );
      expect(firstScoutView.frame.timestampMs, 12500);
      expect(firstScoutView.frame.sourceVideoPath, '/videos/clip.mp4');
    });

    test('restore messaging is shared across paywall and settings', () {
      expect(
        StillScoutAccessPolicy.noActiveProSubscriptionMessage,
        'No active AI Pro subscription found.',
      );
    });
  });
}
