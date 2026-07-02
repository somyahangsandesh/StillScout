import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:stillscout/config/stillscout_config.dart';
import '../vision_scoring_client.dart';

/// Google Gemini 2.0 Flash — Priority 2 (most generous free tier).
///
/// Free tier: 15 RPM, 1 million TPM, 1,500 requests/day.
/// Uses a different request/response format from the OpenAI-compatible
/// providers — note the `contents` array, `inline_data` for images, and
/// `generationConfig.responseMimeType` for JSON mode.
///
/// Endpoint: https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent
/// Auth: query-param `?key={API_KEY}` (not a Bearer token header)
class GeminiVisionClient implements VisionScoringClient {
  bool _sessionDisabled = false;

  @override
  String get name => 'Gemini';

  @override
  bool get isConfigured => StillScoutConfig.isGeminiConfigured;

  @override
  Future<VisionScoringResult> scoreFrame({required String base64Jpeg}) async {
    if (_sessionDisabled || !isConfigured) {
      return const VisionScoringFailure('not configured or session disabled');
    }
    try {
      final response = await sharedVisionDio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
        queryParameters: {'key': StillScoutConfig.geminiApiKey},
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: {
          'contents': [
            {
              'role': 'user',
              'parts': [
                // Gemini doesn't have a separate system role for vision requests;
                // prepend the system prompt as the first text part.
                {'text': '$kVisionSystemPrompt\n\nScore this frame per the schema.'},
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
            'maxOutputTokens': 200,
            // Forces Gemini to return valid JSON — no markdown fences.
            'responseMimeType': 'application/json',
          },
        },
      );

      // Gemini response shape:
      // { "candidates": [{ "content": { "parts": [{"text": "..."}] } }] }
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
      // Gemini uses 400 for invalid API key ("API key not valid")
      if (status == 400 || status == 401 || status == 403) {
        debugPrint('[$name] Auth/config error ($status) — disabling for session.');
        _sessionDisabled = true;
        return const VisionScoringAuthError();
      }
      // Gemini uses 429 for RESOURCE_EXHAUSTED (free tier quota)
      if (status == 429) {
        debugPrint('[$name] Rate-limited (429) — cascading to next provider.');
        return const VisionScoringRateLimit();
      }
      debugPrint('[$name] Request failed (status=$status): ${e.message}');
      return VisionScoringFailure('status=$status');
    } catch (e) {
      return VisionScoringFailure(e.toString());
    }
  }

  @override
  void resetForTests() => _sessionDisabled = false;
}
