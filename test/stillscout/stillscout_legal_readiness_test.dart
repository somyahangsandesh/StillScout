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
    });

    test('legal URLs are https', () {
      expect(StillScoutConfig.privacyPolicyUrl, startsWith('https://'));
      expect(StillScoutConfig.termsOfUseUrl, startsWith('https://'));
      expect(StillScoutConfig.supportUrl, startsWith('https://'));
      expect(StillScoutConfig.appleStandardEulaUrl, startsWith('https://'));
    });

    test('direct AI keys are gated off in release by default', () {
      expect(StillScoutConfig.allowDirectAiKeysInRelease, isFalse);
    });

    test('privacy copy is Gemini-only (no legacy vision vendors)', () {
      const staleVendors = ['Groq', 'Grok', 'OpenRouter', 'groq', 'grok'];
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

    test('hosted privacy.html matches Gemini-only policy', () {
      final html = File('docs/legal/privacy.html').readAsStringSync();
      const staleVendors = ['Groq', 'Grok', 'OpenRouter'];
      for (final vendor in staleVendors) {
        expect(
          html.contains(vendor),
          isFalse,
          reason: 'privacy.html must not mention $vendor',
        );
      }
      expect(html.toLowerCase(), contains('gemini'));
      expect(html.toLowerCase(), contains('supabase'));
    });
  });
}
