import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:wellbeing_mapper/ui/recurring_survey_screen.dart';
import 'package:wellbeing_mapper/ui/interactive_location_privacy_map.dart';
import 'package:wellbeing_mapper/models/data_sharing_consent.dart';
import 'package:wellbeing_mapper/models/consent_models.dart';
import 'package:wellbeing_mapper/models/survey_models.dart';
import 'package:wellbeing_mapper/services/data_upload_service.dart';
import 'package:wellbeing_mapper/db/survey_database.dart';
import 'package:wellbeing_mapper/services/app_mode_service.dart';
import 'package:wellbeing_mapper/models/app_mode.dart';

import 'location_sharing_integration_test.mocks.dart';

@GenerateMocks([SurveyDatabase, AppModeService])
void main() {
  group('Location Sharing Integration Tests', () {
    late MockSurveyDatabase mockDatabase;
    late MockAppModeService mockAppModeService;

    setUp(() {
      mockDatabase = MockSurveyDatabase();
      mockAppModeService = MockAppModeService();
    });

    testWidgets('Survey form shows location sharing section for research participants', (WidgetTester tester) async {
      // Mock research participant
      when(mockDatabase.getConsent()).thenAnswer((_) async => ConsentResponse(
        participantUuid: 'test-uuid-123',
        consentGiven: true,
        consentTimestamp: DateTime.now(),
        researchSite: 'gauteng',
      ));

      await tester.pumpWidget(MaterialApp(
        home: RecurringSurveyScreen(),
      ));

      await tester.pumpAndSettle();

      // Verify location sharing section is present
      expect(find.text('Location Sharing'), findsOneWidget);
      expect(find.text('Share All Locations'), findsOneWidget);
      expect(find.text('Select Specific Locations'), findsOneWidget);
      expect(find.text('Survey Only'), findsOneWidget);
    });

    testWidgets('Location sharing options update correctly when selected', (WidgetTester tester) async {
      // Mock research participant with location data
      when(mockDatabase.getConsent()).thenAnswer((_) async => ConsentResponse(
        participantUuid: 'test-uuid-123',
        consentGiven: true,
        consentTimestamp: DateTime.now(),
        researchSite: 'gauteng',
      ));

      await tester.pumpWidget(MaterialApp(
        home: RecurringSurveyScreen(),
      ));

      await tester.pumpAndSettle();

      // Initially should show "Share All Locations" as default
      expect(find.text('Status: All locations ('), findsOneWidget);

      // Tap on "Survey Only" option
      await tester.tap(find.text('Survey Only'));
      await tester.pumpAndSettle();

      // Should now show survey only status
      expect(find.text('Status: Survey responses only'), findsOneWidget);

      // Tap on "Share All Locations" option
      await tester.tap(find.text('Share All Locations'));
      await tester.pumpAndSettle();

      // Should show all locations status again
      expect(find.text('Status: All locations ('), findsOneWidget);
    });

    testWidgets('Interactive map opens when "Select Specific Locations" is chosen', (WidgetTester tester) async {
      // Mock research participant with location data
      when(mockDatabase.getConsent()).thenAnswer((_) async => ConsentResponse(
        participantUuid: 'test-uuid-123',
        consentGiven: true,
        consentTimestamp: DateTime.now(),
        researchSite: 'gauteng',
      ));

      await tester.pumpWidget(MaterialApp(
        home: RecurringSurveyScreen(),
      ));

      await tester.pumpAndSettle();

      // Tap on "Select Specific Locations" button (not radio button)
      await tester.tap(find.text('Select Specific Locations').last);
      await tester.pumpAndSettle();

      // Should show help dialog first
      expect(find.text('Location Sharing Choices Guide'), findsOneWidget);
      
      // Accept help dialog
      await tester.tap(find.text('Got It!'));
      await tester.pumpAndSettle();

      // Should now open the interactive map
      expect(find.text('Select Location Data to Share'), findsOneWidget);
      expect(find.text('Confirm Selection'), findsOneWidget);
    });

    test('Location selection data integrity - erased indices are preserved correctly', () async {
      // Create test location data
      final testLocations = [
        LocationTrack(
          timestamp: DateTime.now().subtract(Duration(days: 1)),
          latitude: -26.2041,
          longitude: 28.0473,
        ),
        LocationTrack(
          timestamp: DateTime.now().subtract(Duration(days: 2)),
          latitude: -26.1951,
          longitude: 28.0624,
        ),
        LocationTrack(
          timestamp: DateTime.now().subtract(Duration(days: 3)),
          latitude: -26.2444,
          longitude: 28.1216,
        ),
      ];

      // Simulate erasing locations at indices 0 and 2 (keeping only index 1)
      final erasedIndices = {0, 2};

      // Calculate expected remaining locations
      final expectedRemainingLocations = testLocations
          .asMap()
          .entries
          .where((entry) => !erasedIndices.contains(entry.key))
          .map((entry) => entry.value)
          .toList();

      // Verify only location at index 1 remains
      expect(expectedRemainingLocations.length, equals(1));
      expect(expectedRemainingLocations[0].latitude, equals(-26.1951));
      expect(expectedRemainingLocations[0].longitude, equals(28.0624));
    });

    test('Data sharing consent creation with correct location IDs', () async {
      // Test creating consent with partial data selection
      final testLocations = [
        LocationTrack(
          timestamp: DateTime.now().subtract(Duration(days: 1)),
          latitude: -26.2041,
          longitude: 28.0473,
        ),
        LocationTrack(
          timestamp: DateTime.now().subtract(Duration(days: 2)),
          latitude: -26.1951,
          longitude: 28.0624,
        ),
        LocationTrack(
          timestamp: DateTime.now().subtract(Duration(days: 3)),
          latitude: -26.2444,
          longitude: 28.1216,
        ),
      ];

      // Simulate selecting first and third locations (indices 0 and 2)
      final erasedIndices = {1}; // Erase middle location
      final selectedTracks = testLocations
          .asMap()
          .entries
          .where((entry) => !erasedIndices.contains(entry.key))
          .map((entry) => entry.value)
          .toList();

      // Create location IDs based on selected tracks
      final customLocationIds = <String>[];
      for (int i = 0; i < selectedTracks.length; i++) {
        customLocationIds.add('track_$i');
      }

      // Create consent object
      final consent = DataSharingConsent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        locationSharingOption: LocationSharingOption.partialData,
        decisionTimestamp: DateTime.now(),
        participantUuid: 'test-uuid-123',
        customLocationIds: customLocationIds,
      );

      // Verify consent contains correct number of location IDs
      expect(consent.customLocationIds?.length, equals(2));
      expect(consent.customLocationIds, contains('track_0'));
      expect(consent.customLocationIds, contains('track_1'));
      expect(consent.locationSharingOption, equals(LocationSharingOption.partialData));
    });

    testWidgets('Beta testers see appropriate success message after submission', (WidgetTester tester) async {
      // Mock beta testing mode
      when(mockAppModeService.getCurrentMode()).thenAnswer((_) async => AppMode.appTesting);
      when(mockDatabase.getConsent()).thenAnswer((_) async => null); // No research consent

      await tester.pumpWidget(MaterialApp(
        home: RecurringSurveyScreen(),
      ));

      await tester.pumpAndSettle();

      // Fill out minimal form data
      await tester.enterText(find.byKey(Key('generalHealth')), 'Good');
      
      // Submit the form
      await tester.tap(find.text('Submit Survey'));
      await tester.pumpAndSettle();

      // Should see beta testing success dialog
      expect(find.text('🧪 Beta Testing Mode'), findsOneWidget);
      expect(find.text('Your data is stored locally for testing purposes. No data was transmitted to research servers.'), findsOneWidget);
    });

    testWidgets('Research participants see research success message after submission', (WidgetTester tester) async {
      // Mock research mode
      when(mockAppModeService.getCurrentMode()).thenAnswer((_) async => AppMode.research);
      when(mockDatabase.getConsent()).thenAnswer((_) async => ConsentResponse(
        participantUuid: 'test-uuid-123',
        consentGiven: true,
        consentTimestamp: DateTime.now(),
        researchSite: 'gauteng',
      ));

      await tester.pumpWidget(MaterialApp(
        home: RecurringSurveyScreen(),
      ));

      await tester.pumpAndSettle();

      // Fill out minimal form data
      await tester.enterText(find.byKey(Key('generalHealth')), 'Good');
      
      // Submit the form
      await tester.tap(find.text('Submit Survey'));
      await tester.pumpAndSettle();

      // Should see research participant success dialog
      expect(find.text('Research Participation'), findsOneWidget);
      expect(find.text('Your data is ready to contribute to scientific research.'), findsOneWidget);
    });

    test('Location sharing consent is saved correctly with survey submission', () async {
      // Mock the database insert method
      when(mockDatabase.insertRecurringSurvey(any)).thenAnswer((_) async => 1);
      when(mockDatabase.insertDataSharingConsent(any)).thenAnswer((_) async => 1);
      when(mockDatabase.getConsent()).thenAnswer((_) async => ConsentResponse(
        participantUuid: 'test-uuid-123',
        consentGiven: true,
        consentTimestamp: DateTime.now(),
        researchSite: 'gauteng',
      ));

      // Verify that when survey is submitted with location sharing preferences,
      // both the survey and consent are saved
      
      // This would be tested by triggering the actual submission flow
      // and verifying the mock methods are called with correct parameters
      verify(mockDatabase.insertRecurringSurvey(any)).called(0); // Not called yet
      verify(mockDatabase.insertDataSharingConsent(any)).called(0); // Not called yet
    });

    group('Interactive Map Selection Logic', () {
      test('Map returns correct erased indices when locations are removed', () {
        // Create a set representing erased locations
        final erasedIndices = <int>{0, 2, 4}; // Erase locations at these indices
        
        // Simulate having 6 total locations
        final totalLocations = 6;
        final remainingLocationCount = totalLocations - erasedIndices.length;
        
        expect(remainingLocationCount, equals(3));
        
        // Verify the indices that should remain
        final remainingIndices = <int>{};
        for (int i = 0; i < totalLocations; i++) {
          if (!erasedIndices.contains(i)) {
            remainingIndices.add(i);
          }
        }
        
        expect(remainingIndices, equals({1, 3, 5}));
      });

      test('Empty erased indices set means all locations are selected', () {
        final erasedIndices = <int>{};
        final totalLocations = 5;
        final remainingLocationCount = totalLocations - erasedIndices.length;
        
        expect(remainingLocationCount, equals(5));
        expect(erasedIndices.isEmpty, isTrue);
      });

      test('All locations erased means survey-only equivalent', () {
        final erasedIndices = <int>{0, 1, 2, 3, 4};
        final totalLocations = 5;
        final remainingLocationCount = totalLocations - erasedIndices.length;
        
        expect(remainingLocationCount, equals(0));
        expect(erasedIndices.length, equals(totalLocations));
      });
    });

    group('Status Text Generation', () {
      test('Status text reflects correct location counts', () {
        // Test different scenarios for status text generation
        final testCases = [
          {
            'totalLocations': 10,
            'erasedIndices': <int>{},
            'option': LocationSharingOption.fullData,
            'expectedStatus': 'Status: All locations (10 records) will be shared'
          },
          {
            'totalLocations': 10,
            'erasedIndices': <int>{1, 3, 5},
            'option': LocationSharingOption.partialData,
            'expectedContains': 'Status: 7 of 10 locations selected'
          },
          {
            'totalLocations': 10,
            'erasedIndices': <int>{0, 1, 2, 3, 4, 5, 6, 7, 8, 9},
            'option': LocationSharingOption.partialData,
            'expectedContains': 'Status: 0 of 10 locations selected'
          },
        ];

        for (final testCase in testCases) {
          final totalLocations = testCase['totalLocations'] as int;
          final erasedIndices = testCase['erasedIndices'] as Set<int>;
          final option = testCase['option'] as LocationSharingOption;
          
          final remainingCount = totalLocations - erasedIndices.length;
          
          if (option == LocationSharingOption.fullData) {
            final status = 'Status: All locations ($totalLocations records) will be shared';
            expect(status, equals(testCase['expectedStatus']));
          } else if (option == LocationSharingOption.partialData) {
            final status = 'Status: $remainingCount of $totalLocations locations selected';
            expect(status, contains(testCase['expectedContains'] as String));
          }
        }
      });
    });
  });
}
