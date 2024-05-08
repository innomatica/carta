import 'package:async/async.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// import '../../service/audiohandler.dart';
import '../../logic/cartabloc.dart';
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
  Widget _buildMoreButton(CartaBloc logic) {
    return IconButton(
      icon: const Icon(Icons.more_horiz_rounded, size: 32.0),
      onPressed: () {
        _timer?.reset();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final logic = context.read<CartaBloc>();
    return StreamBuilder<MediaItem?>(
      stream: logic.mediaItem,
      builder: (context, snapshot) => snapshot.hasData
          ? Padding(
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
                            BookCover(logic, size: 60),
                            const SizedBox(width: 48.0),
                            BookTitle(logic),
                          ],
                        )
                      : Column(
                          children: [
                            BookTitle(logic),
                            const SizedBox(height: 16.0),
                            BookCover(logic),
                          ],
                        ),
                  // progress bar
                  const SizedBox(height: 16.0),
                  buildProgressBar(logic),
                  // buttons
                  Row(
                    // mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: isScreenWide
                        ? <Widget>[
                            buildSpeedSelector(logic, size: 18),
                            buildPreviousButton(logic, size: 36),
                            buildRewindButton(logic, size: 36),
                            buildPlayButton(logic, size: 48),
                            buildForwardButton(logic, size: 36),
                            buildNextButton(logic, size: 36),
                            _buildMoreButton(logic),
                          ]
                        : <Widget>[
                            buildSpeedSelector(logic, size: 18),
                            buildRewindButton(logic, size: 36),
                            buildPlayButton(logic, size: 48),
                            buildForwardButton(logic, size: 36),
                            _buildMoreButton(logic),
                          ],
                  ),
                ],
              ),
            )
          : const SizedBox(height: 0.0),
    );
  }
}
