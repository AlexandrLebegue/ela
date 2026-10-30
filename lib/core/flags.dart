import 'dart:io';

/// Vrai uniquement quand l'app code tourne sous `flutter test`.
///
/// `flutter test` définit la variable d'environnement `FLUTTER_TEST=true`
/// dans le processus de test — ce n'est pas un `--dart-define`, donc
/// `bool.fromEnvironment('FLUTTER_TEST')` renvoie `false` (vérifié
/// empiriquement). Ce helper centralise la détection pour éviter d'appeler
/// la caméra, le réseau, etc., pendant les tests.
bool get isRunningUnderFlutterTest =>
    Platform.environment['FLUTTER_TEST'] == 'true';
