import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../logic/cartabloc.dart';
import '../../logic/screenconfig.dart';
import '../../model/cartabook.dart';
import '../../service/audiohandler.dart';
import '../../shared/booksites.dart';
import '../../shared/constants.dart';
import '../../shared/settings.dart';
import '../about/about.dart';
import '../book/bookpanel.dart';
import '../catalog/catalog.dart';
import '../booksite/booksite.dart';
import 'instruction.dart';
import 'library.dart';
import 'player.dart';
import 'widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _sleepTimer;
  int _sleepTimeout = sleepTimeouts[0];

  //
  // Screen Layout Select
  //
  Widget? _buildScreenSelect() {
    final screen = context.read<ScreenConfig>();
    Icon btnIcon;
    const btnSize = 32.0;
    final btnColor = Theme.of(context).colorScheme.tertiary;
    void Function() handler;

    if (screen.layout == ScreenLayout.library) {
      btnIcon = Icon(Icons.list_rounded, color: btnColor, size: btnSize);
      handler = () => screen.setLayout(ScreenLayout.split);
    } else if (screen.layout == ScreenLayout.split) {
      btnIcon =
          Icon(Icons.vertical_split_rounded, color: btnColor, size: btnSize);
      handler = () => screen.setLayout(ScreenLayout.book);
    } else {
      btnIcon = Icon(Icons.book_rounded, color: btnColor, size: btnSize);
      // switching to library view disrupts web view
      // handler = () => screen.setLayout(ScreenLayout.library);
      // instead back to split from book view
      handler = () => screen.setLayout(ScreenLayout.split);
    }

    return isScreenWide
        ? IconButton(
            icon: btnIcon,
            onPressed: handler,
          )
        : null;
  }

  //
  // Sleep Timer Button
  //
  Widget _buildSleepTimerButton() {
    return TextButton.icon(
      icon: const Icon(Icons.timelapse_rounded),
      label: Text((_sleepTimeout - _sleepTimer!.tick).toString()),
      onPressed: () {
        int index = sleepTimeouts.indexOf(_sleepTimeout);
        index = (index + 1) % sleepTimeouts.length;
        _sleepTimeout = sleepTimeouts[index];
        setState(() {});
      },
    );
  }

  //
  // Scaffold Menu Button
  //
  Widget _buildMenuButton(CartaAudioHandler handler) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.menu_rounded),
      onSelected: (String item) {
        if (item == 'LibriVox') {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) =>
                const BookSitePage(url: urlLibriVoxSearchByAuthor),
          ));
        } else if (item == 'Internet Archive') {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) =>
                const BookSitePage(url: urlInternetArchiveAudio),
          ));
        } else if (item == 'Legamus') {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) =>
                const BookSitePage(url: urlLegamusAllRecordings),
          ));
        } else if (item == 'Selected Books') {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const CatalogPage(),
          ));
        } else if (item == 'Set Sleep Timer') {
          if (_sleepTimer != null) {
            _sleepTimer!.cancel();
            _sleepTimer = null;
          }
          _sleepTimer = Timer.periodic(
            const Duration(minutes: 1),
            (timer) async {
              if (timer.tick == _sleepTimeout) {
                // timeout
                await handler.stop();
                _sleepTimer!.cancel();
                // is this safe?
                _sleepTimer = null;
              }
              setState(() {});
            },
          );
          setState(() {});
        } else if (item == 'Cancel Sleep Timer') {
          if (_sleepTimer != null) {
            _sleepTimer!.cancel();
            _sleepTimer = null;
          }
          setState(() {});
        } else if (item == 'How To') {
          launchUrl(Uri.parse(urlInstruction));
        } else if (item == 'About') {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => const AboutPage()));
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'LibriVox',
          child: Row(
            children: [
              CartaBook.getIconBySource(
                CartaSource.librivox,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8.0),
              const Text('LibriVox'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'Internet Archive',
          child: Row(
            children: [
              CartaBook.getIconBySource(
                CartaSource.archive,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8.0),
              const Text('Internet Archive'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'Legamus',
          child: Row(
            children: [
              CartaBook.getIconBySource(
                CartaSource.legamus,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8.0),
              const Text('Legamus'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'Selected Books',
          child: Row(
            children: [
              Icon(Icons.list_alt_rounded,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8.0),
              const Text('Selected Books'),
            ],
          ),
        ),
        PopupMenuItem(
          value: _sleepTimer != null && _sleepTimer!.isActive
              ? "Cancel Sleep Timer"
              : "Set Sleep Timer",
          child: Row(
            children: [
              Icon(Icons.timelapse_rounded,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              _sleepTimer != null && _sleepTimer!.isActive
                  ? const Text('Cancel Sleep Timer')
                  : const Text('Set Sleep Timer'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'How To',
          child: Row(
            children: [
              Icon(Icons.help_rounded,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8.0),
              const Text('How To'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'About',
          child: Row(
            children: [
              Icon(Icons.info_rounded,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8.0),
              const Text('About'),
            ],
          ),
        ),
      ],
    );
  }

  //
  // Scaffold.Bottomsheet
  //
  Widget? _buildBottomSheet(CartaAudioHandler handler) {
    // needs to redraw whenever the playing state changes
    return StreamBuilder<AudioProcessingState>(
      stream: handler.playbackState.map((e) => e.processingState).distinct(),
      builder: (context, snapshot) {
        if (snapshot.hasData &&
            [
              AudioProcessingState.loading,
              AudioProcessingState.buffering,
              AudioProcessingState.ready,
            ].contains(snapshot.data)) {
          return Container(
            color: Theme.of(context).colorScheme.surfaceVariant,
            padding: const EdgeInsets.only(
              left: 8.0,
              right: 8.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      showModalBottomSheet(
                        isScrollControlled: true,
                        context: context,
                        builder: (context) => const PlayerScreen(),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10.0),
                            topRight: Radius.circular(10.0),
                          ),
                        ),
                      ).then((value) => setState(() {}));
                    },
                    child: BookTitle(handler, layout: TitleLayout.horizontal),
                  ),
                ),
                isScreenWide
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          buildPreviousButton(handler),
                          buildRewindButton(handler),
                          buildPlayButton(handler),
                          buildForwardButton(handler),
                          buildNextButton(handler),
                        ],
                      )
                    : buildPlayButton(handler),
              ],
            ),
          );
        }
        return const SizedBox(height: 0);
      },
    );
  }

  //
  // Scaffold.Body
  //
  Widget _buildBody() {
    final books = context.watch<CartaBloc>().books;
    final screen = context.watch<ScreenConfig>();
    // debugPrint('home.body screen.layout: ${screen.layout}');
    // debugPrint('home.body isWide: ${screen.isWide}');

    if (books.isEmpty) {
      // no books
      return const Instruction();
    } else if (isScreenWide) {
      // wide screen
      if (screen.layout == ScreenLayout.split) {
        // split view
        return const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 300,
              child: Library(),
            ),
            Expanded(child: BookPanel()),
          ],
        );
      } else if (screen.layout == ScreenLayout.book) {
        // book panel only
        return const BookPanel();
      }
    }
    // library view
    return const Library();
  }

  @override
  Widget build(BuildContext context) {
    final handler = context.read<CartaAudioHandler>();

    return Scaffold(
      appBar: AppBar(
        leading: _buildScreenSelect(),
        title: const Text(appName),
        actions: [
          _sleepTimer != null && _sleepTimer!.isActive
              ? _buildSleepTimerButton()
              : Container(),
          _buildMenuButton(handler),
        ],
      ),
      body: _buildBody(),
      // https://github.com/flutter/flutter/issues/50314#issuecomment-1264861424
      // bottomSheet: _buildBottomSheet(player),
      bottomNavigationBar: _buildBottomSheet(handler),
    );
  }
}
