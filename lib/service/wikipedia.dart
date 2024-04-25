import 'dart:convert';

import 'package:http/http.dart' as http;

class WikipediaService {
  static const urlDesktop = 'https://en.wikipedia.org/wiki/Main_Page';
  static const urlMobile = 'https://en.m.wikipedia.org/wiki/Main_Page';
  static const urlSearch = 'https://en.wiipedia.org/w/api.php';

  static Future<String> searchByKeyword(String keyword) async {
    final refinedKeyword = keyword.split('(')[0].split(',')[0];

    final url = Uri(
      scheme: 'https',
      host: 'en.wikipedia.org',
      path: '/w/api.php',
      queryParameters: {
        'action': 'opensearch',
        'search': refinedKeyword,
        'limit': '1',
        'namespace': '0',
        'format': 'json'
      },
    );
    final res = await http.get(url);
    final data = jsonDecode(res.body);
    // logDebug('url:$url');
    // logDebug('res: $res');
    // logDebug('data: ${data.toString()}');
    return data[3].isEmpty ? urlMobile : data[3][0];
  }
}
