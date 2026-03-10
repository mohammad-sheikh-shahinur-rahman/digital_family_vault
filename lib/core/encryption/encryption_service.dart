import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  final _storage = const FlutterSecureStorage();
  static const _keyAlias = 'vault_encryption_key';

  Future<Key> _getOrCreateKey() async {
    String? storedKey = await _storage.read(key: _keyAlias);
    if (storedKey == null) {
      final key = Key.fromSecureRandom(32);
      await _storage.write(key: _keyAlias, value: key.base64);
      return key;
    }
    return Key.fromBase64(storedKey);
  }

  Future<Uint8List> encryptData(Uint8List data) async {
    final key = await _getOrCreateKey();
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key));

    final encrypted = encrypter.encryptBytes(data, iv: iv);
    
    // Combine IV and Encrypted Data: [IV (16 bytes)] + [Data]
    final combined = Uint8List(iv.bytes.length + encrypted.bytes.length);
    combined.setAll(0, iv.bytes);
    combined.setAll(iv.bytes.length, encrypted.bytes);
    
    return combined;
  }

  Future<Uint8List> decryptData(Uint8List combinedData) async {
    final key = await _getOrCreateKey();
    final iv = IV(combinedData.sublist(0, 16));
    final encryptedData = combinedData.sublist(16);
    
    final encrypter = Encrypter(AES(key));
    final decrypted = encrypter.decryptBytes(Encrypted(encryptedData), iv: iv);
    
    return Uint8List.fromList(decrypted);
  }
}
