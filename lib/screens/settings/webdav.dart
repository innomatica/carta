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
  final _userController = TextEditingController();
  final _pswController = TextEditingController();
  final _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late final CartaBloc _bloc;

  ServerType? _serverType;
  String _urlHintText = '';
  bool hidePassword = true;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<CartaBloc>();
    if (widget.server != null) {
      _serverType = widget.server!.type;
      _titleController.text = widget.server!.title;
      // _siteController.text = widget.server!.url;
      _userController.text = widget.server!.settings?['username'] ?? '';
      _pswController.text = widget.server!.settings?['password'] ?? '';
      _urlController.text =
          widget.server!.url + widget.server!.settings?['directory'];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _userController.dispose();
    _pswController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _updateDavUrl() {
    if (_serverType == ServerType.nextcloud) {
      _urlController.text = "";
      _urlHintText =
          "https://cloud.example.com/remote.php/dav/files/${_userController.text}";
    } else if (_serverType == ServerType.koofr) {
      _urlController.text = "https://app.koofr.net/dav/Koofr";
      _urlHintText = "";
    } else if (_serverType == ServerType.webdav) {
      _urlController.text = "";
      _urlHintText = "https://cloud.example.com/webdav";
    }
  }

  String? _checkDavUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter valid WebDAV url';
    } else if (!value.startsWith('http')) {
      return 'url should start with http or https';
    } else {
      if (_serverType == ServerType.koofr &&
          !value.startsWith("https://app.koofr.net/dav/Koofr")) {
        return 'incorrect webdav url for Koofr';
      } else if (_serverType == ServerType.nextcloud &&
          !value.contains('remote.php/dav/files')) {
        return 'must contain /remote.php/dav/files';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          //
          // title
          //
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              label: Text('title'),
              hintText: 'My Cloud',
            ),
            validator: (value) {
              if (value == null || value.isEmpty == true) {
                return 'Please enter site title';
              }
              return null;
            },
          ),
          //
          // server type
          //
          DropdownButtonFormField(
            decoration: const InputDecoration(label: Text('server type')),
            validator: (value) {
              if (value == null) {
                return 'Please select server instance type';
              }
              return null;
            },
            value: _serverType,
            items: ServerType.values
                .map((e) =>
                    DropdownMenuItem<ServerType>(value: e, child: Text(e.name)))
                .toList(),
            onChanged: (ServerType? value) => setState(() {
              _serverType = value;
              _updateDavUrl();
            }),
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
          //
          // password
          //
          TextFormField(
            controller: _pswController,
            obscureText: hidePassword,
            decoration: InputDecoration(
              label: const Text('password'),
              suffixIcon: IconButton(
                onPressed: () => setState(() => hidePassword = !hidePassword),
                icon: const Icon(Icons.remove_red_eye),
                color: Theme.of(context)
                    .colorScheme
                    .secondary
                    .withAlpha(hidePassword ? 100 : 200),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty == true) {
                return 'Please enter password';
              }
              return null;
            },
          ),
          //
          // webdav url
          //
          TextFormField(
              controller: _urlController,
              decoration: InputDecoration(
                  label: const Text('webdav url'), hintText: _urlHintText),
              validator: _checkDavUrl),
          const SizedBox(height: 12.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              //
              // Delete Entry
              //
              ElevatedButton(
                onPressed: widget.server == null
                    ? null
                    : () {
                        _bloc.deleteBookServer(widget.server!);
                        ExpansionTileController.of(context).collapse();
                      },
                child: const Text('Delete Server'),
              ),
              //
              // Add Server
              //
              TextButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // dismiss screen keyboard
                    FocusManager.instance.primaryFocus?.unfocus();
                    final title = _titleController.text.trim();
                    final username = _userController.text.trim();
                    final password = _pswController.text.trim();
                    String url = _urlController.text.trim();
                    // get rid of trailing slash
                    url = url.replaceAll(RegExp(r'/$'), '');
                    int split = url.indexOf('/', 8);
                    String host = url;
                    String directory = '';
                    if (split != -1) {
                      host = url.substring(0, split);
                      directory = url.substring(split);
                    }
                    logDebug('host: $host, directory: $directory');
                    if (widget.server == null) {
                      final server = CartaServer(
                          serverId: getIdFromUrl(url),
                          type: _serverType!,
                          title: title,
                          // get rid of trailing slash
                          url: host,
                          settings: {
                            'authentication': 'basic',
                            'username': username,
                            'password': password,
                            // get rid of reading and trailing slash
                            'directory': directory,
                          });
                      logDebug('add server: $server');
                      _bloc.addBookServer(server);
                    } else {
                      widget.server!.title = title;
                      widget.server!.url = host;
                      widget.server!.settings = {
                        'authentication': 'basic',
                        'username': username,
                        'password': password,
                        'directory': directory,
                      };
                      logDebug('update server: ${widget.server}');
                      _bloc.updateBookServer(widget.server!);
                    }
                    // Navigator.of(context).pop();
                    ExpansionTileController.of(context).collapse();
                  }
                },
                child: const Text('Register / Update'),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }
}
