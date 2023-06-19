import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
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

Duration? fromDurationString(String? time) {
  if (time != null) {
    final hms = time.split('.')[0].split(':');
    if (hms.length < 3) {
      return Duration.zero;
    }
    return Duration(
      hours: int.tryParse(hms[0]) ?? 0,
      minutes: int.tryParse(hms[1]) ?? 0,
      seconds: int.tryParse(hms[2]) ?? 0,
    );
  }
  return null;
}

String? toDurationString(Duration? duration) {
  if (duration != null) {
    return duration.toString().split('.')[0];
  }
  return null;
}

// application document directory
String? appDocDirPath;
