import 'package:flutter_test/flutter_test.dart';
import 'package:wellbeing_mapper/services/data_upload_service.dart';
import 'package:wellbeing_mapper/models/survey_models.dart';
import 'package:wellbeing_mapper/models/wellbeing_survey_models.dart';

void main() {
  group('DataUploadService (CI-safe unit tests)', () {
    test('shouldUploadData returns true on first run', () async {
      final result = await DataUploadService.shouldUploadData('gauteng');
      expect(result, isTrue);
    });

    test('uploadParticipantData returns error for unknown site', () async {
      final result = await DataUploadService.uploadParticipantData(
        researchSite: 'unknown',
        initialSurveys: const [],
        recurringSurveys: const [],
        wellbeingSurveys: const [],
        locationTracks: const [],
        participantUuid: 'test-user',
      );
      expect(result.success, isFalse);
      expect(result.error, contains('Unknown research site'));
    });
  });
}
