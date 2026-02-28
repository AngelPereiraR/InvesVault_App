import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  // ── Tipografía ─────────────────────────────────────────────────────────────
  static TextTheme _buildTextTheme({required bool dark}) {
    final textColor = dark ? AppNeutrals.c200 : AppColors.textPrimary;
    final subColor  = dark ? AppNeutrals.c400 : AppColors.textSecondary;
    final hintColor = dark ? AppNeutrals.c400 : AppColors.textHint;

    return TextTheme(
      // H1 — Títulos de página: 24px, Roboto, Bold
      displayLarge: GoogleFonts.roboto(
        fontSize: 24, fontWeight: FontWeight.w700, color: textColor,
      ),
      // H2 — Títulos de tarjeta/sección: 20px, Roboto, Medium
      titleLarge: GoogleFonts.roboto(
        fontSize: 20, fontWeight: FontWeight.w500, color: textColor,
      ),
      titleMedium: GoogleFonts.roboto(
        fontSize: 18, fontWeight: FontWeight.w500, color: textColor,
      ),
      titleSmall: GoogleFonts.roboto(
        fontSize: 16, fontWeight: FontWeight.w500, color: textColor,
      ),
      // Cuerpo principal: 16px, Open Sans, Regular
      bodyLarge: GoogleFonts.openSans(
        fontSize: 16, fontWeight: FontWeight.w400, color: textColor,
      ),
      // Texto de apoyo: 14px, Open Sans, Regular
      bodyMedium: GoogleFonts.openSans(
        fontSize: 14, fontWeight: FontWeight.w400, color: subColor,
      ),
      bodySmall: GoogleFonts.openSans(
        fontSize: 14, fontWeight: FontWeight.w400, color: subColor,
      ),
      // Etiquetas / texto muy pequeño: 12px, Open Sans, Regular
      labelLarge: GoogleFonts.openSans(
        fontSize: 14, fontWeight: FontWeight.w500, color: subColor,
      ),
      labelMedium: GoogleFonts.openSans(
        fontSize: 12, fontWeight: FontWeight.w500, color: subColor,
      ),
      labelSmall: GoogleFonts.openSans(
        fontSize: 12, fontWeight: FontWeight.w400, color: hintColor,
      ),
    );
  }

  // ── Tema claro ─────────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: AppColors.surface,
          primaryContainer: AppGreens.c100,
          onPrimaryContainer: AppColors.primaryDark,
          secondary: AppColors.secondary,
          onSecondary: AppColors.surface,
          secondaryContainer: AppPurples.c100,
          onSecondaryContainer: AppColors.secondaryDark,
          error: AppColors.danger,
          onError: AppColors.surface,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          surfaceContainerHighest: AppNeutrals.c200,
          onSurfaceVariant: AppColors.textSecondary,
          outline: AppColors.border,
          outlineVariant: AppNeutrals.c300,
          shadow: AppColors.shadowDark,
        ),
        textTheme: _buildTextTheme(dark: false),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.roboto(
            fontSize: 20, fontWeight: FontWeight.w500,
            color: AppColors.surface,
          ),
          shadowColor: AppColors.shadowDark,
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: AppColors.surface,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 2,
          shadowColor: AppColors.shadowLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.surface,
            elevation: 2,
            shadowColor: AppColors.shadowLight,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: GoogleFonts.roboto(
              fontSize: 16, fontWeight: FontWeight.w500,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: GoogleFonts.roboto(
              fontSize: 16, fontWeight: FontWeight.w500,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          hintStyle: GoogleFonts.openSans(
            fontSize: 14, color: AppColors.textHint,
          ),
          labelStyle: GoogleFonts.openSans(
            fontSize: 14, color: AppColors.textSecondary,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.border,
          thickness: 1,
          space: 1,
        ),
      );

  // ── Tema oscuro ─────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: AppGreens.c300,
          onPrimary: AppNeutrals.c600,
          primaryContainer: AppGreens.c600,
          onPrimaryContainer: AppGreens.c100,
          secondary: AppPurples.c200,
          onSecondary: AppNeutrals.c600,
          secondaryContainer: AppPurples.c600,
          onSecondaryContainer: AppPurples.c100,
          error: AppColors.danger,
          onError: AppColors.surface,
          surface: Color(0xFF1E1E1E),
          onSurface: AppNeutrals.c200,
          surfaceContainerHighest: Color(0xFF2C2C2C),
          onSurfaceVariant: AppNeutrals.c400,
          outline: AppNeutrals.c500,
          outlineVariant: AppNeutrals.c500,
          shadow: AppColors.shadowDark,
        ),
        textTheme: _buildTextTheme(dark: true),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.roboto(
            fontSize: 20, fontWeight: FontWeight.w500,
            color: AppNeutrals.c200,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: AppColors.shadowDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: GoogleFonts.roboto(
              fontSize: 16, fontWeight: FontWeight.w500,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          hintStyle: GoogleFonts.openSans(fontSize: 14),
          labelStyle: GoogleFonts.openSans(fontSize: 14),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        dividerTheme: const DividerThemeData(
          thickness: 1,
          space: 1,
        ),
      );
}
