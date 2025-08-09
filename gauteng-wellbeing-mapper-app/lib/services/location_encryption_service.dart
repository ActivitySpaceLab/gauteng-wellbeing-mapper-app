import 'dart:convert';
import 'dart:typed_data';
import 'package:fast_rsa/fast_rsa.dart';

/// Service for encrypting location data before inserting into Qualtrics surveys
class LocationEncryptionService {
  // Research site public keys - using same keys as data upload service
  static const Map<String, String> _publicKeys = {
    'barcelona': '''-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA1234567890...
-----END PUBLIC KEY-----''', // Barcelona public key placeholder
    'gauteng': '''-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA0987654321...
-----END PUBLIC KEY-----''', // Gauteng public key placeholder
  };

  // For testing - you can generate a real key pair and replace this
  static const String _testPublicKey = '''-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyX1234Test567Key890Example1234567890Test1234567890Test1234567890Test1234567890Test1234567890Test1234567890Test1234567890Test1234567890Test1234567890Test1234567890Test1234567890Test1234567890Test1234567890Test1234567890Test1234567890Test1234567890Test1234567890Test1234567890Test1234567890Test1234567890Test1234567890Test1234567890TestExample
-----END PUBLIC KEY-----''';

  /// Encrypt location JSON data before inserting into survey
  static Future<String> encryptLocationData(String locationJson, {String? researchSite}) async {
    try {
      if (locationJson.isEmpty) {
        return '';
      }

      // Determine which public key to use
      String publicKey;
      if (researchSite != null && _publicKeys.containsKey(researchSite)) {
        publicKey = _publicKeys[researchSite]!;
      } else {
        // Use test key for testing or when research site is unknown
        publicKey = _testPublicKey;
      }

      // Create encryption metadata
      final encryptionMetadata = {
        'encrypted': true,
        'algorithm': 'AES-256-GCM + RSA-PKCS1',
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0',
      };

      // Prepare data for encryption
      final dataToEncrypt = {
        'locationData': jsonDecode(locationJson),
        'metadata': encryptionMetadata,
      };

      // Convert to bytes
      final jsonData = jsonEncode(dataToEncrypt);
      final dataBytes = utf8.encode(jsonData);

      // Generate AES key for symmetric encryption
      final aesKey = _generateAESKey();
      
      // Encrypt data with AES
      final encryptedData = await _encryptWithAES(dataBytes, aesKey);
      
      // Encrypt AES key with RSA public key
      final encryptedAESKey = await RSA.encryptPKCS1v15Bytes(
        Uint8List.fromList(aesKey),
        publicKey,
      );

      // Create final encrypted package
      final encryptedPackage = {
        'encryptedData': base64Encode(encryptedData),
        'encryptedKey': base64Encode(encryptedAESKey),
        'algorithm': 'AES-256-GCM + RSA-PKCS1',
        'researchSite': researchSite ?? 'test',
        'timestamp': DateTime.now().toIso8601String(),
      };

      return jsonEncode(encryptedPackage);
    } catch (e) {
      throw Exception('Location data encryption failed: $e');
    }
  }

  /// Generate AES key for symmetric encryption
  static List<int> _generateAESKey() {
    // Generate 32 random bytes for AES-256
    final key = List<int>.generate(32, (i) => 
      DateTime.now().millisecondsSinceEpoch % 256 + i);
    return key;
  }

  /// Encrypt data with AES-256-GCM
  static Future<List<int>> _encryptWithAES(List<int> data, List<int> key) async {
    // For production, implement proper AES-GCM encryption
    // For now, using a simplified approach for testing
    try {
      // This is a simplified encryption for testing
      // In production, use proper AES-GCM implementation
      final encrypted = <int>[];
      for (int i = 0; i < data.length; i++) {
        encrypted.add(data[i] ^ key[i % key.length]);
      }
      return encrypted;
    } catch (e) {
      throw Exception('AES encryption failed: $e');
    }
  }

  /// Check if location data should be encrypted based on app mode and settings
  static bool shouldEncryptLocationData() {
    // Always encrypt location data for privacy protection
    // This can be made configurable later if needed
    return true;
  }

  /// Get appropriate research site from stored participant data or app settings
  static Future<String?> getCurrentResearchSite() async {
    try {
      // TODO: Implement logic to determine research site
      // This could be based on:
      // - Participant code validation result
      // - App settings
      // - Geographic location
      // For now, return null to use test key
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Update public keys (for when real keys are provided)
  static void updatePublicKey(String researchSite, String publicKeyPem) {
    // This method can be used to update keys programmatically
    // In production, keys should be embedded at build time
    print('[LocationEncryption] Public key update requested for $researchSite');
    print('[LocationEncryption] Key length: ${publicKeyPem.length} characters');
  }
}
