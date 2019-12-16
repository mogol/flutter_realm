import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_realm_example/helpers/encrypted_realm_storage.dart';

void main() {
  group('Encryption', () {

    test('aes256 hex encoded string should decode to 64 bytes Uint8List', () {
      final storage = EncryptedRealmStorage(aes256Hex: '5870cce530afbb10cf55604bf28693921e540bd1dc75c3df8f6a9dd55c1633707b50727d9c0b0f2326469cfba08feb28fd444b5b290a39a8544ee2332eea1d4b');
      expect(storage.encryptionKey(), [88, 112, 204, 229, 48, 175, 187, 16, 207, 85, 96, 75, 242, 134, 147, 146, 30, 84, 11, 209, 220, 117, 195, 223, 143, 106, 157, 213, 92, 22, 51, 112, 123, 80, 114, 125, 156, 11, 15, 35, 38, 70, 156, 251, 160, 143, 235, 40, 253, 68, 75, 91, 41, 10, 57, 168, 84, 78, 226, 51, 46, 234, 29, 75]);
    });

    test('generated aes256 hex encoded string length should be 128 characters', () {
      final hex = EncryptedRealmStorage.generateKeyHex();
      expect(hex, hasLength(128));
    });

    test('generated aes256 hex strings should be random', () {
      final hexStrings = <String>[];
      for (var i = 0; i < 10; i++) {
        final hex = EncryptedRealmStorage.generateKeyHex();
        expect(hexStrings, isNot(contains(hex)));
        hexStrings.add(hex);
      }
    });

  });
}