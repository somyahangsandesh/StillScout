import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:stillscout/config/stillscout_config.dart';
import '../vision_scoring_client.dart';

/// Google Gemini 3.1 Flash Lite — the only cloud vision model for AI Pro.
///
/// gemini-3.1-flash-lite is the current production model for AQ.* API keys.
/// It does not support responseMimeType; JSON is enforced via prompt only.
///
/// Endpoint: https://generativelanguage.googleapis.com/v1/models/gemini-3.1-flash-lite:generateContent
/// Auth: query-param `?key={API_KEY}`
class GeminiVisionClient implements VisionScoringClient {
  bool _sessionDisabled = false;

  @override
  String get name => 'Gemini 3.1 Flash Lite';

  @override
  bool get isConfigured => StillScoutConfig.isGeminiConfigured;

  @override
  Future<VisionScoringResult> scoreFrame({
    required String base64Jpeg,
    StillScoutVideoContext videoContext = StillScoutVideoContext.auto,
  }) async {
    if (_sessionDisabled || !isConfigured) {
      return const VisionScoringFailure('not configured or session disabled');
    }
    try {
      final systemPrompt =
          kVisionSystemPrompt + contextInstructionFor(videoContext);
      final response = await sharedVisionDio.post(
        'https://generativelanguage.googleapis.com/v1/models/gemini-3.1-flash-lite:generateContent',
        queryParameters: {'key': StillScoutConfig.geminiApiKey},
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': '$systemPrompt\n\nScore this frame per the schema.'},
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64Jpeg,
                  },
                },
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.2,
            'maxOutputTokens': 512,
          },
        },
      );

      final candidates = response.data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        return const VisionScoringFailure('empty candidates');
      }
      final parts = candidates[0]['content']['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        return const VisionScoringFailure('empty parts');
      }
      final text = parts[0]['text'] as String?;
      if (text == null) return const VisionScoringFailure('no text part');

      final metadata = parseVisionResponse(text);
      if (metadata != null) return VisionScoringSuccess(metadata);
      debugPrint('[$name] Unparseable response: $text');
      return const VisionScoringFailure('parse error');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      if (status == 401 || status == 403) {
        debugPrint('[$name] Auth error ($status) — disabling. body=$body');
        _sessionDisabled = true;
        return const VisionScoringAuthError();
      }
      if (status == 400) {
        debugPrint('[$name] Bad request (400) — body=$body');
        return const VisionScoringFailure('bad_request');
      }
      if (status == 429) {
        debugPrint('[$name] Rate-limited (429).');
        return const VisionScoringRateLimit();
      }
      debugPrint('[$name] Request failed (status=$status): ${e.message}');
      return VisionScoringFailure('status=$status');
    } catch (e) {
      return VisionScoringFailure(e.toString());
    }
  }

  /// Sends [base64Jpegs] (384px thumbnails) as a single multi-image Gemini
  /// request and returns per-frame scores + the [pickCount] best indices.
  @override
  Future<VisionBatchResult> batchScoreFrames({
    required List<String> base64Jpegs,
    required int pickCount,
    StillScoutVideoContext videoContext = StillScoutVideoContext.auto,
  }) async {
    if (_sessionDisabled || !isConfigured) {
      return const VisionBatchFailure('not configured or session disabled');
    }
    if (base64Jpegs.isEmpty) {
      return const VisionBatchFailure('no frames');
    }

    try {
      final prompt = batchScoringPromptFor(
        videoContext,
        base64Jpegs.length,
        pickCount,
      );

      // Build the parts array: interleaved label text + inline image data.
      // Gemini processes multi-image requests sequentially when images and
      // text are interleaved, giving it a clear frame-by-frame context.
      final parts = <Map<String, dynamic>>[];
      parts.add({'text': prompt});
      for (var i = 0; i < base64Jpegs.length; i++) {
        parts.add({'text': 'Frame $i:'});
        parts.add({
          'inline_data': {
            'mime_type': 'image/jpeg',
            'data': base64Jpegs[i],
          },
        });
      }

      final response = await sharedVisionDio.post(
        // gemini-3.1-flash-lite: current production model for AQ.* keys.
        'https://generativelanguage.googleapis.com/v1/models/gemini-3.1-flash-lite:generateContent',
        queryParameters: {'key': StillScoutConfig.geminiApiKey},
        options: Options(
          headers: {'Content-Type': 'application/json'},
          // Batch calls with 48 images take longer than single-frame calls.
          receiveTimeout: const Duration(seconds: 60),
        ),
        data: {
          'contents': [
            {'role': 'user', 'parts': parts},
          ],
          'generationConfig': {
            'temperature': 0.1,
            // responseMimeType is not supported by AQ.* keys on newer models.
            // JSON output is enforced via the prompt ("Return ONLY this compact JSON").
            // 48 frames × ~42 tokens each ≈ 2 000 tokens output — well within limit.
            'maxOutputTokens': 8192,
          },
        },
      );

      final candidates = response.data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        // Log the full response so we can diagnose future failures.
        debugPrint('[$name] Batch: empty candidates — response: ${response.data}');
        return const VisionBatchFailure('empty candidates');
      }
      final respParts =
          candidates[0]['content']['parts'] as List<dynamic>?;
      if (respParts == null || respParts.isEmpty) {
        debugPrint('[$name] Batch: empty parts in candidate[0]');
        return const VisionBatchFailure('empty parts');
      }
      final text = respParts[0]['text'] as String?;
      if (text == null) return const VisionBatchFailure('no text part');

      final result = parseBatchScoringResponse(
        text,
        expectedFrameCount: base64Jpegs.length,
      );
      if (result != null) return result;
      // Log enough of the raw text to diagnose schema mismatches.
      debugPrint(
        '[$name] Batch unparseable (first 500 chars): '
        '${text.length > 500 ? '${text.substring(0, 500)}…' : text}',
      );
      return const VisionBatchFailure('parse error');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      // 401 / 403 = key wrong or API not enabled → disable for session.
      // 400 = bad request (malformed params, model unavailable) → do NOT
      //       permanently disable; the key may still be valid.
      if (status == 401 || status == 403) {
        debugPrint('[$name] Auth error ($status) — disabling for session. body=$body');
        _sessionDisabled = true;
        return const VisionBatchAuthError();
      }
      if (status == 400) {
        debugPrint('[$name] Bad request (400) — body=$body');
        return const VisionBatchFailure('bad_request');
      }
      if (status == 429) {
        debugPrint('[$name] Rate-limited (429).');
        return const VisionBatchRateLimit();
      }
      debugPrint('[$name] Batch failed (status=$status): ${e.message} body=$body');
      return VisionBatchFailure('status=$status');
    } catch (e) {
      return VisionBatchFailure(e.toString());
    }
  }

  @override
  void resetForTests() => _sessionDisabled = false;
}
