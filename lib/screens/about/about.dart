import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/constants.dart';
import '../../shared/settings.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String? _getStoreUrl() {
    if (Platform.isAndroid) {
      return urlGooglePlay;
    } else if (Platform.isIOS) {
      return urlAppStore;
    }
    return urlHomePage;
  }

  Widget _buildBody() {
    final titleStyle = TextStyle(color: Theme.of(context).colorScheme.primary);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView(
        shrinkWrap: true,
        children: [
          // Version
          ListTile(
            title: Text('Version', style: titleStyle),
            subtitle: const Text(appVersion),
          ),
          // Open Source
          ListTile(
            title: Text('Open Source', style: titleStyle),
            subtitle: const Text('Visit source repository'),
            onTap: () => launchUrl(Uri.parse(urlSourceRepo)),
          ),
          // Play Store
          ListTile(
            title: Text('Play Store', style: titleStyle),
            subtitle: const Text('Review Apps, Report Bugs'),
            onTap: () {
              final url = _getStoreUrl();
              if (url != null) {
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              }
            },
          ),
          // QR Code
          ListTile(
            title: Text('Play Store QR Code', style: titleStyle),
            subtitle: const Text('Recommend to Others'),
            onTap: () {
              final url = _getStoreUrl();
              if (url != null) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return SimpleDialog(
                      title: Center(
                        child: Text('Visit Our Store', style: titleStyle),
                      ),
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
          // Carta Plus
          ListTile(
            title: Text('Communal Reading Experience', style: titleStyle),
            subtitle: const Text('Check out Carta Plus'),
            onTap: () => launchUrl(Uri.parse(plusGooglePlay)),
          ),
          // About
          ListTile(
            title: Text('About Us', style: titleStyle),
            subtitle: const Text(urlHomePage),
            onTap: () => launchUrl(Uri.parse(urlHomePage)),
          ),
          // App Icons
          ListTile(
            title: Text('App Icons', style: titleStyle),
            subtitle: const Text("Book icons created by Freepik - Flaticon"),
            onTap: () => launchUrl(Uri.parse(urlAppIconSource)),
          ),
          // Store Image
          ListTile(
            title: Text('Store Background Image', style: titleStyle),
            subtitle: const Text("Photo by Florencia Viadana at unsplash.com"),
            onTap: () => launchUrl(Uri.parse(urlStoreImageSource)),
          ),
          // Disclaimer
          ListTile(
            title: Text('Disclaimer', style: titleStyle),
            subtitle: const Text('We assumes no responsibility for errors '
                'in the contents of the Service. (tap to see the full text).'),
            onTap: () => launchUrl(Uri.parse(urlDisclaimer)),
          ),
          // Privacy
          ListTile(
            title: Text('Privacy Policy', style: titleStyle),
            subtitle: const Text('We only collect data essential for the '
                'service and do not share it with any third parties '
                '(tap to see the full text).'),
            onTap: () => launchUrl(Uri.parse(urlPrivacyPolicy)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: const Text('About'),
      ),
      body: _buildBody(),
    );
  }
}
