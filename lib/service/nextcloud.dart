import 'dart:convert';
// import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../model/webdav.dart';

class NextCloudApiService {
  static Future<List<NextCloudResource>?> davPropfind(
    String host,
    String user,
    String pass,
    String libDir,
  ) async {
    // remove leading and trailing slash
    libDir = libDir.replaceAll(RegExp(r'^/|/$'), '');
    final files = <NextCloudResource>[];
    // Nextcloud file root
    final ncDirRoot = '/remote.php/dav/files/$user';
    // target url
    final url = '$host$ncDirRoot/$libDir';
    // debugPrint('davPropfind.url:$url');

    final client = http.Client();
    final request = http.Request('PROPFIND', Uri.parse(url));
    final credential = base64Encode(utf8.encode('$user:$pass'));
    // auth header
    request.headers.addAll({
      HttpHeaders.authorizationHeader: 'Basic $credential',
      'content-type': 'text/xml',
    });
    // body
    request.body = _getRequestXml('PROPFIND');

    http.StreamedResponse res;
    String body;

    try {
      res = await client.send(request);
      body = await res.stream.transform(utf8.decoder).join();
      // log('body:$body');
      client.close();
    } catch (e) {
      debugPrint(e.toString());
      client.close();
      return null;
    }

    // accept only with status codes 200 and 207
    if (res.statusCode != 200 && res.statusCode != 207) {
      debugPrint('statusCode: ${res.statusCode}');
      return null;
    }

    try {
      final xmlDoc = XmlDocument.parse(body);
      // log('xmlDoc: $xmlDoc');
      // iterate over d:response elements
      for (final response
          in xmlDoc.rootElement.findElements('response', namespace: '*')) {
        String? href;
        int? contentLength;
        ContentType? contentType;
        String? etag;
        DateTime? lastModified;
        WebDavResourceType? resourceType;
        int? id;
        int? fileId;
        int? favorite;
        int? size;
        String? ownerDisplayName;
        int? containedFolderCount;
        int? containedFileCount;
        String? permissions;
        for (final item in response.childElements) {
          if (item.name.local == 'href') {
            // decode is necessary as it is http encoded
            href = Uri.decodeFull(item.innerText);
            // remove Nextcloud file root prefix
            href = href.replaceFirst('$ncDirRoot/', '');
          } else if (item.name.local == 'propstat') {
            // propstat section: could be one or more
            for (final subItem in item.childElements) {
              if (subItem.name.local == 'status') {
                // stat section
                if (!subItem.innerText.contains('200')) {
                  // ignore if not 200 OK
                  continue;
                }
              } else if (subItem.name.local == 'prop') {
                // prop section
                for (final subSubItem in subItem.childElements) {
                  // debugPrint('prop item:$subSubItem');
                  switch (subSubItem.name.local) {
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
                      lastModified = HttpDate.parse(subSubItem.innerText);
                      break;
                    case 'resourcetype':
                      if (subSubItem.innerXml.contains('collection')) {
                        resourceType = WebDavResourceType.collection;
                      }
                      break;
                    //
                    // OpenCloud dialects
                    //
                    case 'id':
                      id = int.tryParse(subSubItem.innerText);
                      break;
                    case 'fileid':
                      fileId = int.tryParse(subSubItem.innerText);
                      break;
                    case 'favorite':
                      favorite = int.tryParse(subSubItem.innerText);
                      break;
                    case 'owner-display-name':
                      ownerDisplayName = subSubItem.innerText;
                      break;
                    case 'size':
                      size = int.tryParse(subSubItem.innerText);
                      break;
                    case 'permissions':
                      permissions = subSubItem.innerText;
                      break;
                    //
                    // NextCloud dialects
                    //
                    case 'contained-folder-count':
                      containedFolderCount = int.tryParse(subSubItem.innerText);
                      break;
                    case 'contained-file-count':
                      containedFileCount = int.tryParse(subSubItem.innerText);
                      break;
                    default:
                      break;
                  }
                }
              }
            }
          }
        }
        if (href != null && href.isNotEmpty) {
          files.add(
            NextCloudResource(
              // Nextcloud attaches trailing slash to directory resources
              // which can cause trouble
              href: href.replaceAll(RegExp(r'/$'), ''),
              contentLength: contentLength,
              contentType: contentType,
              etag: etag,
              lastModified: lastModified,
              resourceType: resourceType,
              // oc
              id: id,
              fileId: fileId,
              favorite: favorite,
              ownerDisplayName: ownerDisplayName,
              size: size,
              permissions: permissions,
              // nc
              containedFolderCount: containedFolderCount,
              containedFileCount: containedFileCount,
            ),
          );
        }
      }
    } catch (e) {
      // failed to parse xml body
      debugPrint(e.toString());
      return null;
    }
    return files;
  }

  static String _getRequestXml(String method) {
    String xml = '<?xml version="1.0" encoding="UTF-8"?>';
    if (method == 'PROPFIND') {
      xml = '$xml '
          '<d:propfind xmlns:d="DAV:"'
          '   xmlns:oc="http://owncloud.org/ns"'
          '   xmlns:nc="http://nextcloud.org/ns">'
          ' <d:prop>'
          // '   <d:creationdate />'
          // '   <d:displayname />'
          // '   <d:getcontentlanguage />'
          '   <d:getcontentlength />'
          '   <d:getcontenttype />'
          '   <d:getetag />'
          '   <d:getlastmodified />'
          '   <d:resourcetype />'
          '   <oc:id />'
          '   <oc:fileid />'
          '   <oc:favorite />'
          // '   <oc:comments-href />'
          // '   <oc:comments-count />'
          // '   <oc:comments-unread />'
          // '   <oc:owner-id />'
          '   <oc:owner-display-name />'
          // '   <oc:share-types />'
          // '   <oc:checksums />'
          // '   <nc:has-preview />'
          '   <oc:size />'
          // '   <nc:rich-workspace />'
          '   <nc:contained-folder-count />'
          '   <nc:contained-file-count />'
          '   <oc:permissions />'
          ' </d:prop>'
          '</d:propfind>';
    }
    return xml;
  }
}
