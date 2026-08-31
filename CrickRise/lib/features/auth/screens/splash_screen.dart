import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../widgets/splash_cinema.dart';

/// Premium cinematic splash — single master timeline, then route to welcome.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _master;

  @override
  void initState() {
    super.initState();
    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _master.forward().whenComplete(() {
        if (mounted) context.go('/welcome');
      });
    });
  }

  @override
  void dispose() {
    _master.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CR.bg,
      body: AnimatedBuilder(
        animation: _master,
        builder: (_, __) => SplashCinema(progress: _master.value),
      ),
    );
  }
}
