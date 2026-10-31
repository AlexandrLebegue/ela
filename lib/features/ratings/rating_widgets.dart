import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/widgets/rating_stars.dart';
import '../../data/models/review.dart';
import '../../providers.dart';

class BookRatingLabel extends ConsumerWidget {
  const BookRatingLabel({super.key, required this.isbn, this.personal = false});
  final String isbn;
  final bool personal;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(ratingSummaryProvider(isbn));
    final own = ref.watch(personalRatingProvider(isbn));
    final value = personal ? own : summary.average;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 5,
      children: [
        RatingStars(value: value ?? 0, size: 14),
        Text(
          personal
              ? (own == null
                    ? 'À noter'
                    : 'Vous : ${own.toString().replaceAll('.', ',')}')
              : summary.count == 0
              ? 'Pas encore de note'
              : '${summary.label} · ${summary.count}',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

Future<void> showRatingSheet(BuildContext context, String isbn) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => RatingEditor(isbn: isbn),
    );

class RatingSummaryCard extends ConsumerWidget {
  const RatingSummaryCard({super.key, required this.isbn});
  final String isbn;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(ratingSummaryProvider(isbn));
    final own = ref.watch(personalRatingProvider(isbn));
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: PageCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Les lecteurs d’Ela', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.count == 0 ? '—' : summary.label,
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontSize: 54,
                            height: 1,
                          ),
                        ),
                        RatingStars(value: summary.average),
                        Text(
                          '${summary.count} notes',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Semantics(
                      label:
                          'Répartition, demi-étoiles dans la tranche supérieure',
                      child: Column(
                        children: [
                          for (var i = 5; i >= 1; i--)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Text('$i', style: theme.textTheme.labelSmall),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: summary.count == 0
                                          ? 0
                                          : summary.histogram[i]! /
                                                summary.count,
                                      minHeight: 4,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  SizedBox(
                                    width: 26,
                                    child: Text(
                                      '${summary.histogram[i]}',
                                      textAlign: TextAlign.end,
                                      style: theme.textTheme.labelSmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => showRatingSheet(context, isbn),
                icon: const Icon(Icons.star_outline_rounded),
                label: Text(
                  own == null
                      ? 'Noter ce livre'
                      : 'Modifier ma note · ${own.toString().replaceAll('.', ',')}',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RatingEditor extends ConsumerStatefulWidget {
  const RatingEditor({super.key, required this.isbn});
  final String isbn;
  @override
  ConsumerState<RatingEditor> createState() => _RatingEditorState();
}

class _RatingEditorState extends ConsumerState<RatingEditor> {
  double? _value;
  final _title = TextEditingController();
  final _text = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _value = ref.read(personalRatingProvider(widget.isbn));
    final uid = ref.read(profileProvider).id;
    ref.read(communityReviewsProvider(widget.isbn).future).then((list) {
      if (!mounted) return;
      final review = list.where((r) => r.userId == uid).firstOrNull;
      if (review != null) {
        _title.text = review.title;
        _text.text = review.text;
      }
    }, onError: (Object _, StackTrace __) {});
  }

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _save({bool delete = false}) async {
    if (_busy || (!delete && _value == null)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final profile = ref.read(profileProvider);
      final ratings = ref.read(ratingServiceProvider);
      final reviews = ref.read(reviewServiceProvider);
      if (delete) {
        await reviews.deleteCommunityReview(widget.isbn, profile.id);
        await ratings.deleteRating(widget.isbn, profile.id);
      } else {
        if (!profile.isAnonymous) {
          final allowed = await ref
              .read(moderationServiceProvider)
              .isAllowed('${_title.text} ${_text.text}');
          if (!allowed) {
            if (mounted) {
              setState(() {
                _error = 'Votre avis contient un passage à reformuler.';
                _busy = false;
              });
            }
            return;
          }
          await reviews.addCommunityReview(
            Review(
              id: 'user-${profile.id}-${widget.isbn}',
              isbn: widget.isbn,
              source: ReviewSource.community,
              userId: profile.id,
              author: profile.displayNameOrEmail,
              rating: _value,
              title: _title.text.trim().isEmpty
                  ? 'Ma lecture'
                  : _title.text.trim(),
              text: _text.text.trim(),
              publishedAt: DateTime.now(),
            ),
          );
          final prefs = ref.read(sharedPreferencesProvider);
          if (ref.read(personalRatingProvider(widget.isbn)) == null) {
            await prefs.setInt(
              'ela.stats.reviews',
              (prefs.getInt('ela.stats.reviews') ?? 0) + 1,
            );
          }
        }
        await ratings.setRating(widget.isbn, profile.id, _value!);
      }
      ref.invalidate(communityReviewsProvider(widget.isbn));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Enregistrement interrompu. Votre saisie est conservée.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final own = ref.watch(personalRatingProvider(widget.isbn));
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Votre avis',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Text('Une note, quelques mots si vous le souhaitez.'),
            Center(
              child: RatingStars(
                value: _value ?? 0,
                size: 48,
                onChanged: _busy ? null : (v) => setState(() => _value = v),
              ),
            ),
            Text(
              _value == null
                  ? 'Choisissez de 0,5 à 5 étoiles'
                  : '${_value.toString().replaceAll('.', ',')} / 5',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (!profile.isAnonymous) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _title,
                maxLength: 90,
                decoration: const InputDecoration(
                  labelText: 'Un titre pour votre avis',
                ),
              ),
              TextField(
                controller: _text,
                maxLength: 600,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Ce livre vous a fait quoi ?',
                ),
              ),
            ] else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Votre note est enregistrée sur cet appareil. Connectez-vous pour publier un avis.',
                ),
              ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
                FilledButton(
                  onPressed: _busy || _value == null ? null : () => _save(),
                  child: Text(
                    _busy
                        ? 'Enregistrement…'
                        : profile.isAnonymous
                        ? 'Enregistrer'
                        : 'Publier',
                  ),
                ),
                if (own != null)
                  TextButton(
                    onPressed: _busy ? null : () => _save(delete: true),
                    child: const Text('Supprimer ma note'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
