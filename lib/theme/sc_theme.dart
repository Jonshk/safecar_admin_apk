// lib/theme/sc_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta y tipografía del "cluster de instrumentos" — la identidad
/// visual elegida para Safe Car Admin. Todo color y fuente de la app
/// debería salir de aquí, nunca de un hex suelto en un widget.
class SC {
  SC._();

  // Superficies
  static const bg = Color(0xFF121316);
  static const surface = Color(0xFF1C2024);
  static const surfaceAlt = Color(0xFF1E2024);
  static const border = Color(0xFF232529);

  // Acento único: naranja de taller. Úsalo para todo lo que represente
  // grúas / "en camino" / la acción principal de la pantalla.
  static const orange = Color(0xFFFF6A1A);
  static const orangeBg = Color(0xFF2A1C12);

  // Acento secundario: cian de diagnóstico. Para "confirmado" y datos
  // informativos que no son la acción principal.
  static const cyan = Color(0xFF00D4C2);
  static const cyanBg = Color(0xFF0F2926);

  // Semánticos
  static const success = Color(0xFF9FE1A0);
  static const successBg = Color(0xFF0F2916);
  static const danger = Color(0xFFF09595);
  static const dangerBg = Color(0xFF2A1212);

  // Texto
  static const textPrimary = Color(0xFFF2F1ED);
  static const textSecondary = Color(0xFF7A7D83);
  static const textMuted = Color(0xFF5A5D63);

  /// Display condensado para títulos de pantalla, tipo señalética.
  static TextStyle display({double size = 20, Color? color}) =>
      GoogleFonts.oswald(
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: color ?? textPrimary,
      );

  /// Monoespaciada tabular para cualquier número que se muestre al
  /// usuario (contadores, referencias, precios, horas) — efecto
  /// "odómetro" consistente con el resto del cluster.
  static TextStyle mono({double size = 14, FontWeight weight = FontWeight.w700, Color? color}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color ?? textPrimary,
      );

  /// Cuerpo de texto general.
  static TextStyle body({double size = 13, FontWeight weight = FontWeight.w400, Color? color}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color ?? textPrimary,
      );

  static const Color statusPending = textSecondary;
  static const Color statusConfirmed = cyan;
  static const Color statusInProgress = orange;
  static const Color statusCompleted = success;
  static const Color statusCancelled = danger;

  static Color statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return statusConfirmed;
      case 'in_progress':
        return statusInProgress;
      case 'completed':
        return statusCompleted;
      case 'cancelled':
        return statusCancelled;
      case 'pending':
      default:
        return statusPending;
    }
  }

  static Color statusBg(String status) {
    switch (status) {
      case 'confirmed':
        return cyanBg;
      case 'in_progress':
        return orangeBg;
      case 'completed':
        return successBg;
      case 'cancelled':
        return dangerBg;
      case 'pending':
      default:
        return surfaceAlt;
    }
  }
}