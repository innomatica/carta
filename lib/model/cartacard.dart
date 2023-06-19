import 'cartabook.dart' show CartaSource;

class CartaCard {
  String title;
  String? genre;
  String? authors;
  String? language;
  String? description;
  CartaSource source;
  Map<String, dynamic> data;

  CartaCard({
    required this.title,
    this.genre,
    this.authors,
    this.language,
    this.description,
    required this.source,
    required this.data,
  });

  factory CartaCard.fromJsonDoc(Map<String, dynamic> data) {
    return CartaCard(
      title: data['title'],
      genre: data['genre'],
      authors: data['authors'],
      language: data['language'],
      description: data['description'],
      source: CartaSource.values.firstWhere((e) => e.name == data['source']),
      data: data['data'],
    );
  }

  @override
  String toString() {
    return {
      'title': title,
      'genre': genre,
      'authors': authors,
      'language': language,
      'description': description == null || description!.isEmpty
          ? ''
          : description!.substring(
              0, description!.length > 10 ? 10 : description!.length),
      'source': source.name,
      'data': data,
    }.toString();
  }
}
