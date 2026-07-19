import 'package:flutter/material.dart';

import '../theme/stillscout_theme.dart';

/// A shimmering placeholder rectangle used while content is loading.
///
/// Animates a highlight sweep from left → right using the cinema-dark palette.
class StillScoutSkeleton extends StatefulWidget {
  const StillScoutSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.radius,
  });

  final double width;
  final double height;
  final double? radius;

  @override
  State<StillScoutSkeleton> createState() => _StillScoutSkeletonState();
}

class _StillScoutSkeletonState extends State<StillScoutSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.radius ?? StillScoutRadius.s;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _ctrl.value * 3, 0),
              end: Alignment(1.0 + _ctrl.value * 3, 0),
              colors: [
                StillScoutColors.filmGray,
                StillScoutColors.slateLight.withValues(alpha: 0.55),
                StillScoutColors.filmGray,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// A shimmer skeleton card sized for the history 2-column grid.
class StillScoutSessionSkeleton extends StatelessWidget {
  const StillScoutSessionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: StillScoutDecorations.surfaceCard(),
      clipBehavior: Clip.antiAlias,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Thumbnail placeholder
          Expanded(
            child: StillScoutSkeleton(
              width: double.infinity,
              height: double.infinity,
              radius: 0,
            ),
          ),
          // Caption area
          Padding(
            padding: EdgeInsets.all(StillScoutSpacing.s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonRow(width: 80, height: 10),
                SizedBox(height: 6),
                _SkeletonRow(width: 56, height: 9),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return StillScoutSkeleton(
      width: width,
      height: height,
      radius: StillScoutRadius.xs,
    );
  }
}

/// Drop-in 2-column grid of skeleton cards for the history screen.
class StillScoutHistorySkeleton extends StatelessWidget {
  const StillScoutHistorySkeleton({super.key, this.count = 6});
  final int count;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        StillScoutSpacing.m,
        StillScoutSpacing.s,
        StillScoutSpacing.m,
        StillScoutSpacing.xxl,
      ),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: StillScoutSpacing.m,
        crossAxisSpacing: StillScoutSpacing.m,
        childAspectRatio: 0.8,
      ),
      itemCount: count,
      itemBuilder: (_, __) => const StillScoutSessionSkeleton(),
    );
  }
}
