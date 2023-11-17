import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

import '../model/cartabook.dart';
import '../model/cartacard.dart';
import '../model/cartaserver.dart';
import '../repo/sqlite.dart';
import '../service/webpage.dart';
import '../shared/settings.dart';

const sortOptions = ['title', 'authors'];
const filterOptions = ['all', 'librivox', 'archive', 'cloud'];
const sortIcons = [Icons.album_rounded, Icons.account_circle_rounded];
const filterIcons = [
  Icons.import_contacts_rounded,
  Icons.local_library_rounded,
  Icons.account_balance_rounded,
  Icons.cloud_rounded,
];

class CartaBloc extends ChangeNotifier {
  int sortIndex = 0;
  int filterIndex = 0;

  final _books = <CartaBook>[];
  // download related variables
  final _cancelRequests = <String>{};
  final _isDownloading = <String>{};
  // database
  final _db = SqliteRepo();
  // book server data stored in the local database
  final List<CartaServer> _servers = <CartaServer>[];

  CartaBloc() {
    // update book server list when start
    refreshBookServers();
    refreshBooks();
  }

  @override
  dispose() {
    _db.close();
    super.dispose();
  }

  String get currentSort => sortOptions[sortIndex];
  String get currentFilter => filterOptions[filterIndex];
  IconData get sortIcon => sortIcons[sortIndex];
  IconData get filterIcon => filterIcons[filterIndex];

  // Return list of books filtered
  List<CartaBook> get books {
    final filterOption = filterOptions[filterIndex];
    // debugPrint('filterOption: $filterOption');
    if (filterOption == 'librivox') {
      return _books
          .where((b) =>
              b.source == CartaSource.librivox ||
              b.source == CartaSource.legamus)
          .toList();
    } else if (filterOption == 'archive') {
      return _books.where((b) => b.source == CartaSource.archive).toList();
    } else if (filterOption == 'cloud') {
      return _books.where((b) => b.source == CartaSource.cloud).toList();
    } else {
      return _books;
    }
  }

  //
  // BOOK
  //
  // Refresh list of books
  Future<void> refreshBooks() async {
    _books.clear();
    _books.addAll(await _db.getAudioBooks());
    _sortBooks();
    notifyListeners();
  }

  // Create
  Future<bool> addAudioBook(CartaBook book) async {
    // add book to database
    await _db.addAudioBook(book);
    refreshBooks();
    return true;
  }

  // Read by Id
  Future<CartaBook?> getAudioBookByBookId(String bookId) async {
    return _db.getAudioBookByBookId(bookId);
  }

  // Delete
  Future deleteAudioBook(CartaBook book) async {
    // remove stored data regardless of book.source
    await book.deleteBookDirectory();
    // remove database entry
    if (await _db.deleteAudioBook(book) > 0) {
      refreshBooks();
    }
  }

  // Update
  Future updateAudioBook(CartaBook book) async {
    if (await _db.updateAudioBook(book) > 0) {
      refreshBooks();
    }
  }

  // Update only certain fields of the book: the caller has to
  //  1. do the conversion of the field
  //  2. refresh screen contents when it returns true
  Future updateBookData(String bookId, Map<String, Object?> data) async {
    await _db.updateBookData(bookId, data);
  }

  // Book filter
  void rotateFilterBy() {
    filterIndex = (filterIndex + 1) % filterOptions.length;
    notifyListeners();
  }

  // Book sort
  void rotateSortBy() {
    sortIndex = (sortIndex + 1) % sortOptions.length;
    _sortBooks();
    notifyListeners();
  }

  _sortBooks() {
    final sortOption = sortOptions[sortIndex];
    // debugPrint('sortOption: $sortOption');
    if (sortOption == 'title') {
      _books.sort((a, b) => a.title.compareTo(b.title));
    } else if (sortOption == 'authors') {
      _books.sort((a, b) => (a.authors ?? '').compareTo(b.authors ?? ''));
    }
  }

  //
  // Handling Download
  //
  bool isDownloading(String bookId) {
    return _isDownloading.contains(bookId);
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
      // otherwise go ahead
      final res = await http.get(
        Uri.parse(section.uri),
        headers: book.getAuthHeaders(),
      );
      // check statusCode
      if (res.statusCode == 200) {
        final file = File('${bookDir.path}/${section.uri.split('/').last}');
        // store audio data
        await file.writeAsBytes(res.bodyBytes);
      }
    }
    // cancel requested
    if (_cancelRequests.contains(book.bookId)) {
      // delete media data in the directory
      deleteMediaData(book);
      _cancelRequests.remove(book.bookId);
    }
    // notify the end of download
    _isDownloading.remove(book.bookId);
    // debugPrint('download done: ${book.title}');
    notifyListeners();
  }

  // Delete audio data
  Future deleteMediaData(CartaBook book) async {
    final bookDir = book.getBookDirectory();
    for (final entry in bookDir.listSync()) {
      if (entry is File &&
          lookupMimeType(entry.path)?.contains('audio') == true) {
        entry.deleteSync();
      }
    }
    notifyListeners();
  }

  //
  // CartaCard
  //
  // Get Sample Cards
  Future<List<CartaCard>> getSampleBookCards() async {
    final cards = <CartaCard>[];
    final res = await http.get(Uri.parse(urlSelectedBooksJson));
    if (res.statusCode == 200) {
      final jsonDoc = jsonDecode(res.body) as Map<String, dynamic>;
      if (jsonDoc.containsKey('data') && jsonDoc['data'] is List) {
        for (final item in jsonDoc['data']) {
          cards.add(CartaCard.fromJsonDoc(item));
        }
      }
    }
    return cards;
  }

  // Get Book from the card
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

  //
  //  CartaServer
  //
  List<CartaServer> get servers => _servers;

  // Refresh server list
  Future refreshBookServers() async {
    _servers.clear();
    _servers.addAll(await _db.getBookServers());
    notifyListeners();
  }

  // Create
  Future addBookServer(CartaServer server) async {
    if (await _db.addBookServer(server) > 0) {
      refreshBookServers();
    }
  }

  // Update
  Future updateBookServer(CartaServer server) async {
    if (await _db.updateBookServer(server) > 0) {
      refreshBookServers();
    }
  }

  // Delete
  Future deleteBookServer(CartaServer server) async {
    if (await _db.deleteBookServer(server) > 0) {
      refreshBookServers();
    }
  }
}
