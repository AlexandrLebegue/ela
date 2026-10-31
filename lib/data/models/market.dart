enum BookCondition {
  newBook('Neuf'),
  likeNew('Comme neuf'),
  veryGood('Très bon'),
  good('Bon'),
  fair('Correct');

  const BookCondition(this.label);
  final String label;
}

enum OfferSort { totalPrice, condition }

class BookOffer {
  const BookOffer({
    required this.isbn,
    required this.merchant,
    required this.price,
    required this.shipping,
    required this.condition,
  });
  final String isbn, merchant;
  final double price, shipping;
  final BookCondition condition;
  double get total => price + shipping;
  bool get isNew => condition == BookCondition.newBook;
}

List<BookOffer> sortedOffers(Iterable<BookOffer> offers, OfferSort sort) =>
    offers.toList()..sort((a, b) {
      final comparison = sort == OfferSort.condition
          ? a.condition.index.compareTo(b.condition.index)
          : 0;
      return comparison != 0 ? comparison : a.total.compareTo(b.total);
    });

class ReaderListing {
  const ReaderListing({
    required this.id,
    required this.isbn,
    required this.sellerId,
    required this.seller,
    required this.price,
    required this.condition,
    required this.city,
    required this.createdAt,
    this.photoUrl,
  });
  final String id, isbn, sellerId, seller, city;
  final double price;
  final BookCondition condition;
  final DateTime createdAt;
  final String? photoUrl;
  Map<String, dynamic> toJson() => {
    'id': id,
    'isbn': isbn,
    'sellerId': sellerId,
    'seller': seller,
    'price': price,
    'condition': condition.name,
    'city': city,
    'createdAt': createdAt.toIso8601String(),
    'photoUrl': photoUrl,
  };
  factory ReaderListing.fromJson(Map<String, dynamic> json) => ReaderListing(
    id: json['id'] as String,
    isbn: json['isbn'] as String,
    sellerId: json['sellerId'] as String,
    seller: json['seller'] as String,
    price: (json['price'] as num).toDouble(),
    condition: BookCondition.values.byName(json['condition'] as String),
    city: json['city'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    photoUrl: json['photoUrl'] as String?,
  );
}
