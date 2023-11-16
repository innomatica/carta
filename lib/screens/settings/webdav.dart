import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/cartabloc.dart';
import '../../model/cartaserver.dart';
import '../../shared/helpers.dart';

class WebDavSettings extends StatefulWidget {
  final CartaServer? server;
  const WebDavSettings({this.server, super.key});

  @override
  State<WebDavSettings> createState() => _WebDavSettingsState();
}

class _WebDavSettingsState extends State<WebDavSettings> {
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  final _userController = TextEditingController();
  final _pswController = TextEditingController();
  final _dirController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late final CartaBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<CartaBloc>();
    if (widget.server != null) {
      _titleController.text = widget.server!.title;
      _urlController.text = widget.server!.url;
      _userController.text = widget.server!.settings?['username'] ?? '';
      _pswController.text = widget.server!.settings?['password'] ?? '';
      _dirController.text = widget.server!.settings?['directory'] ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _userController.dispose();
    _pswController.dispose();
    _dirController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // title
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              label: Text('title'),
              hintText: 'My Nextcloud Instance',
            ),
            validator: (value) {
              if (value == null || value.isEmpty == true) {
                return 'Please enter site title';
              }
              return null;
            },
          ),
          // url
          TextFormField(
            controller: _urlController,
            decoration: const InputDecoration(
              label: Text('site url'),
              hintText: 'https://my.nextcloud.domain',
            ),
            validator: (value) {
              if (value == null) {
                return 'Please enter url';
              } else if (!value.startsWith('http://') &&
                  !value.startsWith('https://')) {
                return 'url should start with "http://" or "https://"';
              }
              return null;
            },
          ),
          // user
          TextFormField(
            controller: _userController,
            decoration: const InputDecoration(label: Text('username')),
            validator: (value) {
              if (value == null || value.isEmpty == true) {
                return 'Please enter login username';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _pswController,
            obscureText: true,
            decoration: const InputDecoration(label: Text('password')),
            validator: (value) {
              if (value == null || value.isEmpty == true) {
                return 'Please enter password';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _dirController,
            decoration: const InputDecoration(
              label: Text('directory'),
              hintText: '/Media/MyAudioBooks',
            ),
          ),
          const SizedBox(height: 12.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: widget.server == null
                    ? null
                    : () {
                        _bloc.deleteBookServer(widget.server!);
                        ExpansionTileController.of(context).collapse();
                      },
                child: const Text('Delete Entry'),
              ),
              TextButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // dismiss screen keyboard
                    FocusManager.instance.primaryFocus?.unfocus();
                    final title = _titleController.text.trim();
                    final url = _urlController.text.trim();
                    final username = _userController.text.trim();
                    final password = _pswController.text.trim();
                    final dir = _dirController.text.trim();
                    if (widget.server == null) {
                      final server = CartaServer(
                          serverId: getIdFromUrl(url),
                          type: ServerType.nextcloud,
                          title: title,
                          // get rid of trailing slash
                          url: url.replaceAll(RegExp(r'/$'), ''),
                          settings: {
                            'authentication': 'basic',
                            'username': username,
                            'password': password,
                            // get rid of reading and trailing slash
                            'directory': dir.replaceAll(RegExp(r'^/|/$'), ''),
                          });
                      // debugPrint('server: ${server.toString()}');
                      _bloc.addBookServer(server);
                    } else {
                      widget.server!.title = title;
                      widget.server!.url = url;
                      widget.server!.settings = {
                        'authentication': 'basic',
                        'username': username,
                        'password': password,
                        'directory': dir.replaceAll(RegExp(r'^/|/$'), ''),
                      };
                      _bloc.updateBookServer(widget.server!);
                    }
                    // Navigator.of(context).pop();
                    ExpansionTileController.of(context).collapse();
                  }
                },
                child: const Text('Add/Update Entry'),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }
}
