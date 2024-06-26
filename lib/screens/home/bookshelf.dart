import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/cartabloc.dart';
import '../../logic/screenconfig.dart';
import '../../model/cartabook.dart';
import '../../shared/helpers.dart';
import '../../shared/settings.dart';
import '../book/book.dart';
import '../webbook/webbook.dart';
import '../webbook/webbookview.dart';

class BookShelf extends StatefulWidget {
  const BookShelf({super.key});

  @override
  State<BookShelf> createState() => _BookShelfState();
}

class _BookShelfState extends State<BookShelf> {
  //
  // Book View Button
  //
  Widget _buildTrailingWidget(CartaBook book) {
    // CartaBloc is here to trigger rebuild but no direct use
    // ignore: unused_local_variable
    final bloc = context.watch<CartaBloc>();
    final screen = context.read<ScreenConfig>();
    return IconButton(
      onPressed: () {
        switch (book.source) {
          // this type is not supported
          case CartaSource.internet:
            Navigator.of(context)
                .push(MaterialPageRoute(
                  builder: (context) => WebBookPage(book),
                ))
                .then((value) => setState(() {}));
            break;
          // all the other cases
          case CartaSource.cloud:
          case CartaSource.archive:
          case CartaSource.librivox:
          default:
            // set book data
            screen.setBook(book);
            // always return to the info view for the book panel
            // screen.setPanelView(BookPanelView.bookInfo);

            if (isScreenWide) {
              // wide screen
              if (screen.layout == ScreenLayout.library) {
                // switch to split screen
                screen.setLayout(ScreenLayout.split);
              }
            } else {
              // non wide screen: navigate to the book view page
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const BookPage(),
              ));
            }
        }
      },
      icon: book.getIcon(
        size: 28,
        color: Theme.of(context).colorScheme.tertiary,
      ),
    );
  }

  //
  // Section List Popup
  //
  Widget _buildBookSections(CartaBook book) {
    final logic = context.read<CartaBloc>();
    // logDebug('buildBookSections.bookId:${book.bookId}, '
    //     'lastSection:${book.lastSection}, lastPosition:${book.lastPosition}');
    return AlertDialog(
      //
      // book title
      //
      title: Text(
        book.title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.tertiary,
          fontSize: 17.0,
          fontWeight: FontWeight.w700,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      backgroundColor: Theme.of(context).dialogBackgroundColor.withOpacity(0.9),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      content: SizedBox(
        width: isScreenWide ? 600 : double.maxFinite,
        child: StreamBuilder<int?>(
          stream: logic.playbackState.map((e) => e.queueIndex).distinct(),
          builder: (context, snapshot) {
            // section list
            return ListView.builder(
              shrinkWrap: true,
              itemCount: book.sections?.length ?? 0,
              itemBuilder: (context, index) {
                final bool isCurrentBook = logic.currentBookId == book.bookId;
                // player section
                final bool isCurrentSection =
                    isCurrentBook && logic.currentSectionIdx == index;
                // book mark
                final bool hasBookmark =
                    book.lastSection == index && book.lastPosition != 0;
                // logDebug(
                //     'index:$index, isCurrentSection:$isCurrentSection, hasBookmark: $hasBookmark');
                return Container(
                  // decorator
                  decoration: BoxDecoration(
                      color: isCurrentSection
                          ? Theme.of(context).colorScheme.tertiaryContainer
                          : null,
                      border: hasBookmark && !isCurrentBook
                          ? Border.all(
                              color: Theme.of(context).colorScheme.outline)
                          : null,
                      borderRadius: BorderRadius.circular(5.0)),
                  //
                  // section title and play time
                  //
                  child: TextButton(
                    onPressed: () {
                      // return with the selected section index
                      Navigator.of(context).pop(index);
                    },
                    child: Row(
                      children: [
                        //
                        // section title
                        //
                        Expanded(
                          child: Text(
                            book.sections?[index].title ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              // saved section indicator (book)
                              fontSize: 15.0,
                              color: isCurrentSection
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onTertiaryContainer
                                  : null,
                            ),
                          ),
                        ),
                        //
                        // section duration
                        //
                        book.sections?[index].duration != null
                            ? Text(
                                // book.sections?[index].duration
                                //         ?.toString()
                                //         .split('.')[0] ??
                                //     '',
                                secondsToHms(book.sections?[index].duration),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isCurrentSection
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onTertiaryContainer
                                      : null,
                                  fontSize: 13.0,
                                ),
                              )
                            : const SizedBox(width: 0, height: 0),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  //
  // Book Card
  //
  Widget _buildBookCard(CartaBook book) {
    final logic = context.read<CartaBloc>();
    return StreamBuilder<MediaItem?>(
        stream: logic.mediaItem,
        builder: (context, snapshot) {
          final mediaItem = snapshot.data;
          final isCurrentBook =
              mediaItem != null && mediaItem.extras!['bookId'] == book.bookId;
          return Card(
            color: isCurrentBook
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
              // Cover Image
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Image(
                    image: book.getCoverImage(),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Book Title
              title: Text(
                book.title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isCurrentBook
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.secondary,
                ),
              ),
              // Author
              subtitle: Text(
                book.authors ?? '',
                overflow: TextOverflow.ellipsis,
              ),
              // Icon
              trailing: _buildTrailingWidget(book),
              onTap: () {
                if (book.source == CartaSource.internet) {
                  // WebPageBook => open webview : not supported now
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: ((context) => WebBookView(book)),
                  ));
                } else {
                  // All the other Books => show section list dialog
                  showDialog(
                    context: context,
                    builder: (context) => _buildBookSections(book),
                  ).then((value) async {
                    if (value != null) {
                      // directly play the section of the book
                      await logic.play(book, sectionIdx: value);
                      // switch to the book info ?
                      // this is not a good idea given the widget structure
                      // for example, if you go to the other part of the book
                      // while reading certain page, it will close the webview
                      // and display the book info immediately
                    }
                  });
                }
              },
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final logic = context.read<CartaBloc>();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      /*
      padding: EdgeInsets.only(
        top: 0.0,
        left: 6.0,
        right: 6.0,
        // this is required due to the years old flutter bug
        // https://github.com/flutter/flutter/issues/50314
        bottom: bottomPadding,
      ),
      */
      child: RefreshIndicator(
        onRefresh: () async {
          return Future(() => setState(() {}));
        },
        // needs to redraw whenever playing state changes
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: logic.books.length,
          itemExtent: 80.0,
          itemBuilder: (context, index) => _buildBookCard(logic.books[index]),
        ),
      ),
    );
  }
}
