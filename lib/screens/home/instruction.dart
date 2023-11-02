import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../model/cartabook.dart';
import '../../shared/constants.dart';
import '../../shared/settings.dart';

class Instruction extends StatefulWidget {
  const Instruction({super.key});

  @override
  State<Instruction> createState() => _InstructionState();
}

class _InstructionState extends State<Instruction> {
  bool? _addingBooks;

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary);
    const textStyle = TextStyle(fontSize: 16.0, fontWeight: FontWeight.w400);
    return _addingBooks == true
        ? Center(
            child: Text(
              'Adding books to bookshelf ...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Welcome to $appName', style: titleStyle),
              const SizedBox(height: 24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Navigate to ', style: textStyle),
                  CartaBook.getIconBySource(
                    CartaSource.librivox,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const Text(' LibriVox book pages', style: textStyle),
                ],
              ),
              const SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('or ', style: textStyle),
                  CartaBook.getIconBySource(
                    CartaSource.archive,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const Text(' Internet Archive book pages.', style: textStyle),
                ],
              ),
              const SizedBox(height: 8.0),
              const Text('And add books to your bookshelf', style: textStyle),
              const SizedBox(height: 24.0),
              const Text('Alternatively, you can', style: textStyle),
              const SizedBox(height: 12.0),
              ElevatedButton(
                child: const Text('Start with sample books'),
                onPressed: () async {
                  Navigator.of(context).pushNamed('/selected');
                },
              ),
              TextButton(
                child: const Text('Or read Instructions'),
                onPressed: () async {
                  launchUrl(Uri.parse(urlInstruction));
                },
              )
            ],
          );
  }
}
