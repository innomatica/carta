import 'package:encrypt/encrypt.dart' as enc;
import 'secrets.dart';

String encrypt(String value) {
  final key = enc.Key.fromBase64(keyString);
  // https://github.com/leocavalcante/encrypt/issues/314
  // final iv = enc.IV.fromLength(16);
  final iv = enc.IV.allZerosOfLength(16);
  final encrypter = enc.Encrypter(enc.AES(key));

  return encrypter.encrypt(value, iv: iv).base64;
}

String decrypt(String value) {
  final key = enc.Key.fromBase64(keyString);
  // https://github.com/leocavalcante/encrypt/issues/314
  // final iv = enc.IV.fromLength(16);
  final iv = enc.IV.allZerosOfLength(16);
  final encrypter = enc.Encrypter(enc.AES(key));

  return encrypter.decrypt(enc.Encrypted.fromBase64(value), iv: iv);
}
