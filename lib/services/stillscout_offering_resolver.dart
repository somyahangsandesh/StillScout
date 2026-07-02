import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:stillscout/config/stillscout_config.dart';

/// Resolved monthly/yearly Pro packages from a RevenueCat offering.
class StillScoutProOffering {
  const StillScoutProOffering({
    required this.offering,
    this.monthly,
    this.yearly,
  });

  final Offering offering;
  final Package? monthly;
  final Package? yearly;

  bool get hasPackages => monthly != null || yearly != null;

  /// e.g. "SAVE 40%" when yearly beats 12× monthly.
  String? get yearlySavingsLabel {
    final m = monthly?.storeProduct.price;
    final y = yearly?.storeProduct.price;
    if (m == null || y == null || m <= 0) return null;
    final annualizedMonthly = m * 12;
    if (annualizedMonthly <= y) return null;
    final pct = ((1 - y / annualizedMonthly) * 100).round().clamp(1, 99);
    return 'SAVE $pct%';
  }

  String get monthlyPriceLabel =>
      monthly?.storeProduct.priceString ?? '—';

  String get yearlyPriceLabel =>
      yearly?.storeProduct.priceString ?? '—';

  /// Per-month equivalent for yearly plan (shown under yearly chip).
  String? get yearlyPerMonthLabel {
    final y = yearly?.storeProduct.price;
    if (y == null || y <= 0) return null;
    final perMonth = y / 12;
    final currency = yearly?.storeProduct.currencyCode ?? 'USD';
    return '${_formatPrice(perMonth, currency)}/mo';
  }

  static String _formatPrice(double amount, String currencyCode) {
    // RevenueCat already localizes priceString; this is a simple fallback.
    if (currencyCode == 'USD') return '\$${amount.toStringAsFixed(2)}';
    return '${amount.toStringAsFixed(2)} $currencyCode';
  }
}

/// Finds the best RevenueCat offering + Pro packages for the paywall.
class StillScoutOfferingResolver {
  StillScoutOfferingResolver._();

  static const _offeringIds = [
    StillScoutConfig.rcOfferingIdentifier,
    'default',
    'stillscout_main',
  ];

  /// Picks the first matching offering, then resolves monthly/yearly packages
  /// by package type OR store product identifier.
  static StillScoutProOffering? resolve(Offerings? offerings) {
    if (offerings == null) return null;

    Offering? offering;
    for (final id in _offeringIds) {
      final candidate = offerings.getOffering(id);
      if (candidate != null && candidate.availablePackages.isNotEmpty) {
        offering = candidate;
        break;
      }
    }
    offering ??= offerings.current;
    if (offering == null || offering.availablePackages.isEmpty) return null;

    return StillScoutProOffering(
      offering: offering,
      monthly: _findPackage(
        offering,
        packageType: PackageType.monthly,
        productId: StillScoutConfig.rcProMonthlyId,
      ),
      yearly: _findPackage(
        offering,
        packageType: PackageType.annual,
        productId: StillScoutConfig.rcProYearlyId,
      ),
    );
  }

  static Package? _findPackage(
    Offering offering, {
    required PackageType packageType,
    required String productId,
  }) {
    for (final pkg in offering.availablePackages) {
      if (pkg.storeProduct.identifier == productId) return pkg;
    }
    for (final pkg in offering.availablePackages) {
      if (pkg.packageType == packageType) return pkg;
    }
    // Custom package identifiers used in some RC dashboards.
    final customId = packageType == PackageType.monthly ? '\$rc_monthly' : '\$rc_annual';
    for (final pkg in offering.availablePackages) {
      if (pkg.identifier == customId) return pkg;
    }
    return null;
  }
}
