import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../logic/cartabloc.dart';
import '../../logic/screenconfig.dart';
import '../../service/audiohandler.dart';
import '../../shared/constants.dart';
import '../../shared/settings.dart';
import '../about/about.dart';
import '../settings/settings.dart';
import '../book/bookpanel.dart';
import 'bookshelf.dart';
import 'fab.dart';
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
  Widget _buildScreenSelect() {
    final screen = context.read<ScreenConfig>();
    Icon btnIcon;
    const btnSize = 28.0;
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
    return IconButton(icon: btnIcon, onPressed: handler);
  }

  //
  // Sort Button
  //
  Widget _buildSortButton() {
    final logic = context.read<CartaBloc>();
    return IconButton(
      icon: Icon(
        logic.sortIcon,
        size: 30.0,
        color: Theme.of(context).colorScheme.tertiary,
      ),
      onPressed: () => logic.rotateSortBy(),
    );
  }

  //
  // Filter Button
  //
  Widget _buildFilterButton() {
    final logic = context.read<CartaBloc>();
    return IconButton(
      icon: Icon(
        logic.filterIcon,
        size: 26.0,
        color: Theme.of(context).colorScheme.tertiary,
      ),
      onPressed: () => logic.rotateFilterBy(),
    );
  }

  Widget? _buildTitleWidgets() {
    return isScreenWide
        ? Row(children: [
            _buildScreenSelect(),
            const SizedBox(width: 16.0),
            const Text(appName),
            const SizedBox(width: 16.0),
            _buildSortButton(),
            _buildFilterButton(),
          ])
        : const Text(appName);
  }

  List<Widget> _buildActionWidgets() {
    final handler = context.read<CartaAudioHandler>();
    return isScreenWide
        ? [
            _sleepTimer != null && _sleepTimer!.isActive
                ? _buildSleepTimerButton()
                : const SizedBox(width: 0, height: 0),
            _buildMenuButton(handler),
          ]
        : [
            _buildSortButton(),
            _buildFilterButton(),
            _sleepTimer != null && _sleepTimer!.isActive
                ? _buildSleepTimerButton()
                : const SizedBox(width: 0, height: 0),
            _buildMenuButton(handler),
          ];
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
        if (item == 'Set Sleep Timer') {
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
        } else if (item == 'Settings') {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsPage()));
        } else if (item == 'About') {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => const AboutPage()));
        }
      },
      itemBuilder: (context) => [
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
          value: 'Settings',
          child: Row(
            children: [
              Icon(Icons.settings_rounded,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8.0),
              const Text('Settings'),
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
  Widget? _buildBottomSheet() {
    final handler = context.read<CartaAudioHandler>();
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
      return const FirstLogin();
    } else if (isScreenWide) {
      // wide screen
      if (screen.layout == ScreenLayout.split) {
        // split view
        return const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 300,
              child: BookShelf(),
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
    return const BookShelf();
  }

  //
  // Floating Action Buttton
  //
  FloatingActionButton _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => buildFabDialog(context),
        );
      },
      backgroundColor:
          Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.8),
      child: const Icon(Icons.add),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildTitleWidgets(),
        actions: _buildActionWidgets(),
      ),
      body: _buildBody(),
      // https://github.com/flutter/flutter/issues/50314#issuecomment-1264861424
      // bottomSheet: _buildBottomSheet(player),
      bottomNavigationBar: _buildBottomSheet(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: isScreenWide
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.centerFloat,
    );
  }
}
