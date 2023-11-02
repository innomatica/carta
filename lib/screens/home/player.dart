import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/cartaplayer.dart';
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
  Widget _buildMoreButton(CartaPlayer player) {
    return IconButton(
      icon: const Icon(Icons.more_horiz_rounded, size: 32.0),
      onPressed: () {
        _timer?.reset();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = context.read<CartaPlayer>();

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
                    BookCover(player, size: 60),
                    const SizedBox(width: 48.0),
                    BookTitle(player),
                  ],
                )
              : Column(
                  children: [
                    BookTitle(player),
                    const SizedBox(height: 8.0),
                    BookCover(player),
                  ],
                ),
          // progress bar
          ProgressSlider(player),
          // buttons
          Row(
            // mainAxisAlignment: MainAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: isScreenWide
                ? <Widget>[
                    PlaySpeedButton(player, size: 18),
                    PreviousButton(player, size: 36),
                    Rewind30Button(player, size: 36),
                    PlayButton(player, size: 48),
                    Forward30Button(player, size: 36),
                    NextButton(player, size: 36),
                    _buildMoreButton(player),
                  ]
                : <Widget>[
                    PlaySpeedButton(player, size: 18),
                    Rewind30Button(player, size: 36),
                    PlayButton(player, size: 48),
                    Forward30Button(player, size: 36),
                    _buildMoreButton(player),
                  ],
          ),
        ],
      ),
    );
  }
}
