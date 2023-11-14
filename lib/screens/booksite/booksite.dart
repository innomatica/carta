import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../logic/cartabloc.dart';
import '../../service/webpage.dart';
import '../../shared/booksites.dart';
import '../../shared/settings.dart';

class BookSitePage extends StatefulWidget {
  final String? url;
  const BookSitePage({this.url, super.key});

  @override
  State<BookSitePage> createState() => _BookSitePageState();
}

class _BookSitePageState extends State<BookSitePage> {
  late WebViewController _controller;
  late NavigationDelegate _delegate;

  bool _showFab = false;
  List<Map>? menuData;
  String? jsString;
  String? title;

  @override
  void initState() {
    super.initState();

    if (widget.url!.contains('librivox.org')) {
      menuData = bookSiteData[BookSite.librivox]?['menu'] as List<Map>;
      jsString = bookSiteData[BookSite.librivox]?['filterString'] as String;
      title = bookSiteData[BookSite.librivox]?['title'] as String;
    } else if (widget.url!.contains('archive.org')) {
      menuData = bookSiteData[BookSite.internetArchive]?['menu'] as List<Map>;
      jsString =
          bookSiteData[BookSite.internetArchive]?['filterString'] as String;
      title = bookSiteData[BookSite.internetArchive]?['title'] as String;
    } else if (widget.url!.contains('legamus.eu')) {
      menuData = bookSiteData[BookSite.legamus]?['menu'] as List<Map>;
      jsString = bookSiteData[BookSite.legamus]?['filterString'] as String;
      title = bookSiteData[BookSite.legamus]?['title'] as String;
    }

    _delegate = NavigationDelegate(
      onPageFinished: (_) async {
        // debugPrint('delegate.onPageFinished:$jsString');
        if (jsString != null) {
          final isBookPage =
              await _controller.runJavaScriptReturningResult(jsString!);
          _showFab = isBookPage == true ? true : false;
          setState(() {});
        }
      },
    );
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(_delegate)
      ..loadRequest(Uri.parse(widget.url ?? urlDefaultSearch));
  }

  //
  // Menu button
  //
  Widget _buildMenuButton() {
    return menuData == null
        ? const SizedBox(width: 0, height: 0)
        : PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              final url = menuData
                  ?.firstWhere((element) => element['value'] == value)['url'];
              if (url is String) {
                _controller.loadRequest(Uri.parse(url));
              } else {
                String? inputUrl;
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Enter Book Page Url'),
                    content: TextField(
                      onChanged: (value) => inputUrl = value,
                      decoration: const InputDecoration(
                        label: Text('url'),
                        hintText: urlLibriVoxDoHyangNa,
                      ),
                    ),
                    actions: [
                      ElevatedButton(
                        // minimal validation
                        onPressed: () {
                          if (inputUrl != null && inputUrl!.isNotEmpty) {
                            Navigator.of(context).pop(inputUrl);
                          }
                        },
                        child: const Text('O.K.'),
                      ),
                    ],
                  ),
                ).then((value) {
                  if (value is String) {
                    _controller.loadRequest(Uri.parse(value)).catchError((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invalid URL entered')));
                    });
                  }
                });
              }
            },
            itemBuilder: (context) => menuData!
                .map((entry) => PopupMenuItem<String>(
                    value: entry['value'],
                    child: Text(entry['title'] as String)))
                .toList(),
          );
  }

  //
  // FAB
  //
  Widget? _buildFab() {
    return _showFab
        ? FloatingActionButton.extended(
            onPressed: () async {
              final bloc = context.read<CartaBloc>();
              final url = await _controller.currentUrl();
              String message = 'Failed to get book information';
              if (url != null) {
                //
                // Grab entire HTML document from the webview
                //
                // THIS IS PROBLEMATIC. WAIT FOR FLUTTER FIXES THE BUG
                // https://github.com/flutter/flutter/issues/80328
                //
                // String html = await _controller.runJavascriptReturningResult(
                //     "window.document.getElementsByTagName('html')[0].outerHTML;");
                // final book = WebPageParser.getBookFromHtml(
                //   html: html
                //       .replaceAll(r'\u003C', '<')
                //       .replaceAll(r'\"', '"'),
                //   url: url,
                // );

                final book = await WebPageParser.getBookFromUrl(url);

                if (book != null) {
                  final res = await bloc.addAudioBook(book);
                  if (res) {
                    message = 'Book is created on the bookshelf';
                  } else {
                    message = 'Failed to add to the bookshelf';
                  }
                }
              }
              if (!mounted) return;
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(message)));
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add to my bookshelf'),
          )
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await _controller.canGoBack()) {
          _controller.goBack();
          return Future.value(false);
        } else {
          return Future.value(true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leadingWidth: 96,
          leading: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.keyboard_double_arrow_left_rounded,
                  size: 32,
                ),
              ),
              IconButton(
                onPressed: () async {
                  if (await _controller.canGoBack()) {
                    _controller.goBack();
                  } else if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(
                  Icons.keyboard_arrow_left_rounded,
                  size: 32,
                ),
              ),
            ],
          ),
          title: Text(title ?? 'Webpage'),
          actions: [_buildMenuButton()],
        ),
        body: WebViewWidget(controller: _controller),
        floatingActionButton: _buildFab(),
      ),
    );
  }
}
