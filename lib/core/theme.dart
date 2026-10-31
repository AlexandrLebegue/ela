import 'package:flutter/material.dart';
import 'design/tokens.dart';
export 'design/tokens.dart';
export 'design/components.dart';

class ElaTheme {
  ElaTheme._();
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData _build(Brightness brightness) {
    final light = brightness == Brightness.light;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: light ? ElaColors.sepia : ElaColors.nightSepia,
      onPrimary: light ? ElaColors.paperCard : ElaColors.night,
      primaryContainer: light ? ElaColors.sepiaSoft : const Color(0xFF3F3540),
      onPrimaryContainer: light
          ? ElaColors.sepiaDeep
          : ElaColors.nightSepiaDeep,
      secondary: light ? ElaColors.gold : ElaColors.nightSepia,
      onSecondary: light ? ElaColors.paperCard : ElaColors.night,
      secondaryContainer: light
          ? const Color(0xFFEDE4D2)
          : const Color(0xFF343C38),
      onSecondaryContainer: light
          ? const Color(0xFF574322)
          : ElaColors.nightSepiaDeep,
      surface: light ? ElaColors.paperSurface : ElaColors.nightSurface,
      onSurface: light ? ElaColors.ink : ElaColors.nightInk,
      surfaceContainerHighest: light
          ? const Color(0xFFECE6D9)
          : const Color(0xFF2C3B42),
      onSurfaceVariant: light ? ElaColors.inkSoft : ElaColors.nightInkSoft,
      outline: light ? ElaColors.lineLight : ElaColors.lineNight,
      outlineVariant: light ? ElaColors.lineLight : ElaColors.lineNight,
      error: light ? ElaColors.error : const Color(0xFFF0AAA4),
      onError: light ? ElaColors.paperCard : ElaColors.night,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final body = base.textTheme.apply(
      fontFamily: ElaType.bodyFamily,
      fontFamilyFallback: const ['NotoSymbols', 'NotoEmoji'],
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    TextStyle title(double size) => TextStyle(
      fontFamily: ElaType.titleFamily,
      fontFamilyFallback: const ['NotoSymbols', 'NotoEmoji'],
      fontSize: size,
      height: 1.12,
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
    );
    TextStyle label(double size) => TextStyle(
      fontFamily: ElaType.labelFamily,
      fontFamilyFallback: const ['NotoSymbols', 'NotoEmoji'],
      fontSize: size,
      height: 1.35,
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
    );
    final text = body.copyWith(
      displayLarge: title(ElaType.display),
      displayMedium: title(48),
      displaySmall: title(40),
      headlineLarge: title(ElaType.heading),
      headlineMedium: title(32),
      headlineSmall: title(28),
      titleLarge: title(ElaType.title),
      titleMedium: title(ElaType.section),
      titleSmall: title(18),
      bodyLarge: body.bodyLarge?.copyWith(
        fontSize: 16,
        height: ElaType.leading,
      ),
      bodyMedium: body.bodyMedium?.copyWith(
        fontSize: ElaType.body,
        height: ElaType.leading,
      ),
      bodySmall: body.bodySmall?.copyWith(
        fontSize: ElaType.small,
        height: ElaType.leading,
      ),
      labelLarge: label(14),
      labelMedium: label(12),
      labelSmall: label(11),
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ElaSpace.radius),
    );
    final buttons = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      shape: WidgetStatePropertyAll(shape),
      textStyle: WidgetStatePropertyAll(text.labelLarge),
    );
    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        shape: Border(
          bottom: BorderSide(color: scheme.outline.withValues(alpha: .5)),
        ),
      ),
      cardTheme: CardThemeData(
        color: light ? ElaColors.paperCard : ElaColors.nightCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: shape.copyWith(
          side: BorderSide(color: scheme.outline.withValues(alpha: .6)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(style: buttons),
      outlinedButtonTheme: OutlinedButtonThemeData(style: buttons),
      textButtonTheme: TextButtonThemeData(style: buttons),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(48, 48))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.onSurface,
        contentTextStyle: text.bodySmall?.copyWith(color: scheme.surface),
        shape: shape,
      ),
      dividerTheme: DividerThemeData(color: scheme.outline, thickness: 1),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.transparent,
        selectedColor: scheme.primaryContainer,
        labelStyle: text.labelMedium,
        shape: shape.copyWith(side: BorderSide(color: scheme.outline)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: light ? ElaColors.paperCard : ElaColors.nightCard,
        contentPadding: const EdgeInsets.all(16),
        labelStyle: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
        hintStyle: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ElaSpace.radius),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ElaSpace.radius),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ElaSpace.radius),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: shape,
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodySmall,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }
}

abstract final class ElaLampHalo {
  static const core = ElaColors.nightSepiaDeep;
  static const glow = Color(0x59876A36);
  static const glowWide = Color(0x24876A36);
}
