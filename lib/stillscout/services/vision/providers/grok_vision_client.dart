import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:stillscout/config/stillscout_config.dart';
import '../vision_scoring_client.dart';

/// xAI Grok vision — Priority 3 (free tier, OpenAI-compatible format).
///
/// Uses the grok-2-vision-1212 model via xAI's OpenAI-compatible API.
/// Free tier available at https://console.x.ai — check current limits there.
///
/// Endpoint: https://api.x.ai/v1/chat/completions
/// Auth: Bearer token (same format as OpenAI)
class GrokVisionClient implements VisionScoringClient {
  bool _sessionDisabled = false;

  @override
  String get name => 'Grok';

  @override
  bool get isConfigured => StillScoutConfig.isGrokConfigured;

  @override
  Future<VisionScoringResult> scoreFrame({required String base64Jpeg}) async {
    if (_sessionDisabled || !isConfigured) {
      return const VisionScoringFailure('not configured or session disabled');
    }
    try {
      final response = await sharedVisionDio.post(
        'https://api.x.ai/v1/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer ${StillScoutConfig.grokApiKey}',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': 'grok-2-vision-1212',
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
