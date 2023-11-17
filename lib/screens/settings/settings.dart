import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/cartabloc.dart';
import 'webdav.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const tilePadding = EdgeInsets.symmetric(horizontal: 16.0);
  Widget _buildBody() {
    final logic = context.watch<CartaBloc>();
    final servers = logic.servers;
    final titleStyle = TextStyle(color: Theme.of(context).colorScheme.tertiary);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView(
        children: [
          // WebDav Servers
          for (final server in servers)
            ExpansionTile(
              tilePadding: tilePadding,
              childrenPadding: tilePadding,
              title: Text(server.title, style: titleStyle),
              children: [WebDavSettings(server: server)],
            ),
          // add a WebDav server
          ExpansionTile(
            tilePadding: tilePadding,
            childrenPadding: tilePadding,
            title: Text('Register WebDAV Server', style: titleStyle),
            children: const [WebDavSettings()],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _buildBody(),
    );
  }
}
