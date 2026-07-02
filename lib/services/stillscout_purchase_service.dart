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

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config/stillscout_config.dart';
import 'stillscout_offering_resolver.dart';

/// RevenueCat wrapper for StillScout Pro — unlimited exports + native-res saves.
class StillScoutPurchaseService {
  StillScoutPurchaseService._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    final appleKey = StillScoutConfig.revenueCatAppleApiKey;
    final googleKey = StillScoutConfig.revenueCatGoogleApiKey;

    if (!StillScoutConfig.isRevenueCatConfigured) {
      debugPrint(
        '[StillScout IAP] No valid public SDK key — using sandbox fallback '
        'or offline mode. Add appl_/goog_ key to secrets.local.dart',
      );
    }

    try {
      await Purchases.setLogLevel(
        kDebugMode ? LogLevel.debug : LogLevel.error,
      );

      final PurchasesConfiguration config;
      if (Platform.isAndroid) {
        config = PurchasesConfiguration(googleKey);
      } else if (Platform.isIOS || Platform.isMacOS) {
        config = PurchasesConfiguration(appleKey);
      } else {
        debugPrint('[StillScout IAP] Skipping — unsupported platform');
        return;
      }

      await Purchases.configure(config);
      _initialized = true;
      debugPrint('[StillScout IAP] Initialized (${Platform.isIOS ? 'iOS' : 'Android'})');
    } catch (e) {
      debugPrint('[StillScout IAP] Init error: $e');
    }
  }

  static bool get isInitialized => _initialized;

  static Future<bool> hasPro() async =>
      hasEntitlement(StillScoutConfig.rcEntitlementPro);

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
    if (!_initialized) {
      return const StillScoutPurchaseResult(
        success: false,
        error: 'Store is not ready yet. Please try again in a moment.',
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
      return StillScoutPurchaseResult(
        success: false,
        error: _friendlyError(code),
      );
    } catch (e) {
      return StillScoutPurchaseResult(success: false, error: e.toString());
    }
  }

  static Future<StillScoutPurchaseResult> restorePurchases() async {
    if (!_initialized) {
      return const StillScoutPurchaseResult(
        success: false,
        error: 'Store is not ready yet. Please try again in a moment.',
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

  static String _friendlyError(PurchasesErrorCode code) {
    switch (code) {
      case PurchasesErrorCode.networkError:
        return 'No internet connection. Please try again.';
      case PurchasesErrorCode.paymentPendingError:
        return 'Payment is pending. Check your App Store account.';
      case PurchasesErrorCode.invalidCredentialsError:
        return 'Store configuration error. Check RevenueCat public API key.';
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
    this.isRestore = false,
    this.hasPro = false,
    this.error,
    this.customerInfo,
  });

  final bool success;
  final bool cancelled;
  final bool isRestore;
  final bool hasPro;
  final String? error;
  final CustomerInfo? customerInfo;
}
