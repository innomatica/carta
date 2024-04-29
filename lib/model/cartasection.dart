import 'dart:convert';

import '../shared/helpers.dart';

class CartaSection {
  int index;
  String title;
  String uri;
  // Duration? duration;
  int? duration;
  // int? seekPos;
  Map<String, dynamic> info;

  CartaSection({
    required this.index,
    required this.title,
    required this.uri,
    this.duration,
    // this.seekPos,
    required this.info,
  });

  factory CartaSection.fromDatabase(Map<String, dynamic> data) {
    return CartaSection(
      index: data['index'],
      title: data['title'] ?? 'Unknown',
      uri: data['uri'],
      duration: hmsToSeconds(data['duration']),
      // seekPos: data['seekPos'] ?? 0,
      info: jsonDecode(data['info']),
    );
  }

  Map<String, dynamic> toDatabase() {
    return {
      'index': index,
      'title': title,
      'uri': uri,
      'duration': secondsToHms(duration),
      // 'seekPos': seekPos ?? 0,
      'info': jsonEncode(info),
    };
  }

  @override
  String toString() {
    return toDatabase().toString();
  }
}
