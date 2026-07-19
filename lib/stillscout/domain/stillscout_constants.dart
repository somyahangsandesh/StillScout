// StillScout pipeline and monetization constants.
import 'package:flutter/material.dart';

class StillScoutConstants {
  StillScoutConstants._();

  static const String appName = 'StillScout';
  static const String tagline = 'Scout the perfect still.';

  /// Extract one frame every second — balances coverage vs speed on 1-min clips.
  static const int frameIntervalMs = 1000;

  /// Parallel native thumbnail extractions (AVFoundation is I/O bound on iOS).
  static const int maxConcurrentThumbnailExtractions = 4;

  // ── AI scoring pipeline ─────────────────────────────────────────────────

  /// Final keeper frames selected by Gemini per AI Pro scout.
  /// Gemini batch-scores up to [maxGridFramesPerScout] frames and returns the
  /// top [maxCloudFramesPerScout] picks. Matches [maxGalleryFrames] so the
  /// full gallery can be Gemini-scored rather than partly on-device.
  static const int maxCloudFramesPerScout = 20;

  /// Number of temporally-diverse frames sent to Gemini in a single batch
  /// call. The timeline is divided into this many equal buckets and one frame
  /// per bucket is chosen, so every moment of the video is represented.
  /// At 384px, 48 images ≈ 12,400 image tokens — well within Gemini limits.
  static const int maxGridFramesPerScout = 48;

  /// Width of thumbnails sent in the Gemini batch call. 384px is under
  /// Gemini's low-resolution tile threshold (768px) so each image costs only
  /// 258 tokens, yet is large enough to judge expressions and sharpness.
  static const int gridThumbnailWidth = 384;

  /// Vision-only absolute reject thresholds — only frames below these are
  /// eliminated before Gemini sees them. Very permissive by design: Gemini
  /// makes all aesthetic decisions; Vision only removes true garbage.
  static const int visionRejectBlurThreshold = 15;   // 0-100, lower = blurrier
  static const int visionRejectLightingThreshold = 8; // 0-100, lower = darker

  /// Hard ceiling on extracted/scored frames per video regardless of length.
  /// A 10-minute clip at a 1s interval would otherwise yield ~600 frames —
  /// brutal for memory, scoring latency, and API spend. Past this cap the
  /// extractor widens its sampling interval so coverage stays even across
  /// the whole clip instead of just the first ~3 minutes.
  static const int maxFramesPerVideo = 180;

  /// Below this, AVFoundation/MediaMetadataRetriever reliably fail to seek.
  static const int minVideoDurationMs = 120;

  /// Hard ceiling for import / record / scout. Longer clips are rejected
  /// (or must be trimmed) so extraction stays bounded.
  static const int maxVideoDurationMs = 10 * 60 * 1000; // 10 minutes

  /// Above this we still process, but the UI warns it'll take a while.
  static const int longVideoWarningMs = 5 * 60 * 1000;

  /// Max decoded width — keeps thumbnails lightweight on device.
  static const int maxFrameWidth = 1280;

  /// Width sent to the vision LLM — smaller payload = fewer image tokens =
  /// cheaper + faster, with no meaningful scoring accuracy loss.
  static const int llmUploadWidth = 512;

  static const int jpegQuality = 85;
  static const int llmUploadJpegQuality = 70;

  /// Full-resolution re-extraction quality used for Pro exports.
  static const int proExportJpegQuality = 100;

  /// How many frames we'll let fail (codec hiccup, memory pressure) before
  /// treating the whole extraction as broken.
  static const double maxFrameFailureRatio = 0.4;

  static const String scoreCacheBoxName = 'stillscout_score_cache';

  /// Soft per-device daily cap on Gemini picks charged against the device.
  /// Each scout costs [maxCloudFramesPerScout] picks (20). At 200 that allows
  /// 10 full AI Pro scouts per day before fallback to on-device scoring.
  static const int maxCloudFramesPerDeviceDay = 200;

  static const String cloudQuotaCountKey = 'stillscout_cloud_quota_count';
  static const String cloudQuotaDateKey = 'stillscout_cloud_quota_date';

  /// Free tier polished exports allowed **per scout session** (resets each run).
  static const int freeExportsPerScout = 3;

  /// Free scouts per calendar day (UTC). Pro users are unlimited.
  /// Kept intentionally low so the AI Pro trial → paid conversion has teeth.
  static const int freeScoutsPerDay = 2;

  /// Sentinel returned by [StillScoutScoutQuotaTracker.remainingToday] for Pro.
  static const int unlimitedScoutsSentinel = 999;

  /// Sentinel for unlimited polished exports per scout (Pro tier UI).
  static const int unlimitedExportsSentinel = 999;

  static const String scoutQuotaCountKey = 'stillscout_scout_quota_count';
  static const String scoutQuotaDayKey = 'stillscout_scout_quota_day';

  /// Maximum frames shown in the gallery regardless of video length.
  /// We extract & score many frames but surface only the best [maxGalleryFrames]
  /// so the UI stays clean. Free users see [freeKeeperLimit] unlocked +
  /// ([maxGalleryFrames] − [freeKeeperLimit]) teaser locked frames.
  static const int maxGalleryFrames = 20;

  /// Unlocked keeper frames visible in gallery (rank 0..limit-1).
  static const int freeKeeperLimit = 5;
  /// Matches [maxGalleryFrames] / [maxCloudFramesPerScout] so Pro unlocks
  /// every Gemini-scored gallery frame.
  static const int proKeeperLimit = 20;
  /// First-scout bonus keeper count — an extra 3 on top of freeKeeperLimit
  /// so a brand-new user sees 8 frames the very first time (nearly a full
  /// Pro experience), creating genuine "wow" before the conversion ask.
  static const int firstScoutBonusKeepers = 3;

  /// Max width for locked-frame teaser thumbnails on free tier.
  static const int freePreviewMaxWidth = 720;

  // ── Persistent session cache ──────────────────────────────────────────────
  static const String sessionCacheBoxName = 'stillscout_sessions';

  /// Max number of past sessions kept in History before LRU eviction.
  static const int maxCachedSessions = 20;

  /// Max total bytes the persistent frame cache may occupy before the
  /// janitor evicts the oldest sessions by LRU order.
  static const int maxCacheSizeBytes = 512 * 1024 * 1024; // 512 MB

  // ── De-duplication ───────────────────────────────────────────────────────
  /// aHash similarity threshold: two frames with hamming distance ≤ this
  /// are considered near-duplicates (0 = identical, 64 = max different).
  static const int dedupHammingThreshold = 8;

  /// Minimum time gap (ms) between frames before we even run the hash
  /// comparison — frames this close in time are always candidates for dedup.
  static const int dedupWindowMs = 1000;

  // ── Top Picks diversity ───────────────────────────────────────────────────
  /// Minimum time gap between any two Top-Pick frames to avoid showing
  /// three near-identical consecutive frames in the hero carousel.
  static const int topPicksMinGapMs = 2000;

  static const int topPicksCount = 3;
}

/// Creator-declared video intent — adjusts heuristic scoring weights.
enum StillScoutVideoContext { auto, portrait, action, landscape, event }

extension StillScoutVideoContextExt on StillScoutVideoContext {
  String get label => switch (this) {
        StillScoutVideoContext.auto => 'Auto',
        StillScoutVideoContext.portrait => 'Portrait',
        StillScoutVideoContext.action => 'Action',
        StillScoutVideoContext.landscape => 'Landscape',
        StillScoutVideoContext.event => 'Event',
      };

  IconData get icon => switch (this) {
        StillScoutVideoContext.auto => Icons.auto_awesome_outlined,
        StillScoutVideoContext.portrait => Icons.person_outline,
        StillScoutVideoContext.action => Icons.directions_run_outlined,
        StillScoutVideoContext.landscape => Icons.landscape_outlined,
        StillScoutVideoContext.event => Icons.celebration_outlined,
      };

  Map<String, double> get scoreWeights => switch (this) {
        StillScoutVideoContext.auto => {
            'blur': 0.25,
            'lighting': 0.25,
            'eyes': 0.30,
            'composition': 0.20,
          },
        StillScoutVideoContext.portrait => {
            'blur': 0.20,
            'lighting': 0.20,
            'eyes': 0.45,
            'composition': 0.15,
          },
        StillScoutVideoContext.action => {
            'blur': 0.40,
            'lighting': 0.20,
            'eyes': 0.15,
            'composition': 0.25,
          },
        StillScoutVideoContext.landscape => {
            'blur': 0.25,
            'lighting': 0.30,
            'eyes': 0.05,
            'composition': 0.40,
          },
        StillScoutVideoContext.event => {
            'blur': 0.20,
            'lighting': 0.25,
            'eyes': 0.35,
            'composition': 0.20,
          },
      };
}
