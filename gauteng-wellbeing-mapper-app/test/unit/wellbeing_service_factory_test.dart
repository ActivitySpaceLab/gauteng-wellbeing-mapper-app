import 'package:flutter_test/flutter_test.dart';
import 'package:wellbeing_mapper/services/wellbeing_survey_service.dart';

void main() {
  group('WellbeingSurveyService.createResponse', () {
    test('creates response with defaults', () {
      final r = WellbeingSurveyService.createResponse(happinessScore: 6.0);
      expect(r.happinessScore, 6.0);
      expect(r.isSynced, isFalse);
      expect(r.id, isNotEmpty);
    });
  });
}
