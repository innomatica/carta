import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/constants.dart';

class AppInfo extends StatelessWidget {
  const AppInfo({Key? key}) : super(key: key);

  String? _getStoreUrl() {
    if (Platform.isAndroid) {
      return urlGooglePlay;
    } else if (Platform.isIOS) {
      return urlAppStore;
    }
    return urlHomePage;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      children: [
        ListTile(
          title: Text(
            'Version',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          subtitle: const Text(appVersion),
        ),
        // ListTile(
        //   title: Text(
        //     'Questions and Answers',
        //     style: TextStyle(color: Theme.of(context).colorScheme.primary),
        //   ),
        //   subtitle: const Text('How to Use This App'),
        //   onTap: () {
        //     launchUrl(Uri.parse(urlInstruction),
        //         mode: LaunchMode.externalApplication);
        //   },
        // ),
        ListTile(
          title: Text(
            'Visit Our Store',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          subtitle: const Text('Review Apps, Report Bugs, Share Your Thoughts'),
          onTap: () {
            final url = _getStoreUrl();
            if (url != null) {
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            }
          },
        ),
        ListTile(
          title: Text(
            'Recommand to Others',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          subtitle: const Text('Show QR Code'),
          onTap: () {
            final url = _getStoreUrl();
            if (url != null) {
              showDialog(
                context: context,
                builder: (context) {
                  return SimpleDialog(
                    title: Center(
                      child: Text(
                        'Visit Our Store',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    // backgroundColor: Colors.white,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Image.asset(playStoreUrlQrCode),
                      )
                    ],
                  );
                },
              );
            }
          },
        ),
        ListTile(
          title: Text(
            'Want More Features?',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          subtitle: const Text('Check out Carta Plus'),
          onTap: () {
            launchUrl(Uri.parse(plusGooglePlay),
                mode: LaunchMode.externalApplication);
          },
        ),
        ListTile(
          title: Text(
            'Contact Us',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          subtitle: const Text(urlHomePage),
          onTap: () {
            launchUrl(Uri.parse(urlHomePage),
                mode: LaunchMode.externalApplication);
            // launchUrl(Uri(
            //   scheme: 'mailto',
            //   path: emailDeveloper,
            //   queryParameters: {'subject': 'Inquiry:$appName'},
            // ));
          },
        ),
      ],
    );
  }
}
