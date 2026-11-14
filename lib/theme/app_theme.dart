import 'package:flutter/material.dart';

/// Central design tokens for the "Kneipentisch" look.
///
/// Every colour and text style in the app should come from here so the look
/// can be changed in one place.
class AppColors {
  AppColors._();

  static const ink = Color(0xFF10121C); // deepest background
  static const table = Color(0xFF181C2B); // app background / play surface
  static const raised = Color(0xFF222840); // sheets, chips, rows
  static const line = Color(0xFF2F3654); // outlines, empty tracks
  static const card = Color(0xFFF6F2E9); // card face
  static const cardInk = Color(0xFF1D1F2A); // black suits on cards
  static const suitRed = Color(0xFFC8283B); // red suits on cards
  static const amber = Color(0xFFF2A93B); // accent: beer / multiplier
  static const amberInk = Color(0xFF2A1A00); // text on amber
  static const danger = Color(0xFFE5484D);
  static const dangerText = Color(0xFFFFB3B5);
  static const ok = Color(0xFF3DD68C);
  static const gold = Color(0xFFFFD166);
  static const fg = Color(0xFFECEEF6);
  static const muted = Color(0xFF8F95B0);

  static Color amberSoft = amber.withValues(alpha: 0.16);
  static Color dangerSoft = danger.withValues(alpha: 0.18);

  /// Stable per-player colours (indexed by [Player.colorIndex]).
  static const players = <Color>[
    Color(0xFFF2A93B),
    Color(0xFF7CC4FA),
    Color(0xFF3DD68C),
    Color(0xFFE58CD2),
    Color(0xFFFF8A65),
    Color(0xFFB39DFF),
    Color(0xFF4DD0C8),
    Color(0xFFF7E26B),
  ];

  static Color player(int colorIndex) => players[colorIndex % players.length];
}

class AppFonts {
  AppFonts._();

  static const display = 'BricolageGrotesque';
  static const mono = 'JetBrainsMono';

  /// Guarantees ♥ ♠ ♦ ♣ render on every device.
  static const symbols = 'NotoSansSymbols2';
  static const fallback = <String>[symbols];
}

/// Text style helpers. The bundled fonts are variable fonts, so the weight is
/// set via the `wght` axis in addition to [FontWeight].
class AppText {
  AppText._();

  static FontWeight _weight(int w) =>
      FontWeight.values[((w ~/ 100) - 1).clamp(0, 8)];

  static TextStyle display(
    double size, {
    int weight = 800,
    Color color = AppColors.fg,
    double? height = 1.05,
    double letterSpacing = -0.3,
  }) =>
      TextStyle(
        fontFamily: AppFonts.display,
        fontFamilyFallback: AppFonts.fallback,
        fontSize: size,
        fontWeight: _weight(weight),
        fontVariations: [FontVariation('wght', weight.toDouble())],
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle mono(
    double size, {
    int weight = 500,
    Color color = AppColors.muted,
    double letterSpacing = 0,
  }) =>
      TextStyle(
        fontFamily: AppFonts.mono,
        fontFamilyFallback: AppFonts.fallback,
        fontSize: size,
        fontWeight: _weight(weight),
        fontVariations: [FontVariation('wght', weight.toDouble())],
        color: color,
        letterSpacing: letterSpacing,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.fg,
    double? height,
  }) =>
      TextStyle(
        fontFamilyFallback: AppFonts.fallback,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );

  /// Small uppercase section label ("RUNDE · 4 SPIELER").
  static TextStyle eyebrow({Color color = AppColors.muted}) =>
      mono(10.5, weight: 500, color: color, letterSpacing: 1.4);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.amber,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.amber,
    onPrimary: AppColors.amberInk,
    secondary: AppColors.amber,
    surface: AppColors.table,
    onSurface: AppColors.fg,
    error: AppColors.danger,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.table,
    canvasColor: AppColors.table,
    dialogTheme: const DialogThemeData(backgroundColor: AppColors.raised),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.table,
      foregroundColor: AppColors.fg,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: AppText.display(22),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? AppColors.amberInk
              : AppColors.muted),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.amber : AppColors.line),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.raised,
      contentTextStyle: AppText.body(14),
    ),
    textSelectionTheme:
        const TextSelectionThemeData(cursorColor: AppColors.amber),
  );
}
