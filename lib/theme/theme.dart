// lib/theme/theme.dart
import 'package:flutter/material.dart';

class AppColors {
  // Light Theme Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF9FBFF);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color borderGrey = Color(0xFFE6E6E6);
  static const Color textGrey = Color(0xFF4A4A4A);
  static const Color hintGrey = Color(0xFFA1A1A1);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2D2D2D);
  static const Color darkText = Color(0xFFE1E1E1);
  static const Color darkHint = Color(0xFF888888);
  static const Color darkBorder = Color(0xFF404040);

  // Panel Accent Colors (Same for both themes)
  static const Color studentPrimary = Color(0xFFA1C4FD);
  static const Color studentSecondary = Color(0xFFC2E9FB);

  static const Color securityPrimary = Color(0xFFFBC2EB);
  static const Color securitySecondary = Color(0xFFA6C1EE);

  static const Color adminPrimary = Color(0xFFFEE140);
  static const Color adminSecondary = Color(0xFFFA709A);

  static const Color superAdminPrimary = Color(0xFF84FAB0);
  static const Color superAdminSecondary = Color(0xFF8FD3F4);

  // SOS Button
  static const Color sosStart = Color(0xFFF857A6);
  static const Color sosEnd = Color(0xFFFF5858);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.studentPrimary,
      scaffoldBackgroundColor: AppColors.offWhite,
      fontFamily: 'Nunito',

      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: AppColors.studentPrimary,
        secondary: AppColors.studentSecondary,
        background: AppColors.offWhite,
        surface: AppColors.white,
        onBackground: AppColors.textGrey,
        onSurface: AppColors.textGrey,
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        titleTextStyle: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textGrey,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: AppColors.textGrey),
        actionsIconTheme: IconThemeData(color: AppColors.textGrey),
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.textGrey,
          letterSpacing: 0.5,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textGrey,
          letterSpacing: 0.5,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textGrey,
          letterSpacing: 0.5,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textGrey,
          letterSpacing: 0.5,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textGrey,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textGrey,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textGrey,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textGrey,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textGrey,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textGrey,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.hintGrey,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
          letterSpacing: 1.0,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
          letterSpacing: 1.0,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
          letterSpacing: 1.0,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Button Themes
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        buttonColor: AppColors.studentPrimary,
        textTheme: ButtonTextTheme.primary,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.studentPrimary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 3,
          textStyle: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.studentPrimary,
          textStyle: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.studentPrimary,
          side: BorderSide(color: AppColors.studentPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w600,
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppColors.borderGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppColors.borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppColors.studentPrimary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppColors.error),
        ),
        hintStyle: TextStyle(
          color: AppColors.hintGrey,
          fontFamily: 'Nunito',
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(
          color: AppColors.textGrey,
          fontFamily: 'Nunito',
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.studentPrimary,
        unselectedItemColor: AppColors.hintGrey,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.studentPrimary,
        unselectedLabelColor: AppColors.hintGrey,
        labelStyle: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w400,
        ),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            color: AppColors.studentPrimary,
            width: 2.0,
          ),
        ),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: AppColors.borderGrey,
        thickness: 1,
        space: 1,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.studentPrimary,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightGrey,
        selectedColor: AppColors.studentPrimary,
        secondarySelectedColor: AppColors.studentPrimary,
        labelStyle: TextStyle(
          fontFamily: 'Nunito',
          color: AppColors.textGrey,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: 'Nunito',
          color: AppColors.white,
          fontWeight: FontWeight.w500,
        ),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.studentPrimary,
        linearTrackColor: AppColors.lightGrey,
        circularTrackColor: AppColors.lightGrey,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.studentPrimary,
      scaffoldBackgroundColor: AppColors.darkBackground,
      fontFamily: 'Nunito',

      // Color Scheme
      colorScheme: ColorScheme.dark(
        primary: AppColors.studentPrimary,
        secondary: AppColors.studentSecondary,
        background: AppColors.darkBackground,
        surface: AppColors.darkSurface,
        onBackground: AppColors.darkText,
        onSurface: AppColors.darkText,
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.3),
        titleTextStyle: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: AppColors.darkText),
        actionsIconTheme: IconThemeData(color: AppColors.darkText),
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.darkText,
          letterSpacing: 0.5,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.darkText,
          letterSpacing: 0.5,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.darkText,
          letterSpacing: 0.5,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
          letterSpacing: 0.5,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.darkText,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.darkText,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.darkHint,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
          letterSpacing: 1.0,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
          letterSpacing: 1.0,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
          letterSpacing: 1.0,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.studentPrimary,
          foregroundColor: AppColors.darkText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 3,
          textStyle: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppColors.studentPrimary),
        ),
        hintStyle: TextStyle(
          color: AppColors.darkHint,
          fontFamily: 'Nunito',
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(
          color: AppColors.darkText,
          fontFamily: 'Nunito',
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.studentPrimary,
        unselectedItemColor: AppColors.darkHint,
        elevation: 8,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }
}

// Gradient helper class
class AppGradients {
  static LinearGradient get studentGradient => LinearGradient(
    colors: [AppColors.studentPrimary, AppColors.studentSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get securityGradient => LinearGradient(
    colors: [AppColors.securityPrimary, AppColors.securitySecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get adminGradient => LinearGradient(
    colors: [AppColors.adminPrimary, AppColors.adminSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get superAdminGradient => LinearGradient(
    colors: [AppColors.superAdminPrimary, AppColors.superAdminSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get sosGradient => LinearGradient(
    colors: [AppColors.sosStart, AppColors.sosEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get cardGradient => LinearGradient(
    colors: [AppColors.white, AppColors.offWhite],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient get darkCardGradient => LinearGradient(
    colors: [AppColors.darkSurface, AppColors.darkCard],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

// Text Styles for quick access
class AppTextStyles {
  static TextStyle get headlineLarge => TextStyle(
    fontFamily: 'Nunito',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textGrey,
    letterSpacing: 0.5,
  );

  static TextStyle get headlineMedium => TextStyle(
    fontFamily: 'Nunito',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textGrey,
  );

  static TextStyle get titleLarge => TextStyle(
    fontFamily: 'Nunito',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textGrey,
  );

  static TextStyle get bodyLarge => TextStyle(
    fontFamily: 'Nunito',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textGrey,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontFamily: 'Nunito',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textGrey,
  );

  static TextStyle get caption => TextStyle(
    fontFamily: 'Nunito',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.hintGrey,
  );

  static TextStyle get button => TextStyle(
    fontFamily: 'Nunito',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    letterSpacing: 1.0,
  );
}

// Shadow styles
class AppShadows {
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 15,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: AppColors.studentPrimary.withOpacity(0.3),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get navBarShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
  ];
}