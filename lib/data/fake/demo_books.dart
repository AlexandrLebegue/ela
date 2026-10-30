import 'dart:math';

import '../models/book.dart';
import '../models/curation_result.dart';
import '../models/review.dart';
import 'fake_delay.dart';

/// Catalogue de démonstration FR : 18 livres variés (classiques, contemporains,
/// thrillers, fantasy), couvertures réelles via OpenLibrary.
abstract final class DemoData {
  static const List<Book> books = [
    Book(
      isbn: '9782070667918',
      title: 'Le Petit Prince',
      author: 'Antoine de Saint-Exupéry',
      coverUrl: 'https://covers.openlibrary.org/b/id/966008-M.jpg',
      description:
          'Un aviateur en panne dans le désert rencontre un petit prince venu '
          'd’une planète minuscule. Une fable tendre et vertigineuse sur '
          'l’amitié, la responsabilité et ce qu’on ne voit bien qu’avec le cœur.',
      genre: 'Classiques',
      year: 1943,
      publisher: 'Gallimard',
      badge: PopularityBadge.timelessClassic,
      readersCount: 14900,
      priceEur: 8.90,
      usedPriceEur: 2.90,
    ),
    Book(
      isbn: '9782070413438',
      title: 'L’Étranger',
      author: 'Albert Camus',
      coverUrl: 'https://covers.openlibrary.org/b/id/13151269-M.jpg',
      description:
          '« Aujourd’hui, maman est morte. » Une prose nue, un personnage en '
          'désaccord avec le monde, et un roman qui n’a pas pris une ride.',
      genre: 'Classiques',
      year: 1942,
      publisher: 'Gallimard',
      badge: PopularityBadge.hiddenGem,
      readersCount: 7830,
      priceEur: 6.90,
      usedPriceEur: 2.10,
    ),
    Book(
      isbn: '9782070409236',
      title: 'Les Misérables',
      author: 'Victor Hugo',
      coverUrl: 'https://covers.openlibrary.org/b/id/12721865-M.jpg',
      description:
          'De la prison de Toulon aux barricades de Paris, l’odyssée de '
          'Jean Valjean. La grande fresque humaniste de Hugo, à lire ou à '
          're-lire sans jamais se lasser.',
      genre: 'Classiques',
      year: 1862,
      publisher: 'Gallimard',
      badge: PopularityBadge.timelessClassic,
      readersCount: 9410,
      priceEur: 11.90,
      usedPriceEur: 4.30,
    ),
    Book(
      isbn: '9781974149498',
      title: 'Madame Bovary',
      author: 'Gustave Flaubert',
      coverUrl: 'https://covers.openlibrary.org/b/id/15009957-M.jpg',
      description:
          'Emma Bovary s’ennuie à mort dans la Normandie provinciale. Flaubert '
          'sculpte chaque mot pour peindre l’abîme entre le rêve et la vie.',
      genre: 'Classiques',
      year: 1857,
      publisher: 'Folio',
      badge: PopularityBadge.timelessClassic,
      readersCount: 6120,
      priceEur: 7.90,
      usedPriceEur: 2.50,
    ),
    Book(
      isbn: '9782013216270',
      title: 'Le Comte de Monte-Cristo',
      author: 'Alexandre Dumas',
      coverUrl: 'https://covers.openlibrary.org/b/id/14566393-M.jpg',
      description:
          'Capturé à tort, Edmond Dantès s’évade et devient un mystérieux '
          'comte pour faire payer, un par un, ceux qui l’ont trahi. Le roi du '
          'polar romantique, avant la lettre.',
      genre: 'Classiques',
      year: 1844,
      publisher: 'Le Livre de Poche',
      badge: PopularityBadge.timelessClassic,
      readersCount: 8760,
      priceEur: 9.90,
      usedPriceEur: 3.80,
    ),
    Book(
      isbn: '9780837197296',
      title: 'La Princesse de Clèves',
      author: 'Madame de La Fayette',
      coverUrl: 'https://covers.openlibrary.org/b/id/119470-M.jpg',
      description:
          'Au XVIᵉ siècle, une jeune princesse mariée refuse un amour interdit. '
          'Le premier grand roman psychologique français, d’une modernité '
          'déroutante.',
      genre: 'Classiques',
      year: 1678,
      publisher: 'Gallimard',
      badge: PopularityBadge.hiddenGem,
      readersCount: 2980,
      priceEur: 8.90,
      usedPriceEur: 3.10,
    ),
    Book(
      isbn: '9780060970406',
      title: 'L’Amant',
      author: 'Marguerite Duras',
      coverUrl: 'https://covers.openlibrary.org/b/id/5401955-M.jpg',
      description:
          'Saïgon, 1929. Une adolescente française et un riche Chinese. Le '
          'roman autobiographique de Duras, Prix Goncourt 1984, écrit comme '
          'un souffle.',
      genre: 'Contemporains',
      year: 1984,
      publisher: 'Gallimard',
      badge: PopularityBadge.hiddenGem,
      readersCount: 5240,
      priceEur: 9.90,
      usedPriceEur: 3.40,
    ),
    Book(
      isbn: '9782218055961',
      title: 'Germinal',
      author: 'Émile Zola',
      coverUrl: 'https://covers.openlibrary.org/b/id/8236935-M.jpg',
      description:
          'Dans le nord de la France, les mineurs de charbon se lèvent contre '
          'la faim et l’exploitation. Le roman-évènement du naturalisme.',
      genre: 'Classiques',
      year: 1885,
      publisher: 'Folio',
      badge: PopularityBadge.timelessClassic,
      readersCount: 4870,
      priceEur: 9.90,
      usedPriceEur: 3.20,
    ),
    Book(
      isbn: '9782743420405',
      title: 'Le Rouge et le Noir',
      author: 'Stendhal',
      coverUrl: 'https://covers.openlibrary.org/b/id/8231413-M.jpg',
      description:
          'Julien Sorel, fils de charpentier, veut tout conquérir dans la '
          'France de la Restauration. Le roman de l’ambition et de la '
          'déception, écrit d’une ironité mordante.',
      genre: 'Classiques',
      year: 1830,
      publisher: 'Folio',
      badge: PopularityBadge.timelessClassic,
      readersCount: 3650,
      priceEur: 7.90,
      usedPriceEur: 2.70,
    ),
    Book(
      isbn: '9780344279098',
      title: 'Candide',
      author: 'Voltaire',
      coverUrl: 'https://covers.openlibrary.org/b/id/12736044-M.jpg',
      description:
          '« Tout va pour le mieux dans le meilleur des mondes » ? Candide '
          'en doute après le tremblement de terre de Lisbonne. La satire la '
          'plus célèbre de Voltaire, toujours redoutable.',
      genre: 'Classiques',
      year: 1759,
      publisher: 'Gallimard',
      badge: PopularityBadge.timelessClassic,
      readersCount: 4110,
      priceEur: 6.90,
      usedPriceEur: 2.20,
    ),
    Book(
      isbn: '9782040162146',
      title: 'L’Écume des jours',
      author: 'Boris Vian',
      coverUrl: 'https://covers.openlibrary.org/b/id/10777065-M.jpg',
      description:
          'Chloé, Colline et Martin, l’amour et la folie dans un Paris '
          'surréaliste. Le roman le plus follement inventif de Boris Vian.',
      genre: 'Contemporains',
      year: 1946,
      publisher: 'Gallimard',
      badge: PopularityBadge.trending,
      readersCount: 3210,
      priceEur: 9.90,
      usedPriceEur: 3.90,
    ),
    Book(
      isbn: '9782081641624',
      title: 'L’Alchimiste',
      author: 'Paulo Coelho',
      coverUrl: 'https://covers.openlibrary.org/b/id/10997745-M.jpg',
      description:
          'Santiago, berger andalou, part chercher un trésor aux pyramides de '
          'Gizeh. Le conte initiatique qui a fait rêver des millions de '
          'lecteurs.',
      genre: 'Contemporains',
      year: 1987,
      publisher: 'J’ai Lu',
      badge: PopularityBadge.trending,
      readersCount: 10320,
      priceEur: 12.90,
      usedPriceEur: 4.80,
    ),
    Book(
      isbn: '9780062096982',
      title: 'Cent ans de solitude',
      author: 'Gabriel García Márquez',
      coverUrl: 'https://covers.openlibrary.org/b/id/14831167-M.jpg',
      description:
          'La saga des Buendía à Macondo, village où l’histoire se répète en '
          'boucle. Le chef-d’œuvre du réalisme magique.',
      genre: 'Contemporains',
      year: 1967,
      publisher: 'Folio',
      badge: PopularityBadge.timelessClassic,
      readersCount: 7215,
      priceEur: 15.90,
      usedPriceEur: 5.60,
    ),
    Book(
      isbn: '9782755692766',
      title: 'Verity',
      author: 'Colleen Hoover',
      coverUrl: 'https://covers.openlibrary.org/b/id/8747160-M.jpg',
      description:
          'La secrétaire d’une romancière célèbre découvre un manuscrit '
          'inachevé digne d’un cauchemar. Le thriller BookTok le plus '
          'discuté de l’année.',
      genre: 'Thrillers',
      year: 2021,
      publisher: 'Albin Michel',
      badge: PopularityBadge.phenomenon,
      readersCount: 11230,
      priceEur: 18.90,
      usedPriceEur: 7.40,
    ),
    Book(
      isbn: '9781501174827',
      title: 'Les Sept Maris d’Evelyn Hugo',
      author: 'Taylor Jenkins Reid',
      coverUrl: 'https://covers.openlibrary.org/b/id/8354226-M.jpg',
      description:
          'Une star hollywoodienne au crépuscule confie sa vie à une jeune '
          'biographe. Entre scandales, amours et secrets, un portrait '
          'incandescent.',
      genre: 'Contemporains',
      year: 2021,
      publisher: 'Albin Michel',
      badge: PopularityBadge.trending,
      readersCount: 9870,
      priceEur: 20.90,
      usedPriceEur: 8.90,
    ),
    Book(
      isbn: '9782253258199',
      title: 'L’Insoumise',
      author: 'Alex Michaelides',
      coverUrl: 'https://covers.openlibrary.org/b/id/9407338-M.jpg',
      description:
          'Peintre célèbre, Alicia s’est tue après avoir tué son mari. Six '
          'ans plus tard, son psychanalyste tente de briser le silence. '
          'Thriller à suspense étouffant.',
      genre: 'Thrillers',
      year: 2020,
      publisher: 'Pocket',
      badge: PopularityBadge.trending,
      readersCount: 8640,
      priceEur: 18.90,
      usedPriceEur: 6.80,
    ),
    Book(
      isbn: '9781538742578',
      title: 'La Femme de chambre',
      author: 'Freida McFadden',
      coverUrl: 'https://covers.openlibrary.org/b/id/15105883-M.jpg',
      description:
          'Milly est engagée pour faire le ménage dans une demeure huppée. '
          'Elle ignore que la famille qu’elle sert cache un secret qui va '
          'tout détruire. Le phénomène des réseaux.',
      genre: 'Thrillers',
      year: 2024,
      publisher: 'Pocket',
      badge: PopularityBadge.phenomenon,
      readersCount: 12480,
      priceEur: 15.90,
      usedPriceEur: 6.20,
    ),
    Book(
      isbn: '9781250624975',
      title: 'La Neufième Maison',
      author: 'Leigh Bardugo',
      coverUrl: 'https://covers.openlibrary.org/b/id/12667414-M.jpg',
      description:
          'À Oxford, Tom Barlow enquête sur un meurtre qui réveille des '
          'forces anciennes. Le roman dark fantasy culte de l’autrice des '
          'Sombres.',
      genre: 'Fantasy',
      year: 2022,
      publisher: 'Le Livre de Poche',
      badge: PopularityBadge.trending,
      readersCount: 4560,
      priceEur: 19.90,
      usedPriceEur: 8.30,
    ),
  ];

  static final Map<String, Book> byIsbn = {
    for (final b in books) b.isbn: b,
  };

  static Book? byIsbnLookup(String isbn) {
    final clean = isbn.replaceAll(RegExp(r'[^0-9Xx]'), '');
    for (final b in books) {
      if (b.isbn == clean) return b;
    }
    return null;
  }

  // ---------------------------------------------------------------- avis

  static const List<String> _pressOutlets = [
    'Le Monde',
    'Télérama',
    'Le Figaro',
    'L’Obs',
    'Livres Hebdo',
    'France Culture',
    'The Guardian',
    'The New York Times',
  ];

  static const List<String> _pressTemplates = [
    'Un chef-d’œuvre de douceur et de lucidité. {author} signe une œuvre qui '
        'résonne longtemps après la dernière page.',
    'Impossible de poser {title} avant la fin : une écriture limpide, des '
        'personnages qui hantent.',
    '{author} démontre une fois de plus sa maîtrise du roman : une page '
        'd’anthologie.',
    'Ce livre est un événement. On ressort du récit transformé, avec des '
        'images en tête pendant des jours.',
    'Une fresque bouleversante, digne des plus grandes œuvres du genre.',
    '{title} s’impose comme l’un des romans les plus marquants de l’année.',
    'Une prose aussi précise que sensible, portée par une intrigue qui ne '
        'faiblit jamais.',
    '{author} écrit des pages de cinéma, d’une intensité rare.',
    'Le récit décape, répare, émeut. Rare et précieux.',
    'Une œuvre qui traverse les générations : inclassable, inoubliable.',
    '{title} prouve qu’un roman peut être à la fois accessible et '
        'prodigieux.',
    'On ne lit pas {title}, on le traverse.',
  ];

  static const List<String> _pressTitles = [
    'Une lecture qui marquera',
    'L’histoire d’une vie',
    'Entre deux bords',
    'La page parfaite',
    'Ce que le silence raconte',
  ];

  static const List<String> _webOutlets = [
    'Bookblog 37',
    'Carnet de lecture',
    'Le Boudoir des pages',
    'Chroniques du soir',
    'Étagères & co',
    'La Palabra',
    'Les Nuits du Feuillage',
    'Bibliothèque nomade',
  ];

  static const List<String> _webTemplates = [
    'J’ai lu {title} en un weekend et j’en suis sortie différente. Coup de '
        'cœur énorme, à mettre entre toutes les mains.',
    'Un 5/5 sans hésiter. {author} m’a fait pleurer, rire, et réfléchir. '
        'Merci Ela pour cette reco !',
    'Le début est lent mais la suite est folle. J’ai dû me forcer à fermer '
        'le livre à 2 h du matin.',
    'Ma PAL m’attendait et ça valait le coup. L’ambiance est si cocooning, '
        'parfaite avec un thé et une plaid.',
    'Attention : aucun spoiler ici, juste : lisez-le. Point.',
    'Je n’avais jamais rien lu d’aussi bon de {author}. La plume est '
        'addictive.',
    'Parfait pour une lecture d’hiver. Les personnages sont attachants du '
        'premier au dernier chapitre.',
    'Un peu mitigée au départ, puis accrochée à 100 %. La fin m’a retourné '
        'le cerveau.',
    'Je l’ai prêté à trois amies et personne ne veut me le rendre.',
    'Le style est moderne, l’histoire universelle. J’achète aussi '
        'l’audiobook.',
    'C’est le genre de livre qu’on relit à dix ans d’intervalle avec un '
        'plaisir intact.',
    'Avis long promis, mais la vérité c’est que les mots me manquent devant '
        '{title}.',
  ];

  static const List<String> _webTitles = [
    'Coup de cœur inattendu',
    'Lu d’une traite',
    'La PAL ne me survivra pas',
    'À offrir (et à garder)',
    'Un livre-étreinte',
  ];

  static const List<String> _communityAuthors = [
    'Claire L.',
    'Mathis',
    'Anaïs P.',
    'Hugo',
    'Léa',
    'Camille R.',
    'Nadia',
    'Thomas B.',
    'Inès',
    'Margaux',
    'Yann',
    'Solène',
    'Karim',
    'Élodie',
    'Jules M.',
  ];

  static const List<String> _communityTemplates = [
    'Lu en trois jours d’un trait. Les personnages me suivent partout.',
    'Le dernier livre que je recommande à ma sœur. Elle ne m’arrête plus de '
        'parler de la fin.',
    'J’avais peur d’être déçue, j’ai eu le coup de foudre.',
    'La scène du chapitre 12 m’a détruite. Dans le bon sens.',
    'Je l’ai relu l’été dernier, toujours aussi beau.',
    'Un livre qui apaise, exactement ce dont j’avais besoin.',
    'Cinq étoiles. La sixième pour la fin.',
    'Je ne lis presque plus rien depuis que j’ai découvert {author}.',
    'Acheté d’occasion à quatre euros, je ne regrette rien.',
    'Ma bibliothèque elle-même en est jalouse.',
    'Lu pendant les vacances, quatre cents pages dévorées.',
    'Le début m’a posée, la fin m’a volée.',
    'Je l’écoute au réveil, meilleure façon de commencer la journée.',
    'Un livre que je n’attendais pas de moi, et que j’adore.',
  ];

  static const List<String> _communityTitles = [
    'Il ne me quitte plus',
    'Lu d’une assise',
    'Ma bulle du mois',
    'Recommandation du salon de librairie',
    'Petit coin de bonheur',
  ];

  static const List<String> _summaries = [
    'Les lecteurs d’Ela s’accordent sur une chose : {title}, de {author}, ne '
        'se lit pas, il s’habite. La critique salue la justesse de l’écriture, '
        'la communauté souligne l’émotion que le livre laisse après la '
        'dernière page. Une œuvre qui traverse les générations, à mettre dans '
        'la PAL de tous ceux qui aiment les grandes histoires.',
    'Entre la presse qui le hisse au rang d’ouvrage majeur et les lecteurs '
        'qui le recommandent dans les commentaires, {title} de {author} '
        'connaît un engouement rare. Notre curation a retenu les avis les '
        'plus justes : ce livre parle à ceux qui cherchent une lecture '
        'douce, intense et durable.',
    '{title} cumule les éloges : une écriture décrite comme « limpide » par '
        'la presse, une expérience de lecture décrite comme un cocon par les '
        'lecteurs d’Ela. {author} signe ici une œuvre qui apaise autant '
        'qu’elle marque.',
  ];

  static String _fill(String template, Book b) =>
      template.replaceAll('{title}', b.title).replaceAll('{author}', b.author);

  static List<Review> _generate(
    Book book,
    ReviewSource source,
    int count,
    List<String> outlets,
    List<String> titles,
    List<String> templates,
  ) {
    final rng = Random(stableHash(book.isbn + source.name));
    final now = DateTime.now();
    final result = <Review>[];
    for (var i = 0; i < count; i++) {
      final outlet = source == ReviewSource.community
          ? null
          : outlets[rng.nextInt(outlets.length)];
      final author = source == ReviewSource.community
          ? _communityAuthors[rng.nextInt(_communityAuthors.length)]
          : (outlet ?? 'Lecteur');
      final daysAgo = rng.nextInt(700) + 5;
      result.add(Review(
        id: '${book.isbn}-${source.name}-$i',
        isbn: book.isbn,
        source: source,
        author: author,
        outlet: outlet,
        title: titles[rng.nextInt(titles.length)],
        text: _fill(templates[rng.nextInt(templates.length)], book),
        url: source == ReviewSource.press
            ? 'https://example-press.fr/articles/${book.isbn}/$i'
            : null,
        publishedAt: now.subtract(Duration(days: daysAgo)),
        likes: rng.nextInt(source == ReviewSource.community ? 320 : 90),
      ));
    }
    return result;
  }

  /// 5 avis presse curés.
  static List<Review> pressFor(Book book) =>
      _generate(book, ReviewSource.press, 5, _pressOutlets, _pressTitles,
          _pressTemplates);

  /// 15 avis web curés.
  static List<Review> webFor(Book book) =>
      _generate(book, ReviewSource.web, 15, _webOutlets, _webTitles,
          _webTemplates);

  /// Avis communauté (démo, illimités côté fake).
  static List<Review> communityFor(Book book) =>
      _generate(book, ReviewSource.community, 24, const [], _communityTitles,
          _communityTemplates);

  /// Synthèse IA courte (le « super-curateur », pas un résumé robotique).
  static String summaryFor(Book book) => _fill(
        _summaries[stableHash('${book.isbn}summary') % _summaries.length],
        book,
      );

  /// Curation complète, comme le ferait le serveur (cache par ISBN).
  static Future<CurationResult> curate(Book book) async {
    await fakeDelay(min: const Duration(milliseconds: 900),
        max: const Duration(milliseconds: 1600));
    return CurationResult(
      isbn: book.isbn,
      summary: summaryFor(book),
      press: pressFor(book),
      web: webFor(book),
      curatedAt: DateTime.now(),
    );
  }
}
