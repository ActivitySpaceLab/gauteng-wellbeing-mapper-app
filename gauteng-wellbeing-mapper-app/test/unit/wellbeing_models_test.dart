import 'package:flutter_test/flutter_test.dart';
import 'package:wellbeing_mapper/models/wellbeing_survey_models.dart';

void main() {
  group('WellbeingSurveyResponse model', () {
    test('toJson/fromJson roundtrip', () {
      final now = DateTime.now();
      final r = WellbeingSurveyResponse(
        id: 'abc',
        timestamp: now,
        happinessScore: 7.5,
        latitude: 1.2,
        longitude: 3.4,
        accuracy: 5.6,
        locationTimestamp: now.toIso8601String(),
        isSynced: true,
      );
      final json = r.toJson();
      final r2 = WellbeingSurveyResponse.fromJson(json);
      expect(r2.id, 'abc');
      expect(r2.happinessScore, 7.5);
      expect(r2.isSynced, true);
    });

    test('derived getters work', () {
      expect(WellbeingSurveyResponse(id: '1', timestamp: DateTime.now(), happinessScore: null).wellbeingScore, 0);
      expect(WellbeingSurveyResponse(id: '1', timestamp: DateTime.now(), happinessScore: 5).answeredQuestionCount, 1);
      expect(WellbeingSurveyResponse(id: '1', timestamp: DateTime.now(), happinessScore: null).answeredQuestionCount, 0);
      expect(WellbeingSurveyResponse(id: '1', timestamp: DateTime.now(), happinessScore: 10).normalizedWellbeingScore, 1.0);
    });

    test('getWellbeingColor returns a Color', () {
      expect(WellbeingSurveyResponse.getWellbeingColor(0.0), isNotNull);
      expect(WellbeingSurveyResponse.getWellbeingColor(10.0), isNotNull);
    });
  });
}
