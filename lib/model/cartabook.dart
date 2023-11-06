import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:mime/mime.dart';

import '../shared/constants.dart';
import '../shared/helpers.dart';
import 'cartacard.dart';
import 'cartasection.dart';

enum CartaSource {
  librivox, // librivox
  internet, // other internet sources: currently none considered
  cloud, // cloud source such as nextcloud
  archive, // internet archive
  carta, // carta repository
  legamus, // legamus
  unknown,
}

enum LocalDataState {
  none, // this does not include book cover image file
  partial,
  audioOnly,
  audioAndCoverImage,
}

class CartaBook {
  String bookId;
  String title;
  String? authors;
  String? description;
  String? language;
  String? imageUri;
  Duration? duration;
  int? lastSection;
  Duration? lastPosition;
  CartaSource source;
  Map<String, dynamic> info;
  List<CartaSection>? sections;
  int localSections;

  CartaBook({
    required this.bookId,
    required this.title,
    this.authors,
    this.description,
    this.language,
    this.imageUri,
    this.duration,
    this.lastSection,
    this.lastPosition,
    required this.source,
    required this.info,
    this.sections,
    this.localSections = 0,
  });

  factory CartaBook.fromLibriVoxApi(Map<String, dynamic> result) {
    return CartaBook(
      bookId: getIdFromUrl(result['url_librivox'] ??
          'librivox ${(result['id'] ?? 'idUnknown')}'),
      title: result['title'] ?? 'Unknown Title',
      authors: result['authors'].join(','),
      description: result['description'],
      language: result['language'],
      duration: fromDurationString(result['totaltime']),
      lastSection: 0,
      lastPosition: Duration.zero,
      source: CartaSource.librivox,
      info: {
        'id': result['id'],
        'textUrl': result['url_text_source'].trim(),
        'num_sections': result['num_sections'],
        'urlRss': result['url_rss'].trim(),
        'urlZip': result['url_zip_file'].trim(),
        'urlProject': result['url_project'].trim(),
        'siteUrl': result['url_librivox'].trim(),
        'urlOther': result['url_other'],
        'copyrightYear': result['copyright_year'],
      },
    );
  }

  factory CartaBook.fromSqlite(Map<String, dynamic> data) {
    return CartaBook(
      bookId: data['bookId'],
      title: data['title'],
      authors: data['authors'].startsWith('[{')
          ? jsonDecode(data['authors'])[0]['lastName'] // old model
          : data['authors'], // new model
      description: data['description'],
      language: data['language'],
      imageUri: data['imageUri'],
      duration: fromDurationString(data['duration']),
      lastSection: data['lastSection'],
      lastPosition: fromDurationString(data['lastPosition']),
      source: CartaSource.values[data['source']],
      info: jsonDecode(data['info']),
      sections: jsonDecode(data['sections'])
          ?.map<CartaSection>((e) => CartaSection.fromDatabase(e))
          .toList(),
    );
  }

  factory CartaBook.fromCartaCard(CartaCard card) {
    if (card.data['bookId'] == null || card.data['title'] == null) {
      throw Exception('bookId and title cannot be null');
    }
    return CartaBook(
      bookId: card.data['bookId'],
      title: card.data['title'],
      authors: card.data['authors'],
      description: card.data['description'],
      language: card.data['language'],
      imageUri: card.data['imageUrl'],
      duration: card.data['duration'],
      source: CartaSource.values[card.data['source']],
      info: card.data['info'],
      sections: card.data['sections']
          .map((e) => CartaSection.fromDatabase(e))
          .toList(),
    );
  }

  Map<String, dynamic> toSqlite() {
    return {
      'bookId': bookId,
      'title': title,
      'authors': authors,
      'description': description,
      'language': language,
      'imageUri': imageUri,
      'duration': toDurationString(duration),
      'lastSection': lastSection,
      'lastPosition': toDurationString(lastPosition),
      'source': source.index,
      'info': jsonEncode(info),
      'sections': jsonEncode(sections?.map((e) => e.toDatabase()).toList()),
    };
  }

  @override
  String toString() {
    return toSqlite().toString();
  }

  List<IndexedAudioSource> getAudioSource({int initIndex = 0}) {
    final sectionData = <IndexedAudioSource>[];

    if (sections != null && sections!.isNotEmpty) {
      final bookDir = getBookDirectory();
      final headers = getAuthHeaders();
      // NOTE: sections must be in order
      for (final section in sections!) {
        if (section.index >= initIndex) {
          // build tag
          final tag = MediaItem(
            id: bookId,
            // section title as title
            title: section.title,
            // book title as album
            album: title,
            duration: section.duration,
            artUri: imageUri != null ? Uri.parse(imageUri!) : null,
            artHeaders: headers,
            // extra for internal use
            extras: {
              'bookId': bookId,
              'bookTitle': title,
              'sectionIdx': section.index,
              'sectionTitle': section.title,
            },
          );
          // check if local data for the section exists
          final file = File('${bookDir.path}/${section.uri.split("/").last}');
          if (file.existsSync()) {
            sectionData.add(AudioSource.uri(
              Uri.parse('file://${file.path}'),
              tag: tag,
            ));
            // debugPrint('file source: ${file.path}');
          } else {
            // otherwise data from url
            // audioData.add(LockCachingAudioSource(uri, tag: tag));
            sectionData.add(ProgressiveAudioSource(
              Uri.parse(section.uri),
              headers: headers,
              tag: tag,
            ));
            // debugPrint('url headers: ${headers.toString()}');
            // debugPrint('url source: ${section.uri}');
          }
          // debugPrint('adding: ${section.title}');
        }
      }
    }
    return sectionData;
  }

  Map<String, String>? getAuthHeaders() {
    if (info.containsKey('authentication') &&
        info['authentication'] == 'basic' &&
        info.containsKey('username') &&
        info.containsKey('password')) {
      final credential =
          base64Encode(utf8.encode('${info["username"]}:${info["password"]}'));
      return {
        HttpHeaders.authorizationHeader: 'Basic $credential',
        // 'content-type': 'text/xml',
      };
    }
    return null;
  }

  // check the local data status
  Map<String, dynamic> getLocalDataState() {
    final bookDir = getBookDirectory();
    if (bookDir.existsSync()) {
      // check if any media files in the book directory
      localSections = 0;
      for (final entry in bookDir.listSync()) {
        final mimeType = lookupMimeType(entry.path);
        if (mimeType != null && mimeType.contains('audio')) {
          localSections++;
        }
      }

      if (localSections == sections?.length) {
        // all sections are in the local
        final file = File('${bookDir.path}/${imageUri?.split('/').last}');
        if (file.existsSync()) {
          // with cover image
          return {'state': LocalDataState.audioAndCoverImage};
        }
        // no cover image
        return {'state': LocalDataState.audioOnly};
      } else if (localSections > 0) {
        // section data is not complete
        return {'state': LocalDataState.partial, 'sections': localSections};
      }
    }
    return {'state': LocalDataState.none};
  }

  Icon getIcon({Color? color, double? size}) {
    switch (getLocalDataState()['state']) {
      case LocalDataState.partial:
        return Icon(Icons.file_download_rounded, color: color, size: size);
      case LocalDataState.audioOnly:
      case LocalDataState.audioAndCoverImage:
        return Icon(Icons.storage_rounded, color: color, size: size);
      case LocalDataState.none:
      default:
        if (source == CartaSource.librivox) {
          return Icon(Icons.local_library_rounded, color: color, size: size);
        } else if (source == CartaSource.cloud) {
          return Icon(Icons.cloud_rounded, color: color, size: size);
        } else if (source == CartaSource.internet) {
          return Icon(Icons.link_rounded, color: color, size: size);
        } else if (source == CartaSource.archive) {
          return Icon(Icons.account_balance_rounded, color: color, size: size);
        } else if (source == CartaSource.legamus) {
          return Icon(Icons.group, color: color, size: size);
        }
        return Icon(Icons.local_library_rounded, color: color, size: size);
    }
  }

  static Icon getIconBySource(CartaSource source,
      {Color? color, double? size}) {
    switch (source) {
      case CartaSource.librivox:
        return Icon(Icons.local_library_rounded, color: color, size: size);
      case CartaSource.internet:
        return Icon(Icons.link_rounded, color: color, size: size);
      case CartaSource.cloud:
        return Icon(Icons.cloud_rounded, color: color, size: size);
      case CartaSource.archive:
        return Icon(Icons.account_balance_rounded, color: color, size: size);
      case CartaSource.legamus:
        return Icon(Icons.group, color: color, size: size);
      default:
        return Icon(Icons.local_library_rounded, color: color, size: size);
    }
  }

  // returns the directory dedicated to the book
  // do not convert this into an async function
  Directory getBookDirectory() {
    return Directory('$appDocDirPath/$title');
  }

  Future deleteAudioData() async {
    final bookDir = getBookDirectory();
    if (bookDir.existsSync()) {
      // check if any media files
      for (final entry in bookDir.listSync()) {
        final mimeType = lookupMimeType(entry.path);
        if (mimeType != null && mimeType.contains('audio')) {
          await entry.delete();
        }
      }
    }
  }

  Future deleteBookDirectory() async {
    final bookDir = getBookDirectory();
    if (bookDir.existsSync()) {
      await bookDir.delete(recursive: true);
    }
  }

  // return cover image
  // DO NOT make this function ASYNC
  ImageProvider getCoverImage() {
    final bookDir = getBookDirectory();

    if (imageUri != null) {
      try {
        final file = File('${bookDir.path}/${imageUri!.split('/').last}');
        if (file.existsSync()) {
          // debugPrint('albumImage:FileImage');
          return FileImage(file);
        }
        // debugPrint('albumImage:NetworkImage');
        downloadCoverImage();
        // this will download the image twice but for the first time only
        return NetworkImage(imageUri!, headers: getAuthHeaders());
      } catch (e) {
        debugPrint(e.toString());
      }
    }
    // debugPrint('albumImage:AssetImage');
    return const AssetImage(defaultAlbumImage);
  }

  // download book cover
  Future<bool> downloadCoverImage() async {
    // get book directory
    final bookDir = getBookDirectory();
    // if not exists, create one
    if (!await bookDir.exists()) {
      await bookDir.create();
    }

    // download image
    if (imageUri != null) {
      final res = await http.get(
        Uri.parse(imageUri!),
        headers: getAuthHeaders(),
      );
      if (res.statusCode == 200) {
        final file = File('${bookDir.path}/${imageUri!.split('/').last}');
        await file.writeAsBytes(res.bodyBytes);
        // image url will be handled automatically
        // book.imageUri = 'file://${file.path}';
        return true;
      }
    }
    return false;
  }
}
