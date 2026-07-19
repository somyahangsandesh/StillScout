import 'package:flutter/material.dart';

import '../../domain/stillscout_legal_copy.dart';
import '../theme/stillscout_theme.dart';

enum StillScoutLegalDocument { privacyPolicy, termsOfUse }

/// Full-screen legal document viewer for App Store Guideline 3.1.2.
class StillScoutLegalScreen extends StatelessWidget {
  const StillScoutLegalScreen({super.key, required this.document});

  final StillScoutLegalDocument document;

  static Future<void> open(
    BuildContext context, {
    required StillScoutLegalDocument document,
    bool replace = false,
  }) {
    final route = MaterialPageRoute<void>(
      builder: (_) => StillScoutLegalScreen(document: document),
    );
    return replace
        ? Navigator.of(context).pushReplacement(route)
        : Navigator.of(context).push(route);
  }

  @override
  Widget build(BuildContext context) {
    final isPrivacy = document == StillScoutLegalDocument.privacyPolicy;
    final title = isPrivacy
        ? StillScoutLegalCopy.privacyPolicyTitle
        : StillScoutLegalCopy.termsOfUseTitle;
    final body = isPrivacy
        ? StillScoutLegalCopy.privacyPolicyBody
        : StillScoutLegalCopy.termsOfUseBody;
    final otherLabel = isPrivacy ? 'Terms of Use' : 'Privacy Policy';
    final otherDoc = isPrivacy
        ? StillScoutLegalDocument.termsOfUse
        : StillScoutLegalDocument.privacyPolicy;

    return Scaffold(
      backgroundColor: StillScoutColors.voidBlack,
      appBar: AppBar(
        backgroundColor: StillScoutColors.voidBlack,
        foregroundColor: StillScoutColors.chalk,
        title: Text(title, style: StillScoutTextStyles.subtitle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  StillScoutSpacing.m,
                  StillScoutSpacing.s,
                  StillScoutSpacing.m,
                  StillScoutSpacing.l,
                ),
                child: SelectableText(
                  body,
                  style: StillScoutTextStyles.body.copyWith(
                    color: StillScoutColors.silver,
                    height: 1.45,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => open(context, document: otherDoc, replace: true),
              child: Text(
                'View $otherLabel',
                style: StillScoutTextStyles.caption.copyWith(
                  color: StillScoutColors.accent,
                ),
              ),
            ),
            const SizedBox(height: StillScoutSpacing.s),
          ],
        ),
      ),
    );
  }
}
