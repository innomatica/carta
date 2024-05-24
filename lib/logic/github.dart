import 'package:flutter/foundation.dart';
import 'package:github/github.dart';

import '../shared/helpers.dart';
import '../shared/settings.dart';

class CartaRepo extends ChangeNotifier {
  final _github = GitHub();

  Release? _latestRelease;
  late final int _currentVersion;
  int? _latestVersion;

  CartaRepo() {
    _currentVersion = int.parse(appVersion.split('+')[1]);
    _checkVersion();
  }

  Release? get latestRelease => _latestRelease;
  bool get newAvailable =>
      _latestVersion != null && (_latestVersion! > _currentVersion);
  String? get urlAsset => _latestRelease?.assets?[0].browserDownloadUrl;
  String? get urlRelease => _latestRelease?.htmlUrl;

  Future _checkVersion() async {
    try {
      _latestRelease = await _github.repositories
          .getLatestRelease(RepositorySlug(githubUser, githubRepo));
      // https://pub.dev/documentation/github/latest/github/Release-class.html
      final tag = _latestRelease?.tagName;
      if (tag != null && tag.contains('+')) {
        _latestVersion = int.tryParse(tag.split('+')[1]);
        logDebug(
            'latest version: $_latestVersion vs $_currentVersion : $newAvailable');
      }
    } catch (e) {
      logError(e.toString());
    }
    notifyListeners();
  }
}
