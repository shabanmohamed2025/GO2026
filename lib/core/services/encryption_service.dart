import 'package:encrypt/encrypt.dart' as encrypt_lib;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EncryptionService {
  // Singleton pattern
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;

  late final String _keyString;
  late final String _ivString;

  late final encrypt_lib.Key _key;
  late final encrypt_lib.IV _iv;
  late final encrypt_lib.Encrypter _encrypter;

  EncryptionService._internal() {
    _keyString = dotenv.env['ENCRYPTION_KEY'] ?? 'fallback_32_char_key_do_not_use!';
    _ivString = dotenv.env['ENCRYPTION_IV'] ?? 'fallback_16_char';

    if (_keyString.length != 32 || _ivString.length != 16) {
      throw Exception('SECURITY ERROR: Invalid AES keys configuration in .env!');
    }

    _key = encrypt_lib.Key.fromUtf8(_keyString);
    _iv = encrypt_lib.IV.fromUtf8(_ivString);
    _encrypter = encrypt_lib.Encrypter(
      encrypt_lib.AES(
        _key,
        mode: encrypt_lib.AESMode.cbc,
        padding: 'PKCS7',
      ),
    );
  }

  /// Encrypts a plain string into an AES-256 base64 string
  String encryptData(String plainText) {
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  /// Decrypts an AES-256 base64 string back to arbitrary text
  String decryptData(String base64Text) {
    final encrypted = encrypt_lib.Encrypted.fromBase64(base64Text);
    return _encrypter.decrypt(encrypted, iv: _iv);
  }

  /// Decrypts a JSON payload safely
  Map<String, dynamic>? decryptJson(String base64Text) {
    try {
      final decryptedText = decryptData(base64Text);
      return json.decode(decryptedText) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}
