import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../logic/cartabloc.dart';
import '../../logic/screenconfig.dart';
import '../../model/cartabook.dart';
import '../../service/wikipedia.dart';
import '../../shared/settings.dart';
import 'deletebook.dart';
import 'sharebook.dart';

class BookInfoView extends StatefulWidget {
  final CartaBook book;
  const BookInfoView({required this.book, super.key});

  @override
  State<BookInfoView> createState() => _BookInfoViewState();
}

class _BookInfoViewState extends State<BookInfoView> {
  final _textUrlController = TextEditingController();
  final unescape = HtmlUnescape();

  @override
  void dispose() {
    _textUrlController.dispose();
    super.dispose();
  }

  //
  // Download Media Data Button
  //
  Widget _buildDownloadButton() {
    final bloc = context.watch<CartaBloc>();
    final localDataState = widget.book.getLocalDataState();
    final currentSection = localDataState.containsKey('sections')
        ? localDataState['sections'] + 1
        : 1;
    if (bloc.isDownloading(widget.book.bookId)) {
      // CANCEL
      return TextButton(
        onPressed: () {
          bloc.cancelDownload(widget.book.bookId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('download canceled')),
          );
        },
        // download progress
        child: Text(
          'Downloading section $currentSection'
          ' / ${widget.book.sections?.length}',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    } else {
      switch (localDataState['state']) {
        case LocalDataState.none:
          // DOWNLOAD
          return TextButton(
            onPressed: () => bloc.downloadMediaData(widget.book),
            child: const Text('Download media data'),
          );
        case LocalDataState.audioOnly:
        case LocalDataState.audioAndCoverImage:
          // DELETE MEDIA DATA
          return TextButton(
            onPressed: () async {
              await bloc.deleteMediaData(widget.book);
            },
            child: const Text('Delete local media data'),
          );
        default:
          return Container();
      }
    }
  }

  //
  // Text Source Button
  //
  Widget _buildTextSourceButton() {
    final screen = context.read<ScreenConfig>();

    if (widget.book.info['textUrl'] != null) {
      return Row(
        children: [
          Flexible(
            child: TextButton(
              child: Text(
                widget.book.info['textUrl'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onPressed: () {
                screen.setPanelView(BookPanelView.bookText);
              },
            ),
          ),
        ],
      );
    } else if (widget.book.sections != null &&
        widget.book.sections!.isNotEmpty &&
        widget.book.sections!.first.info['textUrl'] != null) {
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widget.book.sections!
              .map(
                (e) => TextButton(
                  child: Text(e.title),
                  onPressed: () {
                    screen.setPanelView(BookPanelView.bookText);
                  },
                ),
              )
              .toList());
    }
    return const Text('Book text not availble');
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontSize: 16.0,
      fontWeight: FontWeight.w500,
      color: Theme.of(context).colorScheme.tertiary,
    );
    final author =
        widget.book.authors == null ? '' : widget.book.authors!.split(',')[0];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // title
          ListTile(
            title: Text('Title', style: titleStyle),
            subtitle: Text(widget.book.title),
            onTap: () async {
              final url =
                  await WikipediaService.searchByKeyword(widget.book.title);
              launchUrl(Uri.parse(url));
            },
            trailing: isScreenWide
                ? SizedBox(
                    width: 200,
                    child: Row(
                      // mainAxisSize: MainAxisSize.min,
                      children: [
                        // SHARE
                        (widget.book.source == CartaSource.archive ||
                                widget.book.source == CartaSource.librivox)
                            ? ShareBook(book: widget.book)
                            : const SizedBox(width: 0, height: 0),
                        // DELETE
                        DeleteBook(book: widget.book),
                      ],
                    ),
                  )
                : const SizedBox(width: 0),
          ),

          // author
          ListTile(
            title: Text('Author(s)', style: titleStyle),
            subtitle: Text(author),
            onTap: () async {
              if (author.isNotEmpty &&
                  author != 'Various' &&
                  author != 'Internet Archive') {
                final url =
                    await WikipediaService.searchByKeyword(author.trim());
                launchUrl(Uri.parse(url));
              }
            },
          ),

          // source
          ListTile(
            title: Text('Source', style: titleStyle),
            subtitle: Text(widget.book.source.name),
            trailing: enableDownload ? _buildDownloadButton() : null,
            onTap: () async {
              try {
                await launchUrl(Uri.parse(widget.book.info['siteUrl']));
              } catch (e) {
                debugPrint(e.toString());
              }
            },
          ),

          // text source
          ListTile(
            title: Text('Text', style: titleStyle),
            subtitle: _buildTextSourceButton(),
          ),

          // description
          ListTile(
            title: Text('Description', style: titleStyle),
            subtitle: Text(unescape.convert(widget.book.description ?? '')),
          ),

          // bottom padding
          // https://github.com/flutter/flutter/issues/50314
          // SizedBox(
          //   height: bottomPadding,
          // )
        ],
      ),
    );
  }
}
