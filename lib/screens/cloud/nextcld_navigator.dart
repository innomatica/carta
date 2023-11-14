import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/cartabloc.dart';
import '../../enc_dec.dart';
import '../../model/cartabook.dart';
import '../../model/cartasection.dart';
import '../../model/cartaserver.dart';
import '../../model/webdav.dart';
import '../../service/nextcloud.dart';
import '../../shared/helpers.dart';

class NextCloudNavigator extends StatefulWidget {
  final CartaServer server;
  const NextCloudNavigator({required this.server, super.key});

  @override
  State<NextCloudNavigator> createState() => _NextCloudNavigatorState();
}

class _NextCloudNavigatorState extends State<NextCloudNavigator> {
  late final CartaBloc bloc;
  late final String host;
  late final String user;
  late final String pass;

  String currentDir = '';

  @override
  void initState() {
    super.initState();
    bloc = context.read<CartaBloc>();
    host = widget.server.url;
    user = widget.server.settings?['username'] ?? '';
    pass = widget.server.settings?['password'] ?? '';
    currentDir = widget.server.settings?['directory'] ?? '';
  }

  //
  // parse files and returns CartaBook
  //
  CartaBook? _parseFiles(List<NextCloudResource> files) {
    final sections = <CartaSection>[];
    int index = 0;

    final path = currentDir.split('/').reversed;
    if (path.length < 2) {
      return null;
    }

    String bookTitle = path.elementAt(0);
    String author = path.elementAt(1);
    String? imageUri;
    // nextcloud specific
    // String urlPrefix = '$host/remote.php/dav/files/$user/$currentDir';
    String urlPrefix = host;

    for (final file in files) {
      final fileName = file.href.split('/').last;

      if (file.contentType?.primaryType == 'audio') {
        final section = CartaSection(
          index: index,
          title: fileName.split('.')[0],
          uri: '$urlPrefix/$fileName',
          info: {
            'authentication': 'basic',
            'username': encrypt(user),
            'password': encrypt(pass),
          },
        );
        sections.add(section);
        index++;
      } else if (file.contentType?.primaryType == 'image') {
        imageUri = '$urlPrefix/$fileName';
      }
    }

    if (sections.isEmpty) {
      return null;
    } else {
      return CartaBook(
        bookId: getIdFromUrl(urlPrefix),
        title: bookTitle,
        authors: author,
        imageUri: imageUri,
        source: CartaSource.cloud,
        sections: sections,
        info: {
          'source': widget.server.title,
          'authentication': 'basic',
          'username': user,
          'password': pass,
        },
      );
    }
  }

  //
  // book details dialog
  //
  Widget _buildBookDetailsDialog(CartaBook book) {
    String? title = book.title;
    String? author = book.authors;
    String? description;

    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            initialValue: title,
            decoration: const InputDecoration(label: Text('title')),
            onChanged: (value) => title = value,
          ),
          TextFormField(
            initialValue: author,
            decoration: const InputDecoration(label: Text('author(s)')),
            onChanged: (value) => author = value,
          ),
          TextFormField(
            maxLines: 5,
            decoration: const InputDecoration(label: Text('description')),
            onChanged: (value) => description = value,
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            if (title != null && title!.isNotEmpty) {
              book.title = title!;
            }
            if (author != null && author!.isNotEmpty) {
              book.authors = author;
            }
            if (description != null && description!.isNotEmpty) {
              book.description = description!;
            }
            await bloc.addAudioBook(book);
            if (!mounted) return;
            Navigator.of(context).pop(true);
          },
          child: const Text('Add to bookshelf'),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // debugPrint('currentDir: $currentDir');
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 110,
        leading: Row(
          children: [
            IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.keyboard_double_arrow_left_rounded,
                  size: 36, color: Theme.of(context).colorScheme.primary),
            ),
            IconButton(
              onPressed: () {
                if (currentDir == '') {
                  Navigator.of(context).pop();
                } else {
                  final parts = currentDir.split('/');
                  parts.removeLast();
                  currentDir = parts.join('/');
                  setState(() {});
                }
              },
              icon: Icon(Icons.keyboard_arrow_left_rounded,
                  size: 36, color: Theme.of(context).colorScheme.tertiary),
            ),
          ],
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.server.title),
            currentDir == ''
                ? const SizedBox(width: 0, height: 0)
                : Text(
                    currentDir,
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
          ],
        ),
      ),
      body: FutureBuilder<List<NextCloudResource>?>(
        future: NextCloudApiService.davPropfind(host, user, pass, currentDir),
        builder: ((context, snapshot) {
          bool foundAudioFiles = false;
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              final files = snapshot.data!;
              for (final file in files) {
                if (file.contentType?.primaryType == 'audio') {
                  foundAudioFiles = true;
                  break;
                }
              }

              return Stack(
                children: [
                  ListView.builder(
                    itemCount: files.length,
                    itemBuilder: ((context, index) {
                      final isDir = files[index].resourceType ==
                          WebDavResourceType.collection;
                      // current directory artifact specfic to Nextcloud
                      final curDirItem =
                          isDir && (files[index].href == currentDir);
                      foundAudioFiles = foundAudioFiles ||
                          files[index].contentType?.primaryType == 'audio';
                      // debugPrint('foundAudioFiles: $foundAudioFiles');

                      return curDirItem
                          // hide current directory
                          ? const SizedBox(width: 0, height: 0)
                          // normal files and folders
                          : ListTile(
                              minLeadingWidth: 20.0,
                              leading: isDir
                                  ? Icon(Icons.folder_rounded,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .tertiary)
                                  : Icon(
                                      getContentTypeIcon(
                                        files[index].contentType ??
                                            ContentType('text', 'html'),
                                      ),
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                              title: Text(files[index].href.split('/').last),
                              onTap: isDir
                                  ? () {
                                      // set the new directory
                                      currentDir = files[index].href;
                                      setState(() {});
                                    }
                                  : null,
                              onLongPress: null,
                            );
                    }),
                  ),
                  foundAudioFiles
                      ? Positioned(
                          bottom: 10,
                          right: 10,
                          child: FloatingActionButton.extended(
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add to my bookshelf'),
                            onPressed: () {
                              final book = _parseFiles(files);
                              // debugPrint('book: $book');
                              if (book != null) {
                                showDialog(
                                  context: context,
                                  builder: ((context) =>
                                      _buildBookDetailsDialog(book)),
                                ).then((flag) {
                                  if (flag == true) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Book is in the bookshelf'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'No audio book found in the directory'),
                                  ),
                                );
                              }
                            },
                          ),
                        )
                      : const SizedBox(width: 0, height: 0),
                ],
              );
            } else {
              return Center(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Failed to connect to the server',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(
                    height: 16.0,
                  ),
                  const Text(
                    'Go back and check the settings',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ));
            }
          } else {
            return const Center(
              child: SizedBox(
                width: 20.0,
                height: 20.0,
                child: CircularProgressIndicator(),
              ),
            );
          }
        }),
      ),
    );
  }
}
