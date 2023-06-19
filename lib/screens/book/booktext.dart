import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../model/cartabook.dart';

class BookTextView extends StatefulWidget {
  final CartaBook book;
  const BookTextView({required this.book, super.key});

  @override
  State<BookTextView> createState() => BookTextViewState();
}

class BookTextViewState extends State<BookTextView> {
  late WebViewController _controller;
  late NavigationDelegate _delegate;

  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _delegate = NavigationDelegate(
      onPageStarted: (_) {
        // beware the order of the logic: call setState only when mounted
        if (mounted) {
          setState(() {
            _loading = true;
          });
        }
      },
      onPageFinished: (_) {
        // beware the order of the logic: call setState only when mounted
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
      },
    );

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(_delegate)
      ..loadRequest(Uri.parse(widget.book.info['textUrl']));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(
          controller: _controller,
          gestureRecognizers: {}..add(
              Factory<LongPressGestureRecognizer>(
                  () => LongPressGestureRecognizer()),
            ),
        ),
        _loading
            ? const Center(child: CircularProgressIndicator())
            : const SizedBox(width: 0, height: 0)
      ],
    );
  }
}
