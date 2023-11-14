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
  // Widget _buildDownloadButton() {
  //   final bloc = context.watch<CartaBloc>();
  //   final localDataState = widget.book.getLocalDataState();
  //   final currentSection = localDataState.containsKey('sections')
  //       ? localDataState['sections'] + 1
  //       : 1;
  //   if (bloc.isDownloading(widget.book.bookId)) {
  //     // CANCEL
  //     return TextButton(
  //       onPressed: () {
  //         bloc.cancelDownload(widget.book.bookId);
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('download canceled')),
  //         );
  //       },
  //       // download progress
  //       child: Text(
  //         'Downloading section $currentSection'
  //         ' / ${widget.book.sections?.length}',
  //         style: const TextStyle(color: Colors.grey),
  //       ),
  //     );
  //   } else {
  //     debugPrint('localDataState: ${localDataState['state']}');
  //     switch (localDataState['state']) {
  //       case LocalDataState.none:
  //         // DOWNLOAD
  //         return TextButton(
  //           onPressed: () => bloc.downloadMediaData(widget.book),
  //           child: const Text('Download media data'),
  //         );
  //       case LocalDataState.audioOnly:
  //       case LocalDataState.audioAndCoverImage:
  //       case LocalDataState.partial:
  //         // DELETE MEDIA DATA
  //         return TextButton(
  //           onPressed: () async {
  //             await bloc.deleteMediaData(widget.book);
  //           },
  //           child: const Text('Delete local media'),
  //         );
  //       default:
  //         return const SizedBox(width: 0, height: 0);
  //     }
  //   }
  // }

  Widget _buildCacheButton(CartaBloc logic) {
    final info = widget.book.info;
    final cached = info['cached'] == true;
    return TextButton(
      onPressed: () async {
        info['cached'] = !cached;
        final flag =
            await logic.updateBookData(widget.book.bookId, {'info': info});
        if (flag) {
          widget.book.info = info;
          setState(() {});
        }
      },
      child: Text(cached ? 'Download before play' : 'Cache disabled'),
    );
  }

  Future<String?> _editField(String title, String? initialValue,
      {int maxLines = 1}) async {
    return showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        controller.text = initialValue ?? '';
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          content: TextField(
            maxLines: maxLines,
            controller: controller,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
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
    final logic = context.read<CartaBloc>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          //
          // title
          //
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
                      mainAxisAlignment: MainAxisAlignment.end,
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
          //
          // author (editable)
          //
          ListTile(
            title: Text('Author(s)', style: titleStyle),
            subtitle: Text(widget.book.authors ?? ''),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final res =
                    await _editField('Edit Author(s)', widget.book.authors);
                if (res?.isNotEmpty == true) {
                  final flag = await logic
                      .updateBookData(widget.book.bookId, {'authors': res});
                  // update currnt view without rebuiling parent tree
                  if (flag) {
                    widget.book.authors = res;
                    setState(() {});
                  }
                }
              },
            ),
            onTap: () async {
              if (widget.book.authors?.isNotEmpty == true &&
                  widget.book.authors != 'Various' &&
                  widget.book.authors != 'Internet Archive') {
                final firstAuthor = widget.book.authors!.split(',')[0].trim();
                final url = await WikipediaService.searchByKeyword(firstAuthor);
                launchUrl(Uri.parse(url));
              }
            },
          ),
          //
          // image URL (editable)
          //
          ListTile(
            title: Text('Cover Image URL', style: titleStyle),
            subtitle: Text(widget.book.imageUri ?? '(empty)'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final res = await _editField(
                    'Edit Cover Image URL', widget.book.imageUri);
                if (res?.isNotEmpty == true) {
                  final flag = await logic
                      .updateBookData(widget.book.bookId, {'imageUri': res});
                  // update currnt view without rebuiling parent tree
                  if (flag) {
                    widget.book.imageUri = res;
                    setState(() {});
                  }
                }
              },
            ),
          ),
          //
          // source
          //
          ListTile(
            title: Text('Source', style: titleStyle),
            subtitle: Text(widget.book.source.name),
            // trailing: enableDownload ? _buildDownloadButton() : null,
            trailing: _buildCacheButton(logic),
            onTap: () async {
              try {
                await launchUrl(Uri.parse(widget.book.info['siteUrl']));
              } catch (e) {
                debugPrint(e.toString());
              }
            },
          ),
          //
          // text source
          //
          ListTile(
            title: Text('Text', style: titleStyle),
            subtitle: _buildTextSourceButton(),
          ),
          //
          // description (editable)
          //
          ListTile(
            title: Text('Description', style: titleStyle),
            subtitle: Text(unescape.convert(widget.book.description ?? '')),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final res = await _editField(
                  'Edit Book Description',
                  unescape.convert(widget.book.description ?? ''),
                  maxLines: 10,
                );
                if (res?.isNotEmpty == true) {
                  final flag = await logic
                      .updateBookData(widget.book.bookId, {'description': res});
                  // update currnt view without rebuiling parent tree
                  if (flag) {
                    widget.book.description = res;
                    setState(() {});
                  }
                }
              },
            ),
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
