import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';

class PreviewApp extends StatelessWidget {
  const PreviewApp({super.key, required this.accent, required this.child});

  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildMissionOutTheme(accent: accent),
      home: child,
    );
  }
}
