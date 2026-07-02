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

    test('free users cannot view frames beyond rank 2', () {
      expect(StillScoutAccessPolicy.canViewFrame(rank: 0, isPro: false), isTrue);
      expect(StillScoutAccessPolicy.canViewFrame(rank: 2, isPro: false), isTrue);
      expect(StillScoutAccessPolicy.canViewFrame(rank: 3, isPro: false), isFalse);
    });

    test('pro users can view up to 10 keepers', () {
      expect(StillScoutAccessPolicy.canViewFrame(rank: 9, isPro: true), isTrue);
      expect(StillScoutAccessPolicy.canViewFrame(rank: 10, isPro: true), isFalse);
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
        StillScoutAccessPolicy.semanticsLabel(rank: 0, isPro: false, score: 88),
        'Top Pick #1, score 88',
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
        'Unlimited polished saves',
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
        [0, 1, 2],
      );
      expect(
        StillScoutAccessPolicy.browsableRanks(totalFrames: 12, isPro: true).length,
        StillScoutConstants.proKeeperLimit,
      );
    });

    test('scouts allowance label reflects loading and remaining', () {
      expect(
        StillScoutAccessPolicy.scoutsAllowanceLabel(
          isPro: true,
          scoutsRemainingThisWeek: 0,
        ),
        'Unlimited scouts',
      );
      expect(
        StillScoutAccessPolicy.scoutsAllowanceLabel(
          isPro: false,
          scoutsRemainingThisWeek: 0,
          isLoading: true,
        ),
        'Checking weekly allowance…',
      );
      expect(
        StillScoutAccessPolicy.scoutsAllowanceLabel(
          isPro: false,
          scoutsRemainingThisWeek: 8,
        ),
        '8 free scouts left this week',
      );
      expect(
        StillScoutAccessPolicy.scoutsAllowanceLabel(
          isPro: false,
          scoutsRemainingThisWeek: 0,
        ),
        'No scouts left this week',
      );
    });

    test('persisted json redacts locked free frames', () {
      final frame = ScoredFrame(
        frame: ExtractedFrame(
          id: 'f1',
          filePath: '/cache/frame.jpg',
          timestampMs: 12500,
          width: 1280,
          height: 720,
          sourceVideoPath: '/videos/clip.mp4',
        ),
        score: 80,
        metadata: const FrameScoreMetadata(
          blurScore: 80,
          lightingScore: 70,
          openEyesScore: 75,
          compositionScore: 72,
        ),
      );

      final lockedJson = StillScoutAccessPolicy.toPersistedJson(frame: frame);
      expect(lockedJson['timestampMs'], 12500);
      expect(lockedJson['sourceVideoPath'], '/videos/clip.mp4');

      final unlockedJson = StillScoutAccessPolicy.toPersistedJson(frame: frame);
      expect(unlockedJson['timestampMs'], 12500);
      expect(unlockedJson['sourceVideoPath'], '/videos/clip.mp4');

      final lockedView = StillScoutAccessPolicy.fromPersistedJson(
        lockedJson,
        isPro: false,
        rank: 5,
      );
      expect(lockedView.frame.timestampMs, 0);
      expect(lockedView.frame.sourceVideoPath, isEmpty);
    });
  });
}
