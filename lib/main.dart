import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'bootstrap/app_bootstrap.dart';

void main() async {
  await AppBootstrap.initialize();
  runApp(const ProviderScope(child: StillScoutApp()));
}
