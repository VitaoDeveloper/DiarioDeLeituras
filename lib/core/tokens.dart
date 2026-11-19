import 'package:flutter/material.dart';

/// Constantes visuais da direção "biblioteca clássica".
///
/// Junto com `theme.dart`, este é o único lugar do projeto onde cores, raios,
/// espessuras e tamanhos de texto podem ser declarados. Telas devem usar
/// `Theme.of(context)` e estes tokens, nunca valores fixos.
abstract final class AppTokens {
  /// Família única, embutida como asset (o app é offline).
  static const String fontFamily = 'Literata';

  // Forma
  static const double radius = 8;
  static const double radiusLarge = 12;
  static const double borderWidth = 1;
  static const double focusedBorderWidth = 1.5;

  // Espaçamento (múltiplos de 8)
  static const double space = 8;
  static const double screenMargin = 16;
  static const double cardPadding = 16;
  static const double cardGap = 12;
  static const double minListTileHeight = 56;
  static const double minTouchTarget = 48;
  static const double minFilterHeight = 56;

  // Texto
  static const double longTextFontSize = 17;
  static const double longTextLineHeight = 28 / 17;
  static const double maxReadingWidth = 640;

  static const double iconSize = 24;
}

/// Paleta completa da direção visual, sem derivações de `ColorScheme.fromSeed`.
@immutable
class AppPalette {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.outline,
    required this.onBackground,
    required this.onSurfaceVariant,
    required this.accent,
    required this.onAccent,
    required this.error,
    required this.onError,
  });

  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color outline;
  final Color onBackground;
  final Color onSurfaceVariant;
  final Color accent;
  final Color onAccent;
  final Color error;
  final Color onError;

  static const light = AppPalette(
    background: Color(0xFFF4F1EB),
    surface: Color(0xFFFBF9F5),
    surfaceVariant: Color(0xFFECE7DE),
    outline: Color(0xFFCFC8BB),
    onBackground: Color(0xFF24211E),
    onSurfaceVariant: Color(0xFF6B645B),
    accent: Color(0xFF7A1B2C),
    onAccent: Color(0xFFFBF9F5),
    error: Color(0xFF9B2C2C),
    onError: Color(0xFFFBF9F5),
  );

  static const dark = AppPalette(
    background: Color(0xFF1C1A18),
    surface: Color(0xFF25221F),
    surfaceVariant: Color(0xFF2F2B27),
    outline: Color(0xFF433E38),
    onBackground: Color(0xFFEDE8DF),
    onSurfaceVariant: Color(0xFFA39B8F),
    accent: Color(0xFFD98591),
    onAccent: Color(0xFF1C1A18),
    error: Color(0xFFE08A8A),
    onError: Color(0xFF1C1A18),
  );
}
