import 'dart:convert';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:mime/mime.dart';

import '../enc_dec.dart';
import '../shared/helpers.dart';
import '../shared/settings.dart';
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

const defaultCategory = 'Audio Book';

class CartaBook {
  String bookId;
  String title;
  String? authors;
  String? description;
  String? language;
  String? imageUri;
  // Duration? duration;
  int? duration;
  int? lastSection;
  // Duration? lastPosition;
  int? lastPosition;
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
      duration: hmsToSeconds(result['totaltime']),
      lastSection: 0,
      // lastPosition: Duration.zero,
      lastPosition: 0,
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
    // logDebug('fromSqlite: $data');
    try {
      return CartaBook(
        bookId: data['bookId'],
        title: data['title'],
        authors: data['authors'].startsWith('[{')
            ? jsonDecode(data['authors'])[0]['lastName'] // old model
            : data['authors'], // new model
        description: data['description'],
        language: data['language'],
        imageUri: data['imageUri'],
        duration: hmsToSeconds(data['duration']),
        lastSection: data['lastSection'],
        lastPosition: hmsToSeconds(data['lastPosition']),
        source: CartaSource.values[data['source']],
        info: jsonDecode(data['info']),
        sections: jsonDecode(data['sections'])
            ?.map<CartaSection>((e) => CartaSection.fromDatabase(e))
            .toList(),
      );
    } catch (e) {
      logError(e.toString());
      rethrow;
    }
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
      'duration': secondsToHms(duration),
      'lastSection': lastSection,
      'lastPosition': secondsToHms(lastPosition),
      'source': source.index,
      'info': jsonEncode(info),
      'sections': jsonEncode(sections?.map((e) => e.toDatabase()).toList()),
    };
  }

  @override
  String toString() {
    return toSqlite().toString();
  }

  List<IndexedAudioSource> getAudioSources({int initIndex = 0}) {
    final sectionData = <IndexedAudioSource>[];
    // book must have valid sections
    if (sections != null && sections!.isNotEmpty) {
      final bookDir = getBookDirectory();
      final headers = getAuthHeaders();
      // NOTE: sections must be in order
      for (final section in sections!) {
        if (section.index >= initIndex) {
          // build tag
          final tag = MediaItem(
            id: section.uri,
            // section title as title
            title: section.title,
            // book title as album
            album: title == section.title ? authors : title,
            duration: section.duration != null
                ? Duration(seconds: section.duration!)
                : Duration.zero,
            // artHeaders are not recognized by the background process
            // artUri: imageUri != null ? Uri.parse(imageUri!) : null,
            // artHeaders: headers,
            artUri: getArtUri(),
            // extra for internal use
            extras: {
              'bookId': bookId,
              'bookTitle': title,
              'sectionIdx': section.index,
              'sectionTitle': section.title,
              // 'seekPos': section.seekPos,
            },
          );
          // check if local data for the section exists
          final file = File('${bookDir.path}/${section.uri.split("/").last}');
          if (file.existsSync()) {
            sectionData.add(AudioSource.uri(
              Uri.parse(Uri.encodeFull('file://${file.path}')),
              tag: tag,
            ));
            // logDebug('file source: ${file.path}');
          } else {
            // NOTE: this is experimental
            // if (info['cached'] == true) {
            //   sectionData.add(LockCachingAudioSource(
            //     Uri.parse(section.uri),
            //     headers: headers,
            //     tag: tag,
            //   ));
            // } else
            {
              sectionData.add(AudioSource.uri(
                Uri.parse(section.uri),
                headers: headers,
                tag: tag,
              ));
            }
            // logDebug('url headers: ${headers.toString()}');
            // logDebug('url source: ${section.uri}');
          }
          // logDebug('adding: ${section.title}');
        }
      }
    }
    // logDebug('getAudioSource.return: $sectionData');
    return sectionData;
  }

  Map<String, String>? getAuthHeaders() {
    // logDebug('getAuthHeaders: $info');
    if (info.containsKey('authentication') &&
        info['authentication'] == 'basic' &&
        info.containsKey('username') &&
        info.containsKey('password')) {
      // logDebug('info: $info');
      final username = decrypt(info['username']);
      final password = decrypt(info['password']);
      // logDebug('username: $username, password: $password');
      final credential = base64Encode(utf8.encode('$username:$password'));
      return {
        HttpHeaders.authorizationHeader: 'Basic $credential',
        // 'content-type': 'audio/mpeg',
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
      // check the number of local sections
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
          return Icon(Icons.auto_stories_rounded, color: color, size: size);
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
        return Icon(Icons.auto_stories_rounded, color: color, size: size);
      default:
        return Icon(Icons.local_library_rounded, color: color, size: size);
    }
  }

  // returns the directory dedicated to the book
  // do not convert this into an async function
  Directory getBookDirectory() {
    // logDebug('getBookDirectory:$appDocDirPath/$title');
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
    // validate imageUri
    if (imageUri != null) {
      final bookDir = getBookDirectory();
      try {
        final file = File('${bookDir.path}/${imageUri!.split('/').last}');
        if (file.existsSync()) {
          // logDebug('albumImage:FileImage');
          return FileImage(file);
        }
        // logDebug('albumImage:NetworkImage');
        // NOTE: do not use AWAIT here
        // THIS WILL CRASH WHEN BOOK IS BEING DELETED
        // downloadCoverImage();
        return NetworkImage(imageUri!, headers: getAuthHeaders());
      } catch (e) {
        logError(e.toString());
      }
    }
    // logDebug('albumImage:AssetImage');
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

  Uri? getArtUri() {
    final bookDir = getBookDirectory();
    if (imageUri != null) {
      final file = File('${bookDir.path}/${imageUri!.split('/').last}');
      if (file.existsSync()) {
        return Uri.file('${bookDir.path}/${imageUri!.split('/').last}');
      } else {
        return Uri.tryParse(imageUri!);
      }
    }
    return null;
  }
}
