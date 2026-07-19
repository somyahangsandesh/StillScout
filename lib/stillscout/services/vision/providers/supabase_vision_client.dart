import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../config/stillscout_config.dart';
import '../../../data/models/frame_score_metadata.dart';
import '../../stillscout_device_id.dart';
import '../vision_scoring_client.dart';

/// Priority-0 proxy — StillScout Supabase Edge Function.
///
/// The edge function calls **Gemini Flash** with server-side keys only.
/// Supports single-frame scoring and multi-image batch scoring (AI Pro).
class SupabaseVisionClient implements VisionScoringClient {
  SupabaseVisionClient();

  @override
  String get name => 'Supabase';

  @override
  bool get isConfigured => StillScoutConfig.isSupabaseConfigured;

  @override
  void resetForTests() {}

  String get _baseUrl =>
      '${StillScoutConfig.supabaseUrl}/functions/v1/vision-score';

  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${StillScoutConfig.supabaseAnonKey}',
        'apikey': StillScoutConfig.supabaseAnonKey,
      };

  @override
  Future<VisionBatchResult> batchScoreFrames({
    required List<String> base64Jpegs,
    required int pickCount,
    StillScoutVideoContext videoContext = StillScoutVideoContext.auto,
  }) async {
    if (!isConfigured) {
      return const VisionBatchFailure('not configured');
    }
    if (base64Jpegs.isEmpty) {
      return const VisionBatchFailure('no frames');
    }

    final deviceId = await StillScoutDeviceId.get();

    try {
      final response = await sharedVisionDio.post<Map<String, dynamic>>(
        _baseUrl,
        data: <String, dynamic>{
          'images': base64Jpegs,
          'pick_count': pickCount,
          'device_id': deviceId,
          'context': videoContext.name,
        },
        options: Options(
          headers: _headers,
          // 48×384px JPEGs need headroom on cellular.
          sendTimeout: const Duration(seconds: 45),
          receiveTimeout: const Duration(seconds: 65),
        ),
      );

      final body = response.data;
      if (body == null) {
        return const VisionBatchFailure('empty_body');
      }

      final parsed = parseBatchScoringResponse(
        jsonEncode(body),
        expectedFrameCount: base64Jpegs.length,
      );
      if (parsed != null) {
        debugPrint('[Supabase] Batch scored ${base64Jpegs.length} frames.');
        return parsed;
      }
      debugPrint('[Supabase] Batch parse failed — body keys: ${body.keys}');
      return const VisionBatchFailure('parse_error');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final errorCode = e.response?.data is Map
          ? (e.response!.data as Map)['code'] as String?
          : null;

      if (status == 429 || errorCode == 'DAILY_CAP_REACHED') {
        debugPrint('[Supabase] Batch daily quota reached.');
        return const VisionBatchRateLimit();
      }
      if (status == 401 || status == 403) {
        debugPrint('[Supabase] Batch auth error ($status).');
        return const VisionBatchAuthError();
      }
      debugPrint('[Supabase] Batch failed: status=$status msg=${e.message}');
      return VisionBatchFailure('status=$status');
    } catch (e) {
      debugPrint('[Supabase] Batch unexpected error: $e');
      return VisionBatchFailure(e.toString());
    }
  }

  @override
  Future<VisionScoringResult> scoreFrame({
    required String base64Jpeg,
    StillScoutVideoContext videoContext = StillScoutVideoContext.auto,
  }) async {
    final deviceId = await StillScoutDeviceId.get();

    try {
      final response = await sharedVisionDio.post<Map<String, dynamic>>(
        _baseUrl,
        data: <String, dynamic>{
          'image': base64Jpeg,
          'device_id': deviceId,
          'context': videoContext.name,
        },
        options: Options(
          headers: _headers,
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 25),
        ),
      );

      final body = response.data;
      if (body == null) {
        return const VisionScoringFailure('empty_body');
      }

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
        debugPrint('[Supabase] Device daily quota reached.');
        return const VisionScoringRateLimit();
      }
      if (status == 401 || status == 403) {
        debugPrint('[Supabase] Auth error ($status).');
        return const VisionScoringAuthError();
      }
      if (status == 503) {
        debugPrint('[Supabase] Gemini unavailable on edge (503).');
        return const VisionScoringFailure('server_gemini_unavailable');
      }
      debugPrint('[Supabase] Request failed: status=$status msg=${e.message}');
      return VisionScoringFailure('status=$status');
    } catch (e) {
      debugPrint('[Supabase] Unexpected error: $e');
      return VisionScoringFailure(e.toString());
    }
  }
}

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
