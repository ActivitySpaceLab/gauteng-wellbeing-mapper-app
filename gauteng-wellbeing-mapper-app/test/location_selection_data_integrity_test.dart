import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:wellbeing_mapper/db/survey_database.dart';
import 'package:wellbeing_mapper/models/data_sharing_consent.dart';
import 'package:wellbeing_mapper/models/consent_models.dart';
import 'package:wellbeing_mapper/services/data_upload_service.dart';

// Generate mocks for testing
@GenerateMocks([SurveyDatabase])
import 'location_selection_data_integrity_test.mocks.dart';

void main() {
  group('Location Selection Data Integrity Tests', () {
    late MockSurveyDatabase mockDatabase;
    
    setUp(() {
      mockDatabase = MockSurveyDatabase();
    });

    test('DataSharingConsent correctly stores location sharing preferences', () async {
      // Test data integrity for different location sharing options
      final testCases = [
        LocationSharingOption.fullData,
        LocationSharingOption.partialData,
        LocationSharingOption.surveyOnly,
      ];

      for (final option in testCases) {
        final consent = DataSharingConsent(
          id: 'consent-123',
          locationSharingOption: option,
          decisionTimestamp: DateTime.now(),
          participantUuid: 'test-uuid-123',
        );

        // Verify the object correctly stores the selected option
        expect(consent.locationSharingOption, equals(option));
        expect(consent.participantUuid, equals('test-uuid-123'));
        expect(consent.id, equals('consent-123'));
        
        // Verify the enum value is preserved correctly  
        expect(consent.locationSharingOption, equals(option));
      }
    });

    test('LocationTrack model correctly stores GPS coordinates', () async {
      // Test that LocationTrack preserves coordinate precision
      final locationTrack = LocationTrack(
        timestamp: DateTime.now(),
        latitude: -26.204103,
        longitude: 28.047305,
        accuracy: 10.0,
      );

      // Verify coordinate precision is maintained
      expect(locationTrack.latitude, equals(-26.204103));
      expect(locationTrack.longitude, equals(28.047305));
      expect(locationTrack.accuracy, equals(10.0));
      expect(locationTrack.timestamp, isA<DateTime>());
    });

    test('Database insertion preserves location sharing preference integrity', () async {
      // Setup mock database responses
      when(mockDatabase.insertDataSharingConsent(any)).thenAnswer((_) async => 1);
      
      // Create test data
      final consent = DataSharingConsent(
        id: 'consent-123',
        participantUuid: 'test-uuid-123',
        locationSharingOption: LocationSharingOption.partialData,
        decisionTimestamp: DateTime.now(),
      );

      // Insert record
      final consentId = await mockDatabase.insertDataSharingConsent(consent);

      // Verify successful insertion
      expect(consentId, equals(1));

      // Verify the mock was called with correct data
      verify(mockDatabase.insertDataSharingConsent(
        argThat(predicate<DataSharingConsent>((c) =>
          c.participantUuid == 'test-uuid-123' &&
          c.locationSharingOption == LocationSharingOption.partialData
        ))
      )).called(1);
    });

    test('Location sharing option enum values are consistent', () {
      // Test that enum values are correct
      expect(LocationSharingOption.fullData.index, equals(0));
      expect(LocationSharingOption.partialData.index, equals(1));
      expect(LocationSharingOption.surveyOnly.index, equals(2));
      
      // Test creating DataSharingConsent with each option
      for (final option in LocationSharingOption.values) {
        final consent = DataSharingConsent(
          id: 'consent-123',
          participantUuid: 'test-uuid',
          locationSharingOption: option,
          decisionTimestamp: DateTime.now(),
        );
        
        expect(consent.locationSharingOption, equals(option));
      }
    });

    test('ConsentResponse model correctly stores comprehensive consent data', () {
      // Test the updated ConsentResponse model
      final consent = ConsentResponse(
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

      // Verify all consent fields are properly stored
      expect(consent.participantUuid, equals('test-uuid-123'));
      expect(consent.informedConsent, isTrue);
      expect(consent.dataProcessing, isTrue);
      expect(consent.locationData, isTrue);
      expect(consent.surveyData, isTrue);
      expect(consent.dataRetention, isTrue);
      expect(consent.dataSharing, isTrue);
      expect(consent.voluntaryParticipation, isTrue);
      expect(consent.participantSignature, equals('Test Signature'));
      expect(consent.consentedAt, isA<DateTime>());
    });

    test('Data integrity preserved during JSON serialization', () {
      // Create consent with location sharing preference
      final originalConsent = DataSharingConsent(
        id: 'consent-123',
        participantUuid: 'participant-456',
        locationSharingOption: LocationSharingOption.partialData,
        decisionTimestamp: DateTime.now(),
        customLocationIds: ['loc1', 'loc2'],
        reasonForPartialSharing: 'Privacy concerns',
      );

      // Convert to JSON and back
      final json = originalConsent.toJson();
      final reconstructedConsent = DataSharingConsent.fromJson(json);

      // Verify data integrity is preserved
      expect(reconstructedConsent.id, equals(originalConsent.id));
      expect(reconstructedConsent.participantUuid, equals(originalConsent.participantUuid));
      expect(reconstructedConsent.locationSharingOption, equals(originalConsent.locationSharingOption));
      expect(reconstructedConsent.customLocationIds, equals(originalConsent.customLocationIds));
      expect(reconstructedConsent.reasonForPartialSharing, equals(originalConsent.reasonForPartialSharing));
    });

    test('LocationTrack JSON serialization maintains coordinate precision', () {
      // Create LocationTrack with precise coordinates
      final originalTrack = LocationTrack(
        timestamp: DateTime.parse('2024-01-15T10:30:00Z'),
        latitude: -26.204103456789,
        longitude: 28.047305123456,
        accuracy: 12.345,
        altitude: 1234.56,
        speed: 15.75,
        activity: 'walking',
      );

      // Convert to JSON and verify precision is maintained
      final json = originalTrack.toJson();
      
      expect(json['latitude'], equals(-26.204103456789));
      expect(json['longitude'], equals(28.047305123456));
      expect(json['accuracy'], equals(12.345));
      expect(json['altitude'], equals(1234.56));
      expect(json['speed'], equals(15.75));
      expect(json['activity'], equals('walking'));
      expect(json['timestamp'], equals('2024-01-15T10:30:00.000Z'));
    });
  });
}
