import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../widgets/splash_cinema.dart';

/// Splash driven by wall-clock elapsed time — reliable on Flutter web release builds.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  static const _durationMs = 4500;

  late final Ticker _ticker;
  int _startMs = -1;
  double _progress = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ticker.start();
    });
  }

  void _onTick(Duration elapsed) {
    if (_startMs < 0) _startMs = elapsed.inMilliseconds;

    final t = ((elapsed.inMilliseconds - _startMs) / _durationMs).clamp(0.0, 1.0);
    if (t != _progress) {
      setState(() => _progress = t);
    }

    if (t >= 1.0 && !_done) {
      _done = true;
      _ticker.stop();
      if (mounted) context.go('/welcome');
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CR.bg,
      body: SplashCinema(progress: _progress),
    );
  }
}
