import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';


class EncryptedRealmStorage {
  final String _aes256Hex;
  final String _relativePath;

  EncryptedRealmStorage({
    @required String aes256Hex,
    String relativePath
  }) : this._aes256Hex = aes256Hex, this._relativePath = relativePath;

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File(path + this._relativePath);
  }

  Future<String> filePath() async {
    final file = await _localFile;
    await file.parent.create(recursive: true);
    return file.path;
  }

  Uint8List encryptionKey() {
    return hex.decode(this._aes256Hex);
  }

  static Uint8List generateKey() {
    int byteLength = 64;
    final values = List<int>.generate(byteLength, (i) => Random.secure().nextInt(256));
    return Uint8List.fromList(values);
  }

  static String generateKeyHex() {
    return hex.encode(generateKey());
  }

}