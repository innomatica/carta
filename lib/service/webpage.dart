// import 'package:feed_parser/feed_parser.dart';
// import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;

import '../model/cartabook.dart';
import '../model/cartasection.dart';
import '../shared/helpers.dart';

class WebPageParser {
  static Future<CartaBook?> getBookFromHtml(
      {required String html, required String url}) async {
    CartaBook? book;
    // debugPrint('url: $url');
    // log('html: $html');
    final document = parse(html);

    if (url.contains('archive.org')) {
      //
      // Internet Archive
      //
      final attrs = <String, dynamic>{};

      // meta tag
      final metas = document.getElementsByTagName('meta');
      for (final item in metas) {
        if (item.attributes['property'] == 'twitter:title') {
          attrs['title'] = item.attributes['content']?.split(':')[0].trim();
        } else if (item.attributes['property'] == 'twitter:image') {
          attrs['imageUrl'] = item.attributes['content']!;
        } else if (item.attributes['property'] == 'twitter:description') {
          attrs['description'] = item.attributes['content']!;
        }
      }

      // decode theatre-ia-wrap for sections
      final sections = <CartaSection>[];
      String? title;
      String? uri;
      String? durString;
      Duration? duration;

      final theatre = document.querySelectorAll(
          '#theatre-ia-wrap > div[itemtype="http://schema.org/AudioObject"]');
      for (final item in theatre) {
        // debugPrint('item: ${item.innerHtml}');
        for (final child in item.children) {
          // debugPrint('child: ${child.localName}');
          // debugPrint('child: ${child.attributes}');
          if (child.attributes.containsKey('itemprop')) {
            if (child.attributes['itemprop'] == 'name') {
              // title
              title = child.attributes['content'];
            } else if (child.attributes['itemprop'] == 'associatedMedia') {
              // url
              uri = child.attributes['href'];
            } else if (child.attributes['itemprop'] == 'duration') {
              // duration
              durString = child.attributes['content']?.trim();
              if (durString != null && durString.length > 5) {
                final totalSecs = int.tryParse(
                        durString.substring(4, durString.length - 1)) ??
                    0;
                duration = Duration(
                  hours: totalSecs ~/ 3600,
                  minutes: (totalSecs % 3600) ~/ 60,
                  seconds: (totalSecs % 60),
                );
              }
            }
          }
        }
        if (title != null && uri != null) {
          sections.add(
            CartaSection(
              index: sections.length,
              title: title,
              uri: uri,
              duration: duration,
              info: {},
            ),
          );
        }
        title = null;
        uri = null;
      }

      if (attrs.containsKey('title')) {
        book = CartaBook(
          bookId: getIdFromUrl(url),
          title: attrs['title'],
          source: CartaSource.archive,
          info: {'siteUrl': url},
          authors: 'Internet Archive',
          description: attrs['description'],
          imageUri: attrs['imageUrl'],
          sections: sections,
        );
      }
    } else if (url.contains('librivox.org')) {
      //
      // LibriVox
      //
      String? urlRss;
      String? librivoxId;
      Duration? duration;
      String? textUrl;
      final sections = <CartaSection>[];

      // book page
      final bookPage = document.querySelector('.page.book-page');

      if (bookPage != null) {
        // album image
        final imageUrl = bookPage
            .querySelector('.book-page-book-cover img')
            ?.attributes['src'];

        // title
        final title = bookPage.querySelector('h1')?.text ?? 'Unknown Title';
        // authors
        final author = bookPage
            .querySelector('.book-page-author a')
            ?.text
            .split('(')[0] // remove DOB,DOD
            .trim();

        // POTENTIAL BUGS IN THE HTML: pass this step
        // genre
        // language

        // description
        final description = bookPage.querySelector('.description')?.text.trim();

        // sidebar
        final sidebar = document.querySelector('.sidebar.book-page');
        if (sidebar != null) {
          // get all dt tags
          final dts = sidebar.getElementsByTagName('dt');
          // go over dt tags
          for (final dt in dts) {
            if (dt.text.contains('RSS')) {
              // RSS feed url
              final dd = dt.nextElementSibling;
              urlRss = dd?.firstChild?.attributes['href'];
              if (urlRss != null) {
                librivoxId = urlRss.split('/').last;
              }
            } else if (dt.text.contains('Running Time')) {
              // running time
              final dd = dt.nextElementSibling;
              duration = getDurationFromString(dd?.text);
            }
          }
          // get all p a tags
          final pas = sidebar.querySelectorAll('p a');
          for (final pa in pas) {
            if (pa.text.contains('Online text')) {
              textUrl = pa.attributes['href'];
            }
          }
        }

        // sections
        final tableBody = bookPage.querySelector('.chapter-download tbody');
        if (tableBody != null) {
          final trs = tableBody.getElementsByTagName('tr');
          int index = 0;
          String title = 'Unknown';
          String uri = '';
          Duration? duration;

          for (final tr in trs) {
            duration = null;
            // map must be defined inside
            final info = <String, dynamic>{};
            // debugPrint('row: ${tr.text}');
            final tds = tr.getElementsByTagName('td');
            for (final td in tds) {
              final atag = td.querySelector('a');
              // debugPrint('atag: ${atag?.text}');
              if (atag == null) {
                // duration (comes first) or language
                // debugPrint('duation: ${td.text}');
                duration ??= getDurationFromString(td.text);
              } else if (atag.className == 'play-btn') {
                // uri first candidate
                uri = atag.attributes['href'] ?? '';
              } else if (atag.className == 'chapter-name') {
                // title
                title = atag.text.trim();
                // uri second candidate
                if (atag.attributes['href'] != null) {
                  uri = atag.attributes['href']!;
                }
              } else if (atag.text.contains('Etext')) {
                info['textUrl'] = atag.attributes['href'];
              }
            }

            sections.add(CartaSection(
              index: index,
              title: title,
              uri: uri,
              duration: duration,
              info: info,
            ));
            index++;
          }
        }

        book = CartaBook(
          bookId: getIdFromUrl(url),
          title: title,
          authors: author,
          description: description,
          imageUri: imageUrl,
          duration: duration,
          source: CartaSource.librivox,
          sections: sections,
          info: {
            'num_sections': sections.length,
            'bookId': librivoxId,
            'urlRss': urlRss,
            'siteUrl': url,
            'textUrl': textUrl,
          },
        );
      }
    } else if (url.contains('legamus.eu')) {
      //
      // Legamus
      //
      // title
      final title = document.querySelector('h1.entry-title')?.innerHtml ??
          "Title Unknown";
      // author
      String? author =
          document.querySelector('.entry-content strong')?.innerHtml ??
              "Author Unknown";
      if (author.contains('(')) {
        author = author.split('(')[0].trim();
      }
      // FIXME: this is fragile description
      final description =
          document.querySelectorAll('.entry-content p')[2].innerHtml;
      // image url
      String? imageUrl =
          document.querySelector('.entry-content img')?.attributes['src'];
      if (imageUrl != null && !imageUrl.startsWith('http')) {
        imageUrl = 'https://legamus.eu$imageUrl';
      }

      Duration? duration;
      final sections = <CartaSection>[];

      // audio page url
      final audioUrl = document
          .querySelector('li a[href*="listen.legamus.eu"]')
          ?.attributes['href'];
      if (audioUrl != null) {
        final res = await http.get(Uri.parse(audioUrl));
        if (res.statusCode == 200) {
          final audioPage = parse(res.body);
          final rows = audioPage.querySelectorAll('#player_table tr');
          // debugPrint('rows: $rows');
          int index = 0;
          for (final row in rows) {
            // debugPrint('row: $row');
            final titleRow = row.querySelector('.section span')?.innerHtml;
            if (titleRow != null) {
              final uri =
                  row.querySelector('.downloadlinks a')?.attributes['href'] ??
                      "";
              final title = titleRow.split('(')[0].trim();
              final duration = getDurationFromString(
                  RegExp(r'\(([^)]+)\)').firstMatch(titleRow)?.group(1));

              sections.add(CartaSection(
                  index: index,
                  title: title,
                  uri: '$audioUrl/$uri',
                  duration: duration,
                  info: {}));
              index = index + 1;
            }
          }
        }
      }

      book = CartaBook(
        bookId: getIdFromUrl(url),
        title: title,
        authors: author,
        description: description,
        imageUri: imageUrl,
        duration: duration,
        source: CartaSource.legamus,
        sections: sections,
        info: {
          'siteUrl': url,
        },
      );
    }
    // debugPrint('book:$book');
    return book;
  }

  static Future<CartaBook?> getBookFromUrl(String url) async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        return await getBookFromHtml(html: res.body, url: url);
      }
      debugPrint('status code: ${res.statusCode}');
    } catch (e) {
      debugPrint(e.toString());
    }

    return null;
  }

  static Duration? getDurationFromString(String? durationStr) {
    if (durationStr != null && durationStr.isNotEmpty) {
      final times = durationStr.split(':');
      if (times.length == 3) {
        return Duration(
          hours: int.tryParse(times[0]) ?? 0,
          minutes: int.tryParse(times[1]) ?? 0,
          seconds: int.tryParse(times[2]) ?? 0,
        );
      } else if (times.length == 2) {
        return Duration(
          minutes: int.tryParse(times[0]) ?? 0,
          seconds: int.tryParse(times[1]) ?? 0,
        );
      }
    }
    return null;
  }
}
