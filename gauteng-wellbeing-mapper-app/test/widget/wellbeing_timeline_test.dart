import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:wellbeing_mapper/ui/wellbeing_timeline_view.dart';
import 'package:wellbeing_mapper/models/wellbeing_survey_models.dart';

void main() {
  group('WellbeingTimelineView Tests', () {
    testWidgets('Timeline view should build without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WellbeingTimelineView(),
        ),
      );

      // Verify that the app bar is present
      expect(find.text('Wellbeing Timeline'), findsOneWidget);
      
      // Verify loading indicator is shown initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Timeline view should show no data message when empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WellbeingTimelineView(),
        ),
      );

      // Wait for the loading to complete
      await tester.pumpAndSettle();

      // Should show no data message (since we don't have real data in test)
      expect(find.text('No survey data found'), findsOneWidget);
    });

    test('Wellbeing score calculation should work correctly', () {
      final response1 = WellbeingSurveyResponse(
        id: '1',
        timestamp: DateTime.now(),
        cheerfulSpirits: 1,
        calmRelaxed: 1,
        activeVigorous: 1,
        wokeRested: 1,
        interestingLife: 1,
        latitude: 0.0,
        longitude: 0.0,
      );
      
      final response2 = WellbeingSurveyResponse(
        id: '2',
        timestamp: DateTime.now(),
        cheerfulSpirits: 0,
        calmRelaxed: 0,
        activeVigorous: 0,
        wokeRested: 0,
        interestingLife: 0,
        latitude: 0.0,
        longitude: 0.0,
      );
      
      final response3 = WellbeingSurveyResponse(
        id: '3',
        timestamp: DateTime.now(),
        cheerfulSpirits: 1,
        calmRelaxed: 0,
        activeVigorous: 1,
        wokeRested: 0,
        interestingLife: 1,
        latitude: 0.0,
        longitude: 0.0,
      );

      expect(response1.wellbeingScore, equals(5));
      expect(response2.wellbeingScore, equals(0));
      expect(response3.wellbeingScore, equals(3));
    });

    test('Wellbeing categories should be correct', () {
      final lowResponse = WellbeingSurveyResponse(
        id: '1',
        timestamp: DateTime.now(),
        cheerfulSpirits: 0,
        calmRelaxed: 0,
        activeVigorous: 0,
        wokeRested: 0,
        interestingLife: 0,
        latitude: 0.0,
        longitude: 0.0,
      );
      
      final highResponse = WellbeingSurveyResponse(
        id: '2',
        timestamp: DateTime.now(),
        cheerfulSpirits: 1,
        calmRelaxed: 1,
        activeVigorous: 1,
        wokeRested: 1,
        interestingLife: 1,
        latitude: 0.0,
        longitude: 0.0,
      );

      expect(lowResponse.wellbeingCategory, equals('Very Low'));
      expect(highResponse.wellbeingCategory, equals('Excellent'));
    });

    test('Color mapping should work correctly', () {
      expect(WellbeingSurveyResponse.getWellbeingColor(0), isA<Color>());
      expect(WellbeingSurveyResponse.getWellbeingColor(5), isA<Color>());
      expect(WellbeingSurveyResponse.getWellbeingColor(3), isA<Color>());
      
      // Check that different scores have different colors
      final color0 = WellbeingSurveyResponse.getWellbeingColor(0);
      final color5 = WellbeingSurveyResponse.getWellbeingColor(5);
      expect(color0, isNot(equals(color5)));
    });
  });
}
