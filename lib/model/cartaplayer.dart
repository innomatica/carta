import 'dart:async';

// import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';

import '../logic/cartabloc.dart';
import '../shared/helpers.dart';
import 'cartabook.dart';

class CartaPlayer {
  CartaBloc bloc;
  bool hasBook = false;
  final _player = AudioPlayer();
  StreamSubscription? _sub;

  CartaPlayer({required this.bloc}) {
    _sub = _player.playerStateStream.listen((PlayerState state) {
      // play is interrupted: need to update the bookmark
      if (state.playing == false &&
          state.processingState == ProcessingState.ready) {
        _updateBookmark();
      }
    });
  }

  Future<void> dispose() async {
    _sub?.cancel();
    return _player.dispose();
  }

  int? get currentIndex => _player.currentIndex;
  double get speed => _player.speed;
  List<IndexedAudioSource>? get sequence => _player.sequence;

  Stream<int?> get currentIndexStream => _player.currentIndexStream;
  Stream<bool> get playingStream => _player.playingStream;

  Future<void> seek(Duration duration) async {
    await _player.seek(duration);
  }

  Future<void> setSpeed(double value) async {
    await _player.setSpeed(value);
  }

  Future<void> stop() async {
    hasBook = false;
    return _player.stop();
  }

  Future<void> pause() async {
    return _player.pause();
  }

  Future<void> resume() async {
    if (_player.sequence != null && _player.currentIndex != null) {
      return _player.play();
    }
  }

  Future<void> rewind(Duration back) async {
    if (back < _player.position) {
      _player.seek(_player.position - back);
    } else {
      _player.seek(Duration.zero);
    }
  }

  Future<void> seekToNext() async {
    await _player.seekToNext();
  }

  Future<void> seekToPrevious() async {
    await _player.seekToPrevious();
  }

  Future<void> forward(Duration forward) async {
    if (_player.duration != null &&
        (_player.position + forward) > _player.duration!) {
      _player.seek(_player.duration);
    } else {
      _player.seek(_player.position + forward);
    }
  }

  MediaItem? getCurrentTag() {
    if (_player.sequence != null) {
      if (_player.currentIndex != null &&
          _player.currentIndex! < _player.sequence!.length) {
        return _player.sequence![_player.currentIndex!].tag;
      }
    }
    return null;
  }

  Map<String, dynamic>? getCurrentTagExtra() {
    final tag = getCurrentTag();
    if (tag != null) {
      return tag.extras;
    }
    return null;
  }

  bool isCurrentBook({required String bookId}) {
    final extras = getCurrentTagExtra();

    return extras != null &&
            extras.containsKey('bookId') &&
            extras['bookId'] == bookId
        ? true
        : false;
  }

  bool isCurrentSection({required String bookId, required int sectionIdx}) {
    final extras = getCurrentTagExtra();
    return extras != null &&
            extras.containsKey('bookId') &&
            extras['bookId'] == bookId &&
            extras.containsKey('sectionIdx') &&
            extras['sectionIdx'] == sectionIdx
        ? true
        : false;
  }

  // Update book.lastSection and book.lastPosition
  Future<bool> _updateBookmark() async {
    final tag = getCurrentTag();
    if (tag != null && tag.extras != null) {
      if (tag.extras!.containsKey('bookId') &&
          tag.extras!.containsKey('sectionIdx')) {
        // debugPrint('*********** updating bookmark ${tag.extras!['bookId']}');
        await bloc.updateBookData(
          tag.extras!['bookId'],
          {
            'lastSection': tag.extras!['sectionIdx'],
            'lastPosition': toDurationString(_player.position),
          },
        );
      }
    }
    return false;
  }

  Future<void> playAudioBook({
    required CartaBook book,
    int sectionIdx = 0,
  }) async {
    // if playing now
    if (_player.playing) {
      // pause first
      await pause();
    }
    // the book seems to be paused
    if (isCurrentSection(bookId: book.bookId, sectionIdx: sectionIdx)) {
      // resume from the previous position
      return _player.play();
    }

    // need to get AudioSource
    final audioSource = book.getAudioSource();
    if (audioSource == null) {
      return;
    }

    Duration initPosition =
        sectionIdx == (book.lastSection ?? 0) && book.lastPosition != null
            ? book.lastPosition!
            : Duration.zero;

    await _player.setAudioSource(audioSource,
        initialIndex: sectionIdx, initialPosition: initPosition);
    hasBook = true;
    // ready to play new source
    return _player.play();
  }

  // Emit bookId and sectionIdx of currently playing book
  Stream<PlayingBookState?> get playingBookStateStream {
    return Rx.combineLatest2<bool, SequenceState?, PlayingBookState?>(
      _player.playingStream,
      _player.sequenceStateStream,
      (isPlaying, sequenceState) {
        if (isPlaying && sequenceState?.currentSource?.tag != null) {
          final tag = sequenceState?.currentSource?.tag;
          return PlayingBookState(
            bookId: tag.extras['bookId'],
            sectionIdx: tag.extras['sectionIdx'],
          );
        }
        return null;
      },
    );
  }

  // Check https://github.com/suragch/audio_video_progress_bar/
  // for the example
  Stream<DurationState> get durationStateStream {
    return Rx.combineLatest2<Duration, PlaybackEvent, DurationState>(
      _player.positionStream,
      _player.playbackEventStream,
      (position, playbackEvent) => DurationState(
        progress: position,
        buffered: playbackEvent.bufferedPosition,
        total: playbackEvent.duration,
      ),
    );
  }
}

class DurationState {
  final Duration progress;
  final Duration buffered;
  final Duration? total;

  const DurationState({
    required this.progress,
    required this.buffered,
    this.total,
  });
}

class PlayingBookState {
  final String bookId;
  final int sectionIdx;

  const PlayingBookState({
    required this.bookId,
    required this.sectionIdx,
  });

  @override
  String toString() {
    return {
      "bookId": bookId,
      "sectionIdx": sectionIdx,
    }.toString();
  }
}
