import 'dart:io';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';

import '../../model/cartaplayer.dart';

class ProgressSlider extends StatelessWidget {
  final CartaPlayer player;
  const ProgressSlider(this.player, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
      child: StreamBuilder<DurationState>(
        stream: player.durationStateStream,
        builder: (context, snapshot) {
          final durationState = snapshot.data;
          return ProgressBar(
            progress: durationState?.progress ?? Duration.zero,
            buffered: durationState?.progress ?? Duration.zero,
            total: durationState?.total ?? Duration.zero,
            onSeek: (duration) {
              player.seek(duration);
            },
          );
        },
      ),
    );
  }
}

class PlayButton extends StatelessWidget {
  final CartaPlayer player;
  final double? size;
  final Color? color;
  const PlayButton(this.player, {this.size, this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayingBookState?>(
      stream: player.playingBookStateStream,
      builder: (context, snapshot) {
        final playingBookState = snapshot.data;
        if (playingBookState != null) {
          // currently playing => PAUSE button
          return IconButton(
            icon: Icon(Icons.pause_rounded, size: size, color: color),
            onPressed: () async {
              await player.pause();
            },
          );
        } else {
          // currently not playing => PLAY button
          return IconButton(
            icon: Icon(Icons.play_arrow_rounded, size: size, color: color),
            onPressed: () async {
              // resume
              await player.resume();
            },
          );
        }
      },
    );
  }
}

class Rewind30Button extends StatelessWidget {
  final CartaPlayer player;
  final double? size;
  final Color? color;
  const Rewind30Button(this.player, {this.size, this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.replay_30_rounded, size: size, color: color),
      onPressed: () {
        player.rewind(const Duration(seconds: 30));
      },
    );
  }
}

class Forward30Button extends StatelessWidget {
  final CartaPlayer player;
  final double? size;
  final Color? color;
  const Forward30Button(this.player, {this.size, this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.forward_30_rounded, size: size, color: color),
      onPressed: () {
        player.forward(const Duration(seconds: 30));
      },
    );
  }
}

class NextButton extends StatelessWidget {
  final CartaPlayer player;
  final double? size;
  final Color? color;
  const NextButton(this.player, {this.size, this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.skip_next_rounded, size: size, color: color),
      onPressed: () {
        player.seekToNext();
      },
    );
  }
}

class PreviousButton extends StatelessWidget {
  final CartaPlayer player;
  final double? size;
  final Color? color;
  const PreviousButton(this.player, {this.size, this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.skip_previous_rounded, size: size, color: color),
      onPressed: () {
        player.seekToPrevious();
      },
    );
  }
}

class PlaySpeedButton extends StatefulWidget {
  final CartaPlayer player;
  final double? size;
  final Color? color;
  const PlaySpeedButton(this.player, {this.size, this.color, super.key});

  @override
  State<PlaySpeedButton> createState() => _PlaySpeedButtonState();
}

class _PlaySpeedButtonState extends State<PlaySpeedButton> {
  final selection = [0.75, 0.85, 1.0, 1.25, 1.5, 2.0];
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      itemBuilder: (context) => selection
          .map((e) => PopupMenuItem<double>(
                value: e,
                child: Text(
                  '${e}x',
                  style: TextStyle(fontSize: widget.size, color: widget.color),
                ),
              ))
          .toList(),
      onSelected: (value) async {
        // debugPrint('speed: $value');
        await widget.player.setSpeed(value);
        setState(() {});
      },
      child: Text(
        '${widget.player.speed}x',
        style: TextStyle(fontSize: widget.size, color: widget.color),
      ),
    );
  }
}

enum TitleLayout { horizontal, vertical }

class BookTitle extends StatelessWidget {
  final CartaPlayer player;
  final TitleLayout? layout;
  const BookTitle(this.player, {this.layout, super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: player.currentIndexStream,
      builder: (context, snapshot) {
        final tag = player.getCurrentTag();
        final bookTitle = tag?.album ?? 'Unknown Title';
        final sectionTitle = tag?.title ?? '';

        switch (layout) {
          case TitleLayout.horizontal:
            return Text(
              '$bookTitle $sectionTitle',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            );
          default:
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  bookTitle,
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  sectionTitle,
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            );
        }
      },
    );
  }
}

class BookCover extends StatelessWidget {
  final CartaPlayer player;
  final double? size;
  const BookCover(this.player, {this.size, super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: player.currentIndexStream,
      builder: (context, snapshot) {
        final tag = player.getCurrentTag();
        return ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: tag != null && tag.artUri != null
              ? tag.artUri!.isScheme('file')
                  ? Image.file(File(tag.artUri!.toFilePath()),
                      height: size ?? 200, width: size ?? 200)
                  : Image.network(tag.artUri!.toString(),
                      height: size ?? 200, width: size ?? 200)
              : Container(),
        );
      },
    );
  }
}
