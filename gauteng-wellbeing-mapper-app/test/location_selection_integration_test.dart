import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:wellbeing_mapper/db/survey_database.dart';
import 'package:wellbeing_mapper/models/data_sharing_consent.dart';
import 'package:wellbeing_mapper/models/consent_models.dart';
import 'package:wellbeing_mapper/models/survey_models.dart';
import 'package:wellbeing_mapper/services/data_upload_service.dart';
import 'package:wellbeing_mapper/ui/recurring_survey_screen.dart';

// Generate mocks for testing
@GenerateMocks([SurveyDatabase])
import 'location_selection_integration_test.mocks.dart';

void main() {
  group('Location Selection Data Integrity Tests', () {
    late MockSurveyDatabase mockDatabase;
    
    setUp(() {
      mockDatabase = MockSurveyDatabase();
    });

    testWidgets('Survey form shows location sharing section for research participants', (WidgetTester tester) async {
      // Setup: Mock research participant consent
      final mockConsent = ConsentResponse(
        participantUuid: 'test-uuid-123',
        informedConsent: true,
        dataProcessing: true,
        locationData: true,
        surveyData: true,
        dataRetention: true,
        dataSharing: true,
        voluntaryParticipation: true,
        consentedAt: DateTime.now(),
        participantSignature: 'Test Signature',
      );
      
      when(mockDatabase.getConsent()).thenAnswer((_) async => mockConsent);
      when(mockAppModeService.getCurrentMode()).thenAnswer((_) async => AppMode.research);
      
      // Build the survey screen
      await tester.pumpWidget(
        MaterialApp(
          home: RecurringSurveyScreen(),
        ),
      );

      // Wait for the screen to load
      await tester.pumpAndSettle();

      // Verify location sharing section appears for research participants
      expect(find.text('Location Sharing'), findsOneWidget);
      expect(find.text('Share All Locations'), findsOneWidget);
      expect(find.text('Select Specific Locations'), findsOneWidget);
      expect(find.text('Survey Only'), findsOneWidget);
    });

    testWidgets('Survey form does not show location sharing section for non-research participants', (WidgetTester tester) async {
      // Setup: Mock non-research participant (no consent)
      when(mockDatabase.getConsent()).thenAnswer((_) async => null);
      when(mockAppModeService.getCurrentMode()).thenAnswer((_) async => AppMode.research);
      
      // Build the survey screen
      await tester.pumpWidget(
        MaterialApp(
          home: RecurringSurveyScreen(),
        ),
      );

      // Wait for the screen to load
      await tester.pumpAndSettle();

      // Verify location sharing section does NOT appear for non-research participants
      expect(find.text('Location Sharing'), findsNothing);
      expect(find.text('Share All Locations'), findsNothing);
      expect(find.text('Select Specific Locations'), findsNothing);
      expect(find.text('Survey Only'), findsNothing);
    });

    testWidgets('Location selection saves correct sharing preference', (WidgetTester tester) async {
      // Setup: Mock research participant
      final mockConsent = ConsentResponse(
        participantUuid: 'test-uuid-123',
        informedConsent: true,
        dataProcessing: true,
        locationData: true,
        surveyData: true,
        dataRetention: true,
        dataSharing: true,
        voluntaryParticipation: true,
        consentedAt: DateTime.now(),
        participantSignature: 'Test Signature',
      );
      
      when(mockDatabase.getConsent()).thenAnswer((_) async => mockConsent);
      when(mockAppModeService.getCurrentMode()).thenAnswer((_) async => AppMode.research);
      when(mockDatabase.insertRecurringSurvey(any)).thenAnswer((_) async => 1);
      when(mockDatabase.insertDataSharingConsent(any)).thenAnswer((_) async => 1);
      
      // Build the survey screen
      await tester.pumpWidget(
        MaterialApp(
          home: RecurringSurveyScreen(),
        ),
      );

      // Wait for the screen to load
      await tester.pumpAndSettle();

      // Select "Survey Only" option
      await tester.tap(find.text('Survey Only'));
      await tester.pumpAndSettle();

      // Fill out a minimal survey response
      await tester.enterText(find.byKey(Key('generalHealth')), '4');
      await tester.enterText(find.byKey(Key('cheerfulSpirits')), '3');
      
      // Submit the survey
      await tester.tap(find.text('Submit Survey'));
      await tester.pumpAndSettle();

      // Verify that insertDataSharingConsent was called with Survey Only option
      verify(mockDatabase.insertDataSharingConsent(
        argThat(isA<DataSharingConsent>()
          .having((consent) => consent.locationSharingOption, 'sharing option', LocationSharingOption.surveyOnly)
          .having((consent) => consent.participantUuid, 'participant UUID', 'test-uuid-123'))
      )).called(1);
    });

    testWidgets('Beta testing mode shows appropriate success message', (WidgetTester tester) async {
      // Setup: Mock beta testing mode
      final mockConsent = ConsentResponse(
        participantUuid: 'test-uuid-123',
        informedConsent: true,
        dataProcessing: true,
        locationData: true,
        surveyData: true,
        dataRetention: true,
        dataSharing: true,
        voluntaryParticipation: true,
        consentedAt: DateTime.now(),
        participantSignature: 'Test Signature',
      );
      
      when(mockDatabase.getConsent()).thenAnswer((_) async => mockConsent);
      when(mockAppModeService.getCurrentMode()).thenAnswer((_) async => AppMode.appTesting);
      when(mockDatabase.insertRecurringSurvey(any)).thenAnswer((_) async => 1);
      
      // Build the survey screen
      await tester.pumpWidget(
        MaterialApp(
          home: RecurringSurveyScreen(),
        ),
      );

      // Wait for the screen to load
      await tester.pumpAndSettle();

      // Fill out minimal survey and submit
      await tester.enterText(find.byKey(Key('generalHealth')), '4');
      await tester.tap(find.text('Submit Survey'));
      await tester.pumpAndSettle();

      // Verify beta testing success message appears
      expect(find.text('🧪 Beta Testing Mode'), findsOneWidget);
      expect(find.text('Your data is stored locally for testing purposes. No data was transmitted to research servers.'), findsOneWidget);
    });

    testWidgets('Research mode shows appropriate success message', (WidgetTester tester) async {
      // Setup: Mock research mode
      final mockConsent = ConsentResponse(
        participantUuid: 'test-uuid-123',
        informedConsent: true,
        dataProcessing: true,
        locationData: true,
        surveyData: true,
        dataRetention: true,
        dataSharing: true,
        voluntaryParticipation: true,
        consentedAt: DateTime.now(),
        participantSignature: 'Test Signature',
      );
      
      when(mockDatabase.getConsent()).thenAnswer((_) async => mockConsent);
      when(mockAppModeService.getCurrentMode()).thenAnswer((_) async => AppMode.research);
      when(mockDatabase.insertRecurringSurvey(any)).thenAnswer((_) async => 1);
      when(mockDatabase.insertDataSharingConsent(any)).thenAnswer((_) async => 1);
      
      // Build the survey screen
      await tester.pumpWidget(
        MaterialApp(
          home: RecurringSurveyScreen(),
        ),
      );

      // Wait for the screen to load
      await tester.pumpAndSettle();

      // Fill out minimal survey and submit
      await tester.enterText(find.byKey(Key('generalHealth')), '4');
      await tester.tap(find.text('Submit Survey'));
      await tester.pumpAndSettle();

      // Verify research success message appears
      expect(find.text('Research Participation'), findsOneWidget);
      expect(find.text('Your data is ready to contribute to scientific research. Note: Currently no server is set up to receive data, so uploading will be available in a future update.'), findsOneWidget);
    });

    group('Location Selection Data Integrity Tests', () {
      test('DataSharingConsent saves correct location sharing option', () async {
        // Test that the DataSharingConsent model correctly stores different sharing options
        final fullDataConsent = DataSharingConsent(
          id: '1',
          locationSharingOption: LocationSharingOption.fullData,
          decisionTimestamp: DateTime.now(),
          participantUuid: 'test-uuid',
          customLocationIds: null,
        );

        expect(fullDataConsent.locationSharingOption, LocationSharingOption.fullData);
        expect(fullDataConsent.customLocationIds, isNull);

        final partialDataConsent = DataSharingConsent(
          id: '2',
          locationSharingOption: LocationSharingOption.partialData,
          decisionTimestamp: DateTime.now(),
          participantUuid: 'test-uuid',
          customLocationIds: ['location_1', 'location_3', 'location_5'],
        );

        expect(partialDataConsent.locationSharingOption, LocationSharingOption.partialData);
        expect(partialDataConsent.customLocationIds, ['location_1', 'location_3', 'location_5']);

        final surveyOnlyConsent = DataSharingConsent(
          id: '3',
          locationSharingOption: LocationSharingOption.surveyOnly,
          decisionTimestamp: DateTime.now(),
          participantUuid: 'test-uuid',
          customLocationIds: null,
        );

        expect(surveyOnlyConsent.locationSharingOption, LocationSharingOption.surveyOnly);
        expect(surveyOnlyConsent.customLocationIds, isNull);
      });

      test('LocationTrack model handles location data correctly', () {
        final locationTrack = LocationTrack(
          timestamp: DateTime(2025, 8, 3, 14, 30),
          latitude: -26.2041,
          longitude: 28.0473,
          accuracy: 10.0,
          altitude: 1753.0,
          speed: 0.0,
          activity: 'still',
        );

        expect(locationTrack.latitude, -26.2041);
        expect(locationTrack.longitude, 28.0473);
        expect(locationTrack.accuracy, 10.0);
        expect(locationTrack.activity, 'still');
      });
    });
  });
}
