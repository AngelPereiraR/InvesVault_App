import 'package:flutter/material.dart';

/// Paleta de verdes: de menta claro (#D8F3DC) a bosque oscuro (#1B4332)
class AppGreens {
  static const c100 = Color(0xFFD8F3DC);
  static const c200 = Color(0xFFB7E4C7);
  static const c300 = Color(0xFF74C69D);
  static const c400 = Color(0xFF40916C);
  static const c500 = Color(0xFF2D6A4F);
  static const c600 = Color(0xFF1B4332);
}

/// Paleta de morados: de lavanda claro (#E0AAFF) a casi negro (#10002B)
class AppPurples {
  static const c100 = Color(0xFFE0AAFF);
  static const c200 = Color(0xFFC77DFF);
  static const c300 = Color(0xFF9D4EDD);
  static const c400 = Color(0xFF7B2FBE);
  static const c500 = Color(0xFF5A189A);
  static const c600 = Color(0xFF10002B);
}

/// Paleta neutral: de blanco (#FFFFFF) a negro (#121212)
class AppNeutrals {
  static const c100 = Color(0xFFFFFFFF);
  static const c150 = Color(0xFFECECEC);
  static const c200 = Color(0xFFF5F5F5);
  static const c300 = Color(0xFFE0E0E0);
  static const c400 = Color(0xFF9E9E9E);
  static const c500 = Color(0xFF424242);
  static const c600 = Color(0xFF121212);
}

/// Colores semánticos del sistema
class AppColors {
  // Primarios (verde)
  static const primary       = AppGreens.c400;    // #40916C
  static const primaryLight  = AppGreens.c300;    // #74C69D
  static const primaryDark   = AppGreens.c500;    // #2D6A4F

  // Secundarios (morado)
  static const secondary      = AppPurples.c300;  // #9D4EDD
  static const secondaryLight = AppPurples.c200;  // #C77DFF
  static const secondaryDark  = AppPurples.c500;  // #5A189A

  // Superficies
  static const background = AppNeutrals.c200;     // #F5F5F5
  static const surface    = AppNeutrals.c100;     // #FFFFFF

  // Texto
  static const textPrimary   = AppNeutrals.c600;  // #121212
  static const textSecondary = AppNeutrals.c500;  // #424242
  static const textHint      = AppNeutrals.c400;  // #9E9E9E

  // Bordes / divisores
  static const border = AppNeutrals.c300;         // #E0E0E0

  // Feedbacks
  static const danger  = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const success = AppGreens.c300;

  // Sombras (negro con opacidad)
  static const shadowLight = Color(0x1A121212);   // 10 % opacidad
  static const shadowDark  = Color(0x33121212);   // 20 % opacidad

  // AppBar de la shell (púrpura oscuro)
  static const shellAppBar = Color(0xFF3C096C);
}
