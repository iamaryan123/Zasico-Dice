import 'package:flutter/material.dart';

class ZasicoColors {
  // Private constructor to prevent instantiation
  ZasicoColors._();

  // Primary Colors - Based on your logo
  static const Color primaryRed = Color(0xFFDC2626); // Main red from logo
  static const Color darkRed = Color(0xFF991B1B); // Darker red shade
  static const Color lightRed = Color(0xFFEF4444); // Lighter red accent
  static const Color crimsonRed = Color(0xFFB91C1C); // Deep crimson

  // Background Colors
  static const Color primaryBackground = Color(0xFF0F0F0F); // Very dark background
  static const Color secondaryBackground = Color(0xFF1A1A1A); // Dark surface
  static const Color cardBackground = Color(0xFF262626); // Card/container background
  static const Color surfaceBackground = Color(0xFF171717); // Surface color

  // Text Colors
  static const Color primaryText = Color(0xFFFFFFFF); // White text
  static const Color secondaryText = Color(0xFFD1D5DB); // Light gray text
  static const Color mutedText = Color(0xFF9CA3AF); // Muted text
  static const Color hintText = Color(0xFF6B7280); // Hint text

  // Border Colors
  static const Color primaryBorder = Color(0xFFDC2626); // Red border
  static const Color secondaryBorder = Color(0xFF374151); // Gray border
  static const Color mutedBorder = Color(0xFF1F2937); // Muted border

  // Status Colors
  static const Color success = Color(0xFF10B981); // Success green
  static const Color warning = Color(0xFFF59E0B); // Warning orange
  static const Color error = Color(0xFFEF4444); // Error red
  static const Color info = Color(0xFF3B82F6); // Info blue

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F0F0F), // Dark start
      Color(0xFF1A1A1A), // Medium dark
      Color(0xFF262626), // Lighter dark
    ],
  );

  static const LinearGradient redGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFDC2626), // Primary red
      Color(0xFF991B1B), // Dark red
    ],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFDC2626), // Primary red
      Color(0xFFB91C1C), // Crimson red
    ],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0F0F0F), // Very dark
      Color(0xFF1A1A1A), // Dark
      Color(0xFF262626), // Medium dark
    ],
  );

  // Opacity Colors
  static Color get redOpacity10 => primaryRed.withOpacity(0.1);
  static Color get redOpacity20 => primaryRed.withOpacity(0.2);
  static Color get redOpacity30 => primaryRed.withOpacity(0.3);
  static Color get redOpacity50 => primaryRed.withOpacity(0.5);
  static Color get redOpacity70 => primaryRed.withOpacity(0.7);

  static Color get whiteOpacity10 => primaryText.withOpacity(0.1);
  static Color get whiteOpacity20 => primaryText.withOpacity(0.2);
  static Color get whiteOpacity30 => primaryText.withOpacity(0.3);
  static Color get whiteOpacity50 => primaryText.withOpacity(0.5);
  static Color get whiteOpacity70 => primaryText.withOpacity(0.7);
  static Color get whiteOpacity80 => primaryText.withOpacity(0.8);

  // Shadow Colors
  static Color get shadowColor => Colors.black.withOpacity(0.5);
  static Color get redShadow => primaryRed.withOpacity(0.3);

  // Input Field Colors
  static Color get inputBackground => cardBackground;
  static Color get inputBorder => secondaryBorder;
  static Color get inputFocusedBorder => primaryRed;
  static Color get inputText => primaryText;
  static Color get inputHint => hintText;

  // Button Colors
  static Color get buttonPrimary => primaryRed;
  static Color get buttonSecondary => cardBackground;
  static Color get buttonDisabled => mutedText;
  static Color get buttonText => primaryText;

  // Card Colors
  static Color get cardSurface => cardBackground;
  static Color get cardBorder => secondaryBorder;
  static Color get cardShadow => shadowColor;

  // Theme Data
  static ThemeData get themeData => ThemeData(
    brightness: Brightness.dark,
    primarySwatch: MaterialColor(
      primaryRed.value,
      <int, Color>{
        50: primaryRed.withOpacity(0.1),
        100: primaryRed.withOpacity(0.2),
        200: primaryRed.withOpacity(0.3),
        300: primaryRed.withOpacity(0.4),
        400: primaryRed.withOpacity(0.5),
        500: primaryRed,
        600: primaryRed.withOpacity(0.7),
        700: primaryRed.withOpacity(0.8),
        800: primaryRed.withOpacity(0.9),
        900: primaryRed,
      },
    ),
    scaffoldBackgroundColor: primaryBackground,
    cardColor: cardBackground,
    dividerColor: secondaryBorder,
    textTheme: TextTheme(
      displayLarge: TextStyle(color: primaryText),
      displayMedium: TextStyle(color: primaryText),
      displaySmall: TextStyle(color: primaryText),
      headlineLarge: TextStyle(color: primaryText),
      headlineMedium: TextStyle(color: primaryText),
      headlineSmall: TextStyle(color: primaryText),
      titleLarge: TextStyle(color: primaryText),
      titleMedium: TextStyle(color: primaryText),
      titleSmall: TextStyle(color: primaryText),
      bodyLarge: TextStyle(color: secondaryText),
      bodyMedium: TextStyle(color: secondaryText),
      bodySmall: TextStyle(color: mutedText),
      labelLarge: TextStyle(color: primaryText),
      labelMedium: TextStyle(color: secondaryText),
      labelSmall: TextStyle(color: mutedText),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryRed,
        foregroundColor: primaryText,
        elevation: 4,
        shadowColor: redShadow,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: inputFocusedBorder),
      ),
      hintStyle: TextStyle(color: inputHint),
    ),
  );
}