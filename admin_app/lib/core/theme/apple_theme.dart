import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Apple-inspired minimalist theme with clean whites, subtle shadows, and smooth animations
class AppleTheme {
  // Apple-style colors
  static const Color systemBlue = Color(0xFF007AFF);
  static const Color systemGreen = Color(0xFF34C759);
  static const Color systemOrange = Color(0xFFFF9500);
  static const Color systemRed = Color(0xFFFF3B30);
  static const Color systemGray = Color(0xFF8E8E93);
  static const Color systemGray2 = Color(0xFFAEAEB2);
  static const Color systemGray3 = Color(0xFFC7C7CC);
  static const Color systemGray4 = Color(0xFFD1D1D6);
  static const Color systemGray5 = Color(0xFFE5E5EA);
  static const Color systemGray6 = Color(0xFFF2F2F7);
  
  // Background colors
  static const Color background = Color(0xFFF2F2F7);
  static const Color secondaryBackground = Colors.white;
  static const Color tertiaryBackground = Color(0xFFFFFFFF);
  
  // Text colors
  static const Color label = Color(0xFF000000);
  static const Color secondaryLabel = Color(0xFF3C3C43);
  static const Color tertiaryLabel = Color(0xFF48484A);
  static const Color quaternaryLabel = Color(0xFF636366);
  
  // Separator
  static const Color separator = Color(0xFFC6C6C8);
  static const Color opaqueSeparator = Color(0xFFE5E5EA);
  
  // Animation durations
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
  
  // Curves
  static const Curve defaultCurve = Curves.easeInOutCubic;
  static const Curve bouncyCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeOutQuart;
  
  // Spacing
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing48 = 48.0;
  
  // Border radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: systemBlue,
      scaffoldBackgroundColor: background,
      fontFamily: 'SF Pro Display',
      colorScheme: const ColorScheme.light(
        primary: systemBlue,
        secondary: systemGray,
        tertiary: systemGreen,
        error: systemRed,
        surface: secondaryBackground,
        surfaceContainerHighest: systemGray6,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: label,
        outline: separator,
      ),
      
      // AppBar - Clean, minimal
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: label,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: label,
          letterSpacing: -0.5,
        ),
        toolbarTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: label,
        ),
      ),
      
      // Card - Soft shadows, rounded corners
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      
      // Elevated Button - Apple style
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: systemBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      
      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: systemBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      
      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: systemBlue,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          side: const BorderSide(color: systemGray4, width: 1),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      
      // Input - Clean, minimal
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: systemGray6,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: systemBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: systemRed, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(
          color: systemGray,
          fontSize: 17,
        ),
        labelStyle: const TextStyle(
          color: secondaryLabel,
          fontSize: 17,
        ),
      ),
      
      // List Tile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        tileColor: Colors.white,
        titleTextStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: label,
        ),
        subtitleTextStyle: const TextStyle(
          fontSize: 15,
          color: secondaryLabel,
        ),
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: opaqueSeparator,
        thickness: 0.5,
        indent: 20,
      ),
      
      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return systemGreen;
          return systemGray4;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      
      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: systemGray6,
        labelStyle: const TextStyle(
          color: label,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      
      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: systemBlue,
        unselectedItemColor: systemGray,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      ),
      
      // Tab Bar
      tabBarTheme: const TabBarTheme(
        labelColor: systemBlue,
        unselectedLabelColor: systemGray,
        indicatorColor: systemBlue,
        labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: systemBlue,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),
      
      // Dialog
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: label,
        ),
      ),
      
      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1C1C1E),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: systemBlue,
        linearTrackColor: systemGray5,
        circularTrackColor: systemGray5,
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.3),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.3),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.2),
        titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.2),
        titleSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.2),
        bodyLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w400, letterSpacing: -0.2),
        bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: -0.2),
        bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, letterSpacing: -0.1),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: -0.1),
        labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: -0.1),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0),
      ),
    );
  }
}
