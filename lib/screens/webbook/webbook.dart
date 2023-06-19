import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../logic/cartabloc.dart';
import '../../model/cartabook.dart';

class WebBookPage extends StatefulWidget {
  final CartaBook book;
  const WebBookPage(this.book, {Key? key}) : super(key: key);

  @override
  State<WebBookPage> createState() => _WebBookPageState();
}

class _WebBookPageState extends State<WebBookPage> {
  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CartaBloc>();
    final titleStyle = TextStyle(
      fontSize: 16.0,
      fontWeight: FontWeight.w500,
      color: Theme.of(context).colorScheme.primary,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Web Page Link')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ListTile(
                title: Text(
                  'Title',
                  style: titleStyle,
                ),
                subtitle: Text(widget.book.title),
              ),
              ListTile(
                title: Text('Author(s)', style: titleStyle),
                subtitle: Text(widget.book.authors ?? ''),
              ),
              ListTile(
                title: Text('Source', style: titleStyle),
                subtitle: Text(widget.book.info['siteUrl']),
                onTap: () async {
                  await launchUrl(Uri.parse(widget.book.info['siteUrl']));
                },
              ),
              widget.book.info.containsKey('Description')
                  ? ListTile(
                      title: Text('description', style: titleStyle),
                      subtitle: Text(widget.book.info['description']),
                    )
                  : Container(),
              const SizedBox(height: 16.0),
              ElevatedButton(
                child: const Text('Remove link from the bookshelf'),
                onPressed: () async {
                  await bloc.deleteAudioBook(widget.book);
                  if (!mounted) return;
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
