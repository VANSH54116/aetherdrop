import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Signature Dark Glassmorphism design system and theme controller for AetherDrop.
class AetherDropColors {
  AetherDropColors._();

  /// Primary Background: Deep Matte Obsidian (`#0A0A0A`).
  static const Color deepMatteObsidian = Color(0xFF0A0A0A);

  /// Elevated Dark Surface (`#111318`).
  static const Color elevatedObsidian = Color(0xFF111318);

  /// Glass Surface: Translucent Carbon (`rgba(255, 255, 255, 0.04)`).
  static const Color translucentCarbon = Color.fromRGBO(255, 255, 255, 0.04);

  /// Glass Surface Hovered / Active (`rgba(255, 255, 255, 0.08)`).
  static const Color translucentCarbonHover = Color.fromRGBO(
    255,
    255,
    255,
    0.08,
  );

  /// Glass Border: `1px solid rgba(255, 255, 255, 0.10)`.
  static const Color glassBorder = Color.fromRGBO(255, 255, 255, 0.10);

  /// Primary Accent: Electric Cyan (`#00F0FF`).
  static const Color electricCyan = Color(0xFF00F0FF);

  /// Secondary Accent 1: Hyper Cobalt (`#3B82F6`).
  static const Color hyperCobalt = Color(0xFF3B82F6);

  /// Secondary Accent 2: Plasma Violet (`#8B5CF6`).
  static const Color plasmaViolet = Color(0xFF8B5CF6);

  /// Status & Gamification Accents.
  static const Color neonEmerald = Color(0xFF10B981);
  static const Color liquidGold = Color(0xFFF59E0B);
  static const Color crimsonPulse = Color(0xFFEF4444);

  /// Typography Colors (Dark Mode).
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  /// Light Mode Counterparts for Interactive Theme Toggle.
  static const Color alabasterBackground = Color(0xFFF8FAFC);
  static const Color frostedWhiteSurface = Color.fromRGBO(255, 255, 255, 0.72);
  static const Color lightGlassBorder = Color.fromRGBO(15, 23, 42, 0.08);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
}

/// Signature Glassmorphism layout & blur constants.
class AetherDropGlass {
  AetherDropGlass._();

  /// BackdropFilter Gaussian blur sigmaX (`18.0`).
  static const double blurSigmaX = 18.0;

  /// BackdropFilter Gaussian blur sigmaY (`18.0`).
  static const double blurSigmaY = 18.0;

  /// Default border width (`1.0` px).
  static const double borderWidth = 1.0;

  /// Default card corner radius (`20.0` px).
  static const double borderRadius = 20.0;

  /// Shared `ImageFilter.blur(sigmaX: 18, sigmaY: 18)`.
  static ImageFilter get backdropFilter => ImageFilter.blur(
    sigmaX: blurSigmaX,
    sigmaY: blurSigmaY,
  );

  /// Builds the signature glassmorphic `BoxDecoration` for dark or light mode.
  static BoxDecoration decoration({
    bool isDark = true,
    double radius = borderRadius,
    Color? backgroundColor,
    Color? borderColor,
    double borderThickness = borderWidth,
    Gradient? gradient,
    List<BoxShadow>? boxShadow,
  }) {
    final Color effectiveSurface =
        backgroundColor ??
        (isDark
            ? AetherDropColors.translucentCarbon
            : AetherDropColors.frostedWhiteSurface);
    final Color effectiveBorder =
        borderColor ??
        (isDark
            ? AetherDropColors.glassBorder
            : AetherDropColors.lightGlassBorder);

    return BoxDecoration(
      color: gradient == null ? effectiveSurface : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: effectiveBorder,
        width: borderThickness,
      ),
      boxShadow:
          boxShadow ??
          <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
    );
  }
}

/// Interactive Light/Dark theme controller defaulting to Matte Black Dark Mode (`#0A0A0A`).
class ThemeProvider extends ChangeNotifier {
  ThemeProvider({ThemeMode initialThemeMode = ThemeMode.dark})
    : _themeMode = initialThemeMode {
    _loadSavedTheme();
  }

  static const String _themePrefKey = 'aetherdrop_theme_mode';

  ThemeMode _themeMode;

  /// Current active `ThemeMode` (defaults to `ThemeMode.dark`).
  ThemeMode get themeMode => _themeMode;

  /// Returns `true` when Matte Black Dark Mode is active.
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Toggles between Matte Black Dark Mode and Frosted Alabaster Light Mode.
  Future<void> toggleTheme() async {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themePrefKey, _themeMode.name);
    } catch (_) {
      // Ignore persistence errors in tests or restricted environments.
    }
  }

  /// Explicitly sets the theme mode.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themePrefKey, _themeMode.name);
    } catch (_) {
      // Ignore persistence errors in tests or restricted environments.
    }
  }

  Future<void> _loadSavedTheme() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? saved = prefs.getString(_themePrefKey);
      if (saved == ThemeMode.light.name) {
        _themeMode = ThemeMode.light;
        notifyListeners();
      } else if (saved == ThemeMode.dark.name) {
        _themeMode = ThemeMode.dark;
        notifyListeners();
      }
    } catch (_) {
      // Default remains ThemeMode.dark.
    }
  }
}

/// Builds the complete `ThemeData` configurations for AetherDrop.
class AetherDropTheme {
  AetherDropTheme._();

  /// Signature Dark Glassmorphism Theme (`#0A0A0A` Deep Matte Obsidian).
  static ThemeData get darkTheme {
    final TextTheme baseTextTheme = GoogleFonts.spaceGroteskTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AetherDropColors.deepMatteObsidian,
      canvasColor: AetherDropColors.deepMatteObsidian,
      primaryColor: AetherDropColors.electricCyan,
      colorScheme: const ColorScheme.dark(
        primary: AetherDropColors.electricCyan,
        onPrimary: AetherDropColors.deepMatteObsidian,
        secondary: AetherDropColors.hyperCobalt,
        onSecondary: Colors.white,
        tertiary: AetherDropColors.plasmaViolet,
        onTertiary: Colors.white,
        surface: AetherDropColors.deepMatteObsidian,
        onSurface: AetherDropColors.textPrimaryDark,
        error: AetherDropColors.crimsonPulse,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          color: AetherDropColors.textPrimaryDark,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.2,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: AetherDropColors.textPrimaryDark,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: AetherDropColors.textPrimaryDark,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: AetherDropColors.textPrimaryDark,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: AetherDropColors.textSecondaryDark,
        ),
        labelLarge: GoogleFonts.jetBrainsMono(
          color: AetherDropColors.electricCyan,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AetherDropColors.textPrimaryDark,
      ),
      cardTheme: CardThemeData(
        color: AetherDropColors.translucentCarbon,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AetherDropGlass.borderRadius),
          side: const BorderSide(
            color: AetherDropColors.glassBorder,
            width: AetherDropGlass.borderWidth,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AetherDropColors.translucentCarbon,
        hintStyle: const TextStyle(color: AetherDropColors.textMutedDark),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AetherDropColors.glassBorder,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AetherDropColors.electricCyan,
            width: 1.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AetherDropColors.electricCyan,
          foregroundColor: AetherDropColors.deepMatteObsidian,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      dividerColor: AetherDropColors.glassBorder,
    );
  }

  /// Frosted Glass Light Theme for the interactive Light/Dark mode toggle.
  static ThemeData get lightTheme {
    final TextTheme baseTextTheme = GoogleFonts.spaceGroteskTextTheme(
      ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AetherDropColors.alabasterBackground,
      canvasColor: AetherDropColors.alabasterBackground,
      primaryColor: AetherDropColors.hyperCobalt,
      colorScheme: const ColorScheme.light(
        primary: AetherDropColors.hyperCobalt,
        onPrimary: Colors.white,
        secondary: AetherDropColors.electricCyan,
        onSecondary: AetherDropColors.textPrimaryLight,
        tertiary: AetherDropColors.plasmaViolet,
        onTertiary: Colors.white,
        surface: AetherDropColors.alabasterBackground,
        onSurface: AetherDropColors.textPrimaryLight,
        error: AetherDropColors.crimsonPulse,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          color: AetherDropColors.textPrimaryLight,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.2,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: AetherDropColors.textPrimaryLight,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: AetherDropColors.textPrimaryLight,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: AetherDropColors.textPrimaryLight,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: AetherDropColors.textSecondaryLight,
        ),
        labelLarge: GoogleFonts.jetBrainsMono(
          color: AetherDropColors.hyperCobalt,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AetherDropColors.textPrimaryLight,
      ),
      cardTheme: CardThemeData(
        color: AetherDropColors.frostedWhiteSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AetherDropGlass.borderRadius),
          side: const BorderSide(
            color: AetherDropColors.lightGlassBorder,
            width: AetherDropGlass.borderWidth,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AetherDropColors.frostedWhiteSurface,
        hintStyle: const TextStyle(color: AetherDropColors.textSecondaryLight),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AetherDropColors.lightGlassBorder,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AetherDropColors.hyperCobalt,
            width: 1.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AetherDropColors.hyperCobalt,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      dividerColor: AetherDropColors.lightGlassBorder,
    );
  }

  /// Monospace helper style (JetBrains Mono) for transfer speedometers, hashes, and byte counters.
  static TextStyle monoStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double? letterSpacing,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? AetherDropColors.electricCyan,
      letterSpacing: letterSpacing,
    );
  }

  /// Headline typography style (Space Grotesk) for section headers and brand badges.
  static TextStyle headlineStyle({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double? letterSpacing,
  }) {
    return GoogleFonts.spaceGrotesk(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? Colors.white,
      letterSpacing: letterSpacing,
    );
  }

  /// Title typography style (Space Grotesk) for card headers and names.
  static TextStyle titleStyle({
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double? letterSpacing,
  }) {
    return GoogleFonts.spaceGrotesk(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? Colors.white,
      letterSpacing: letterSpacing,
    );
  }

  /// Body typography style (Space Grotesk) for subtitles, labels, and descriptions.
  static TextStyle bodyStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? letterSpacing,
  }) {
    return GoogleFonts.spaceGrotesk(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? AetherDropColors.textSecondaryDark,
      letterSpacing: letterSpacing,
    );
  }
}
