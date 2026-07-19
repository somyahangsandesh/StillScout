import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:stillscout/services/stillscout_offering_resolver.dart';
import 'package:stillscout/services/stillscout_purchase_service.dart';
import '../../domain/stillscout_access_policy.dart';
import '../../domain/stillscout_constants.dart';
import '../providers/stillscout_notifier.dart';
import '../theme/stillscout_theme.dart';
import 'stillscout_buttons.dart';
import 'stillscout_legal_links.dart';

typedef PaywallPurchasedCallback = void Function();

class StillScoutPaywallSheet extends ConsumerStatefulWidget {
  const StillScoutPaywallSheet({
    super.key,
    required this.exportsRemaining,
    required this.onPurchased,
    this.reason,
    this.lockedCount,
    this.bestLockedScore,
  });

  final int exportsRemaining;
  final PaywallPurchasedCallback onPurchased;
  final String? reason;

  /// Number of frames currently locked in the active scout — shown in the
  /// personalised hook card to create specific, concrete FOMO.
  final int? lockedCount;

  /// Highest score among locked frames — shown alongside [lockedCount].
  final double? bestLockedScore;

  static Future<void> show(
    BuildContext context, {
    required int exportsRemaining,
    required PaywallPurchasedCallback onPurchased,
    String? reason,
    int? lockedCount,
    double? bestLockedScore,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StillScoutPaywallSheet(
        exportsRemaining: exportsRemaining,
        onPurchased: onPurchased,
        reason: reason,
        lockedCount: lockedCount,
        bestLockedScore: bestLockedScore,
      ),
    );
  }

  @override
  ConsumerState<StillScoutPaywallSheet> createState() =>
      _StillScoutPaywallSheetState();
}

class _StillScoutPaywallSheetState extends ConsumerState<StillScoutPaywallSheet> {
  bool _loading = false;
  bool _loadingPackages = true;
  bool _yearlySelected = true;
  String? _error;
  bool _paymentPending = false;
  Package? _lastAttemptedPackage;
  StillScoutProOffering? _proOffering;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    setState(() {
      _loadingPackages = true;
      _error = null;
    });
    if (!StillScoutPurchaseService.isInitialized) {
      await StillScoutPurchaseService.retryInitialize();
    }
    final offering = await StillScoutPurchaseService.getProOffering();
    if (!mounted) return;
    setState(() {
      _proOffering = offering;
      _loadingPackages = false;
      if (offering?.yearly == null && offering?.monthly != null) {
        _yearlySelected = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final offering = _proOffering;
    final selected = _yearlySelected ? offering?.yearly : offering?.monthly;
    final storeReady = offering?.hasPackages == true && selected != null;
    final price = selected?.storeProduct.priceString;
    final exportsLeft = StillScoutAccessPolicy.displayExportsRemaining(
      exportsRemaining: widget.exportsRemaining,
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.35,
        maxChildSize: 0.94,
        shouldCloseOnMinExtent: true,
        builder: (context, scrollController) {
          return Material(
            color: StillScoutColors.voidBlack,
            borderRadius: StillScoutRadius.sheet,
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  StillScoutSpacing.m,
                  StillScoutSpacing.s,
                  StillScoutSpacing.m,
                  StillScoutSpacing.l,
                ),
                children: [
                _Handle(),
                const SizedBox(height: StillScoutSpacing.l),
                _HeroBadge(),
                const SizedBox(height: StillScoutSpacing.m),
                Text(
                  'StillScout AI Pro',
                  style: StillScoutTextStyles.display.copyWith(fontSize: 34),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: StillScoutSpacing.xs),
                Text(
                  'AI finds your best moment and turns it into a professional photo.',
                  style: StillScoutTextStyles.bodySmall.copyWith(
                    color: StillScoutColors.accent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: StillScoutSpacing.s),
                // Personalised hook card — only shown when we know what's locked.
                if (widget.lockedCount != null &&
                    widget.lockedCount! > 0 &&
                    widget.bestLockedScore != null) ...[
                  _PersonalizedHook(
                    lockedCount: widget.lockedCount!,
                    bestLockedScore: widget.bestLockedScore!,
                  ),
                  const SizedBox(height: StillScoutSpacing.m),
                ],
                if (widget.reason != null) ...[
                  Text(
                    widget.reason!,
                    style: StillScoutTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: StillScoutSpacing.s),
                ] else if (exportsLeft > 0)
                  Text(
                    'You have $exportsLeft save${exportsLeft != 1 ? 's' : ''} left this scout. '
                    'Go Pro for unlimited scouts, ${StillScoutConstants.proKeeperLimit} keepers, and native 4K.',
                    style: StillScoutTextStyles.body,
                    textAlign: TextAlign.center,
                  )
                else
                  Text(
                    'You\'ve used all ${StillScoutConstants.freeExportsPerScout} saves for this scout. '
                    'Upgrade for unlimited scouts and native 4K exports.',
                    style: StillScoutTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: StillScoutSpacing.l),
                _FeatureBullets(),
                const SizedBox(height: StillScoutSpacing.l),
                if (_loadingPackages)
                  const Padding(
                    padding: EdgeInsets.all(StillScoutSpacing.m),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else if (offering == null || !offering.hasPackages)
                  _StoreUnavailableHint(onRetry: _loading ? null : _loadPackages)
                else
                  _PlanToggle(
                    yearlySelected: _yearlySelected,
                    onChanged: (v) => setState(() => _yearlySelected = v),
                    monthlyPrice: offering.monthlyPriceLabel,
                    yearlyPrice: offering.yearlyPriceLabel,
                    yearlyPerMonth: offering.yearlyPerMonthLabel,
                    savingsBadge: offering.yearlySavingsLabel ?? 'BEST VALUE',
                  ),
                const SizedBox(height: StillScoutSpacing.m),
                Semantics(
                  label: storeReady
                      ? 'Start Pro for $price'
                      : 'Pro prices unavailable',
                  button: true,
                  child: StillScoutPrimaryButton(
                    label: storeReady
                        ? 'Start Pro · $price'
                        : 'Prices unavailable',
                    icon: Icons.bolt_rounded,
                    height: 56,
                    expand: true,
                    backgroundColor: StillScoutColors.scoutGold,
                    foregroundColor: StillScoutColors.voidBlack,
                    isLoading: _loading,
                    onPressed: (_loading ||
                            _loadingPackages ||
                            !storeReady)
                        ? null
                        : () => _purchase(selected),
                  ),
                ),
                const SizedBox(height: StillScoutSpacing.s),
                Center(
                  child: Semantics(
                    label: 'Restore purchases',
                    button: true,
                    child: TextButton.icon(
                      onPressed: _loading ? null : _restore,
                      style: TextButton.styleFrom(
                        foregroundColor:
                            StillScoutColors.silver.withValues(alpha: 0.9),
                        minimumSize: const Size(44, 44),
                        padding: const EdgeInsets.symmetric(
                          horizontal: StillScoutSpacing.m,
                          vertical: StillScoutSpacing.s,
                        ),
                      ),
                      icon: const Icon(Icons.restore_rounded, size: 18),
                      label: Text(
                        'Restore Purchases',
                        style: StillScoutTextStyles.caption.copyWith(
                          color: StillScoutColors.chalk,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_paymentPending) ...[
                  const SizedBox(height: StillScoutSpacing.s),
                  _PaymentPendingBanner(onRestore: _loading ? null : _restore),
                ],
                if (_error != null) ...[
                  const SizedBox(height: StillScoutSpacing.s),
                  _PurchaseErrorBanner(
                    message: _error!,
                    onRetry: _loading
                        ? null
                        : () {
                            final pkg = _lastAttemptedPackage ?? selected;
                            if (pkg != null) {
                              _purchase(pkg);
                            } else {
                              _loadPackages();
                            }
                          },
                  ),
                ],
                const SizedBox(height: StillScoutSpacing.s),
                Text(
                  storeReady
                      ? (_yearlySelected
                          ? 'StillScout Pro Yearly · $price · auto-renews until canceled in Settings → Apple ID → Subscriptions.'
                          : 'StillScout Pro Monthly · $price · auto-renews until canceled in Settings → Apple ID → Subscriptions.')
                      : 'Subscription prices load from the App Store. Check your connection and try again.',
                  style: StillScoutTextStyles.caption.copyWith(
                    color: StillScoutColors.silver.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: StillScoutSpacing.s),
                const StillScoutLegalLinks(showAppleEula: true),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _applyPurchaseSuccess(StillScoutPurchaseResult result) {
    ref
        .read(stillScoutProvider.notifier)
        .onPurchaseCompleted(hasPro: result.hasPro);
    widget.onPurchased();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _purchase(Package? package) async {
    if (package == null) {
      setState(() {
        _error =
            'Store products aren’t available yet. Check your connection and try again.';
        _paymentPending = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _paymentPending = false;
      _lastAttemptedPackage = package;
    });
    final result = await StillScoutPurchaseService.purchasePackage(package);
    if (!mounted) return;
    setState(() => _loading = false);
    // W2.1 — cancelled: silent (no error banner)
    if (result.cancelled) return;
    if (result.paymentPending) {
      setState(() {
        _paymentPending = true;
        _error = null;
      });
      return;
    }
    if (result.success && result.hasPro) {
      _applyPurchaseSuccess(result);
      return;
    }
    setState(() {
      _error = result.error ?? 'Purchase failed.';
      _paymentPending = false;
    });
  }

  Future<void> _restore() async {
    setState(() {
      _loading = true;
      _error = null;
      _paymentPending = false;
    });
    final result = await StillScoutPurchaseService.restorePurchases();
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.hasPro) {
      _applyPurchaseSuccess(result);
      return;
    }
    if (result.success) {
      setState(
        () => _error = StillScoutAccessPolicy.noActiveProSubscriptionMessage,
      );
    } else {
      setState(() => _error = result.error ?? 'Could not restore purchases.');
    }
  }
}

class _StoreUnavailableHint extends StatelessWidget {
  const _StoreUnavailableHint({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(StillScoutSpacing.m),
      decoration: StillScoutDecorations.surfaceCard(),
      child: Column(
        children: [
          const Icon(Icons.store_outlined, color: StillScoutColors.silver),
          const SizedBox(height: StillScoutSpacing.s),
          Text(
            'Prices aren’t loading right now',
            style: StillScoutTextStyles.bodySmall.copyWith(
              color: StillScoutColors.chalk,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Check your internet connection and try again. '
            'If you already subscribed, use Restore Purchases below.',
            style: StillScoutTextStyles.caption,
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: StillScoutSpacing.s),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: StillScoutTextStyles.caption.copyWith(
                  color: StillScoutColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentPendingBanner extends StatelessWidget {
  const _PaymentPendingBanner({this.onRestore});

  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(StillScoutSpacing.m),
      decoration: BoxDecoration(
        color: StillScoutColors.scoutGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(StillScoutRadius.m),
        border: Border.all(
          color: StillScoutColors.scoutGold.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Payment pending',
            style: StillScoutTextStyles.bodySmall.copyWith(
              color: StillScoutColors.scoutGold,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Apple is still confirming your payment. When it clears, tap Restore Purchases.',
            style: StillScoutTextStyles.caption.copyWith(
              color: StillScoutColors.chalk,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRestore != null)
            TextButton(
              onPressed: onRestore,
              child: Text(
                'Restore Purchases',
                style: StillScoutTextStyles.caption.copyWith(
                  color: StillScoutColors.scoutGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PurchaseErrorBanner extends StatelessWidget {
  const _PurchaseErrorBanner({
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(StillScoutSpacing.m),
      decoration: BoxDecoration(
        color: StillScoutColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(StillScoutRadius.m),
        border: Border.all(
          color: StillScoutColors.danger.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Text(
            message,
            style: StillScoutTextStyles.caption.copyWith(
              color: StillScoutColors.danger,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Try again',
                style: StillScoutTextStyles.caption.copyWith(
                  color: StillScoutColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: StillScoutColors.silver.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: StillScoutColors.scoutGold.withValues(alpha: 0.12),
        border: Border.all(
          color: StillScoutColors.scoutGold.withValues(alpha: 0.5),
        ),
        boxShadow: [StillScoutColors.goldGlow(alpha: 0.25, blur: 24)],
      ),
      child: const Icon(
        Icons.star_rounded,
        color: StillScoutColors.scoutGold,
        size: 32,
      ),
    );
  }
}

class _FeatureBullets extends StatelessWidget {
  /// Four punchy lines — keeps the purchase CTA above the fold on most phones.
  static List<(IconData, String)> get _features => [
        (Icons.auto_awesome, 'Gemini judgment on every scout'),
        (Icons.photo_filter_rounded, 'AI Auto Polish with before/after'),
        (
          Icons.workspace_premium_rounded,
          '${StillScoutConstants.proKeeperLimit} keepers · exact timecodes',
        ),
        (
          Icons.all_inclusive_rounded,
          'Unlimited scouts · native 4K saves',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        StillScoutSpacing.m,
        StillScoutSpacing.s + 2,
        StillScoutSpacing.m,
        StillScoutSpacing.s + 2,
      ),
      decoration: StillScoutDecorations.surfaceCard(),
      child: Column(
        children: [
          for (final f in _features)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Icon(f.$1, size: 18, color: StillScoutColors.accent),
                  const SizedBox(width: StillScoutSpacing.m),
                  Expanded(
                    child: Text(
                      f.$2,
                      style: StillScoutTextStyles.bodySmall.copyWith(
                        color: StillScoutColors.chalk,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: StillScoutColors.success,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PlanToggle extends StatelessWidget {
  const _PlanToggle({
    required this.yearlySelected,
    required this.onChanged,
    required this.monthlyPrice,
    required this.yearlyPrice,
    this.yearlyPerMonth,
    this.savingsBadge,
  });

  final bool yearlySelected;
  final ValueChanged<bool> onChanged;
  final String monthlyPrice;
  final String yearlyPrice;
  final String? yearlyPerMonth;
  final String? savingsBadge;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: StillScoutColors.slate,
        borderRadius: BorderRadius.circular(StillScoutRadius.m),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PlanChip(
              label: 'Monthly',
              price: monthlyPrice,
              selected: !yearlySelected,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _PlanChip(
              label: 'Yearly',
              price: yearlyPrice,
              subtitle: yearlyPerMonth,
              selected: yearlySelected,
              onTap: () => onChanged(true),
              badge: savingsBadge,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanChip extends StatelessWidget {
  const _PlanChip({
    required this.label,
    required this.price,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.badge,
  });

  final String label;
  final String price;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label plan, $price${badge != null ? ', $badge' : ''}${selected ? ', selected' : ''}',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? StillScoutColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(StillScoutRadius.s + 2),
          ),
          child: Column(
            children: [
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected
                        ? StillScoutColors.voidBlack.withValues(alpha: 0.15)
                        : StillScoutColors.scoutGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(StillScoutRadius.pill),
                  ),
                  child: Text(
                    badge!,
                    style: StillScoutTextStyles.badge.copyWith(
                      color: selected
                          ? StillScoutColors.voidBlack
                          : StillScoutColors.scoutGold,
                      fontSize: 9,
                    ),
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                label,
                style: StillScoutTextStyles.caption.copyWith(
                  color: selected
                      ? StillScoutColors.voidBlack
                      : StillScoutColors.chalk,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                price,
                style: StillScoutTextStyles.caption.copyWith(
                  color: selected
                      ? StillScoutColors.voidBlack
                      : StillScoutColors.silver,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: StillScoutTextStyles.caption.copyWith(
                    color: selected
                        ? StillScoutColors.voidBlack.withValues(alpha: 0.7)
                        : StillScoutColors.silver.withValues(alpha: 0.8),
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gold-bordered card showing the specific number of locked frames and the
/// highest score among them, creating concrete FOMO before the subscribe CTA.
class _PersonalizedHook extends StatelessWidget {
  const _PersonalizedHook({
    required this.lockedCount,
    required this.bestLockedScore,
  });

  final int lockedCount;
  final double bestLockedScore;

  @override
  Widget build(BuildContext context) {
    final scoreLabel = bestLockedScore >= 10.0
        ? '10'
        : bestLockedScore.toStringAsFixed(1);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: StillScoutSpacing.m,
        vertical: StillScoutSpacing.s,
      ),
      decoration: BoxDecoration(
        color: StillScoutColors.scoutGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: StillScoutColors.scoutGold.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.lock_rounded,
            color: StillScoutColors.scoutGold,
            size: 16,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: StillScoutTextStyles.caption.copyWith(
                  color: StillScoutColors.chalk,
                ),
                children: [
                  TextSpan(
                    text: '$lockedCount ',
                    style: const TextStyle(
                      color: StillScoutColors.scoutGold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text:
                        '${lockedCount == 1 ? 'frame' : 'frames'} locked from your scout',
                  ),
                  const TextSpan(text: ' · best score '),
                  TextSpan(
                    text: scoreLabel,
                    style: const TextStyle(
                      color: StillScoutColors.scoutGold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
