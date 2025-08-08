import 'package:flutter_test/flutter_test.dart';
import 'package:wellbeing_mapper/services/participant_validation_service.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Participant Validation Service Tests', () {
    test('should reject empty participant code', () async {
      final result = await ParticipantValidationService.validateParticipantCode('');
      
      expect(result.isValid, isFalse);
      expect(result.error, contains('cannot be empty'));
    });

    test('should reject invalid participant code (no codes in system)', () async {
      final result = await ParticipantValidationService.validateParticipantCode('INVALID123');
      
      expect(result.isValid, isFalse);
      expect(result.error, contains('No participant codes are currently active'));
    });

    test('should validate input sanitization', () async {
      // Test with whitespace
      final result1 = await ParticipantValidationService.validateParticipantCode('  TEST123  ');
      expect(result1.isValid, isFalse); // Still false because no codes in system
      expect(result1.error, contains('No participant codes are currently active'));
      
      // Test with lowercase (should be normalized to uppercase)
      final result2 = await ParticipantValidationService.validateParticipantCode('test123');
      expect(result2.isValid, isFalse); // Still false because no codes in system
      expect(result2.error, contains('No participant codes are currently active'));
    });

    test('should handle short codes appropriately', () async {
      final result = await ParticipantValidationService.validateParticipantCode('AB');
      
      expect(result.isValid, isFalse);
      // Currently returns the "no codes in system" message for all invalid codes
      expect(result.error, contains('No participant codes are currently active'));
    });

    test('should validate return types are correct', () {
      // Test ValidationResult structure
      final validationResult = ValidationResult(isValid: false, error: 'test');
      expect(validationResult.isValid, isFalse);
      expect(validationResult.error, 'test');
      
      final validResult = ValidationResult(isValid: true);
      expect(validResult.isValid, isTrue);
      expect(validResult.error, isNull);
      
      // Test ConsentResult structure
      final consentResult = ConsentResult(success: false, error: 'test');
      expect(consentResult.success, isFalse);
      expect(consentResult.error, 'test');
      
      final successResult = ConsentResult(success: true);
      expect(successResult.success, isTrue);
      expect(successResult.error, isNull);
    });
  });
}
