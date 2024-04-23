import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/cartabloc.dart';
import '../../logic/screenconfig.dart';
import '../../model/cartabook.dart';
import '../../shared/settings.dart';

class DeleteBook extends StatefulWidget {
  final CartaBook book;
  const DeleteBook({required this.book, super.key});

  @override
  State<DeleteBook> createState() => _DeleteBookState();
}

class _DeleteBookState extends State<DeleteBook> {
  @override
  void initState() {
    super.initState();
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
