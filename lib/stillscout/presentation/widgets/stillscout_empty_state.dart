import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/stillscout_online_status.dart';
import '../../domain/stillscout_constants.dart';
import '../../services/stillscout_permissions.dart';
import '../widgets/stillscout_legal_links.dart';
import '../widgets/stillscout_logo.dart';
import '../widgets/stillscout_source_sheet.dart';
import '../theme/stillscout_theme.dart';

typedef VideoSelectedCallback = void Function(String path);

/// Native video picker — library import or in-app camera record.
class StillScoutVideoPicker {
  StillScoutVideoPicker({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<void> pickFromGallery({
    required BuildContext context,
    required VideoSelectedCallback onVideoSelected,
  }) async {
    if (!context.mounted) return;

    final allowed = await StillScoutPermissions.ensureGalleryRead(context);
    if (!allowed || !context.mounted) return;

    try {
      final file = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );
      if (file != null) onVideoSelected(file.path);
    } catch (e) {
      if (!context.mounted) return;
      _showPermissionSnack(
        context,
        'Could not open your video library. Check app permissions in Settings.',
      );
    }
  }

  Future<void> recordVideo({
    required BuildContext context,
    required VideoSelectedCallback onVideoSelected,
  }) async {
    // The iOS simulator has no physical camera — fail fast with a clear message.
    if (Platform.isIOS && _isSimulator) {
      _showPermissionSnack(
        context,
        'Camera is not available on the iOS Simulator. Use "Choose from Library" instead.',
      );
      return;
    }

    final allowed = await StillScoutPermissions.ensureCameraRecord(context);
    if (!allowed || !context.mounted) return;

    try {
      final file = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 10),
      );
      if (file != null) onVideoSelected(file.path);
    } catch (e) {
      if (!context.mounted) return;
      _showPermissionSnack(context, 'Could not open the camera.');
    }
  }

  /// Returns `true` when running inside the iOS Simulator.
  bool get _isSimulator {
    if (!Platform.isIOS) return false;
    // The SIMULATOR_DEVICE_NAME env var is only set in the Simulator process.
    return Platform.environment.containsKey('SIMULATOR_DEVICE_NAME') ||
        Platform.environment.containsKey('SIMULATOR_UDID');
  }

  void _showPermissionSnack(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: StillScoutColors.slate,
      ),
    );
  }
}

class StillScoutEmptyState extends StatefulWidget {
  const StillScoutEmptyState({
    super.key,
    required this.onVideoSelected,
    this.isEnabled = true,
    this.onlineStatus = OnlineStatus.checking,
  });

  final VideoSelectedCallback onVideoSelected;
  final bool isEnabled;
  final OnlineStatus onlineStatus;

  @override
  State<StillScoutEmptyState> createState() => _StillScoutEmptyStateState();
}

class _StillScoutEmptyStateState extends State<StillScoutEmptyState>
    with TickerProviderStateMixin {
  final _picker = StillScoutVideoPicker();
  late final AnimationController _pulseCtrl;
  late final AnimationController _ambientCtrl;
  bool _isDragOver = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    // Very slow drift so the empty state feels alive without drawing focus —
    // a full cycle takes almost half a minute.
    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 26),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _ambientCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 680;
        final uploadHeight = compact ? 240.0 : 300.0;
        final titleSize = compact ? 28.0 : 32.0;

        const canScout = true;
        final enabled = widget.isEnabled;
        final isChecking = widget.onlineStatus == OnlineStatus.checking;

        return Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: _AmbientGlow(animation: _ambientCtrl),
              ),
            ),
            _buildContent(context, constraints,
                compact: compact,
                uploadHeight: uploadHeight,
                titleSize: titleSize,
                canScout: canScout,
                enabled: enabled,
                isChecking: isChecking),
          ],
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    BoxConstraints constraints, {
    required bool compact,
    required double uploadHeight,
    required double titleSize,
    required bool canScout,
    required bool enabled,
    required bool isChecking,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight - 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const StillScoutLogo(
                size: 56, animateGlow: true, glowStrength: 0.28),
            const SizedBox(height: StillScoutSpacing.m),
            Text(
              'Scout → Polish → Post',
              style: StillScoutTextStyles.display.copyWith(fontSize: titleSize),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: StillScoutSpacing.s),
            Text(
              'On-device ranking · ${StillScoutConstants.freeScoutsPerDay} free scouts/day · '
              'AI Pro adds Gemini & polish',
              style: StillScoutTextStyles.body,
              textAlign: TextAlign.center,
            ),
            SizedBox(
                height: compact ? StillScoutSpacing.l : StillScoutSpacing.xl),
            DragTarget<String>(
              onWillAcceptWithDetails: (_) => enabled,
              onMove: (_) {
                if (enabled) setState(() => _isDragOver = true);
              },
              onLeave: (_) => setState(() => _isDragOver = false),
              onAcceptWithDetails: (details) =>
                  widget.onVideoSelected(details.data),
              builder: (context, candidate, rejected) {
                return GestureDetector(
                  onTap: enabled ? () => _showSourceSheet(context) : null,
                  child: AnimatedScale(
                    scale: _isDragOver ? 1.02 : 1.0,
                    duration: StillScoutMotion.fast,
                    curve: StillScoutMotion.toggle,
                    child: ClipRRect(
                      borderRadius: StillScoutRadius.card,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                        child: AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (context, child) {
                            final baseDecoration =
                                StillScoutDecorations.glassCard(
                              borderColor: _isDragOver
                                  ? StillScoutColors.accent
                                  : StillScoutColors.silver
                                      .withValues(alpha: 0.35),
                              borderWidth: _isDragOver ? 2 : 1,
                            );
                            return AnimatedContainer(
                              duration: StillScoutMotion.fast,
                              curve: StillScoutMotion.toggle,
                              width: double.infinity,
                              height: uploadHeight,
                              decoration: _isDragOver
                                  ? baseDecoration.copyWith(
                                      boxShadow: [
                                        ...?baseDecoration.boxShadow,
                                        BoxShadow(
                                          color: StillScoutColors.accentGlow
                                              .withValues(alpha: 0.6),
                                          blurRadius: 40,
                                          spreadRadius: 4,
                                        ),
                                      ],
                                    )
                                  : baseDecoration,
                              child: child,
                            );
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                canScout
                                    ? Icons.movie_filter_outlined
                                    : isChecking
                                        ? Icons.sync_rounded
                                        : Icons.wifi_off_rounded,
                                size: compact ? 48 : 56,
                                color: canScout
                                    ? StillScoutColors.chalk
                                        .withValues(alpha: 0.9)
                                    : StillScoutColors.silver
                                        .withValues(alpha: 0.55),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                canScout
                                    ? 'Tap to upload video'
                                    : isChecking
                                        ? 'Checking connection…'
                                        : 'Connect to the internet',
                                style: StillScoutTextStyles.title
                                    .copyWith(fontSize: 18),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                canScout
                                    ? 'or drop a clip here'
                                    : isChecking
                                        ? 'Setting things up…'
                                        : 'AI Pro scouting needs Wi‑Fi or mobile data',
                                style: StillScoutTextStyles.caption,
                                textAlign: TextAlign.center,
                              ),
                              if (canScout) ...[
                                const SizedBox(height: 18),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _QuickImportChip(
                                      icon: Icons.photo_library_rounded,
                                      label: 'Gallery',
                                      accent: StillScoutColors.secondaryAccent,
                                      onTap: enabled
                                          ? () => _runPickerAfterSheet(() {
                                                _picker.pickFromGallery(
                                                  context: context,
                                                  onVideoSelected:
                                                      widget.onVideoSelected,
                                                );
                                              })
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    _QuickImportChip(
                                      icon: Icons.videocam_rounded,
                                      label: 'Record',
                                      accent: StillScoutColors.accent,
                                      onTap: enabled
                                          ? () => _runPickerAfterSheet(() {
                                                _picker.recordVideo(
                                                  context: context,
                                                  onVideoSelected:
                                                      widget.onVideoSelected,
                                                );
                                              })
                                          : null,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Clips up to 10 minutes',
                                  style: StillScoutTextStyles.caption.copyWith(
                                    color: StillScoutColors.silver
                                        .withValues(alpha: 0.7),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: StillScoutSpacing.l),
            const StillScoutLegalLinks(compact: true),
          ],
        ),
      ),
    );
  }

  Future<void> _runPickerAfterSheet(void Function() action) async {
    // Let the bottom sheet finish closing before launching a native picker.
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    action();
  }

  Future<void> _showSourceSheet(BuildContext context) async {
    await StillScoutSourceSheet.show(
      context,
      onGallery: () => _runPickerAfterSheet(() {
        _picker.pickFromGallery(
          context: context,
          onVideoSelected: widget.onVideoSelected,
        );
      }),
      onCamera: () => _runPickerAfterSheet(() {
        _picker.recordVideo(
          context: context,
          onVideoSelected: widget.onVideoSelected,
        );
      }),
    );
  }
}

/// Slow, low-opacity drifting glow behind the empty-state content — purely
/// ambient, never intercepts touches (always wrapped in [IgnorePointer] by
/// the caller).
class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value * 2 * math.pi;
        final primaryCenter = Alignment(
          math.cos(t) * 0.7,
          math.sin(t * 0.6) * 0.8 - 0.2,
        );
        final secondaryCenter = Alignment(
          math.cos(t * 0.5 + math.pi) * 0.8,
          math.sin(t * 0.8 + math.pi) * 0.6 + 0.4,
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: primaryCenter,
              radius: 1.1,
              colors: [
                StillScoutColors.accent.withValues(alpha: 0.05),
                Colors.transparent,
              ],
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: secondaryCenter,
                radius: 0.9,
                colors: [
                  StillScoutColors.secondaryAccent.withValues(alpha: 0.04),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuickImportChip extends StatelessWidget {
  const _QuickImportChip({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: accent.withValues(alpha: 0.12),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: StillScoutTextStyles.label.copyWith(color: accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
