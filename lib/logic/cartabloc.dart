import 'dart:async';
import 'dart:convert';
import 'dart:io';

// import 'package:async/async.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:mime/mime.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/cartabook.dart';
import '../model/cartacard.dart';
import '../model/cartaserver.dart';
import '../repo/sqlite.dart';
import '../service/audiohandler.dart';
import '../service/webpage.dart';
import '../shared/helpers.dart';
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
  int _sortIndex = 0;
  int _filterIndex = 0;
  late final SharedPreferences _prefs;
  late final CartaAudioHandler _handler;

  StreamSubscription? _subPlayState;

  final _books = <CartaBook>[];
  // download related variables
  final _cancelRequests = <String>{};
  final _isDownloading = <String>{};
  // database
  final _db = SqliteRepo();
  // book server data stored in the local database
  final List<CartaServer> _servers = <CartaServer>[];

  CartaBloc(CartaAudioHandler handler) {
    _handler = handler;
    init();
  }

  @override
  dispose() {
    _db.close();
    _subPlayState?.cancel();
    _handler.dispose();
    super.dispose();
  }

  void init() async {
    _prefs = await SharedPreferences.getInstance();
    _sortIndex = _prefs.getInt('sortIndex') ?? 0;
    _filterIndex = _prefs.getInt('filterIndex') ?? 0;
    _handlePlayStateChange();
    // update book server list when start
    await refreshBookServers();
    await refreshBooks();
  }

  // getters
  String get currentSort => sortOptions[_sortIndex];
  String get currentFilter => filterOptions[_filterIndex];
  IconData get sortIcon => sortIcons[_sortIndex];
  IconData get filterIcon => filterIcons[_filterIndex];

  // from handler
  Duration get position => _handler.position;
  BehaviorSubject<List<MediaItem>> get queue => _handler.queue;
  BehaviorSubject<MediaItem?> get mediaItem => _handler.mediaItem;
  BehaviorSubject<PlaybackState> get playbackState => _handler.playbackState;
  MediaItem? get currentTag => _handler.mediaItem.value;
  String? get currentBookId => currentTag?.extras?['bookId'];
  int? get currentSectionIdx => currentTag?.extras?['sectionIdx'];
  // from handler.player
  Duration get duration => _handler.duration;
  Stream<Duration> get positionStream => _handler.positionStream;

  //
  // Due to some potential issues, we need to directly access to the
  // _handler.player.playerStateStream instead of _handler.playbackStateStream
  //
  void _handlePlayStateChange() {
    _subPlayState =
        _handler.playerStateStream.listen((PlayerState state) async {
      logDebug('playerState: ${state.playing}  ${state.processingState}');
      if (state.processingState == ProcessingState.ready) {
        if (state.playing) {
          // logDebug('START: $currentBookId, $currentSectionIdx, $position');
        } else {
          // logDebug('PAUSED: $currentBookId, $currentSectionIdx, $position');
          if (position.inSeconds > 0) await _updateBookmark();
        }
      } else if (state.processingState == ProcessingState.buffering) {
        if (state.playing) {
          // logDebug('SEEK: $currentBookId, $currentSectionIdx, $position');
          if (position.inSeconds > 0) await _updateBookmark();
        } else {
          // you can update lastSection
          // logDebug('LOAD: $currentBookId, $currentSectionIdx, $position');
        }
      } else if (state.processingState == ProcessingState.completed) {
        if (state.playing) {
          await _resetBookmark();
        }
      }
    });
  }

  //
  // AudioHandler proxies
  //
  Future<void> stop() => _handler.stop();
  Future<void> pause() => _handler.pause();
  Future<void> rewind() => _handler.rewind();
  Future<void> fastForward() => _handler.fastForward();
  Future<void> seek(Duration position) => _handler.seek(position);
  Future<void> setSpeed(double speed) => _handler.setSpeed(speed);
  Future<void> skipToNext() => _handler.skipToNext();
  Future<void> skipToPrevious() => _handler.skipToPrevious();

  Future<void> resume() async {
    if (_handler.queue.value.isNotEmpty) {
      _handler.play();
    }
  }

  Future<void> play(CartaBook? book, {int? sectionIdx}) async {
    // logDebug('handler.play: $sectionIdx, $book');
    if (book == null) {
      // resume paused book
      resume();
    } else if (currentBookId == book.bookId) {
      // the same book as current one
      if (currentSectionIdx == sectionIdx) {
        logDebug(
            'play same book same section: ${book.title} ${book.bookId} $sectionIdx');
        _handler.playing ? pause() : resume();
      } else {
        logDebug(
            'play same book different section: ${book.title} ${book.bookId} $sectionIdx');
        if (sectionIdx != null) _handler.skipToQueueItem(sectionIdx);
      }
    } else {
      // new book
      logDebug('play new book: ${book.title} ${book.bookId} $sectionIdx');
      // if currently playing
      if (_handler.playing &&
          currentBookId != null &&
          currentSectionIdx != null) {
        // and pause before moving on => this will save the bookmark
        await _handler.pause();
      }

      // load new audio source
      final audioSources = book.getAudioSources();
      await _handler.setAudioSource(
        audioSources,
        initialIndex: sectionIdx ?? book.lastSection ?? 0,
        initialPosition:
            sectionIdx == book.lastSection ? book.lastPosition ?? 0 : 0,
      );

      // start play
      _handler.play();
    }
  }

  // Return list of books filtered
  List<CartaBook> get books {
    final filterOption = filterOptions[_filterIndex];
    // logDebug('filterOption: $filterOption');
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
    await refreshBooks();
    return true;
  }

  // Read by Id
  Future<CartaBook?> getAudioBookByBookId(String bookId) async {
    return _db.getAudioBookByBookId(bookId);
  }

  // Delete
  Future deleteAudioBook(CartaBook book) async {
    if (book.bookId == currentBookId) {
      if (_handler.playing) {
        await _handler.stop();
      }
      _handler.clearQueue();
    }
    // remove stored data regardless of book.source
    await book.deleteBookDirectory();
    // remove database entry
    if (await _db.deleteAudioBook(book) > 0) {
      await refreshBooks();
    }
  }

  // Update
  Future updateAudioBook(CartaBook book) async {
    if (await _db.updateAudioBook(book) > 0) {
      await refreshBooks();
    }
  }

  // Update book.lastSection and book.lastPosition
  Future _updateBookmark({bool refresh = true}) async {
    if (currentBookId != null && currentSectionIdx != null) {
      logWarn(
          'updateBookmark.book:$currentBookId, lastSection:$currentSectionIdx,'
          ' lastPosition:${_handler.position.inSeconds}');
      await _db.updateAudioBooks(values: {
        'lastSection': currentSectionIdx,
        'lastPosition': secondsToHms(_handler.position.inSeconds),
      }, params: {
        'where': 'bookId = ?',
        'whereArgs': [currentBookId],
      });
      if (refresh) refreshBooks();
    }
  }

  Future _resetBookmark({bool refresh = true}) async {
    logWarn('resetBoomark.book:$currentBookId');
    await _db.updateAudioBooks(values: {
      'lastSection': null,
      'lastPosition': null,
    }, params: {
      'where': 'bookId = ?',
      'whereArgs': [currentBookId],
    });
    if (refresh) refreshBooks();
  }

  // Book filter
  void rotateFilterBy() {
    _filterIndex = (_filterIndex + 1) % filterOptions.length;
    _prefs.setInt('filterIndex', _filterIndex);
    notifyListeners();
  }

  // Book sort
  void rotateSortBy() {
    _sortIndex = (_sortIndex + 1) % sortOptions.length;
    _prefs.setInt('sortIndex', _sortIndex);
    _sortBooks();
    notifyListeners();
  }

  _sortBooks() {
    final sortOption = sortOptions[_sortIndex];
    // logDebug('sortOption: $sortOption');
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
      // logDebug('downloading:${section.index}');
      notifyListeners();
      // break if cancelled
      if (_cancelRequests.contains(book.bookId)) {
        logDebug('download canceled: ${book.title}');
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
    // logDebug('download done: ${book.title}');
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
      await refreshBookServers();
    }
  }

  // Update
  Future updateBookServer(CartaServer server) async {
    if (await _db.updateBookServer(server) > 0) {
      await refreshBookServers();
    }
  }

  // Delete
  Future deleteBookServer(CartaServer server) async {
    if (await _db.deleteBookServer(server) > 0) {
      await refreshBookServers();
    }
  }
}
