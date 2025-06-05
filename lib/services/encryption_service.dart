import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

class EncryptionService {
  static String encrypt(String plaintext, String base64Key) {
    try {
      final key = base64.decode(base64Key);
      final iv = _generateRandomBytes(12);

      final cipher = GCMBlockCipher(AESEngine());
      final params = AEADParameters(KeyParameter(key), 128, iv, Uint8List(0));
      cipher.init(true, params);

      final plaintextBytes = utf8.encode(plaintext);
      final ciphertext = cipher.process(plaintextBytes);
      final tag = cipher.mac;

      // Format: IV (12 bytes) + Tag (16 bytes) + Ciphertext
      final result = <int>[];
      result.addAll(iv);
      result.addAll(tag);
      result.addAll(ciphertext);

      return base64.encode(result);
    } catch (e) {
      print('Encryption error: $e');
      throw Exception('Encryption failed: $e');
    }
  }

  static String decrypt(String encryptedData, String base64Key) {
    try {
      final key = base64.decode(base64Key);
      final data = base64.decode(encryptedData);

      print('Decryption debug:');
      print('- Data length: ${data.length}');
      print('- Key length: ${key.length}');

      if (data.length < 28) {
        throw Exception('Invalid encrypted data length: ${data.length}');
      }

      final iv = data.sublist(0, 12);
      final tag = data.sublist(12, 28);
      final ciphertext = data.sublist(28);

      print('- IV length: ${iv.length}');
      print('- Tag length: ${tag.length}');
      print('- Ciphertext length: ${ciphertext.length}');

      // Method 1: Try standard approach
      try {
        final cipher = GCMBlockCipher(AESEngine());
        final params = AEADParameters(KeyParameter(key), 128, iv, Uint8List(0));
        cipher.init(false, params);

        // Append tag to ciphertext for GCM
        final input = <int>[];
        input.addAll(ciphertext);
        input.addAll(tag);

        final plaintext = cipher.process(Uint8List.fromList(input));
        final result = utf8.decode(plaintext);
        print('Method 1 success: $result');
        return result;
      } catch (e1) {
        print('Method 1 failed: $e1');

        // Method 2: Try alternative approach
        try {
          final cipher = GCMBlockCipher(AESEngine());
          final params = AEADParameters(KeyParameter(key), 128, iv, tag);
          cipher.init(false, params);

          final plaintext = cipher.process(ciphertext);
          final result = utf8.decode(plaintext);
          print('Method 2 success: $result');
          return result;
        } catch (e2) {
          print('Method 2 failed: $e2');
          throw Exception('Both decryption methods failed: $e1, $e2');
        }
      }
    } catch (e) {
      print('Decryption error: $e');
      throw Exception('Decryption failed: $e');
    }
  }

  static Uint8List _generateRandomBytes(int length) {
    final rnd = Random.secure();
    return Uint8List.fromList(List.generate(length, (i) => rnd.nextInt(256)));
  }

  // Helper method untuk debugging
  static void debugEncryptedData(String encryptedData) {
    try {
      final data = base64.decode(encryptedData);
      print('Encrypted data debug:');
      print('- Total length: ${data.length}');
      print('- IV (first 12 bytes): ${data.sublist(0, 12)}');
      print('- Tag (bytes 12-28): ${data.sublist(12, 28)}');
      print('- Ciphertext (rest): ${data.sublist(28)}');
      print('- Base64: $encryptedData');
    } catch (e) {
      print('Debug failed: $e');
    }
  }
}
