import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/cartabloc.dart';
import '../../logic/screenconfig.dart';
import 'bookinfo.dart';
import 'bookintro.dart';
import 'booktext.dart';

// Do not remove this: it is require to maintain the state of BookTextView
// over the different screen layouts
final textViewKey = GlobalKey<BookTextViewState>();

//
// Book Panel:
//  * for narrow screen devices it goes under BookPage
//  * for wide screen devices it goes under HomePage
//
class BookPanel extends StatefulWidget {
  const BookPanel({super.key});

  @override
  State<BookPanel> createState() => _BookPanelState();
}

class _BookPanelState extends State<BookPanel> {
  @override
  Widget build(BuildContext context) {
    final screen = context.watch<ScreenConfig>();
    final bloc = context.read<CartaBloc>();
    // show details of the selected book or the first one on the list
    final book =
        screen.book ?? (bloc.books.isNotEmpty ? bloc.books.first : null);
    final view = screen.panelView;

    return book == null
        ? const BookIntroView() // no book
        : view == BookPanelView.bookText && book.info['textUrl'] is String
            ? BookTextView(book: book, key: textViewKey)
            : BookInfoView(book: book); // show book info
  }
}
