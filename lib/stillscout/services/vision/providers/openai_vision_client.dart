import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:stillscout/config/stillscout_config.dart';
import '../vision_scoring_client.dart';

/// OpenAI GPT-4o-mini vision — the paid fallback (last AI tier before
/// on-device ML Kit). Cheapest paid model: ~$0.15 / 1M input tokens.
class OpenAiVisionClient implements VisionScoringClient {
  bool _sessionDisabled = false;

  @override
  String get name => 'OpenAI';

  @override
  bool get isConfigured => StillScoutConfig.isOpenAiConfigured;

  @override
  Future<VisionScoringResult> scoreFrame({required String base64Jpeg}) async {
    if (_sessionDisabled || !isConfigured) {
      return const VisionScoringFailure('not configured or session disabled');
    }
    try {
      final response = await sharedVisionDio.post(
        'https://api.openai.com/v1/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer ${StillScoutConfig.openAiApiKey}',
          'Content-Type': 'application/json',
        }),
        data: _buildBody(base64Jpeg, StillScoutConfig.visionModel),
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

Map<String, dynamic> _buildBody(String base64Jpeg, String model) => {
      'model': model,
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
    };
