import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette « cocooning » de Ela.
abstract final class ElaColors {
  // Mode jour : papier / sépia coquille d'œuf.
  static const Color paper = Color(0xFFF6EFE3);
  static const Color paperSurface = Color(0xFFFDF8EC);
  static const Color paperCard = Color(0xFFFFFDF6);
  static const Color sepia = Color(0xFFA9683A);
  static const Color sepiaDeep = Color(0xFF7C4A24);
  static const Color sepiaSoft = Color(0xFFF3DCC0);
  static const Color gold = Color(0xFFC9974F);
  static const Color ink = Color(0xFF3D2E1F);
  static const Color inkSoft = Color(0xFF6B5844);
  static const Color lineLight = Color(0xFFD8C8AE);

  // Mode nuit : bleu nuit / sépia, lumière douce de lampe de chevet.
  static const Color night = Color(0xFF0F1420);
  static const Color nightSurface = Color(0xFF161D2E);
  static const Color nightCard = Color(0xFF1C2438);
  static const Color nightSepia = Color(0xFFE0B06A);
  static const Color nightSepiaDeep = Color(0xFFF0CE93);
  static const Color nightInk = Color(0xFFEAE0CE);
  static const Color nightInkSoft = Color(0xFFB3A48D);
  static const Color lineNight = Color(0xFF39425A);
  static const Color error = Color(0xFFC2543C);
}

class ElaTheme {
  ElaTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: isLight ? ElaColors.sepia : ElaColors.nightSepia,
      onPrimary: isLight ? Colors.white : ElaColors.night,
      primaryContainer: isLight ? Color(0xFFF3DCC0) : Color(0xFF4A3A22),
      onPrimaryContainer: isLight ? ElaColors.sepiaDeep : ElaColors.nightSepiaDeep,
      secondary: isLight ? ElaColors.gold : Color(0xFFD9A556),
      // Accessibilité : encre sur or (≥ 5:1) plutôt que blanc (≈ 2,6:1).
      onSecondary: isLight ? ElaColors.ink : Color(0xFF3D2E1F),
      secondaryContainer: isLight ? Color(0xFFF7E7C8) : Color(0xFF3A3124),
      onSecondaryContainer: isLight ? Color(0xFF6B4E1E) : Color(0xFFEED9AE),
      surface: isLight ? ElaColors.paperSurface : ElaColors.nightSurface,
      onSurface: isLight ? ElaColors.ink : ElaColors.nightInk,
      surfaceContainerHighest:
          isLight ? Color(0xFFF1E7D3) : Color(0xFF232C42),
      onSurfaceVariant: isLight ? ElaColors.inkSoft : ElaColors.nightInkSoft,
      outline: isLight ? ElaColors.lineLight : ElaColors.lineNight,
      error: isLight ? ElaColors.error : Color(0xFFE08A6E),
      onError: Colors.white,
    );

    final TextTheme sans = GoogleFonts.nunitoSansTextTheme(
      (isLight ? ThemeData.light() : ThemeData.dark()).textTheme,
    );
    final TextTheme serif = GoogleFonts.loraTextTheme(sans);
    final TextTheme textTheme = serif.copyWith(
      bodySmall: sans.bodySmall,
      bodyMedium: sans.bodyMedium,
      bodyLarge: sans.bodyLarge,
      labelSmall: sans.labelSmall,
      labelMedium: sans.labelMedium,
      labelLarge: sans.labelLarge,
    );

    final base = isLight ? ThemeData.light() : ThemeData.dark();
    return base.copyWith(
      colorScheme: scheme,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: isLight ? ElaColors.paperCard : ElaColors.nightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      listTileTheme: const ListTileThemeData(iconColor: null),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.surfaceContainerHighest,
        contentTextStyle: TextStyle(color: scheme.onSurface),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline.withValues(alpha: 0.6),
        thickness: 1,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.primaryContainer,
        labelStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.7)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? ElaColors.paperCard : ElaColors.nightCard,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ElaColors.gold, width: 1.4),
        ),
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }
}

/// Halo « lampe de chevet » : doré, doux, jamais agressif.
class ElaLampHalo {
  ElaLampHalo._();

  static const Color core = Color(0xFFFFD98A);
  static const Color glow = Color(0x59C9974F);
  static const Color glowWide = Color(0x24C9974F);
}
