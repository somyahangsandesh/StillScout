// StillScout pipeline and monetization constants.
import 'package:flutter/material.dart';

class StillScoutConstants {
  StillScoutConstants._();

  static const String appName = 'StillScout';
  static const String tagline = 'Scout the perfect still.';

  /// Extract one frame every second — balances coverage vs speed on 1-min clips.
  static const int frameIntervalMs = 1000;

  /// Parallel native thumbnail extractions (MediaMetadataRetriever is I/O bound).
  static const int maxConcurrentThumbnailExtractions = 4;

  /// Max frames sent to cloud AI per scout; the rest use on-device heuristics.
  static const int maxCloudFramesPerScout = 60;

  /// Hard ceiling on extracted/scored frames per video regardless of length.
  /// A 10-minute clip at a 1s interval would otherwise yield ~600 frames —
  /// brutal for memory, scoring latency, and API spend. Past this cap the
  /// extractor widens its sampling interval so coverage stays even across
  /// the whole clip instead of just the first ~3 minutes.
  static const int maxFramesPerVideo = 180;

  /// Below this, AVFoundation/MediaMetadataRetriever reliably fail to seek.
  static const int minVideoDurationMs = 120;

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

  // ── AI scoring pipeline ─────────────────────────────────────────────────
  static const int maxConcurrentScoringRequests = 3;
  static const Duration scoringConnectTimeout = Duration(seconds: 10);
  static const Duration scoringReceiveTimeout = Duration(seconds: 20);
  static const int scoringMaxRetries = 2;
  static const Duration scoringRetryBaseDelay = Duration(milliseconds: 600);
  static const String scoreCacheBoxName = 'stillscout_score_cache';

  /// Soft per-device daily cap on cloud AI (Groq/Gemini/Grok/OpenRouter/OpenAI)
  /// frame-scoring calls. All installs share the same API keys shipped in the
  /// binary, so this protects the shared free-tier pool from any single
  /// install exhausting it for everyone else. Once the cap is hit for the
  /// day, scoring falls back to on-device ML Kit + heuristic — the app never
  /// stops working, it just stops spending shared cloud quota until the
  /// device-local counter resets at UTC midnight.
  static const int maxCloudFramesPerDeviceDay = 40;

  static const String cloudQuotaCountKey = 'stillscout_cloud_quota_count';
  static const String cloudQuotaDateKey = 'stillscout_cloud_quota_date';

  /// Free tier polished exports allowed **per scout session** (resets each run).
  static const int freeExportsPerScout = 3;

  /// Free scouts per calendar week (UTC). Pro users are unlimited.
  static const int freeScoutsPerWeek = 8;

  /// Sentinel returned by [StillScoutScoutQuotaTracker.remainingThisWeek] for Pro.
  static const int unlimitedScoutsSentinel = 999;

  /// Sentinel for unlimited polished exports per scout (Pro tier UI).
  static const int unlimitedExportsSentinel = 999;

  static const String scoutQuotaCountKey = 'stillscout_scout_quota_count';
  static const String scoutQuotaWeekKey = 'stillscout_scout_quota_week';

  /// Unlocked keeper frames visible in gallery (rank 0..limit-1).
  static const int freeKeeperLimit = 3;
  static const int proKeeperLimit = 10;

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
