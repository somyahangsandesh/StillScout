import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:stillscout/config/stillscout_config.dart';
import 'package:stillscout/services/stillscout_purchase_service.dart';

import '../../domain/repositories/session_repository.dart';
import '../../services/stillscout_cache_janitor.dart';
import '../../services/stillscout_diagnostics_log.dart';
import '../../services/stillscout_score_cache.dart';
import '../providers/stillscout_notifier.dart';
import '../theme/stillscout_theme.dart';
import '../widgets/stillscout_legal_links.dart';
import 'stillscout_legal_screen.dart';

/// Minimal account / support surface for App Store polish.
class StillScoutSettingsScreen extends ConsumerStatefulWidget {
  const StillScoutSettingsScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const StillScoutSettingsScreen(),
      ),
    );
  }

  @override
  ConsumerState<StillScoutSettingsScreen> createState() =>
      _StillScoutSettingsScreenState();
}

class _StillScoutSettingsScreenState
    extends ConsumerState<StillScoutSettingsScreen> {
  bool _restoring = false;
  bool _retryingStore = false;
  bool _clearing = false;
  String _versionLabel = StillScoutConfig.appVersion;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _versionLabel = info.version);
    } catch (_) {
      // Fall back to StillScoutConfig.appVersion.
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(stillScoutProvider.select((s) => s.isPro));
    final checkFailed = ref.watch(
      stillScoutProvider.select((s) => s.subscriptionCheckFailed),
    );
    final storeMsg = StillScoutPurchaseService.storeStatusMessage();
    final storeUnavailable = storeMsg.isNotEmpty || checkFailed;

    return Scaffold(
      backgroundColor: StillScoutColors.voidBlack,
      appBar: AppBar(
        backgroundColor: StillScoutColors.voidBlack,
        foregroundColor: StillScoutColors.chalk,
        title: Text('Settings', style: StillScoutTextStyles.subtitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            StillScoutSpacing.m,
            StillScoutSpacing.s,
            StillScoutSpacing.m,
            StillScoutSpacing.xl,
          ),
          children: [
            Text(
              'Subscription',
              style: StillScoutTextStyles.caption.copyWith(
                color: StillScoutColors.silver,
              ),
            ),
            const SizedBox(height: StillScoutSpacing.s),
            if (storeUnavailable) ...[
              _StoreStatusCard(
                message: storeMsg.isNotEmpty
                    ? storeMsg
                    : 'Couldn’t verify your subscription. You’re on Free until '
                        'we reconnect — tap Retry.',
                retrying: _retryingStore,
                onRetry: _retryingStore ? null : _retryStore,
              ),
              const SizedBox(height: StillScoutSpacing.s),
            ],
            _SettingsTile(
              icon: Icons.workspace_premium_outlined,
              title: isPro
                  ? 'AI Pro active'
                  : (storeUnavailable ? 'Plan unknown' : 'Free plan'),
              subtitle: isPro
                  ? 'Unlimited scouts · ${StillScoutConfig.geminiModelDisplayName} · Auto Polish'
                  : storeUnavailable
                      ? 'Store unavailable — Pro benefits paused until verified'
                      : '2 free scouts/day · 5 keepers (8 on first scout) · 3 exports',
            ),
            _SettingsTile(
              icon: Icons.restore_rounded,
              title: 'Restore purchases',
              subtitle: 'Recover AI Pro on this device',
              trailing: _restoring
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onTap: _restoring ? null : _restore,
            ),
            _SettingsTile(
              icon: Icons.manage_accounts_outlined,
              title: 'Manage subscription',
              subtitle: 'Apple ID → Subscriptions',
              onTap: _openManageSubscriptions,
            ),
            const SizedBox(height: StillScoutSpacing.l),
            Text(
              'Support & legal',
              style: StillScoutTextStyles.caption.copyWith(
                color: StillScoutColors.silver,
              ),
            ),
            const SizedBox(height: StillScoutSpacing.s),
            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () => StillScoutLegalScreen.open(
                context,
                document: StillScoutLegalDocument.privacyPolicy,
              ),
            ),
            _SettingsTile(
              icon: Icons.gavel_outlined,
              title: 'Terms of Use',
              onTap: () => StillScoutLegalScreen.open(
                context,
                document: StillScoutLegalDocument.termsOfUse,
              ),
            ),
            _SettingsTile(
              icon: Icons.support_agent_outlined,
              title: 'Support',
              subtitle: StillScoutConfig.supportUrl,
              onTap: () => _launch(StillScoutConfig.supportUrl),
            ),
            _SettingsTile(
              icon: Icons.bug_report_outlined,
              title: 'Copy diagnostics',
              subtitle: 'Recent app logs for support (no full file paths)',
              onTap: _copyDiagnostics,
            ),
            const SizedBox(height: StillScoutSpacing.m),
            const StillScoutLegalLinks(preferExternalUrls: true),
            const SizedBox(height: StillScoutSpacing.l),
            Text(
              'Storage',
              style: StillScoutTextStyles.caption.copyWith(
                color: StillScoutColors.silver,
              ),
            ),
            const SizedBox(height: StillScoutSpacing.s),
            _SettingsTile(
              icon: Icons.cleaning_services_outlined,
              title: 'Clear cache',
              subtitle: 'Removes orphaned frame thumbnails and score cache',
              trailing: _clearing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onTap: _clearing ? null : _clearCache,
            ),
            const SizedBox(height: StillScoutSpacing.xl),
            Text(
              '${StillScoutConfig.appName} $_versionLabel',
              style: StillScoutTextStyles.caption.copyWith(
                color: StillScoutColors.silver.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _retryStore() async {
    setState(() => _retryingStore = true);
    try {
      await ref.read(stillScoutProvider.notifier).retrySubscriptionCheck();
      if (!mounted) return;
      final stillFailed = ref.read(stillScoutProvider).subscriptionCheckFailed;
      final storeMsg = StillScoutPurchaseService.storeStatusMessage();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: StillScoutColors.slate,
          content: Text(
            (!stillFailed && storeMsg.isEmpty)
                ? 'Store connection restored.'
                : 'Still can’t reach the App Store. Try again in a moment.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _retryingStore = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _restoring = true);
    try {
      final result = await StillScoutPurchaseService.restorePurchases();
      if (result.hasPro) {
        ref
            .read(stillScoutProvider.notifier)
            .onPurchaseCompleted(hasPro: true);
      } else {
        await ref.read(stillScoutProvider.notifier).refreshSubscriptionState();
      }
      if (!mounted) return;
      final msg = result.cancelled
          ? 'Restore cancelled.'
          : result.success
              ? (result.hasPro
                  ? 'AI Pro restored on this device.'
                  : 'No active subscription found.')
              : (result.error ?? 'Could not restore purchases.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: StillScoutColors.slate,
          content: Text(msg),
        ),
      );
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  Future<void> _openManageSubscriptions() async {
    const url = 'https://apps.apple.com/account/subscriptions';
    await _launch(url);
  }

  Future<void> _clearCache() async {
    setState(() => _clearing = true);
    try {
      final SessionRepository sessions =
          ref.read(stillScoutProvider.notifier).getSessionRepository();
      final active = (await sessions.getSessions())
          .map((s) => s.id)
          .toList(growable: false);
      await StillScoutCacheJanitor.evict(activeSessions: active);
      await StillScoutScoreCache.clearAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: StillScoutColors.slate,
          content: Text('Cache cleared.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: StillScoutColors.slate,
          content: Text('Could not clear cache.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  Future<void> _copyDiagnostics() async {
    final dump = StillScoutDiagnosticsLog.dump();
    await Clipboard.setData(ClipboardData(text: dump));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: StillScoutColors.slate,
        content: Text('Diagnostics copied to clipboard.'),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _StoreStatusCard extends StatelessWidget {
  const _StoreStatusCard({
    required this.message,
    required this.retrying,
    this.onRetry,
  });

  final String message;
  final bool retrying;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(StillScoutSpacing.m),
      decoration: BoxDecoration(
        color: StillScoutColors.scoutGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(StillScoutRadius.m),
        border: Border.all(
          color: StillScoutColors.scoutGold.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.storefront_outlined,
                size: 18,
                color: StillScoutColors.scoutGold.withValues(alpha: 0.95),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'App Store unavailable',
                  style: StillScoutTextStyles.bodySmall.copyWith(
                    color: StillScoutColors.chalk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (retrying)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (onRetry != null)
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: StillScoutColors.accent,
                    minimumSize: const Size(44, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    'Retry',
                    style: StillScoutTextStyles.caption.copyWith(
                      color: StillScoutColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: StillScoutTextStyles.caption.copyWith(
              color: StillScoutColors.silver,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: StillScoutColors.accent),
      title: Text(title, style: StillScoutTextStyles.subtitle.copyWith(fontSize: 15)),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: StillScoutTextStyles.caption.copyWith(
                color: StillScoutColors.silver,
              ),
            ),
      trailing: trailing ??
          (onTap == null
              ? null
              : const Icon(Icons.chevron_right, color: StillScoutColors.silver)),
      onTap: onTap,
    );
  }
}
