import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:stillscout/config/stillscout_config.dart';
import 'package:stillscout/services/stillscout_offering_resolver.dart';
import 'package:stillscout/services/stillscout_purchase_service.dart';
import '../../domain/stillscout_access_policy.dart';
import '../../domain/stillscout_constants.dart';
import '../theme/stillscout_theme.dart';

typedef PaywallPurchasedCallback = void Function();

class StillScoutPaywallSheet extends ConsumerStatefulWidget {
  const StillScoutPaywallSheet({
    super.key,
    required this.exportsRemaining,
    required this.onPurchased,
    this.reason,
  });

  final int exportsRemaining;
  final PaywallPurchasedCallback onPurchased;
  final String? reason;

  static Future<void> show(
    BuildContext context, {
    required int exportsRemaining,
    required PaywallPurchasedCallback onPurchased,
    String? reason,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: StillScoutColors.voidBlack,
      shape: RoundedRectangleBorder(borderRadius: StillScoutRadius.sheet),
      builder: (_) => StillScoutPaywallSheet(
        exportsRemaining: exportsRemaining,
        onPurchased: onPurchased,
        reason: reason,
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
  StillScoutProOffering? _proOffering;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
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
    final price = selected?.storeProduct.priceString ??
        (_yearlySelected ? '\$39.99/yr' : '\$4.99/mo');
    final exportsLeft = StillScoutAccessPolicy.displayExportsRemaining(
      exportsRemaining: widget.exportsRemaining,
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              StillScoutSpacing.m,
              StillScoutSpacing.s,
              StillScoutSpacing.m,
              StillScoutSpacing.l,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Handle(),
                const SizedBox(height: StillScoutSpacing.l),
                _HeroBadge(),
                const SizedBox(height: StillScoutSpacing.m),
                Text(
                  'StillScout Pro',
                  style: StillScoutTextStyles.display.copyWith(fontSize: 34),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: StillScoutSpacing.xs),
                Text(
                  'Unlock the full creator toolkit',
                  style: StillScoutTextStyles.bodySmall.copyWith(
                    color: StillScoutColors.accent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: StillScoutSpacing.s),
                if (widget.reason != null) ...[
                  Text(
                    widget.reason!,
                    style: StillScoutTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: StillScoutSpacing.s),
                ] else if (exportsLeft > 0)
                  Text(
                    'You have $exportsLeft polished save${exportsLeft != 1 ? 's' : ''} left this scout. '
                    'Go Pro for unlimited scouts, 10 keepers, and native 4K.',
                    style: StillScoutTextStyles.body,
                    textAlign: TextAlign.center,
                  )
                else
                  Text(
                    'You\'ve used all ${StillScoutConstants.freeExportsPerScout} polished saves for this scout. '
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
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (offering == null || !offering.hasPackages)
                  _StoreUnavailableHint()
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
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Semantics(
                    label: 'Unlock Pro for $price',
                    button: true,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: StillScoutColors.scoutGold,
                        foregroundColor: StillScoutColors.voidBlack,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(StillScoutRadius.m),
                        ),
                        minimumSize: const Size.fromHeight(56),
                      ),
                      onPressed: (_loading || _loadingPackages)
                          ? null
                          : () => _purchase(selected),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.bolt, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  offering?.hasPackages == true
                                      ? 'Start Pro · $price'
                                      : 'Pro coming soon',
                                  style: StillScoutTextStyles.subtitle.copyWith(
                                    color: StillScoutColors.voidBlack,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: StillScoutSpacing.s),
                  Text(
                    _error!,
                    style: StillScoutTextStyles.caption.copyWith(
                      color: StillScoutColors.danger,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                TextButton(
                  onPressed: _loading ? null : _restore,
                  child: Text(
                    'Restore purchases',
                    style: StillScoutTextStyles.caption.copyWith(
                      color: StillScoutColors.silver,
                    ),
                  ),
                ),
                Text(
                  'Subscription renews automatically. Cancel anytime in Settings.',
                  style: StillScoutTextStyles.caption.copyWith(
                    color: StillScoutColors.silver.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _purchase(Package? package) async {
    if (package == null) {
      setState(() => _error =
          'Store products are not available yet. Check RevenueCat dashboard setup.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await StillScoutPurchaseService.purchasePackage(package);
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.cancelled) return;
    if (result.success && result.hasPro) {
      widget.onPurchased();
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() => _error = result.error ?? 'Purchase failed.');
  }

  Future<void> _restore() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await StillScoutPurchaseService.restorePurchases();
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.hasPro) {
      widget.onPurchased();
      if (mounted) Navigator.of(context).pop();
    } else {
      setState(() => _error = 'No active Pro subscription found.');
    }
  }
}

class _StoreUnavailableHint extends StatelessWidget {
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
            'Store products loading…',
            style: StillScoutTextStyles.bodySmall.copyWith(
              color: StillScoutColors.chalk,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Ensure offering "${StillScoutConfig.rcOfferingIdentifier}" and '
            'entitlement "${StillScoutConfig.rcEntitlementPro}" exist in RevenueCat.',
            style: StillScoutTextStyles.caption,
            textAlign: TextAlign.center,
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
  static const _features = [
    (
      Icons.workspace_premium_rounded,
      '10 Top Picks per scout',
      'See every ranked keeper — not just the first 3',
    ),
    (
      Icons.access_time_filled_rounded,
      'Exact timecodes',
      'Copy precise timestamps to scrub your source video',
    ),
    (
      Icons.all_inclusive_rounded,
      'Unlimited scouts',
      'Scout as many videos as you need — no weekly cap',
    ),
    (
      Icons.photo_size_select_large_rounded,
      'Native 4K + Auto Polish',
      'Full-resolution re-extract with on-device polish',
    ),
    (
      Icons.view_timeline_outlined,
      'Timeline gallery view',
      'Browse frames in chronological order',
    ),
    (
      Icons.auto_awesome,
      'Multi-AI frame scoring',
      'Groq, Gemini, Grok + on-device ML Kit',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(StillScoutSpacing.m),
      decoration: StillScoutDecorations.surfaceCard(),
      child: Column(
        children: _features
            .map(
              (f) => Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: StillScoutSpacing.s,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: StillScoutColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(StillScoutRadius.s),
                      ),
                      child: Icon(f.$1, size: 18, color: StillScoutColors.accent),
                    ),
                    const SizedBox(width: StillScoutSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.$2,
                            style: StillScoutTextStyles.bodySmall.copyWith(
                              color: StillScoutColors.chalk,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(f.$3, style: StillScoutTextStyles.caption),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: StillScoutColors.success,
                    ),
                  ],
                ),
              ),
            )
            .toList(),
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
