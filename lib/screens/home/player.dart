import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/audiohandler.dart';
import '../../shared/settings.dart';
import 'widgets.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  RestartableTimer? _timer;

  @override
  void initState() {
    super.initState();

    // automatically dismiss the screen after a while
    _timer = RestartableTimer(
      const Duration(seconds: 30),
      () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  //
  // More Button
  //
  Widget _buildMoreButton(CartaAudioHandler handler) {
    return IconButton(
      icon: const Icon(Icons.more_horiz_rounded, size: 32.0),
      onPressed: () {
        _timer?.reset();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final handler = context.read<CartaAudioHandler>();

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 24.0,
        horizontal: 24.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // album image and title
          isScreenWide
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BookCover(handler, size: 60),
                    const SizedBox(width: 48.0),
                    BookTitle(handler),
                  ],
                )
              : Column(
                  children: [
                    BookTitle(handler),
                    const SizedBox(height: 16.0),
                    BookCover(handler),
                  ],
                ),
          // progress bar
          const SizedBox(height: 16.0),
          buildProgressBar(handler),
          // buttons
          Row(
            // mainAxisAlignment: MainAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: isScreenWide
                ? <Widget>[
                    buildSpeedSelector(handler, size: 18),
                    buildPreviousButton(handler, size: 36),
                    buildRewindButton(handler, size: 36),
                    buildPlayButton(handler, size: 48),
                    buildForwardButton(handler, size: 36),
                    buildNextButton(handler, size: 36),
                    _buildMoreButton(handler),
                  ]
                : <Widget>[
                    buildSpeedSelector(handler, size: 18),
                    buildRewindButton(handler, size: 36),
                    buildPlayButton(handler, size: 48),
                    buildForwardButton(handler, size: 36),
                    _buildMoreButton(handler),
                  ],
          ),
        ],
      ),
    );
  }
}
