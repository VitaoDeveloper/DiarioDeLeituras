import 'package:flutter/material.dart';

import 'tokens.dart';

/// Textos de leitura longa: fichamentos, citações e editor de análise.
///
/// Acessível nas telas via `Theme.of(context).extension<ReadingTextTheme>()`.
@immutable
class ReadingTextTheme extends ThemeExtension<ReadingTextTheme> {
  const ReadingTextTheme({required this.body, required this.quote});

  /// 17/28 (altura 1,6) para textos corridos.
  final TextStyle body;

  /// Mesmo corpo, em itálico e cor secundária, para citações.
  final TextStyle quote;

  @override
  ReadingTextTheme copyWith({TextStyle? body, TextStyle? quote}) {
    return ReadingTextTheme(body: body ?? this.body, quote: quote ?? this.quote);
  }

  @override
  ReadingTextTheme lerp(covariant ThemeExtension<ReadingTextTheme>? other, double t) {
    if (other is! ReadingTextTheme) return this;
    return ReadingTextTheme(
      body: TextStyle.lerp(body, other.body, t)!,
      quote: TextStyle.lerp(quote, other.quote, t)!,
    );
  }
}

/// Tema único do app. Claro e escuro saem da mesma função.
ThemeData buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final palette = isDark ? AppPalette.dark : AppPalette.light;
  final textTheme = _buildTextTheme(palette);
  final border = BorderSide(color: palette.outline, width: AppTokens.borderWidth);
  final focusedBorder = BorderSide(
    color: palette.accent,
    width: AppTokens.focusedBorderWidth,
  );

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: palette.accent,
    onPrimary: palette.onAccent,
    primaryContainer: palette.surfaceVariant,
    onPrimaryContainer: palette.onBackground,
    secondary: palette.onSurfaceVariant,
    onSecondary: palette.surface,
    secondaryContainer: palette.surfaceVariant,
    onSecondaryContainer: palette.onBackground,
    tertiary: palette.onSurfaceVariant,
    onTertiary: palette.surface,
    tertiaryContainer: palette.surfaceVariant,
    onTertiaryContainer: palette.onBackground,
    error: palette.error,
    onError: palette.onError,
    errorContainer: palette.surfaceVariant,
    onErrorContainer: palette.error,
    surface: palette.surface,
    onSurface: palette.onBackground,
    surfaceContainerHighest: palette.surfaceVariant,
    onSurfaceVariant: palette.onSurfaceVariant,
    outline: palette.outline,
    outlineVariant: palette.outline,
    shadow: palette.onBackground,
    scrim: palette.onBackground,
    inverseSurface: isDark ? palette.surface : palette.onBackground,
    onInverseSurface: isDark ? palette.onBackground : palette.surface,
    inversePrimary: palette.accent,
    surfaceTint: Colors.transparent,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    fontFamily: AppTokens.fontFamily,
    textTheme: textTheme,
    scaffoldBackgroundColor: palette.background,
    canvasColor: palette.background,
    dividerColor: palette.outline,
    splashFactory: NoSplash.splashFactory,
    extensions: [
      ReadingTextTheme(
        body: textTheme.bodyLarge!.copyWith(
          fontSize: AppTokens.longTextFontSize,
          height: AppTokens.longTextLineHeight,
        ),
        quote: textTheme.bodyLarge!.copyWith(
          fontSize: AppTokens.longTextFontSize,
          height: AppTokens.longTextLineHeight,
          fontStyle: FontStyle.italic,
          color: palette.onSurfaceVariant,
        ),
      ),
    ],
    appBarTheme: AppBarTheme(
      backgroundColor: palette.background,
      surfaceTintColor: Colors.transparent,
      foregroundColor: palette.onBackground,
      iconTheme: IconThemeData(color: palette.onBackground, size: AppTokens.iconSize),
      actionsIconTheme: IconThemeData(color: palette.onBackground, size: AppTokens.iconSize),
      titleTextStyle: textTheme.titleLarge!.copyWith(color: palette.onBackground),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      indicatorColor: palette.accent.withValues(alpha: isDark ? 0.30 : 0.16),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? palette.accent : palette.onSurfaceVariant,
          size: AppTokens.iconSize,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return textTheme.labelLarge!.copyWith(
          color: selected ? palette.accent : palette.onSurfaceVariant,
        );
      }),
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: AppTokens.cardGap / 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        side: border,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        side: border,
      ),
      titleTextStyle: textTheme.titleLarge!.copyWith(color: palette.onBackground),
      contentTextStyle: textTheme.bodyMedium!.copyWith(color: palette.onBackground),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTokens.radiusLarge),
        ),
        side: border,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: palette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        side: border,
      ),
      textStyle: textTheme.bodyMedium!.copyWith(color: palette.onBackground),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surfaceVariant,
      hintStyle: textTheme.bodyMedium!.copyWith(color: palette.onSurfaceVariant),
      labelStyle: textTheme.bodyMedium!.copyWith(color: palette.onSurfaceVariant),
      floatingLabelStyle: textTheme.bodySmall!.copyWith(color: palette.accent),
      helperStyle: textTheme.bodySmall!.copyWith(color: palette.onSurfaceVariant),
      errorStyle: textTheme.bodySmall!.copyWith(color: palette.error),
      border: _fieldBorder(border),
      enabledBorder: _fieldBorder(border),
      disabledBorder: _fieldBorder(border),
      focusedBorder: _fieldBorder(focusedBorder),
      errorBorder: _fieldBorder(BorderSide(color: palette.error, width: AppTokens.borderWidth)),
      focusedErrorBorder: _fieldBorder(
        BorderSide(color: palette.error, width: AppTokens.focusedBorderWidth),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTokens.screenMargin,
        vertical: AppTokens.space + AppTokens.borderWidth,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: palette.onAccent,
        disabledBackgroundColor: palette.surfaceVariant,
        disabledForegroundColor: palette.onSurfaceVariant,
        elevation: 0,
        minimumSize: const Size(0, AppTokens.minTouchTarget),
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.screenMargin),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius),
        ),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.onBackground,
        disabledForegroundColor: palette.onSurfaceVariant,
        side: border,
        elevation: 0,
        minimumSize: const Size(0, AppTokens.minTouchTarget),
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.screenMargin),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius),
        ),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.onBackground,
        disabledForegroundColor: palette.onSurfaceVariant,
        minimumSize: const Size(0, AppTokens.minTouchTarget),
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius),
        ),
        textStyle: textTheme.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(AppTokens.minTouchTarget, AppTokens.minTouchTarget),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius),
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: palette.accent,
      foregroundColor: palette.onAccent,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.surface,
      selectedColor: palette.surfaceVariant,
      disabledColor: palette.surfaceVariant,
      side: border,
      showCheckmark: false,
      labelStyle: textTheme.bodySmall!.copyWith(color: palette.onBackground),
      secondaryLabelStyle: textTheme.bodySmall!.copyWith(color: palette.onSurfaceVariant),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space,
        vertical: AppTokens.space / 2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: palette.onBackground,
      linearTrackColor: palette.surfaceVariant,
      circularTrackColor: palette.surfaceVariant,
    ),
    dividerTheme: DividerThemeData(
      color: palette.outline,
      thickness: AppTokens.borderWidth,
      space: AppTokens.space,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.surface,
      contentTextStyle: textTheme.bodyMedium!.copyWith(color: palette.onBackground),
      actionTextColor: palette.accent,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        side: border,
      ),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppTokens.screenMargin),
      minVerticalPadding: AppTokens.space,
      titleTextStyle: textTheme.bodyLarge!.copyWith(color: palette.onBackground),
      subtitleTextStyle: textTheme.bodySmall!.copyWith(color: palette.onSurfaceVariant),
      iconColor: palette.onSurfaceVariant,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          return palette.onBackground;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? palette.surfaceVariant
              : palette.surface;
        }),
        side: WidgetStateProperty.all(border),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radius)),
        ),
        textStyle: WidgetStateProperty.all(textTheme.labelLarge),
        minimumSize: WidgetStateProperty.all(
          const Size(AppTokens.minTouchTarget, AppTokens.minTouchTarget),
        ),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? palette.onBackground
            : Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(palette.surface),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      side: BorderSide(color: palette.outline, width: AppTokens.borderWidth),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius / 2),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected) ? palette.onBackground : palette.outline;
      }),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected) ? palette.surface : palette.outline;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? palette.onBackground
            : palette.surfaceVariant;
      }),
    ),
  );
}

OutlineInputBorder _fieldBorder(BorderSide side) {
  return OutlineInputBorder(
    borderSide: side,
    borderRadius: BorderRadius.circular(AppTokens.radius),
  );
}

TextTheme _buildTextTheme(AppPalette palette) {
  TextStyle style(double size, double lineHeight, FontWeight weight) => TextStyle(
        fontFamily: AppTokens.fontFamily,
        fontSize: size,
        height: lineHeight / size,
        fontWeight: weight,
      );

  final themed = TextTheme(
    headlineSmall: style(24, 32, FontWeight.w600),
    titleLarge: style(20, 28, FontWeight.w600),
    titleMedium: style(16, 24, FontWeight.w600),
    bodyLarge: style(16, 24, FontWeight.w400),
    bodyMedium: style(14, 20, FontWeight.w400),
    bodySmall: style(12, 16, FontWeight.w400),
    labelLarge: style(14, 20, FontWeight.w500),
  ).apply(bodyColor: palette.onBackground, displayColor: palette.onBackground);

  return themed.copyWith(
    bodySmall: themed.bodySmall!.copyWith(color: palette.onSurfaceVariant),
  );
}
