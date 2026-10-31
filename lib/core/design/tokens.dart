import 'package:flutter/material.dart';

/// Les encres et les papiers de l'édition Ela. Les écrans utilisent le
/// ColorScheme sémantique ; cette palette ne sert qu'au thème.
abstract final class ElaColors {
  static const paper = Color(0xFFF4EFE4);
  static const paperSurface = Color(0xFFF8F4EB);
  static const paperCard = Color(0xFFFFFCF5);
  static const sepia = Color(0xFF703B43); // Bordeaux de reliure.
  static const sepiaDeep = Color(0xFF542A32);
  static const sepiaSoft = Color(0xFFEEDFE0);
  static const gold = Color(0xFF876A36);
  static const ink = Color(0xFF302C27);
  static const inkSoft = Color(0xFF6C6257);
  static const lineLight = Color(0xFFD4CABA);
  static const binding = Color(0xFF36554A);
  static const night = Color(0xFF141F24);
  static const nightSurface = Color(0xFF19262C);
  static const nightCard = Color(0xFF213038);
  static const nightSepia = Color(0xFFDFBC83);
  static const nightSepiaDeep = Color(0xFFF0D5AC);
  static const nightInk = Color(0xFFF2E9D8);
  static const nightInkSoft = Color(0xFFC1B7A5);
  static const lineNight = Color(0xFF4F6067);
  static const error = Color(0xFF963B3E);
  static const transparent = Colors.transparent;
  static const camera = Color(0xFF121B20);
}

abstract final class ElaType {
  static const titleFamily = 'CormorantGaramond';
  static const bodyFamily = 'Literata';
  static const labelFamily = 'NunitoSans';
  static const display = 64.0;
  static const heading = 36.0;
  static const title = 26.0;
  static const section = 22.0;
  static const body = 15.0;
  static const small = 13.0;
  static const caption = 12.0;
  static const leading = 1.55;
}

abstract final class ElaSpace {
  static const hairline = 1.0;
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const page = EdgeInsets.symmetric(horizontal: lg, vertical: md);
  static const reading = EdgeInsets.fromLTRB(lg, xs, lg, xl);
  static const radius = 4.0;
  static const coverRadius = 3.0;
}

abstract final class ElaMotion {
  static const page = Duration(milliseconds: 320);
  static const detail = Duration(milliseconds: 240);
}

abstract final class ElaShadows {
  static List<BoxShadow> page(Color ink) => [
    BoxShadow(
      color: ink.withValues(alpha: .045),
      blurRadius: 12,
      offset: const Offset(0, 3),
    ),
    BoxShadow(
      color: ink.withValues(alpha: .025),
      blurRadius: 2,
      offset: const Offset(2, 0),
    ),
  ];
  static List<BoxShadow> cover(Color ink) => [
    BoxShadow(
      color: ink.withValues(alpha: .18),
      blurRadius: 10,
      offset: const Offset(3, 5),
    ),
  ];
}

/// Dimensions de composition partagées : grille, couvertures et contrôles.
/// Les noms v… conservent les valeurs des variantes sans nombres dans les écrans.
abstract final class ElaSize {
  static const v0 = 0.0;
  static const v0_625 = 0.625;
  static const v1_45 = 1.45;
  static const v1_5 = 1.5;
  static const v1_55 = 1.55;
  static const v2 = 2.0;
  static const v3 = 3.0;
  static const v4 = 4.0;
  static const v5 = 5.0;
  static const v6 = 6.0;
  static const v7 = 7.0;
  static const v8 = 8.0;
  static const v10 = 10.0;
  static const v11_5 = 11.5;
  static const v12 = 12.0;
  static const v12_5 = 12.5;
  static const v13 = 13.0;
  static const v13_5 = 13.5;
  static const v14 = 14.0;
  static const v14_5 = 14.5;
  static const v15 = 15.0;
  static const v15_5 = 15.5;
  static const v16 = 16.0;
  static const v17 = 17.0;
  static const v18 = 18.0;
  static const v19 = 19.0;
  static const v20 = 20.0;
  static const v22 = 22.0;
  static const v23 = 23.0;
  static const v24 = 24.0;
  static const v28 = 28.0;
  static const v30 = 30.0;
  static const v32 = 32.0;
  static const v34 = 34.0;
  static const v38 = 38.0;
  static const v40 = 40.0;
  static const v44 = 44.0;
  static const v48 = 48.0;
  static const v76 = 76.0;
  static const v96 = 96.0;
  static const v110 = 110.0;
  static const v120 = 120.0;
  static const v140 = 140.0;
  static const v220 = 220.0;
  static const v240 = 240.0;
}
