import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/settings.dart';
import '../../service/repository.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  Widget _buildBody() {
    final titleStyle = TextStyle(color: Theme.of(context).colorScheme.primary);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView(
        shrinkWrap: true,
        children: [
          // Version
          Consumer<CartaRepo>(
            builder: (context, repo, child) => ListTile(
              title: Text('Version', style: titleStyle),
              subtitle: Row(
                children: [
                  const Text(appVersion),
                  repo.newAvailable
                      ? Text(
                          '  (newer version available)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        )
                      : const SizedBox(width: 0.0),
                ],
              ),
              onTap: repo.newAvailable & (repo.urlRelease != null)
                  ? () => launchUrl(Uri.parse(repo.urlRelease!),
                      mode: LaunchMode.externalApplication)
                  : null,
            ),
          ),
          // Open Source
          ListTile(
            title: Text('Open Source', style: titleStyle),
            subtitle: const Text('Visit source repository'),
            onTap: () => launchUrl(Uri.parse(urlSourceRepo),
                mode: LaunchMode.externalApplication),
          ),
          // QR Code
          ListTile(
            title: Text('Repository QR Code', style: titleStyle),
            subtitle: const Text('Recommend to Others'),
            onTap: () {
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
                        child: Image.asset(sourceRepoUrlQrCode),
                      )
                    ],
                  );
                },
              );
            },
          ),
          // Carta Plus
          ListTile(
            title: Text('Communal Reading Experience', style: titleStyle),
            subtitle: const Text('Check out Carta Plus'),
            onTap: () => launchUrl(Uri.parse(urlSourcePlusRepo),
                mode: LaunchMode.externalApplication),
          ),
          // About
          ListTile(
            title: Text('About Us', style: titleStyle),
            subtitle: const Text(urlHomePage),
            onTap: () => launchUrl(Uri.parse(urlHomePage),
                mode: LaunchMode.externalApplication),
          ),
          // App Icons
          ListTile(
            title: Text('App Icons', style: titleStyle),
            subtitle: const Text("Book icons created by Freepik - Flaticon"),
            onTap: () => launchUrl(Uri.parse(urlAppIconSource),
                mode: LaunchMode.externalApplication),
          ),
          // Background Image
          ListTile(
            title: Text('Background Image', style: titleStyle),
            subtitle: const Text("Photo by Florencia Viadana at unsplash.com"),
            onTap: () => launchUrl(Uri.parse(urlStoreImageSource),
                mode: LaunchMode.externalApplication),
          ),
          // Disclaimer
          ListTile(
            title: Text('Disclaimer', style: titleStyle),
            subtitle: const Text('We assumes no responsibility for errors '
                'in the contents of the Service. (tap to see the full text).'),
            onTap: () => launchUrl(Uri.parse(urlDisclaimer),
                mode: LaunchMode.externalApplication),
          ),
          // Privacy
          ListTile(
            title: Text('Privacy Policy', style: titleStyle),
            subtitle: const Text('We only collect data essential for the '
                'service and do not share it with any third parties '
                '(tap to see the full text).'),
            onTap: () => launchUrl(Uri.parse(urlPrivacyPolicy),
                mode: LaunchMode.externalApplication),
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
