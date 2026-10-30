import 'package:ela/core/theme.dart';
import 'package:ela/features/account/account_screen.dart';
import 'package:ela/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    Map<String, Object>? seed,
  }) {
    SharedPreferences.setMockInitialValues(seed ?? {});
    return SharedPreferences.getInstance().then((prefs) async {
      // Viewport téléphone (le défaut 800×600 est trop court pour cette
      // écran).
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: ElaTheme.light,
            home: home,
          ),
        ),
      );
      await tester.pumpAndSettle();
    });
  }

  /// Fait avancer l'horloge factice assez pour déclencher tous les
  /// délais simulés du backend fake (≤ 1,5 s) puis stabilise.
  /// (`pumpAndSettle` seul ne déclenche pas les `Future.delayed` qui
  /// n'engendrent pas de frame.)
  Future<void> settleAll(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pumpAndSettle();
  }

  /// App complète avec le vrai go_router (pour tester les routes).
  Future<void> pumpRouted(
    WidgetTester tester, {
    String location = '/bibliotheque',
  }) {
    SharedPreferences.setMockInitialValues({});
    return SharedPreferences.getInstance().then((prefs) async {
      final scope = ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: Builder(builder: (context) {
          final ref = ProviderScope.containerOf(context);
          return MaterialApp.router(
            theme: ElaTheme.light,
            routerConfig: ref.read(routerProvider),
          );
        }),
      );
      await tester.pumpWidget(scope);
      await tester.pump();
      ProviderScope.containerOf(
              tester.element(find.byType(MaterialApp)))
          .read(routerProvider)
          .go(location);
      await settleAll(tester);
    });
  }

  Future<void> pumpUntil(WidgetTester tester, Finder find) async {
    for (var i = 0; i < 12; i++) {
      if (find.evaluate().isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(find, findsWidgets);
  }

  testWidgets('Anonyme : invite lazy registration + 3 méthodes', (tester) async {
    await pump(tester, const AccountScreen());

    expect(find.text('Bienvenue chez Ela'), findsOneWidget);
    expect(
      find.textContaining('publier un avis'),
      findsOneWidget,
    );
    expect(find.text('Continuer avec mon e-mail'), findsOneWidget);
    expect(find.text('Continuer avec Google'), findsOneWidget);
    await tester.ensureVisible(find.text('Continuer avec Apple'));
    await tester.pump();
    expect(find.text('Continuer avec Apple'), findsOneWidget);
  });

  testWidgets('E-mail : validation douce, puis profil + déconnexion',
      (tester) async {
    await pump(tester, const AccountScreen());

    // E-mail invalide → erreur douce, pas de connexion.
    await tester.enterText(find.byType(TextField).at(0), 'pas-un-email');
    await tester.enterText(find.byType(TextField).at(1), 'secret123');
    await tester.tap(find.text('Continuer avec mon e-mail'));
    await tester.pump();
    expect(find.textContaining('adresse e-mail valide'), findsOneWidget);
    expect(find.text('Se déconnecter'), findsNothing);

    // Mot de passe trop court.
    await tester.enterText(find.byType(TextField).at(0), 'lectrice@exemple.fr');
    await tester.enterText(find.byType(TextField).at(1), '123');
    await tester.tap(find.text('Continuer avec mon e-mail'));
    await tester.pump();
    expect(find.textContaining('6 caractères'), findsOneWidget);

    // Bon e-mail + bon mot de passe → profil.
    await tester.enterText(find.byType(TextField).at(1), 'secret123');
    await tester.tap(find.text('Continuer avec mon e-mail'));
    await pumpUntil(tester, find.text('Se déconnecter'));
    expect(find.text('lectrice'), findsOneWidget);
    expect(find.text('Membre d’Ela'), findsOneWidget);

    // Persistance locale.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('ela.profile'), isNotNull);

    // Déconnexion → retour à l'anonymat, profil purgé.
    await tester.tap(find.text('Se déconnecter'));
    await pumpUntil(tester, find.text('Bienvenue chez Ela'));
    expect(prefs.getString('ela.profile'), isNull);
  });

  testWidgets('Google (stub) : connexion en une touche', (tester) async {
    await pump(tester, const AccountScreen());

    await tester.tap(find.text('Continuer avec Google'));
    await pumpUntil(tester, find.text('Se déconnecter'));
    expect(find.text('lecteur@gmail.com'), findsOneWidget);
    expect(find.text('Membre d’Ela'), findsOneWidget);
  });

  testWidgets('Profil persisté : on arrive connecté sans se reconnecter',
      (tester) async {
    await pump(
      tester,
      const AccountScreen(),
      seed: {
        'ela.profile':
            '{"id":"user-1","email":"claude@ela.app","displayName":"Claude","isAnonymous":false}',
      },
    );

    expect(find.text('Claude'), findsOneWidget);
    expect(find.text('claude@ela.app'), findsOneWidget);
    expect(find.text('Bienvenue chez Ela'), findsNothing);
  });

  testWidgets('Bibliothèque : icône profil ouvre votre espace', (tester) async {
    await pumpRouted(tester);

    await tester.tap(find.byTooltip('Votre espace'));
    await tester.pumpAndSettle();
    expect(find.text('Votre espace'), findsWidgets);
    expect(find.text('Bienvenue chez Ela'), findsOneWidget);
    await settleAll(tester);
  });
}
