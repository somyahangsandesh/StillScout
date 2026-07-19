import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:url_launcher/url_launcher.dart';

import '../presentation/theme/stillscout_theme.dart';

/// Centralized runtime permission prompts for camera, mic, photos, and saves.
///
/// On iOS 14+:
/// - Gallery READ  → PHPickerViewController needs no permission — return true
///   and let image_picker show the native picker.
/// - Camera/Mic    → UIImagePickerController / AVFoundation shows its own
///   system dialog — return true and let image_picker handle it.
/// - Gallery WRITE → gal handles PHPhotoLibrary.requestAuthorization natively.
///
/// Removing permission_handler avoids the SPM/CocoaPods compile-flag gap where
/// permission checks return .denied before the system dialog can ever appear.
class StillScoutPermissions {
  StillScoutPermissions._();

  /// Gallery read — PHPickerViewController (iOS 14+) needs no prior permission.
  /// image_picker presents the system picker directly; the user selects what to
  /// share without granting full library access.
  static Future<bool> ensureGalleryRead(BuildContext context) async => true;

  /// Camera + microphone — AVFoundation requests permission at the point of
  /// capture inside UIImagePickerController.  If the user previously denied,
  /// iOS shows a "settings" prompt automatically.
  static Future<bool> ensureCameraRecord(BuildContext context) async => true;

  /// Photo Library ADD access required to save polished frames.
  ///
  /// Uses gal's native PHPhotoLibrary.requestAuthorization — no permission_handler.
  static Future<bool> ensureGalleryWrite(BuildContext context) async {
    if (await Gal.hasAccess(toAlbum: true)) return true;
    if (!context.mounted) return false;

    final proceed = await _confirmNeed(
      context,
      title: 'Save to Photos',
      body:
          'StillScout needs permission to save polished frames to your '
          'photo library. This is required to export.',
      confirmLabel: 'Allow Saving',
    );
    if (!proceed || !context.mounted) return false;

    if (await Gal.requestAccess(toAlbum: true)) return true;
    if (!context.mounted) return false;
    return _handleDenied(
      context,
      message:
          'Photo Library access is required to save exports. '
          'Enable Photos for StillScout in Settings → Privacy & Security → Photos.',
    );
  }

  static Future<bool> _confirmNeed(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
  }) async {
    if (!context.mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: StillScoutColors.slate,
          title: Text(
            title,
            style: StillScoutTextStyles.subtitle.copyWith(
              color: StillScoutColors.chalk,
            ),
          ),
          content: Text(
            body,
            style: StillScoutTextStyles.body.copyWith(
              color: StillScoutColors.silver,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Not now',
                style: StillScoutTextStyles.caption.copyWith(
                  color: StillScoutColors.silver,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: StillScoutColors.scoutGold,
                foregroundColor: StillScoutColors.voidBlack,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  static Future<bool> _handleDenied(
    BuildContext context, {
    required String message,
  }) async {
    if (!context.mounted) return false;
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: StillScoutColors.slate,
          title: Text(
            'Permission required',
            style: StillScoutTextStyles.subtitle.copyWith(
              color: StillScoutColors.chalk,
            ),
          ),
          content: Text(
            message,
            style: StillScoutTextStyles.body.copyWith(
              color: StillScoutColors.silver,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancel',
                style: StillScoutTextStyles.caption.copyWith(
                  color: StillScoutColors.silver,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: StillScoutColors.scoutGold,
                foregroundColor: StillScoutColors.voidBlack,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
    if (openSettings == true) {
      // Open the app's Settings page so the user can re-enable Photos access.
      // Uses dart:io Process on iOS to open the settings URL.
      await _openAppSettings();
    }
    return false;
  }

  static Future<void> _openAppSettings() async {
    try {
      await launchUrl(Uri.parse('app-settings:'));
    } catch (_) {}
  }
}
