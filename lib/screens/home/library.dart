import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/cartabloc.dart';
import '../../logic/screenconfig.dart';
import '../../model/cartabook.dart';
import '../../service/audiohandler.dart';
import '../../shared/settings.dart';
import '../book/book.dart';
import '../webbook/webbook.dart';
import '../webbook/webbookview.dart';

class Library extends StatefulWidget {
  const Library({super.key});

  @override
  State<Library> createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
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
    final handler = context.read<CartaAudioHandler>();
    // debugPrint(book.toString());
    return AlertDialog(
      // book title
      title: Text(
        book.title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.tertiary,
          fontSize: 16.0,
          fontWeight: FontWeight.w700,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      backgroundColor: Theme.of(context).dialogBackgroundColor.withOpacity(0.9),
      content: SizedBox(
        width: isScreenWide ? 600 : double.maxFinite,
        child: StreamBuilder<int?>(
          stream: handler.playbackState.map((e) => e.queueIndex).distinct(),
          builder: (context, snapshot) {
            // section list
            return ListView.builder(
              shrinkWrap: true,
              itemCount: book.sections?.length ?? 0,
              itemBuilder: (context, index) {
                final bool isCurrentBook =
                    handler.isCurrentBook(bookId: book.bookId);
                // player section
                final bool isCurrentSection = handler.isCurrentSection(
                    bookId: book.bookId, sectionIdx: index);
                // book mark
                final bool hasBookMark = book.lastSection == index &&
                    book.lastPosition != Duration.zero;
                // debugPrint(
                //     'index:$index, isCurrentSection:$isCurrentSection, hasBookMark: $hasBookMark');
                return Container(
                  // decorator
                  decoration: BoxDecoration(
                      color: isCurrentSection
                          ? Theme.of(context).colorScheme.tertiaryContainer
                          : null,
                      border: hasBookMark && !isCurrentBook
                          ? Border.all(
                              color: Theme.of(context).colorScheme.outline)
                          : null,
                      borderRadius: BorderRadius.circular(5.0)),
                  // section title and play time
                  child: TextButton(
                    onPressed: () {
                      // return with the selected section index
                      Navigator.of(context).pop(index);
                    },
                    child: Row(
                      children: [
                        // section title
                        Expanded(
                          child: Text(
                            book.sections?[index].title ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              // saved section indicator (book)
                              color: isCurrentSection
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onTertiaryContainer
                                  : null,
                            ),
                          ),
                        ),
                        // section duration
                        book.sections?[index].duration != null
                            ? Text(
                                book.sections?[index].duration
                                        ?.toString()
                                        .split('.')[0] ??
                                    '',
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
  Widget _buildBookCard(CartaBook book, bool isPlaying) {
    return Card(
      color: isPlaying ? Theme.of(context).colorScheme.primaryContainer : null,
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
            color: isPlaying
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
          final handler = context.read<CartaAudioHandler>();

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
                await handler.playAudioBook(book, sectionIdx: value);
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
  }

  @override
  Widget build(BuildContext context) {
    final books = context.watch<CartaBloc>().books;
    final handler = context.read<CartaAudioHandler>();

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
        child: StreamBuilder<bool>(
          stream: handler.playbackState.map((e) => e.playing).distinct(),
          builder: (context, snapshot) {
            return ListView.builder(
              shrinkWrap: true,
              itemCount: books.length,
              itemExtent: 80.0,
              itemBuilder: (context, index) => _buildBookCard(
                books[index],
                handler.isCurrentBook(bookId: books[index].bookId),
              ),
            );
          },
        ),
      ),
    );
  }
}
