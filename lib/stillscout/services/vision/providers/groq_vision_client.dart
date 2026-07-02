import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:stillscout/config/stillscout_config.dart';
import '../vision_scoring_client.dart';

/// Groq — Priority 1 (fastest, free tier).
///
/// Uses Llama-4 Scout 17B multimodal via Groq's OpenAI-compatible API.
/// Free tier: 30 requests/min, ~14,400 req/day. Typically <600ms per frame.
///
/// Groq endpoint: https://api.groq.com/openai/v1/chat/completions
/// Model: meta-llama/llama-4-scout-17b-16e-instruct
class GroqVisionClient implements VisionScoringClient {
  bool _sessionDisabled = false;

  @override
  String get name => 'Groq';

  @override
  bool get isConfigured => StillScoutConfig.isGroqConfigured;

  @override
  Future<VisionScoringResult> scoreFrame({required String base64Jpeg}) async {
    if (_sessionDisabled || !isConfigured) {
      return const VisionScoringFailure('not configured or session disabled');
    }
    try {
      final response = await sharedVisionDio.post(
        'https://api.groq.com/openai/v1/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer ${StillScoutConfig.groqApiKey}',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': 'meta-llama/llama-4-scout-17b-16e-instruct',
          // Groq supports json_object mode for llama-4-scout
          'response_format': {'type': 'json_object'},
          'temperature': 0.2,
          'max_tokens': 160,
          'messages': [
            {'role': 'system', 'content': kVisionSystemPrompt},
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': 'Score this frame per the schema.'},
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Jpeg',
                    'detail': 'low',
                  },
                },
              ],
            },
          ],
        },
      );
      final content = response.data['choices'][0]['message']['content'] as String;
      final metadata = parseVisionResponse(content);
      if (metadata != null) return VisionScoringSuccess(metadata);
      debugPrint('[$name] Unparseable response.');
      return const VisionScoringFailure('parse error');
    } on DioException catch (e) {
      final result = dioExceptionToResult(e, name);
      if (result is VisionScoringAuthError) _sessionDisabled = true;
      return result;
    } catch (e) {
      return VisionScoringFailure(e.toString());
    }
  }

  @override
  void resetForTests() => _sessionDisabled = false;
}
