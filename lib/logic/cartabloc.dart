import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

import '../model/cartabook.dart';
import '../model/cartacard.dart';
import '../repo/sqlite.dart';
import '../service/webpage.dart';
import '../shared/settings.dart';

class CartaBloc extends ChangeNotifier {
  List<CartaBook> _books = <CartaBook>[];
  final Set<String> _cancelRequests = <String>{};
  final Set<String> _isDownloading = <String>{};

  final _db = SqliteRepo();

  CartaBloc() {
    refreshAudioBooks();
  }

  @override
  dispose() {
    _db.close();
    super.dispose();
  }

  List<CartaBook> get books {
    return _books;
  }

  Future refreshAudioBooks() async {
    _books = await _db.getAudioBooks();
    notifyListeners();
  }

  Future<bool> addAudioBook(CartaBook book) async {
    // add book to database
    await _db.addAudioBook(book);
    refreshAudioBooks();
    return true;
  }

  Future<CartaBook?> getAudioBookByBookId(String bookId) async {
    return _db.getAudioBookByBookId(bookId);
  }

  Future deleteAudioBook(CartaBook book) async {
    // remove stored data regardless of book.source
    await book.deleteBookDirectory();

    // remove database entry
    await _db.deleteAudioBook(book);
    refreshAudioBooks();
  }

  Future updateAudioBook(CartaBook book) async {
    await _db.updateAudioBook(book);
    refreshAudioBooks();
  }

  // update fields of the book
  //
  // it is the callers responsibility to do the conversion depending on the
  // field and the database
  //
  Future updateBookData(String bookId, Map<String, Object?> data) async {
    await _db.updateDataByBookId(bookId, data);
    refreshAudioBooks();
  }

  //
  // Handling Download
  //
  bool isDownloading(String bookId) {
    return _isDownloading.contains(bookId);
    // return _downloadState.isDownloading && _downloadState.bookId == bookId
    //     ? true
    //     : false;
  }

  void cancelDownload(String bookId) {
    _cancelRequests.add(bookId);
  }

  // Download media files
  //
  // All the download tasks are handled here in one place in order to
  // get rid of the need of CartaBook being a ChangeNotifier
  //
  Future downloadMediaData(CartaBook book) async {
    // book must have sections
    if (book.sections == null || _isDownloading.contains(book.bookId)) {
      return;
    }

    // reset cancel flag first
    _cancelRequests.remove(book.bookId);

    // get book directory
    final bookDir = book.getBookDirectory();
    // if not exists, create one
    if (!bookDir.existsSync()) {
      await bookDir.create();
    }

    // download cover image: no longer necessary
    // book.downloadCoverImage();

    _isDownloading.add(book.bookId);
    // download each section data
    for (final section in book.sections!) {
      // debugPrint('downloading:${section.index}');
      notifyListeners();

      // break if cancelled
      if (_cancelRequests.contains(book.bookId)) {
        debugPrint('download canceled: ${book.title}');
        break;
      }

      // otherwise go head
      final res = await http.get(
        Uri.parse(section.uri),
        headers: book.getAuthHeaders(),
      );

      if (res.statusCode == 200) {
        final file = File('${bookDir.path}/${section.uri.split('/').last}');
        // store audio data
        await file.writeAsBytes(res.bodyBytes);
      }
    }

    if (_cancelRequests.contains(book.bookId)) {
      // delete media data in the directory
      deleteMediaData(book);
      _cancelRequests.remove(book.bookId);
    }
    // notify the end of download
    _isDownloading.remove(book.bookId);
    debugPrint('download done: ${book.title}');
    notifyListeners();
  }

  // delete audio data
  Future deleteMediaData(CartaBook book) async {
    final bookDir = book.getBookDirectory();
    for (final entry in bookDir.listSync()) {
      if (entry is File &&
          lookupMimeType(entry.path)?.contains('audio') == true) {
        entry.deleteSync();
      }
    }
    // debugPrint('deleteMediaData.notifyListeners');
    notifyListeners();
  }

  //
  // CartaCard
  //
  Future<List<CartaCard>> getSampleBookCards() async {
    final cards = <CartaCard>[];
    final res = await http.get(Uri.parse(urlSelectedBooksJson));
    if (res.statusCode == 200) {
      final jsonDoc = jsonDecode(res.body) as Map<String, dynamic>;
      if (jsonDoc.containsKey('data') && jsonDoc['data'] is List) {
        for (final item in jsonDoc['data']) {
          cards.add(CartaCard.fromJsonDoc(item));
          // debugPrint('card: ${CartaCard.fromJsonDoc(item)}');
        }
      }
    }
    return cards;
  }

  Future<CartaBook?> getAudioBookFromCard(CartaCard card) async {
    CartaBook? book;
    if (card.source == CartaSource.carta) {
      book = CartaBook.fromCartaCard(card);
    } else if (card.source == CartaSource.librivox ||
        card.source == CartaSource.archive) {
      book = await WebPageParser.getBookFromUrl(card.data['siteUrl']);
    }
    return book;
  }
}
