/// In-app Privacy Policy and Terms of Use copy for App Store Guideline 3.1.2.
///
/// Keep [StillScoutConfig.privacyPolicyUrl] / [termsOfUseUrl] in sync when you
/// host these pages publicly for App Store Connect metadata.
class StillScoutLegalCopy {
  StillScoutLegalCopy._();

  static const String privacyPolicyTitle = 'Privacy Policy';
  static const String termsOfUseTitle = 'Terms of Use';

  static const String lastUpdated = 'July 13, 2026';

  static const String privacyPolicyBody = '''
Last updated: $lastUpdated

StillScout (“we”, “us”) respects your privacy. This policy explains what information the StillScout mobile app processes when you use frame scouting, polishing, and export features.

1. Information we process
• Videos and still frames you choose to import or record in the app.
• Derived frame images sent to cloud AI solely to score composition, sharpness, and face/eye quality.
• A random on-device identifier used only to enforce fair daily AI usage limits.
• Purchase and entitlement status via Apple In-App Purchase and RevenueCat (no full payment card numbers are collected by StillScout).
• Local session history and cached frames stored on your device (Hive / app documents).

2. How we use information
• To extract, rank, polish, and export stills you request.
• To operate Pro subscriptions and restore purchases.
• To protect shared AI capacity with per-device quotas.
We do not sell your personal information. We do not use your videos for advertising.

3. Cloud AI and third parties
When you use AI Pro while online, selected still frames (downsized JPEGs) may be sent to our scoring proxy (Supabase Edge Functions), which forwards them to Google Gemini Flash to return quality scores and a short explanation. Free on-device scouting uses Apple Vision and local heuristics entirely on your device and does not upload frames for AI scoring. Providers process images according to their policies and our server configuration.
Purchases are processed by Apple and RevenueCat under their privacy policies.

4. On-device processing
Face and eye quality checks run on-device using Apple Vision framework. That analysis stays entirely on your device and is never uploaded.

5. Data retention
Scout history and frame caches live on your device until you clear app data, uninstall, or the app evicts old sessions under its storage limits. Server-side quota counters tied to the random device id are retained only as needed to enforce limits.

6. Your choices
• You control which videos you import or record.
• You can deny camera, microphone, or photo library permission in iOS Settings (some features will stop working).
• You can delete the app to remove local caches.
• Manage or cancel StillScout Pro in Apple ID → Subscriptions.

7. Children
StillScout is not directed at children under 13. Do not use the app to scout media of children if you are not authorized to do so.

8. Contact
Questions about privacy: privacy@stillscout.app

9. Changes
We may update this policy. The “Last updated” date above will change when we do. Continued use after an update means you accept the revised policy.
''';

  static const String termsOfUseBody = '''
Last updated: $lastUpdated

These Terms of Use govern your use of the StillScout mobile application. By downloading or using StillScout you agree to these terms. If you do not agree, do not use the app.

1. The service
StillScout helps creators extract, rank, polish, and export still frames from video. Cloud AI scoring requires a network connection. Features and limits may differ between Free and Pro.

2. Accounts and purchases
StillScout uses Apple In-App Purchase for StillScout Pro (auto-renewable subscription). Payment is charged to your Apple ID. Subscriptions renew automatically unless canceled at least 24 hours before the end of the current period. Manage or cancel in iOS Settings → Apple ID → Subscriptions. Restore purchases is available in the app.
Title, length, and price of each subscription are shown on the purchase sheet before you confirm.

3. License
We grant you a personal, non-exclusive, non-transferable license to use StillScout on Apple devices you own or control, subject to the App Store terms and these Terms.

4. Your content
You retain rights to videos and stills you import. You are responsible for having the rights and permissions needed to process that media (including likenesses of people who appear in it). You grant us a limited license to process frames solely to provide scouting and export features.

5. Acceptable use
Do not misuse the service, attempt to abuse AI quotas, reverse engineer the app except where permitted by law, or use StillScout for unlawful content.

6. AI limitations
Scores and polish suggestions are automated estimates. They may be imperfect. You are responsible for reviewing exports before publishing.

7. Disclaimer
StillScout is provided “as is” without warranties of any kind to the fullest extent permitted by law.

8. Limitation of liability
To the fullest extent permitted by law, we are not liable for indirect, incidental, special, or consequential damages arising from your use of StillScout.

9. Privacy
Our Privacy Policy explains how we process information and is part of these Terms.

10. Apple standard EULA
In addition to these Terms, Apple’s Licensed Application End User License Agreement applies to apps obtained from the App Store:
https://www.apple.com/legal/internet-services/itunes/dev/stdeula/

11. Contact
support@stillscout.app

12. Changes
We may update these Terms. Continued use after an update constitutes acceptance.
''';
}
