import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/settings.dart';

class BookIntroView extends StatelessWidget {
  const BookIntroView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage(bookPanelBgndImage),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.8), BlendMode.dstATop),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                '\u{1f448} Tap the book icons to see the contents',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.tertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              child: const Text('Photo by Florencia Viadana on Unslpash'),
              onPressed: () async {
                await launchUrl(Uri.parse(urlStoreImageSource));
              },
            ),
          ],
        ),
      ),
    );
  }
}
