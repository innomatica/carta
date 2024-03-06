import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/cartabloc.dart';
import '../../logic/screenconfig.dart';
import '../../model/cartabook.dart';
import '../../service/audiohandler.dart';
import '../../shared/settings.dart';

class DeleteBook extends StatefulWidget {
  final CartaBook book;
  const DeleteBook({required this.book, super.key});

  @override
  State<DeleteBook> createState() => _DeleteBookState();
}

class _DeleteBookState extends State<DeleteBook> {
  late final CartaAudioHandler _handler;

  @override
  void initState() {
    super.initState();
    _handler = context.read<CartaAudioHandler>();
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: Icon(
        Icons.delete_rounded,
        color: Theme.of(context).colorScheme.error,
      ),
      label: Text(
        'delete',
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
      onPressed: () async {
        final screen = context.read<ScreenConfig>();
        final bloc = context.read<CartaBloc>();
        if (_handler.isCurrentBook(bookId: widget.book.bookId)) {
          await _handler.stop();
        }
        await bloc.deleteAudioBook(widget.book);
        screen.setBook(null);
        // if narrow screen, needs to pop out the page
        if (context.mounted && !isScreenWide) {
          Navigator.of(context).pop();
        }
      },
    );
  }
}
