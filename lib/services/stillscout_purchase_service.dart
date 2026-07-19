// ============================================================================
// stillscout_purchase_service.dart — RevenueCat IAP facade for StillScout
// ============================================================================
// Dashboard checklist (app.revenuecat.com):
// 1. Add iOS app — bundle ID: com.stillscout.stillscout
// 2. Entitlement identifier: pro
// 3. Products (App Store Connect): stillscout_pro_monthly, stillscout_pro_yearly
// 4. Offering identifier: stillscout_main (or default)
// 5. Attach monthly + annual packages to the offering
// 6. Paste PUBLIC SDK key (appl_…) into secrets.local.dart — NOT sk_ secret keys
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:stillscout/config/stillscout_config.dart';
import 'package:stillscout/stillscout/services/stillscout_diagnostics_log.dart';

import 'stillscout_offering_resolver.dart';

/// Observable RevenueCat / App Store init outcome.
enum StillScoutIapInitStatus {
  /// Purchases.configure succeeded.
  ready,

  /// Configure threw or store returned an unrecoverable error.
  failed,

  /// No usable public SDK key in this build (release without appl_…).
  notConfigured,
}

/// Result of a Pro entitlement check — never treat a failed check as "free forever".
class SubscriptionCheckResult {
  const SubscriptionCheckResult({
    required this.isPro,
    required this.checkFailed,
  });

  final bool isPro;

  /// True when the store / SDK could not be queried. UI should surface a retry.
  final bool checkFailed;
}

/// RevenueCat wrapper for StillScout Pro — unlimited exports + native-res saves.
class StillScoutPurchaseService {
  StillScoutPurchaseService._();

  static bool _initialized = false;
  static StillScoutIapInitStatus _initStatus =
      StillScoutIapInitStatus.notConfigured;

  static StillScoutIapInitStatus get initStatus => _initStatus;

  static Future<StillScoutIapInitStatus> initialize() async {
    if (_initStatus == StillScoutIapInitStatus.ready && _initialized) {
      return _initStatus;
    }

    final appleKey = StillScoutConfig.revenueCatAppleApiKey.trim();
    if (appleKey.isEmpty ||
        !_looksLikePublicSdkKey(appleKey)) {
      _initStatus = StillScoutIapInitStatus.notConfigured;
      _initialized = false;
      StillScoutDiagnosticsLog.log(
        'IAP',
        'Not configured — missing public SDK key (appl_…). '
        'Subscription checks will report checkFailed until a key is added.',
      );
      return _initStatus;
    }

    if (!StillScoutConfig.isRevenueCatStoreConfigured) {
      StillScoutDiagnosticsLog.log(
        'IAP',
        'No production appl_ key — using test/sandbox fallback. '
        'Add RevenueCat public SDK key (appl_…) to secrets.local.dart '
        'before App Store release.',
      );
    }

    try {
      await Purchases.setLogLevel(
        kDebugMode ? LogLevel.debug : LogLevel.error,
      );
      await Purchases.configure(PurchasesConfiguration(appleKey));
      _initialized = true;
      _initStatus = StillScoutIapInitStatus.ready;
      StillScoutDiagnosticsLog.log('IAP', 'Initialized (iOS)');
    } catch (e) {
      _initialized = false;
      _initStatus = StillScoutIapInitStatus.failed;
      StillScoutDiagnosticsLog.log('IAP', 'Init error: $e');
    }
    return _initStatus;
  }

  /// Re-attempt configure after a failed / not-ready init (Settings retry).
  static Future<StillScoutIapInitStatus> retryInitialize() => initialize();

  static bool get isInitialized =>
      _initialized && _initStatus == StillScoutIapInitStatus.ready;

  static bool _looksLikePublicSdkKey(String k) =>
      (k.startsWith('appl_') || k.startsWith('test_')) && !k.contains('YOUR_');

  static Future<bool> hasPro() async {
    final result = await checkProEntitlement();
    return result.isPro;
  }

  /// Preferred entitlement check — surfaces store failures via [checkFailed].
  static Future<SubscriptionCheckResult> checkProEntitlement() async {
    if (_initStatus == StillScoutIapInitStatus.notConfigured ||
        _initStatus == StillScoutIapInitStatus.failed ||
        !_initialized) {
      return const SubscriptionCheckResult(isPro: false, checkFailed: true);
    }
    try {
      final info = await Purchases.getCustomerInfo();
      return SubscriptionCheckResult(
        isPro: info.entitlements.active
            .containsKey(StillScoutConfig.rcEntitlementPro),
        checkFailed: false,
      );
    } catch (e) {
      debugPrint('[StillScout IAP] checkProEntitlement error: $e');
      return const SubscriptionCheckResult(isPro: false, checkFailed: true);
    }
  }

  static Future<bool> hasEntitlement(String entitlementId) async {
    if (!_initialized) return false;
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(entitlementId);
    } catch (e) {
      debugPrint('[StillScout IAP] hasEntitlement error: $e');
      return false;
    }
  }

  static Future<CustomerInfo?> getCustomerInfo() async {
    if (!_initialized) return null;
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('[StillScout IAP] getCustomerInfo error: $e');
      return null;
    }
  }

  static Future<Offerings?> getOfferings() async {
    if (!_initialized) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('[StillScout IAP] getOfferings error: $e');
      return null;
    }
  }

  /// Resolves the Pro offering + monthly/yearly packages for the paywall.
  static Future<StillScoutProOffering?> getProOffering() async {
    final offerings = await getOfferings();
    return StillScoutOfferingResolver.resolve(offerings);
  }

  static Future<StillScoutPurchaseResult> purchasePackage(
    Package package,
  ) async {
    if (!isInitialized) {
      return const StillScoutPurchaseResult(
        success: false,
        error: 'The App Store isn’t ready yet. Please try again in a moment.',
      );
    }
    try {
      final info = await Purchases.purchasePackage(package);
      return StillScoutPurchaseResult(
        success: true,
        hasPro: info.entitlements.active
            .containsKey(StillScoutConfig.rcEntitlementPro),
        customerInfo: info,
      );
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return const StillScoutPurchaseResult(
          success: false,
          cancelled: true,
        );
      }
      if (code == PurchasesErrorCode.paymentPendingError) {
        return const StillScoutPurchaseResult(
          success: false,
          paymentPending: true,
          error:
              'Payment is pending with Apple. When it clears, tap Restore Purchases.',
        );
      }
      return StillScoutPurchaseResult(
        success: false,
        error: _friendlyError(code),
      );
    } catch (e) {
      return const StillScoutPurchaseResult(
        success: false,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  static Future<StillScoutPurchaseResult> restorePurchases() async {
    if (!isInitialized) {
      return const StillScoutPurchaseResult(
        success: false,
        error: 'The App Store isn’t ready yet. Please try again in a moment.',
      );
    }
    try {
      final info = await Purchases.restorePurchases();
      final hasPro = info.entitlements.active
          .containsKey(StillScoutConfig.rcEntitlementPro);
      return StillScoutPurchaseResult(
        success: true,
        hasPro: hasPro,
        customerInfo: info,
        isRestore: true,
      );
    } catch (_) {
      return const StillScoutPurchaseResult(
        success: false,
        error: 'Could not restore purchases. Please try again.',
      );
    }
  }

  /// Human-readable store status for Settings (no entitlement / offering IDs).
  static String storeStatusMessage() {
    switch (_initStatus) {
      case StillScoutIapInitStatus.ready:
        return '';
      case StillScoutIapInitStatus.notConfigured:
        return 'In-app purchases aren’t available in this build. '
            'Subscription status can’t be verified.';
      case StillScoutIapInitStatus.failed:
        return 'Couldn’t connect to the App Store. '
            'Subscription status can’t be verified until you retry.';
    }
  }

  static String _friendlyError(PurchasesErrorCode code) {
    switch (code) {
      case PurchasesErrorCode.networkError:
        return 'No internet connection. Please try again.';
      case PurchasesErrorCode.paymentPendingError:
        return 'Payment is pending. Check your App Store account.';
      case PurchasesErrorCode.invalidCredentialsError:
        return 'Store isn’t configured correctly for this build. Try again later.';
      case PurchasesErrorCode.purchaseNotAllowedError:
        return 'Purchases are not allowed on this device.';
      case PurchasesErrorCode.productNotAvailableForPurchaseError:
        return 'This plan is not available in your region yet.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

class StillScoutPurchaseResult {
  const StillScoutPurchaseResult({
    required this.success,
    this.cancelled = false,
    this.paymentPending = false,
    this.isRestore = false,
    this.hasPro = false,
    this.error,
    this.customerInfo,
  });

  final bool success;
  final bool cancelled;
  final bool paymentPending;
  final bool isRestore;
  final bool hasPro;
  final String? error;
  final CustomerInfo? customerInfo;
}
