import 'dart:async';
import 'dart:developer';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

import '../logic/cartabloc.dart';
import '../model/cartabook.dart';
import '../shared/helpers.dart';

const fastForwardInterval = Duration(seconds: 30);
const rewindInterval = Duration(seconds: 30);

Future<CartaAudioHandler> createAudioHandler() async {
  return await AudioService.init(
    builder: () => CartaAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.innomatic.carta.channel.audio',
      androidNotificationChannelName: 'Carta playback',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'drawable/app_icon',
      fastForwardInterval: fastForwardInterval,
      rewindInterval: rewindInterval,
    ),
  );
}

class CartaAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final _player = AudioPlayer();
  late final CartaBloc _logic;
  StreamSubscription? _subPlayerState;
  StreamSubscription? _subCurrentIndex;
  StreamSubscription? _subPlaybackEvent;

  CartaAudioHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    // listen to playerStateStream
    _subPlayerState =
        _player.playerStateStream.listen((PlayerState state) async {
      // log('playerState: ${state.playing}  ${state.processingState}');
      if (state.processingState == ProcessingState.loading && state.playing) {
        log('loading & playing');
        //
        // (A) broadcast mediaItem when loading
        //     - (PROS) it is called only once each media
        //     - (CONS) _player has no duration info at this point
        //
        // broadcast mediaItem
        // final tag = _player.sequence?[_player.currentIndex ?? 0].tag;
        // mediaItem.add(tag);
      } else if (state.processingState == ProcessingState.ready &&
          _player.playing) {
        log('ready & playing');
        //
        // (B) broadcast mediaItem when ready
        //     - (PROS) it may be called multiple times when seek is used
        //     - (CONS) _player has accurate duration info
        //
        // broadcast mediaItem
        final tag = _player.sequence?[_player.currentIndex ?? 0].tag;
        mediaItem.add(tag?.copyWith(duration: _player.duration));
        // _updateBookmark();
      } else if (state.processingState == ProcessingState.completed &&
          state.playing == true) {
        log('end of the book');
        await stop();
      }
    });
    // listen to currentIndexStream
    _subCurrentIndex = _player.currentIndexStream.listen((int? index) async {
      log('currentIndexState: $index, ${_player.processingState}');
      // detect change of media
      if (index != null &&
          index > 0 &&
          _player.processingState == ProcessingState.ready) {
        // broadcast mediaItem
        final tag = _player.sequence?[index].tag;
        mediaItem.add(tag?.copyWith(duration: _player.duration));
      }
    });
    // listen to playbackEventStream
    _subPlaybackEvent = _player.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace st) {
      if (e is PlayerException) {
        log('PlayerException code: ${e.code}');
        log('PlayerException message: ${e.message}');
      } else {
        log('PlaybackEvent error: $e');
      }
      // do not stop here
    });
  }

  void setLogic(CartaBloc logic) {
    _logic = logic;
  }

  Future<void> dispose() async {
    await _subPlayerState?.cancel();
    await _subCurrentIndex?.cancel();
    await _subPlaybackEvent?.cancel();
    await _player.dispose();
  }

  // Transform a just_audio event into an audio_service state.
  // https://github.com/ryanheise/audio_service/blob/minor/audio_service/example/lib/main.dart
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.rewind,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  @override
  Future<void> pause() async {
    log('handler.pause');
    await _updateBookmark();
    await _player.pause();
  }

  @override
  Future<void> play() => _player.play();

  // SeekHandler implements fastForward, rewind, seekForward, seekBackward
  @override
  Future<void> seek(Duration position) => _player.seek(position);
  // override fastForward additionally to handle zero (or null) duration media
  @override
  Future<void> fastForward() =>
      _player.seek(_player.position + fastForwardInterval);
  // override rewind additionally to handle zero (or null) duration media
  @override
  Future<void> rewind() => _player.seek(_player.position - rewindInterval);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  // QueueHandler implements skipToNext, skipToPrevious
  @override
  Future<void> skipToQueueItem(int index) async {
    final sequence = _player.sequence;
    // validate index
    if (sequence?.isNotEmpty == true &&
        index > -1 &&
        index < sequence!.length) {
      await _player.seek(Duration.zero, index: index);
    }
  }

  @override
  Future<void> stop() async {
    log('handler.stop');
    await _updateBookmark();
    await _player.stop();
  }

  // duration of the current section
  Duration get duration => _player.duration ?? Duration.zero;
  Stream<Duration> get positionStream => _player.positionStream;

  MediaItem? getCurrentTag() {
    if (_player.sequence?.isNotEmpty == true &&
        _player.currentIndex != null &&
        _player.currentIndex! >= 0 &&
        _player.currentIndex! < _player.sequence!.length) {
      return _player.sequence![_player.currentIndex!].tag as MediaItem;
    }
    return null;
  }

  bool isCurrentBook({required String bookId}) {
    final extras = getCurrentTag()?.extras;
    return extras != null &&
            extras.containsKey('bookId') &&
            extras['bookId'] == bookId
        ? true
        : false;
  }

  bool isCurrentSection({required String bookId, required int sectionIdx}) {
    final extras = getCurrentTag()?.extras;
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
    log('handler._updateBookmark');
    final tag = getCurrentTag();
    if (tag != null && tag.extras != null) {
      if (tag.extras!.containsKey('bookId') &&
          tag.extras!.containsKey('sectionIdx')) {
        // debugPrint('*********** updating bookmark ${tag.extras!['bookId']}');
        await _logic.updateBookData(
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

  Future<void> playAudioBook(CartaBook book, {int sectionIdx = 0}) async {
    // log('handler.playAudioBook.book: $book');
    if (isCurrentSection(bookId: book.bookId, sectionIdx: sectionIdx)) {
      // same book, same section => toogle playing
      if (_player.playing) {
        await pause();
      } else {
        await play();
      }
    } else {
      // different book or different section of the book
      await _updateBookmark();
      final audioSource = book.getAudioSource();
      if (audioSource.isNotEmpty) {
        Duration initPosition =
            sectionIdx == (book.lastSection ?? 0) && book.lastPosition != null
                ? book.lastPosition!
                : Duration.zero;
        // it is required to stop before setAudioSource call
        await stop();
        try {
          // https://pub.dev/packages/just_audio#working-with-caches
          // Better to clear cache regardless of the source type
          // if (audioSource[0] is LockCachingAudioSource) {
          try {
            await AudioPlayer.clearAssetCache();
          } catch (e) {
            log(e.toString());
          }
          // }
          await _player.setAudioSource(
            ConcatenatingAudioSource(children: audioSource),
            preload: false,
            initialIndex: sectionIdx,
            initialPosition: initPosition,
          );
          // hasBook = true;
          // ready to play new source
          log('start a new book/section: ${book.title}, $sectionIdx');
          queue.add(audioSource.map((e) => e.tag as MediaItem).toList());
          await play();
        } catch (e) {
          log(e.toString());
        }
      }
    }
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
