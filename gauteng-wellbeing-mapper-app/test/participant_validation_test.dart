import 'package:flutter_test/flutter_test.dart';
import 'package:wellbeing_mapper/services/participant_validation_service.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Participant Validation Service Tests', () {
    test('should initially have no validated participant', () async {
      // Clear any existing validation
      await ParticipantValidationService.clearValidation();
      
      final isValidated = await ParticipantValidationService.isParticipantValidated();
      expect(isValidated, isFalse);
    });

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

    test('consent recording should fail without validated participant', () async {
      // Clear validation first
      await ParticipantValidationService.clearValidation();
      
      final result = await ParticipantValidationService.recordConsent(
        'TEST123',
        DateTime.now(),
      );
      
      expect(result.success, isFalse);
      expect(result.error, contains('must be validated'));
    });

    test('should track consent recording status', () async {
      final hasConsent = await ParticipantValidationService.hasConsentBeenRecorded();
      expect(hasConsent, isA<bool>());
    });
  });
}
