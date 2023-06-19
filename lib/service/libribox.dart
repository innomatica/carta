import 'dart:convert';

import 'package:feed_parser/feed_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;

import '../model/cartabook.dart';
import '../model/cartasection.dart';

const urlLibriVox = 'https://librivox.org/';
const urlLibriVoxBooks = 'https://librivox.org/api/feed/audiobooks';
// id, since, author, title, genre, extended
const urlLibriVoxTracks = 'https://librivox.org/api/feed/audiotracks';
// id, project_id
const urlLibriVoxAuthors = 'https://librivox.org/api/feed/authors';
// id, last_name
const urlNewsFeed = 'https://librivox.org/rss/latest_releases';
const urlBlogFeed = 'https://librivox.org/feed';

class LibriVoxService {
  static Future<CartaBook?> getBookById(int id) async {
    final url = '$urlLibriVoxBooks/?id=$id&format=json';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final books = jsonDecode(res.body)['books'];
      if (books.isNotEmpty) {
        return CartaBook.fromLibriVoxApi(books[0]);
      }
    }
    return null;
  }

  static Future<List<CartaBook>?> searchBooks(
      Map<String, dynamic> params) async {
    String url = '$urlLibriVoxBooks/?format=json';

    if (params.containsKey('id')) {
      url = '$url&id=${params["id"]}';
    } else {
      if (params.containsKey('author')) {
        // url = '$url&author=${params["author"]}';
        url = '$url&author=${params["author"]}';
      }
      if (params.containsKey('title')) {
        // url = '$url&title=${params["title"]}';
        url = '$url&title=${params["title"]}';
      }
      if (params.containsKey('genre')) {
        // url = '$url&genre=${params["genre"]}';
        url = '$url&genre=${params["genre"]}';
      }
    }

    debugPrint('searchBooks.url:${Uri.parse(url)}');
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final books = jsonDecode(res.body)['books'];
      // for (final book in books) {
      //   debugPrint('searchBooks.book: $book');
      // }
      return books.map<CartaBook>((e) => CartaBook.fromLibriVoxApi(e)).toList();
    }
    return null;
  }

  // update sections and image url of the book
  static Future<bool> getSupplmentaryData(CartaBook book) async {
    if (book.source == CartaSource.librivox) {
      //
      // Section Information
      //
      // get RssFeed
      String url = book.info['urlRss'];
      http.Response res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) {
        debugPrint('getSupplmentaryData: cannot find RSS page:$url');
        return false;
      }
      // parse the feed
      try {
        final feedData = FeedData.parse(res.body);
        if (feedData.items == null) {
          // section information is mandatory
          debugPrint('getSupplmentaryData: failed to parse RSS data');
          return false;
        }
        //
        // get section information from RSS
        //
        book.sections = <CartaSection>[];
        int index = 0;
        for (final item in feedData.items!) {
          final section = CartaSection(
            title: item.title ?? 'Unknown Section',
            // index: item.itunes?.episode ?? index,
            index: index,
            // uri: item.enclosure?.url ?? '',
            // duration: item.itunes?.duration,
            uri: item.media?[0].url ?? '',
            duration: Duration(seconds: item.media?[0].duration ?? 0),
            info: {},
          );
          // debugPrint(section.toString());
          book.sections!.add(section);
          index = index + 1;
        }
        //
        // imageUri
        //
        // get librivox page
        url = book.info['siteUrl'];
        res = await http.get(Uri.parse(url));
        if (res.statusCode == 200) {
          // debugPrint('urlSource: $url');
          final document = parse(res.body);
          // get image tags
          final images = document.getElementsByTagName('img');
          for (final img in images) {
            // any url from archive.org is considered to be the book image
            if (img.attributes.containsKey('src') &&
                img.attributes['src'] != null &&
                img.attributes['src']!.contains('archive.org')) {
              book.imageUri = img.attributes['src']?.trim();
              // debugPrint('book.imageUri: ${book.imageUri}');
              break;
            }
          }
          // imageUri is optional thus just return with true without checking
          return true;
        }
      } catch (e) {
        debugPrint('getSupplmentaryData.exception: ${e.toString()}');
        return false;
      }
    }
    return false;
  }

  static List<String> getGenreSuggestions(String pattern) {
    final suggestions = <String>[];
    for (final item in libriVoxGenres) {
      if (item.toLowerCase().contains(pattern.toLowerCase())) {
        suggestions.add(item);
      }
    }
    return suggestions;
  }

  // librivox genres: 2022.07.22
  static final libriVoxGenres = <String>[
    "Children's Fiction",
    "Children's Fiction > Action & Adventure",
    "Children's Fiction > Animals & Nature",
    "Children's Fiction > Myths, Legends & Fairy Tales",
    "Children's Fiction > Family",
    "Children's Fiction > General",
    "Children's Fiction > Historical",
    "Children's Fiction > Poetry",
    "Children's Fiction > Religion",
    "Children's Fiction > School",
    "Children's Fiction > Short works",
    "Children's Non-fiction",
    "Children's Non-fiction > Arts",
    "Children's Non-fiction > General",
    "Children's Non-fiction > Reference",
    "Children's Non-fiction > Religion",
    "Children's Non-fiction > Science",
    "Children's Non-fiction > History",
    "Children's Non-fiction > Biography",
    "Action & Adventure Fiction",
    "Classics (Greek & Latin Antiquity)",
    "Classics (Greek & Latin Antiquity) > Asian Antiquity",
    "Crime & Mystery Fiction",
    "Crime & Mystery Fiction > Detective Fiction",
    "Culture & Heritage Fiction",
    "Dramatic Readings",
    "Epistolary Fiction",
    "Erotica",
    "Travel Fiction",
    "Family Life",
    "Fantastic Fiction",
    "Fantastic Fiction > Myths, Legends & Fairy Tales",
    "Fantastic Fiction > Horror & Supernatural Fiction",
    "Fantastic Fiction > Gothic Fiction",
    "Fantastic Fiction > Science Fiction",
    "Fantastic Fiction > Fantasy Fiction",
    "Fictional Biographies & Memoirs",
    "General Fiction",
    "General Fiction > Published before 1800",
    "General Fiction > Published 1800 -1900",
    "General Fiction > Published 1900 onward",
    "Historical Fiction",
    "Humorous Fiction",
    "Literary Fiction",
    "Nature & Animal Fiction",
    "Nautical & Marine Fiction",
    "Plays",
    "Plays > Comedy",
    "Plays > Comedy > Satire",
    "Plays > Drama",
    "Plays > Drama > Tragedy",
    "Plays > Romance",
    "Poetry",
    "Poetry > Anthologies",
    "Poetry > Single author",
    "Poetry > Ballads",
    "Poetry > Elegies & Odes",
    "Poetry > Epics",
    "Poetry > Free Verse",
    "Poetry > Lyric",
    "Poetry > Narratives",
    "Poetry > Sonnets",
    "Poetry > Multi-version (Weekly and Fortnightly poetry)",
    "Religious Fiction",
    "Religious Fiction > Christian Fiction",
    "Romance",
    "Sagas",
    "Satire",
    "Short Stories",
    "Short Stories > Anthologies",
    "Short Stories > Single Author Collections",
    "Sports Fiction",
    "Suspense, Espionage, Political & Thrillers",
    "War & Military Fiction",
    "Westerns",
    "*Non-fiction",
    "*Non-fiction > War & Military",
    "*Non-fiction > Animals",
    "*Non-fiction > Art, Design & Architecture",
    "*Non-fiction > Bibles",
    "*Non-fiction > Bibles > American Standard Version",
    "*Non-fiction > Bibles > World English Bible",
    "*Non-fiction > Bibles > King James Version",
    "*Non-fiction > Bibles > Weymouth New Testament",
    "*Non-fiction > Bibles > Douay-Rheims Version",
    "*Non-fiction > Bibles > Young's Literal Translation",
    "*Non-fiction > Biography & Autobiography",
    "*Non-fiction > Biography & Autobiography > Memoirs",
    "*Non-fiction > Business & Economics",
    "*Non-fiction > Crafts & Hobbies",
    "*Non-fiction > Education",
    "*Non-fiction > Education > Language learning",
    "*Non-fiction > Essays & Short Works",
    "*Non-fiction > Family & Relationships",
    "*Non-fiction > Health & Fitness",
    "*Non-fiction > History",
    "*Non-fiction > History > Antiquity",
    "*Non-fiction > History > Middle Ages/Middle History",
    "*Non-fiction > History > Early Modern",
    "*Non-fiction > History > Modern (19th C)",
    "*Non-fiction > History > Modern (20th C)",
    "*Non-fiction > House & Home",
    "*Non-fiction > House & Home > Cooking",
    "*Non-fiction > House & Home > Gardening",
    "*Non-fiction > Humor",
    "*Non-fiction > Law",
    "*Non-fiction > Literary Collections",
    "*Non-fiction > Literary Collections > Essays",
    "*Non-fiction > Literary Collections > Short non-fiction",
    "*Non-fiction > Literary Collections > Letters",
    "*Non-fiction > Literary Criticism",
    "*Non-fiction > Mathematics",
    "*Non-fiction > Medical",
    "*Non-fiction > Music",
    "*Non-fiction > Nature",
    "*Non-fiction > Performing Arts",
    "*Non-fiction > Philosophy",
    "*Non-fiction > Philosophy > Ancient",
    "*Non-fiction > Philosophy > Medieval",
    "*Non-fiction > Philosophy > Early Modern",
    "*Non-fiction > Philosophy > Modern",
    "*Non-fiction > Philosophy > Contemporary",
    "*Non-fiction > Philosophy > Atheism & Agnosticism",
    "*Non-fiction > Political Science",
    "*Non-fiction > Psychology",
    "*Non-fiction > Reference",
    "*Non-fiction > Religion",
    "*Non-fiction > Religion > Christianity - Commentary",
    "*Non-fiction > Religion > Christianity - Biographies",
    "*Non-fiction > Religion > Christianity - Other",
    "*Non-fiction > Religion > Other religions",
    "*Non-fiction > Science",
    "*Non-fiction > Science > Astronomy, Physics & Mechanics",
    "*Non-fiction > Science > Chemistry",
    "*Non-fiction > Science > Earth Sciences",
    "*Non-fiction > Science > Life Sciences",
    "*Non-fiction > Self-Help",
    "*Non-fiction > Social Science (Culture & Anthropology)",
    "*Non-fiction > Sports & Recreation",
    "*Non-fiction > Sports & Recreation > Games",
    "*Non-fiction > Technology & Engineering",
    "*Non-fiction > Technology & Engineering > Transportation",
    "*Non-fiction > Travel & Geography",
    "*Non-fiction > Travel & Geography > Exploration",
    "*Non-fiction > True Crime",
    "*Non-fiction > Writing & Linguistics",
  ];
}
