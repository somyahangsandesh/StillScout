import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stillscout/config/stillscout_config.dart';
import 'package:stillscout/stillscout/domain/stillscout_legal_copy.dart';

void main() {
  group('App Store legal readiness', () {
    test('privacy policy and terms copy are present', () {
      expect(StillScoutLegalCopy.privacyPolicyBody.length, greaterThan(200));
      expect(StillScoutLegalCopy.termsOfUseBody.length, greaterThan(200));
      expect(
        StillScoutLegalCopy.privacyPolicyBody.toLowerCase(),
        contains('privacy'),
      );
      expect(
        StillScoutLegalCopy.termsOfUseBody.toLowerCase(),
        contains('subscription'),
      );
      expect(
        StillScoutLegalCopy.termsOfUseBody.toLowerCase(),
        contains('restore purchases'),
      );
    });

    test('legal URLs are https GitHub Pages defaults', () {
      expect(StillScoutConfig.privacyPolicyUrl, startsWith('https://'));
      expect(StillScoutConfig.termsOfUseUrl, startsWith('https://'));
      expect(StillScoutConfig.supportUrl, startsWith('https://'));
      expect(StillScoutConfig.appleStandardEulaUrl, startsWith('https://'));
      expect(
        StillScoutConfig.privacyPolicyUrl,
        'https://somyahangsandesh.github.io/StillScout/legal/privacy.html',
      );
      expect(
        StillScoutConfig.termsOfUseUrl,
        'https://somyahangsandesh.github.io/StillScout/legal/terms.html',
      );
      expect(
        StillScoutConfig.supportUrl,
        'https://somyahangsandesh.github.io/StillScout/legal/support.html',
      );
    });

    test('HOSTED_URLS.txt matches StillScoutConfig defaults', () {
      final hosted = File('docs/legal/HOSTED_URLS.txt').readAsStringSync();
      expect(hosted, contains(StillScoutConfig.privacyPolicyUrl));
      expect(hosted, contains(StillScoutConfig.termsOfUseUrl));
      expect(hosted, contains(StillScoutConfig.supportUrl));
    });

    test('direct AI keys are gated off in release by default', () {
      expect(StillScoutConfig.allowDirectAiKeysInRelease, isFalse);
    });

    test('privacy copy is Gemini-only (no legacy vision vendors)', () {
      const staleVendors = [
        'Groq',
        'Grok',
        'OpenRouter',
        'OpenAI',
        'GPT-4',
        'groq',
        'grok',
      ];
      const privacy = StillScoutLegalCopy.privacyPolicyBody;
      for (final vendor in staleVendors) {
        expect(
          privacy.contains(vendor),
          isFalse,
          reason: 'privacy policy must not mention $vendor',
        );
      }
      expect(privacy.toLowerCase(), contains('gemini'));
      expect(privacy.toLowerCase(), contains('supabase'));
    });

    test('hosted privacy.html matches in-app Gemini-only policy', () {
      final html = File('docs/legal/privacy.html').readAsStringSync();
      const staleVendors = ['Groq', 'Grok', 'OpenRouter', 'OpenAI', 'GPT-4'];
      for (final vendor in staleVendors) {
        expect(
          html.contains(vendor),
          isFalse,
          reason: 'privacy.html must not mention $vendor',
        );
      }
      expect(html.toLowerCase(), contains('gemini'));
      expect(html.toLowerCase(), contains('supabase'));
      expect(
        html,
        contains(
          'That analysis stays entirely on your device and is never uploaded.',
        ),
        reason: 'hosted privacy §4 must match StillScoutLegalCopy',
      );
      expect(html, contains(StillScoutLegalCopy.lastUpdated));
    });

    test('legacy Groq/Grok/OpenAI provider files are gone', () {
      final dir = Directory('lib/stillscout/services/vision/providers');
      final names = dir
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .toList()
        ..sort();
      expect(names, [
        'gemini_vision_client.dart',
        'supabase_vision_client.dart',
      ]);
    });
  });
}
