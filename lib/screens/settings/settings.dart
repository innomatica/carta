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
  Widget _buildBody() {
    final logic = context.watch<CartaBloc>();
    final servers = logic.servers;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView(
        children: [
          // WebDav Servers
          for (final server in servers)
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              title: Text(server.title),
              children: [WebDavSettings(server: server)],
            ),
          const ExpansionTile(
            tilePadding: EdgeInsets.symmetric(horizontal: 16.0),
            childrenPadding: EdgeInsets.symmetric(horizontal: 16.0),
            title: Text('Add a new WebDav server'),
            children: [WebDavSettings()],
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
