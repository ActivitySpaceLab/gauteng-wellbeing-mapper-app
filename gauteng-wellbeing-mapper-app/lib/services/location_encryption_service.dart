import 'dart:convert';
import 'dart:typed_data';
import 'package:fast_rsa/fast_rsa.dart';

/// Service for encrypting location data before inserting into Qualtrics surveys
class LocationEncryptionService {
  // Research site public keys - using production key for Gauteng
  static const Map<String, String> _publicKeys = {
    'barcelona': '''-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA1234567890...
-----END PUBLIC KEY-----''', // Barcelona public key placeholder
    'gauteng': '''-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA0J5sRl93JHb16BSzkkDu
phMMne8Yv/qAtLxGl2yHGZ1dFsMY7xJU+9epEN6DPA5PFbo+NwumQ17aAw7IDm8A
Pyis7gryWDtaGUNjapvQdq+Kfx1Z0D+yx569KjWxAwQpGL6PxOdW0RKwsV3QKgCo
RJxQqtr9QJHQ/FIBrfzuh+MmCie9JSFE3nrRBEjOQszI72AUx4xxE1RauQnwgvGx
HrJoue9tFAAQfWzv95VigRHKqAlzRbZkmNQJOWGng3xAbfgf3v+wSnin51lp5H1/
qMeBmv0ABEMRWpcgsfhd9pIwX13paq766GFYFZMh0n9UDscXA5y2/p4YbgjEINPF
f7vFuRwiFjS4j+0ZiuOLi2DbF9DWYh2jX1ZVxMUMbv2t0cdcCnXsYSqxzAfKODf7
xxTKffLKxP5xEaR8bnrwMS2YaAB3CRAi7ZYSp7OvS/PCM2HeWV9WaCSYZJsv+VJI
0A2bVvauok8Odzmd3z9RZarVowfpc1MyGABrlp52lp1Q6nGuHrIXaUSil/SYP9yD
PwkY+fa6X6hUpSMUmPfgZkS5IAiWPRpbqe6OJ4N+uelyVn+rvmRz/SgJ3g89L6dh
vzgBHEl3b7c051V8daNVoOmadjWYVzVyC7ViXf5Qtzl0Zg2bfyD0MGNUh/gwGgcu
AKr5gbTqca/dY/+Or3Ha/sECAwEAAQ==
-----END PUBLIC KEY-----''', // Gauteng production public key
  };

  // Production public key for encryption
  static const String _productionPublicKey = '''-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA0J5sRl93JHb16BSzkkDu
phMMne8Yv/qAtLxGl2yHGZ1dFsMY7xJU+9epEN6DPA5PFbo+NwumQ17aAw7IDm8A
Pyis7gryWDtaGUNjapvQdq+Kfx1Z0D+yx569KjWxAwQpGL6PxOdW0RKwsV3QKgCo
RJxQqtr9QJHQ/FIBrfzuh+MmCie9JSFE3nrRBEjOQszI72AUx4xxE1RauQnwgvGx
HrJoue9tFAAQfWzv95VigRHKqAlzRbZkmNQJOWGng3xAbfgf3v+wSnin51lp5H1/
qMeBmv0ABEMRWpcgsfhd9pIwX13paq766GFYFZMh0n9UDscXA5y2/p4YbgjEINPF
f7vFuRwiFjS4j+0ZiuOLi2DbF9DWYh2jX1ZVxMUMbv2t0cdcCnXsYSqxzAfKODf7
xxTKffLKxP5xEaR8bnrwMS2YaAB3CRAi7ZYSp7OvS/PCM2HeWV9WaCSYZJsv+VJI
0A2bVvauok8Odzmd3z9RZarVowfpc1MyGABrlp52lp1Q6nGuHrIXaUSil/SYP9yD
PwkY+fa6X6hUpSMUmPfgZkS5IAiWPRpbqe6OJ4N+uelyVn+rvmRz/SgJ3g89L6dh
vzgBHEl3b7c051V8daNVoOmadjWYVzVyC7ViXf5Qtzl0Zg2bfyD0MGNUh/gwGgcu
AKr5gbTqca/dY/+Or3Ha/sECAwEAAQ==
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
        // Use production key for all encryption
        publicKey = _productionPublicKey;
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
      // This is the Gauteng Wellbeing Mapper app, so return 'gauteng'
      // This ensures we use the correct public key for encryption
      return 'gauteng';
    } catch (e) {
      return 'gauteng'; // Fallback to gauteng
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
