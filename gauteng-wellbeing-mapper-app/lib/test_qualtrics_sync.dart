/// Test script to verify Qualtrics sync is working with new survey IDs
/// Run this from the root directory: dart lib/test_qualtrics_sync.dart

import 'services/qualtrics_api_service.dart';

Future<void> main() async {
  print('🧪 Testing Qualtrics Sync with New Survey IDs...');
  print('=================================================\n');
  
  // Test data that matches the Flutter app structure
  final testInitialSurvey = {
    'id': 999,
    'participant_uuid': 'TEST_UUID_123',
    'age': 25,
    'ethnicity': 'African',
    'gender': 'Female',
    'sexuality': 'Heterosexual',
    'birth_place': 'Johannesburg',
    'suburb': 'Sandton',
    'years_in_gauteng': 5,
    'income': 'R10,000 - R20,000',
    'education': 'University degree',
    'employment': 'Full-time',
    'household_size': 3,
    'housing_type': 'Apartment',
    'transport_mode': 'Car',
    'life_satisfaction': 7,
    'happiness_level': 8,
    'stress_level': 4,
    'physical_health': 7,
    'mental_health': 6,
    'social_connections': 8,
    'activities': 'Reading, Exercise, Music',
    'research_site': 'Test Site',
    'submitted_at': DateTime.now().toIso8601String(),
    'encrypted_location_data': 'encrypted_test_data',
  };

  final testBiweeklySurvey = {
    'id': 888,
    'participant_uuid': 'TEST_UUID_123',
    'life_satisfaction': 6,
    'happiness_level': 7,
    'stress_level': 5,
    'physical_health': 6,
    'mental_health': 7,
    'social_connections': 8,
    'sleep_quality': 7,
    'energy_level': 6,
    'opportunities_abilities': 7,
    'enjoy_cultural_traditions': 8,
    'environmental_challenges': 'Traffic noise',
    'challenges_stress_level': 'Moderate',
    'coping_help': 'Exercise and meditation',
    'research_site': 'Test Site',
    'submitted_at': DateTime.now().toIso8601String(),
    'encrypted_location_data': 'encrypted_test_data',
  };

  try {
    print('📋 Testing Initial Survey Sync...');
    final initialSuccess = await QualtricsApiService.syncInitialSurvey(testInitialSurvey);
    print(initialSuccess ? '✅ Initial survey sync successful!' : '❌ Initial survey sync failed');
    
    print('\n📋 Testing Biweekly Survey Sync...');
    final biweeklySuccess = await QualtricsApiService.syncBiweeklySurvey(testBiweeklySurvey);
    print(biweeklySuccess ? '✅ Biweekly survey sync successful!' : '❌ Biweekly survey sync failed');
    
    print('\n🎯 Survey URLs:');
    print('Initial: https://pretoria.eu.qualtrics.com/jfe/form/SV_02r8X8ePu0b2WNw');
    print('Biweekly: https://pretoria.eu.qualtrics.com/jfe/form/SV_88oXgY81cCwIxvw');
    print('Consent: https://pretoria.eu.qualtrics.com/jfe/form/SV_eYdj4iL3W8ydWJ0');
    
    if (initialSuccess && biweeklySuccess) {
      print('\n🎉 All tests passed! Check Qualtrics Data & Analysis for the test responses.');
    } else {
      print('\n⚠️ Some tests failed. Check the error messages above.');
    }
    
  } catch (e) {
    print('❌ Error during testing: $e');
  }
}
