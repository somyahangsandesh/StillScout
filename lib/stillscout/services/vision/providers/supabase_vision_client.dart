import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../config/stillscout_config.dart';
import '../../../data/models/frame_score_metadata.dart';
import '../../stillscout_device_id.dart';
import '../vision_scoring_client.dart';

/// Priority-0 vision provider — calls the StillScout Supabase Edge Function.
///
/// The Edge Function holds the real API keys as server-side Supabase Secrets.
/// No keys are shipped in the app binary. The server runs its own cascade
/// (Groq → Gemini → Grok → OpenAI) and returns a unified score.
///
/// Cascade behaviour when this client fails:
/// - [VisionScoringRateLimit]  → device hit the Supabase server daily cap
///   (configured server-side; app local guard is
///   [StillScoutConstants.maxCloudFramesPerDeviceDay] for direct providers)
/// - [VisionScoringAuthError]  → bad anon key / misconfigured function
/// - [VisionScoringFailure]    → function unreachable (network / cold start)
///
/// In all failure cases the orchestrator falls through to direct API clients.
class SupabaseVisionClient implements VisionScoringClient {
  SupabaseVisionClient();

  @override
  String get name => 'Supabase';

  @override
  bool get isConfigured => StillScoutConfig.isSupabaseConfigured;

  @override
  void resetForTests() {}

  @override
  Future<VisionScoringResult> scoreFrame({required String base64Jpeg}) async {
    final url = '${StillScoutConfig.supabaseUrl}/functions/v1/vision-score';
    final anonKey = StillScoutConfig.supabaseAnonKey;

    final deviceId = await StillScoutDeviceId.get();

    try {
      final response = await sharedVisionDio.post<Map<String, dynamic>>(
        url,
        data: <String, dynamic>{
          'image': base64Jpeg,
          'device_id': deviceId,
        },
        options: Options(
          headers: <String, String>{
            'Authorization': 'Bearer $anonKey',
            'apikey': anonKey,
          },
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 20),
        ),
      );

      final body = response.data;
      if (body == null) {
        return const VisionScoringFailure('empty_body');
      }

      // Parse using the shared parser — same JSON schema as direct providers
      final metadata = _parseSupabaseScore(body);
      if (metadata == null) {
        debugPrint('[Supabase] Parse failed — body: $body');
        return const VisionScoringFailure('parse_error');
      }

      return VisionScoringSuccess(metadata);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final errorCode = e.response?.data is Map
          ? (e.response!.data as Map)['code'] as String?
          : null;

      if (status == 429 || errorCode == 'DAILY_CAP_REACHED') {
        debugPrint('[Supabase] Device daily quota reached — falling back to direct providers.');
        return const VisionScoringRateLimit();
      }
      if (status == 401 || status == 403) {
        debugPrint('[Supabase] Auth error ($status) — check anon key and function deployment.');
        return const VisionScoringAuthError();
      }
      if (status == 503) {
        // All server-side providers also failed — skip to local fallback
        debugPrint('[Supabase] All server providers exhausted (503).');
        return const VisionScoringFailure('server_providers_exhausted');
      }
      debugPrint('[Supabase] Request failed: status=$status msg=${e.message}');
      return VisionScoringFailure('status=$status');
    } catch (e) {
      debugPrint('[Supabase] Unexpected error: $e');
      return VisionScoringFailure(e.toString());
    }
  }
}

/// Converts the edge function's flat JSON response into [FrameScoreMetadata].
FrameScoreMetadata? _parseSupabaseScore(Map<String, dynamic> json) {
  try {
    final b = json['blur_score'];
    final l = json['lighting_score'];
    final o = json['open_eyes_score'];
    final c = json['composition_score'];

    if (b == null || l == null || o == null || c == null) return null;

    return FrameScoreMetadata.fromJson({
      'blurScore': (b as num).toInt(),
      'lightingScore': (l as num).toInt(),
      'openEyesScore': (o as num).toInt(),
      'compositionScore': (c as num).toInt(),
      'summary': json['summary'] as String?,
      'source': ScoreSource.llm.name,
    });
  } catch (e) {
    debugPrint('[Supabase] Field mapping error: $e');
    return null;
  }
}
