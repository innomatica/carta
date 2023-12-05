import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../model/cartabook.dart';

class WebBookView extends StatefulWidget {
  final CartaBook book;
  const WebBookView(this.book, {super.key});

  @override
  State<WebBookView> createState() => _WebBookViewState();
}

class _WebBookViewState extends State<WebBookView> {
  late WebViewController _controller;
  late NavigationDelegate _delegate;

  @override
  void initState() {
    super.initState();
    _delegate = NavigationDelegate();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(_delegate)
      ..loadRequest(Uri.parse(widget.book.info['siteUrl']));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (_) async {
        if (await _controller.canGoBack()) {
          _controller.goBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.book.title,
            // maxLines: 2,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}
