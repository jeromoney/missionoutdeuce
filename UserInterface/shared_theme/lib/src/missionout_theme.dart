import 'package:flutter/material.dart';

import 'missionout_colors.dart';

ThemeData buildMissionOutTheme({
  required Color accent,
  Brightness brightness = Brightness.dark,
}) {
  final scheme = ColorScheme(
    brightness: brightness,
    primary: MissionOutColors.nightSky,
    onPrimary: Colors.white,
    secondary: accent,
    onSecondary: Colors.white,
    error: MissionOutColors.alertRed,
    onError: Colors.white,
    surface: MissionOutColors.panel,
    onSurface: MissionOutColors.ice,
  );

  const radius = 24.0;

  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(20),
    borderSide: const BorderSide(color: MissionOutColors.line),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: MissionOutColors.night,
    canvasColor: Colors.transparent,
    fontFamily: 'Segoe UI',
    textTheme: ThemeData(brightness: brightness).textTheme.apply(
      bodyColor: MissionOutColors.ice,
      displayColor: MissionOutColors.ice,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: MissionOutColors.ice,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: MissionOutColors.ice,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),
    cardColor: MissionOutColors.panel,
    dividerColor: MissionOutColors.line,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: MissionOutColors.panelSoft,
      hintStyle: const TextStyle(color: MissionOutColors.fog),
      labelStyle: const TextStyle(color: MissionOutColors.ice),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(
        borderSide: BorderSide(color: accent, width: 1.4),
      ),
      errorBorder: inputBorder.copyWith(
        borderSide: const BorderSide(
          color: MissionOutColors.alertRed,
          width: 1.2,
        ),
      ),
      focusedErrorBorder: inputBorder.copyWith(
        borderSide: const BorderSide(
          color: MissionOutColors.alertRed,
          width: 1.4,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: MissionOutColors.ice,
        side: const BorderSide(color: MissionOutColors.line),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: MissionOutColors.ice),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: MissionOutColors.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accent;
        }
        return MissionOutColors.fog;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accent.withValues(alpha: 0.38);
        }
        return MissionOutColors.line;
      }),
    ),
  );
}
