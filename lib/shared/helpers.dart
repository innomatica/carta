import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

IconData getContentTypeIcon(ContentType type) {
  switch (type.primaryType) {
    case 'application':
      if (type.subType == 'pdf') {
        return Icons.picture_as_pdf_rounded;
      } else {
        // return Icons.smartphone_rounded;
        return Icons.devices_rounded;
      }
    case 'audio':
      return Icons.music_note_rounded;
    case 'image':
      return Icons.image_rounded;
    case 'video':
      return Icons.movie_rounded;
    case 'text':
    default:
      return Icons.description_rounded;
  }
}

String removeTrailingSlash(String str) {
  return str.replaceAll(RegExp(r'/$'), '');
}

String getIdFromUrl(String url) {
  return sha1.convert(utf8.encode(url)).toString().substring(0, 20);
}

int? timeStringToSeconds(String? time) {
  if (time != null) {
    // expect hh:mm:ss.ms
    final hms = time.split('.')[0].split(':');
    if (hms.length < 3) {
      // invalid time string
      // return Duration.zero;
      return 0;
    }
    // return Duration(
    //   hours: int.tryParse(hms[0]) ?? 0,
    //   minutes: int.tryParse(hms[1]) ?? 0,
    //   seconds: int.tryParse(hms[2]) ?? 0,
    // );
    return (int.tryParse(hms[0]) ?? 0) * 3600 +
        (int.tryParse(hms[1]) ?? 0) * 60 +
        (int.tryParse(hms[2]) ?? 0);
  }
  return null;
}

String? secondsToTimeString(int? seconds) {
  if (seconds != null) {
    return '${seconds ~/ 3600}:${seconds ~/ 60}:${seconds % 60}';
  }
  return null;
}

// application document directory
String? appDocDirPath;

void logDebug(String text) =>
    kDebugMode ? debugPrint('\x1B[32m$text\x1B[0m') : () => {};
void logWarn(String text) => debugPrint('\x1B[33m$text\x1B[0m');
void logError(String text) => debugPrint('\x1B[31m$text\x1B[0m');
