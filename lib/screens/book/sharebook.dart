import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../model/cartabook.dart';

class ShareBook extends StatelessWidget {
  final CartaBook book;
  const ShareBook({required this.book, super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(Icons.share_rounded),
      label: const Text('share'),
      onPressed: () {
        Share.share('Check out this book ${book.info['siteUrl']}',
            subject: 'A Book worth to read');
      },
    );
  }
}
