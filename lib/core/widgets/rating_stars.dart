import 'package:flutter/material.dart';
import '../haptics.dart';
import '../../data/models/rating.dart';

/// Lecture statique ou contrôle tactile/accessible à pas d'une demi-étoile.
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 18,
  });
  final double value;
  final ValueChanged<double>? onChanged;
  final double size;
  @override
  Widget build(BuildContext context) {
    void update(double next) {
      ElaHaptics.softTap();
      onChanged?.call(next);
    }

    final stars = Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          value >= i + 1
              ? Icons.star_rounded
              : value >= i + .5
              ? Icons.star_half_rounded
              : Icons.star_outline_rounded,
          size: size,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
    return Semantics(
      label: onChanged == null ? 'Note' : 'Votre note',
      value: '${value.toStringAsFixed(1).replaceAll('.', ',')} sur 5',
      increasedValue: onChanged == null
          ? null
          : '${(value + .5).clamp(.5, 5)} sur 5',
      decreasedValue: onChanged == null
          ? null
          : '${(value - .5).clamp(.5, 5)} sur 5',
      onIncrease: onChanged == null
          ? null
          : () => update((value + .5).clamp(.5, 5)),
      onDecrease: onChanged == null
          ? null
          : () => update((value - .5).clamp(.5, 5)),
      excludeSemantics: true,
      child: onChanged == null
          ? stars
          : SizedBox(
              height: 56,
              width: size * 5,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  void position(Offset p) => update(
                    BookRating.halfStar(
                      (p.dx / constraints.maxWidth * 10).ceil() / 2,
                    ),
                  );
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) => position(d.localPosition),
                    onHorizontalDragUpdate: (d) => position(d.localPosition),
                    child: Center(child: stars),
                  );
                },
              ),
            ),
    );
  }
}
