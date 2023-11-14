import 'dart:convert';

enum ServerType { nextcloud, webdav, gdrive }

class CartaServer {
  String serverId;
  String title;
  ServerType type;
  String url;
  Map<String, dynamic>? settings;

  CartaServer({
    required this.serverId,
    required this.type,
    required this.title,
    required this.url,
    this.settings,
  });

  factory CartaServer.fromSqlite(Map<String, dynamic> data) {
    return CartaServer(
      serverId: data['serverId'],
      title: data['title'],
      type: ServerType.values[data['type'] ?? 0],
      url: data['url'],
      settings: jsonDecode(data['settings']),
    );
  }

  Map<String, dynamic> toSqlite() {
    return {
      'serverId': serverId,
      'title': title,
      'type': type.index,
      'url': url,
      'settings': jsonEncode(settings),
    };
  }

  @override
  String toString() {
    return toSqlite().toString();
  }
}
