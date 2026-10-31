import 'dart:io';
import 'package:flutter/services.dart';

Future<void> loadAppFonts() async {
  for (final family in [
    'Lora',
    'NunitoSans',
    'CormorantGaramond',
    'Literata',
  ]) {
    final loader = FontLoader(family);
    loader.addFont(rootBundle.load('assets/fonts/$family.ttf'));
    loader.addFont(rootBundle.load('assets/fonts/$family-Italic.ttf'));
    await loader.load();
  }
  for (final family in ['NotoSymbols', 'NotoEmoji']) {
    final loader = FontLoader(family)
      ..addFont(rootBundle.load('assets/fonts/$family.ttf'));
    await loader.load();
  }
  final sdk =
      Platform.environment['FLUTTER_ROOT'] ??
      '${Platform.environment['HOME']}/flutter';
  final icons = FontLoader('MaterialIcons')
    ..addFont(
      Future.value(
        ByteData.sublistView(
          await File(
            '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          ).readAsBytes(),
        ),
      ),
    );
  await icons.load();
}
