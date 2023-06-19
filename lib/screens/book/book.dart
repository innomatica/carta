import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/screenconfig.dart';
import '../../model/cartabook.dart';
import 'bookpanel.dart';
import 'deletebook.dart';
import 'sharebook.dart';

//
// Page, parent for Book Panel in narrow screen device
//
class BookPage extends StatefulWidget {
  const BookPage({Key? key}) : super(key: key);

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  @override
  Widget build(BuildContext context) {
    final book = context.read<ScreenConfig>().book;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Details'),
        actions: [
          // SHARE
          book != null &&
                  (book.source == CartaSource.archive ||
                      book.source == CartaSource.librivox)
              ? ShareBook(book: book)
              : const SizedBox(width: 0, height: 0),
          // DELETE
          book != null
              ? DeleteBook(book: book)
              : const SizedBox(width: 0, height: 0),
        ],
      ),
      body: const BookPanel(),
    );
  }
}
