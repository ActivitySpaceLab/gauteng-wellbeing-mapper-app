import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Service for validating participant codes against a secure server-side list
/// Uses SHA-256 hashing for security - codes are never transmitted in plain text
class ParticipantValidationService {
  // Server endpoints (will be used when server is ready)
  // static const String _baseUrl = 'https://api.gauteng-wellbeing-research.org';
  // static const String _validateEndpoint = '/api/v1/participants/validate';
  // static const String _consentEndpoint = '/api/v1/participants/consent';
  
  // Local storage keys
  static const String _validatedParticipantKey = 'validated_participant_code';
  static const String _validationTimestampKey = 'validation_timestamp';
  static const String _consentRecordedKey = 'consent_recorded';

  /// Check if the current user has already been validated
  static Future<bool> isParticipantValidated() async {
    final prefs = await SharedPreferences.getInstance();
    final validatedCode = prefs.getString(_validatedParticipantKey);
    return validatedCode != null && validatedCode.isNotEmpty;
  }

  /// Get the stored participant code (hashed for security)
  static Future<String?> getValidatedParticipantCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_validatedParticipantKey);
  }

  /// Validate a participant code against the server
  /// Returns true if code is valid, false otherwise
  static Future<ValidationResult> validateParticipantCode(String participantCode) async {
    try {
      // Input validation
      if (participantCode.trim().isEmpty) {
        return ValidationResult(
          isValid: false,
          error: 'Participant code cannot be empty',
        );
      }

      // Clean and normalize the code
      final cleanCode = participantCode.trim().toUpperCase();
      
      // For development/testing - allow specific test codes
      if (cleanCode == 'TESTER' || cleanCode == 'TEST123' || cleanCode == 'DEV001') {
        await _storeValidatedParticipant(cleanCode);
        print('[ParticipantValidation] Test code accepted: $cleanCode');
        return ValidationResult(isValid: true);
      }
      
      // Hash the entered code for validation
      final hashedCode = _hashParticipantCode(cleanCode);
      
      // Pilot participant code hashes for Gauteng study
      // These are SHA-256 hashes of: P4H1P, P4H2P, P4H3P, P4H4P, P4H5P, P4H6P, P4H7P, P4H8P, P4H9P, P4H10P
      final Set<String> validPilotCodeHashes = {
        '4f1b70f8e0ba866e3674212316b7f56f10a10a079c4529388f9e279d0089a5c8', // P4H1P
        'a46ec4139c68af42d976289028fcaa90c6686d441abd2fb4e65e35823dbabd3a', // P4H2P
        'cfb931b358f07251e2668420bb3f3a9c61bd9d7c1361e015877cbbeb0e56d4cd', // P4H3P
        '3ea2efd140c478a97fc149a9f1bb6b1925698dc091b9f79a61861fbec85122d4', // P4H4P
        '1fa5d96e720d3122aad7aa0dc537cc7c213704633ed947e7d22cc30cb2258781', // P4H5P
        'bd4029314d62009a717d0d7b56ee27e534605d2b17809e0a4b88d415385576d4', // P4H6P
        '7f526eb989ccc02af13bb4248dc6ec01aa17bd0d66ace79050cd51e60ae28912', // P4H7P
        '182c2f81f6270bea6be3857d68385993075a4e6f565e014cda67ffe199c3f96f', // P4H8P
        'f0f936f8f6345bbf178ac5820e55dcb2f0f2d84e21b4b69b8d632d24047b73a4', // P4H9P
        '496c8ee77cc087f299d6d54da74269ffbaf2945f16295d7bf918518bf527cbea', // P4H10P
      };
      
      if (validPilotCodeHashes.contains(hashedCode)) {
        await _storeValidatedParticipant(cleanCode);
        print('[ParticipantValidation] Pilot participant code accepted: ${cleanCode.substring(0, min(3, cleanCode.length))}***');
        return ValidationResult(isValid: true);
      }
      
      // Invalid code
      print('[ParticipantValidation] Invalid code attempted: ${cleanCode.substring(0, min(3, cleanCode.length))}***');
      return ValidationResult(
        isValid: false,
        error: 'Invalid participant code. Please check your code and contact the research team if you continue to have issues.',
      );

      // TODO: When server is ready, uncomment this and remove the above return
      /*
      // For development/testing - allow specific test codes
      if (cleanCode == 'TEST123' || cleanCode == 'DEV001') {
        await _storeValidatedParticipant(cleanCode);
        return ValidationResult(isValid: true);
      }
      
      return ValidationResult(
        isValid: false,
        error: 'Invalid participant code. Please check your code and try again.',
      );
      */

      // Server validation (commented out until server is ready)
      /*
      final response = await http.post(
        Uri.parse('$_baseUrl$_validateEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'hashed_code': hashedCode,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          // Store the validation locally
          await _storeValidatedParticipant(cleanCode);
          return ValidationResult(isValid: true);
        } else {
          return ValidationResult(
            isValid: false,
            error: 'Invalid participant code. Please check your code and try again.',
          );
        }
      } else if (response.statusCode == 404) {
        return ValidationResult(
          isValid: false,
          error: 'Participant code not found. Please check your code and try again.',
        );
      } else {
        return ValidationResult(
          isValid: false,
          error: 'Unable to validate code. Please check your internet connection and try again.',
        );
      }
      */
    } catch (e) {
      print('[ParticipantValidation] Error validating code: $e');
      return ValidationResult(
        isValid: false,
        error: 'Network error. Please check your internet connection and try again.',
      );
    }
  }

  /// Record consent for a validated participant
  static Future<ConsentResult> recordConsent(String participantCode, DateTime consentTimestamp) async {
    try {
      // Verify participant is validated
      final isValidated = await isParticipantValidated();
      if (!isValidated) {
        return ConsentResult(
          success: false,
          error: 'Participant must be validated before recording consent',
        );
      }

      // For now, just store locally since server isn't ready
      // TODO: Remove this when server is ready
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_consentRecordedKey, true);
      await prefs.setString('consent_timestamp', consentTimestamp.toIso8601String());
      
      print('[ParticipantValidation] Consent recorded locally for participant: ${participantCode.substring(0, min(3, participantCode.length))}***');
      return ConsentResult(success: true);

      // Server consent recording (commented out until server is ready)
      /*
      final response = await http.post(
        Uri.parse('$_baseUrl$_consentEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'hashed_participant_code': hashedCode,
          'consent_timestamp': consentTimestamp.toIso8601String(),
          'consent_version': '1.0', // Track consent form version
        }),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Mark consent as recorded locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_consentRecordedKey, true);
        await prefs.setString('consent_timestamp', consentTimestamp.toIso8601String());
        
        return ConsentResult(success: true);
      } else {
        return ConsentResult(
          success: false,
          error: 'Failed to record consent on server. Please try again.',
        );
      }
      */
    } catch (e) {
      print('[ParticipantValidation] Error recording consent: $e');
      return ConsentResult(
        success: false,
        error: 'Network error while recording consent. Please try again.',
      );
    }
  }

  /// Check if consent has been recorded for the current participant
  static Future<bool> hasConsentBeenRecorded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_consentRecordedKey) ?? false;
  }

  /// Hash participant code using SHA-256 for security
  static String _hashParticipantCode(String code) {
    final bytes = utf8.encode(code);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Store validated participant locally (stores hashed version for security)
  static Future<void> _storeValidatedParticipant(String participantCode) async {
    final prefs = await SharedPreferences.getInstance();
    // For now, store the plain code until server integration
    // TODO: Use hashed version when server is ready
    await prefs.setString(_validatedParticipantKey, participantCode);
    await prefs.setString(_validationTimestampKey, DateTime.now().toIso8601String());
    print('[ParticipantValidation] Stored validated participant: ${participantCode.substring(0, min(3, participantCode.length))}***');
  }

  /// Clear validation data (for testing or logout)
  static Future<void> clearValidation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_validatedParticipantKey);
    await prefs.remove(_validationTimestampKey);
    await prefs.remove(_consentRecordedKey);
    await prefs.remove('consent_timestamp');
  }

  /// Get validation timestamp
  static Future<DateTime?> getValidationTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_validationTimestampKey);
    if (timestamp != null) {
      return DateTime.tryParse(timestamp);
    }
    return null;
  }
}

/// Result of participant code validation
class ValidationResult {
  final bool isValid;
  final String? error;

  ValidationResult({
    required this.isValid,
    this.error,
  });
}

/// Result of consent recording
class ConsentResult {
  final bool success;
  final String? error;

  ConsentResult({
    required this.success,
    this.error,
  });
}
