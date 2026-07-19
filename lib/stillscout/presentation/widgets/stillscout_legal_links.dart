import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:stillscout/config/stillscout_config.dart';

import '../screens/stillscout_legal_screen.dart';
import '../theme/stillscout_theme.dart';

/// Discoverable Privacy Policy + Terms links (Guideline 3.1.2).
///
/// Opens in-app legal screens by default so review always works offline.
/// Optionally opens hosted URLs when [preferExternalUrls] is true.
class StillScoutLegalLinks extends StatelessWidget {
  const StillScoutLegalLinks({
    super.key,
    this.compact = false,
    this.preferExternalUrls = false,
    this.showAppleEula = false,
  });

  final bool compact;
  final bool preferExternalUrls;
  final bool showAppleEula;

  @override
  Widget build(BuildContext context) {
    final style = StillScoutTextStyles.caption.copyWith(
      color: StillScoutColors.silver.withValues(alpha: 0.85),
      fontSize: compact ? 11 : 12,
      decoration: TextDecoration.underline,
      decorationColor: StillScoutColors.silver.withValues(alpha: 0.5),
    );

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        TextButton(
          onPressed: () => _openPrivacy(context),
          style: TextButton.styleFrom(
            minimumSize: const Size(44, 44),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          child: Text('Privacy Policy', style: style),
        ),
        Text('·', style: style.copyWith(decoration: TextDecoration.none)),
        TextButton(
          onPressed: () => _openTerms(context),
          style: TextButton.styleFrom(
            minimumSize: const Size(44, 44),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          child: Text('Terms of Use', style: style),
        ),
        if (showAppleEula) ...[
          Text('·', style: style.copyWith(decoration: TextDecoration.none)),
          TextButton(
            onPressed: _openAppleEula,
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 44),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            child: Text('Apple EULA', style: style),
          ),
        ],
      ],
    );
  }

  Future<void> _openPrivacy(BuildContext context) async {
    if (preferExternalUrls &&
        await _tryLaunch(StillScoutConfig.privacyPolicyUrl)) {
      return;
    }
    if (!context.mounted) return;
    await StillScoutLegalScreen.open(
      context,
      document: StillScoutLegalDocument.privacyPolicy,
    );
  }

  Future<void> _openTerms(BuildContext context) async {
    if (preferExternalUrls &&
        await _tryLaunch(StillScoutConfig.termsOfUseUrl)) {
      return;
    }
    if (!context.mounted) return;
    await StillScoutLegalScreen.open(
      context,
      document: StillScoutLegalDocument.termsOfUse,
    );
  }

  Future<void> _openAppleEula() async {
    await _tryLaunch(StillScoutConfig.appleStandardEulaUrl);
  }

  static Future<bool> _tryLaunch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    try {
      if (!await canLaunchUrl(uri)) return false;
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
