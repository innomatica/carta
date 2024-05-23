import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../shared/helpers.dart';
import '../shared/settings.dart';

const fastForwardInterval = Duration(seconds: 30);
const rewindInterval = Duration(seconds: 30);

Future<CartaAudioHandler> createAudioHandler() async {
  return await AudioService.init(
    builder: () => CartaAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: androidNotificationChannelId,
      androidNotificationChannelName: androidNotificationChannelName,
      androidNotificationOngoing: true,
      // this will keep the foreground on during pause
      // check: https://pub.dev/packages/audio_service
      // androidStopForegroundOnPause: false,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'drawable/app_icon',
      fastForwardInterval: fastForwardInterval,
      rewindInterval: rewindInterval,
    ),
  );
}

// https://pub.dev/packages/audio_service
class CartaAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final _player = AudioPlayer();
  // late final CartaBloc _logic;
  StreamSubscription? _subDuration;
  StreamSubscription? _subPlyState;
  StreamSubscription? _subCurIndex;
  StreamSubscription? _subPlyEvent;

  CartaAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    // expose _player.playbackEvent stream as plabackState stream
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    // start with empty list of audio source
    await _player.setAudioSource(ConcatenatingAudioSource(children: []));
    queue.add([]);
    // stream subscriptions
    _handleDurationChange();
    _handlePlyStateChange();
    _handleCurIndexChange();
    _handlePlyEventChange();
  }

  Future<void> dispose() async {
    await _subDuration?.cancel();
    await _subPlyState?.cancel();
    await _subCurIndex?.cancel();
    await _subPlyEvent?.cancel();

    await _player.stop();
    await _player.dispose();
  }

  //
  // Note that this will fire twice
  // - at the beginning: playing && buffering (valid data)
  // - at the end: not playing && idle (should be ignored)
  //
  void _handleDurationChange() {
    // subscribe to the duration chane
    _subDuration = _player.durationStream.listen((Duration? duration) {
      // logDebug('handler.durationChange: $duration, ${_player.playerState}');
      if (duration != null && _player.playing) {
        // broadcast duration change
        if (currentMediaItem != null) {
          mediaItem.add(currentMediaItem!.copyWith(duration: duration));
        }
      }
    });
  }

  void _handlePlyStateChange() {
    // subscribe to playerStateStream
    _subPlyState = _player.playerStateStream.listen((PlayerState state) async {
      // logDebug('playerState: ${state.playing}  ${state.processingState}');
      if (state.processingState == ProcessingState.ready) {
        if (state.playing == false) {
          // paused or loading done
        }
      } else if (state.processingState == ProcessingState.completed) {
        // (playing, completed) => (not playing, completed) => (not playing, idle)
        if (state.playing) {
          await stop();
        } else {
          clearQueue();
        }
      }
    });
  }

  void _handleCurIndexChange() {
    _subCurIndex = _player.currentIndexStream.listen((int? index) {
      // new section loaded
      mediaItem.add(currentMediaItem);
    });
  }

  void _handlePlyEventChange() {
    _subPlyEvent = _player.playbackEventStream.listen((PlaybackEvent event) {},
        onError: (Object e, StackTrace st) {
      if (e is PlatformException) {
        logError('PlatformException: ${e.code} ${e.message} ${e.details}');
      } else if (e is PlayerException) {
        logError('PlayerException: ${e.code} ${e.message} ${e.details}');
      } else {
        logError('Unknown Error: $e');
      }
      _showError();
    });
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

  // expose player properties
  bool get playing => _player.playing;
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<PlaybackEvent> get playbackEventStream => _player.playbackEventStream;

  // convenient shortcuts for internal use
  int? get currentIndex => _player.currentIndex;
  List<IndexedAudioSource>? get sequence => _player.sequence;
  IndexedAudioSource? get currentSection => currentIndex != null &&
          sequence != null &&
          currentIndex! < sequence!.length
      ? sequence?.elementAt(currentIndex!)
      : null;
  MediaItem? get currentMediaItem => currentSection?.tag as MediaItem?;

  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  // @override
  // Future<void> playMediaItem(MediaItem mediaItem) async {
  //   // logDebug('playMediaItem: $mediaItem');
  //   // Note: handle only when the mediaItem is alread on the sequence
  //   final audioSource = _player.audioSource as ConcatenatingAudioSource;
  //   // find the index of the item in the source list
  //   final index = audioSource.children
  //       .indexWhere((c) => (c as UriAudioSource).tag.id == mediaItem.id);
  //   // skip to the index
  //   await skipToQueueItem(index);
  //   _player.play();
  // }

  // SeekHandler implements fastForward, rewind, seekForward, seekBackward
  @override
  Future<void> seek(Duration position) => _player.seek(position);

  // SeekHandler.fastForward not working, needs override
  @override
  Future<void> fastForward() async {
    if (_player.duration != null) {
      final newPosition = _player.position + fastForwardInterval;
      newPosition > _player.duration!
          ? await seek(_player.duration!)
          : await seek(newPosition);
    }
  }

  // SeekHandler.rewind not working, needs override
  @override
  Future<void> rewind() async {
    if (_player.duration != null) {
      final newPosition = _player.position - rewindInterval;
      newPosition > Duration.zero
          ? await seek(newPosition)
          : await seek(Duration.zero);
    }
  }

  // QueueHandler implements skipToNext, skipToPrevious
  @override
  Future<void> skipToQueueItem(int index) async {
    // logDebug('skipToQueueItem: $index');
    final qval = queue.value;
    // validate index
    if (index >= 0 && index < qval.length) {
      // always start at the beginning of the chapter
      await _player.seek(Duration.zero, index: index);
      mediaItem.add(qval[index]);
      // } else {
      //   // invalid index range => better to stop in this situation
      //   if (_player.playing) {
      //     logError('invalid index requested: stop');
      //     await stop();
      //   }
      //   // probably end of the queue
      //   if (index == qval.length) {
      //     logDebug('skipToQueueItem.end of the queue');
      //     // clear queue
      //     clearQueue();
      //   }
    }
  }

  // QueueHandler skipToNext() seems to have bugs
  @override
  Future<void> skipToNext() async {
    // logDebug('skipToNext');
    final qval = queue.value;
    if (currentIndex != null && currentIndex! < (qval.length - 1)) {
      skipToQueueItem(currentIndex! + 1);
    }
  }

  UriAudioSource _mediaItemToAudioSource(MediaItem mediaItem) =>
      AudioSource.uri(Uri.parse(mediaItem.id), tag: mediaItem);

  List<MediaItem> get _queueFromSequence => sequence != null
      ? sequence!.map((s) => s.tag as MediaItem).toList()
      : <MediaItem>[];

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    // logDebug('addQueueItem: $mediaItem');
    await (_player.audioSource as ConcatenatingAudioSource)
        .add(_mediaItemToAudioSource(mediaItem));
    // broadcast change
    queue.add(_queueFromSequence);
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    // logDebug('addQueueItems: $mediaItems');
    await (_player.audioSource as ConcatenatingAudioSource)
        .addAll(mediaItems.map((m) => _mediaItemToAudioSource(m)).toList());
    // broadcast change
    queue.add(_queueFromSequence);
  }

  void clearQueue() {
    // logDebug('handler.clearQueue currentIndex: ${_player.currentIndex}');
    queue.add([]);
    mediaItem.add(null);
  }

  Future<void> setAudioSource(List<IndexedAudioSource> audioSources,
      {int initialIndex = 0, int initialPosition = 0}) async {
    await _player.setAudioSource(
      ConcatenatingAudioSource(children: audioSources),
      // preload: false,
      // initialIndex: sectionIdx,
      // initialPosition: initPosition,
    );

    queue.add(_queueFromSequence);

    // final mediaItems = audioSources.map((s) => s.tag as MediaItem).toList();
    // await setQueue(mediaItems);
    // skip to the section
    await skipToQueueItem(initialIndex);
    // seek position
    await seek(Duration(seconds: initialPosition));
  }

  void _showError() {
    // TODO: https://stackoverflow.com/questions/59787163/how-do-i-show-dialog-anywhere-in-the-app-without-context
    // showDialog(context: context, builder: builder);
  }
}
