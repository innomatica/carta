import 'dart:convert';
import 'dart:developer';
import 'dart:io';

// import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../model/webdav.dart';

class WebDavService {
  static Future<List<WebDavResource>?> propFind(
    String host,
    String user,
    String pass,
    String libDir,
  ) async {
    // remove leading and trailing slash
    // libDir = libDir.replaceAll(RegExp(r'^/|/$'), '');
    final resources = <WebDavResource>[];
    // target url
    // final url = '$host/$libDir';
    // apache2 webdav redirection
    final url = '$host/$libDir/';
    // log('davPropfind.url.user.pass:$url, $user, $pass');

    final client = http.Client();
    final request = http.Request('PROPFIND', Uri.parse(url));
    final credential = base64Encode(utf8.encode('$user:$pass'));
    // header
    request.headers.addAll({
      HttpHeaders.authorizationHeader: 'Basic $credential',
      'content-type': 'text/xml',
      'Depth': '1', // includes files and directories in the target path
    });
    // body
    request.body = _getRequestXml('PROPFIND');
    // result
    http.StreamedResponse res;
    String body;
    // send request
    try {
      res = await client.send(request);
      body = await res.stream.transform(utf8.decoder).join();
      // log('body:$body');
      client.close();
    } catch (e) {
      log(e.toString());
      client.close();
      return null;
    }
    // accept only with status codes 200 and 207
    if (res.statusCode != 200 && res.statusCode != 207) {
      log('statusCode: ${res.statusCode}');
      // log('res: $res');
      // log('body: $body');
      return null;
    }
    // decode XML
    try {
      final xmlDoc = XmlDocument.parse(body);
      // log('xmlDoc: $xmlDoc');
      // iterate over all response elements
      for (final response
          in xmlDoc.rootElement.findElements('response', namespace: '*')) {
        String? href;
        DateTime? creationDate;
        String? displayName;
        String? contentLanguage;
        int? contentLength;
        ContentType? contentType;
        String? etag;
        DateTime? lastModified;
        WebDavResourceType? resourceType;
        for (final item in response.childElements) {
          if (item.name.local == 'href') {
            // D:href => http encoded
            href = Uri.decodeFull(item.innerText);
          } else if (item.name.local == 'propstat') {
            // D:propstat => D:prop + D:status
            for (final subItem in item.childElements) {
              if (subItem.name.local == 'status') {
                // D:status
                if (!subItem.innerText.contains('200')) {
                  // ignore if not 200 OK
                  continue;
                }
              } else if (subItem.name.local == 'prop') {
                // D:prop
                for (final subSubItem in subItem.childElements) {
                  // log('prop item:$subSubItem');
                  switch (subSubItem.name.local) {
                    case 'creationdate':
                      try {
                        creationDate = HttpDate.parse(subSubItem.innerText);
                      } catch (e) {
                        // log(subSubItem.innerText);
                        // probably ISO format(2023-10-09T01:27:53Z)
                        // log(e.toString());
                        creationDate = DateTime.tryParse(subSubItem.innerText);
                      }
                      break;
                    case 'displayname':
                      displayName = subSubItem.innerText.replaceAll('"', '');
                      break;
                    case 'getcontentlanguage':
                      contentLanguage =
                          subSubItem.innerText.replaceAll('"', '');
                      break;
                    case 'getcontentlength':
                      contentLength = int.tryParse(subSubItem.innerText);
                      break;
                    case 'getcontenttype':
                      final ctype = subSubItem.innerText;
                      contentType = ctype.contains('/')
                          ? ContentType(
                              ctype.split('/')[0], ctype.split('/')[1])
                          : null;
                      break;
                    case 'getetag':
                      etag = subSubItem.innerText.replaceAll('"', '');
                      break;
                    case 'getlastmodified':
                      try {
                        lastModified = HttpDate.parse(subSubItem.innerText);
                      } catch (e) {
                        // log(e.toString());
                        creationDate = DateTime.tryParse(subSubItem.innerText);
                      }
                      break;
                    case 'resourcetype':
                      if (subSubItem.innerXml.contains('collection')) {
                        resourceType = WebDavResourceType.collection;
                      }
                      break;
                  }
                }
              }
            }
          }
        }
        if (href != null && href.isNotEmpty) {
          // remove trailing slash
          href = href.replaceAll(RegExp(r'/$'), '');
          // in case webdav does not understand certain audio mime-types
          if (contentType == null) {
            if (href.endsWith('aac')) {
              contentType = ContentType('audio', 'x-aac');
            } else if (href.endsWith('flac')) {
              contentType = ContentType('audio', 'x-flac');
            } else if (href.endsWith('m4a')) {
              contentType = ContentType('audio', 'x-m4a');
            } else if (href.endsWith('m4b')) {
              contentType = ContentType('audio', 'x-m4b');
            }
          }
          resources.add(
            WebDavResource(
              // remove trailing slash
              href: href,
              creationDate: creationDate,
              displayName: displayName,
              contentLanguage: contentLanguage,
              contentLength: contentLength,
              contentType: contentType,
              etag: etag,
              lastModified: lastModified,
              resourceType: resourceType,
            ),
          );
          // log('resource: ${resources[resources.length - 1].toString()}');
        }
      }
    } catch (e) {
      // failed to parse xml body
      log(e.toString());
      return null;
    }
    resources.sort(((a, b) => (a.href).compareTo(b.href)));
    return resources;
  }

  static String _getRequestXml(String method) {
    String xml = '<?xml version="1.0" encoding="UTF-8"?>';
    if (method == 'PROPFIND') {
      xml = '$xml '
          '<D:propfind xmlns:D="DAV:">'
          ' <D:prop>'
          '   <D:creationdate />'
          '   <D:displayname />'
          '   <D:getcontentlanguage />'
          '   <D:getcontentlength />'
          '   <D:getcontenttype />'
          '   <D:getetag />'
          '   <D:getlastmodified />'
          '   <D:resourcetype />'
          ' </D:prop>'
          '</D:propfind>';
    }
    return xml;
  }
}
