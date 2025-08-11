import 'dart:convert';
import 'package:http/http.dart' as http;

/// Test script to validate the new simple Qualtrics surveys work correctly
void main() async {
  const apiToken = 'WxyQMBmQvkPrL3H9YuKPCGhpCtccT7Z28KKwkMVt';
  const baseUrl = 'https://pretoria.eu.qualtrics.com/API/v3';
  
  print('🧪 Testing Simple Qualtrics Survey Integration');
  print('==============================================');
  
  // Test 1: Initial Survey
  await testSurvey(
    'Initial Survey',
    'SV_8pudN8qTI6iQKY6',
    {
      'QID1': 'test-participant-uuid-12345',  // participant_uuid
      'QID2': '25',                           // age
      'QID3': 'Johannesburg',                 // suburb
      'QID4': 'Black',                        // race_ethnicity
      'QID5': 'Male',                         // gender_identity
      'QID6': 'Heterosexual/straight',        // sexual_orientation
      'QID7': 'South Africa',                 // place_of_birth
      'QID8': 'Brick house',                  // building_type
      'QID9': 'radio,television,refrigerator,smartphone', // household_items
      'QID10': 'High school',                 // education
      'QID11': 'Sometimes',                   // climate_activism
      'QID12': 'Employed full-time',          // employment_status
      'QID13': 'R5,000 - R10,000',           // income
      'QID14': 'Work,Exercise/sport,Socializing', // activities
      'QID15': 'Living with family',          // living_arrangement
      'QID16': 'In a relationship',           // relationship_status
      'QID17': 'Good',                        // general_health
      'QID18': '4',                           // cheerful_spirits
      'QID19': '4',                           // calm_relaxed
      'QID20': '3',                           // active_vigorous
      'QID21': '4',                           // woke_up_fresh
      'QID22': '3',                           // daily_life_interesting
      'QID23': '4',                           // cooperate_with_people
      'QID24': '5',                           // improving_skills
      'QID25': '4',                           // social_situations
      'QID26': '5',                           // family_support
      'QID27': '4',                           // family_knows_me
      'QID28': '5',                           // access_to_food
      'QID29': '4',                           // people_enjoy_time
      'QID30': '4',                           // talk_to_family
      'QID31': '3',                           // friends_support
      'QID32': '4',                           // belong_in_community
      'QID33': 'encrypted_location_data_placeholder', // locationJson
      'QID34': DateTime.now().toIso8601String(), // submitted_at
    },
    baseUrl,
    apiToken,
  );
  
  await Future.delayed(Duration(seconds: 2));
  
  // Test 2: Biweekly Survey
  await testSurvey(
    'Biweekly Survey',
    'SV_aXmfOtAIRmIVdfU',
    {
      'QID1': 'test-participant-uuid-12345',  // participant_uuid
      'QID2': 'Work,Exercise/sport,Socializing', // activities
      'QID3': 'Living with family',           // living_arrangement  
      'QID4': 'In a relationship',            // relationship_status
      'QID5': 'Good',                         // general_health
      'QID6': '4',                            // cheerful_spirits
      'QID7': '4',                            // calm_relaxed
      'QID8': '3',                            // active_vigorous
      'QID9': '4',                            // woke_up_fresh
      'QID10': '3',                           // daily_life_interesting
      'QID11': '4',                           // cooperate_with_people
      'QID12': '3',                           // improving_skills
      'QID13': '4',                           // social_situations
      'QID14': '5',                           // family_support
      'QID15': '4',                           // family_knows_me
      'QID16': '5',                           // access_to_food
      'QID17': '4',                           // people_enjoy_time
      'QID18': '4',                           // talk_to_family
      'QID19': '3',                           // friends_support
      'QID20': '4',                           // belong_in_community
      'QID21': '5',                           // family_stands_by_me
      'QID22': '3',                           // friends_stand_by_me
      'QID23': '4',                           // treated_fairly
      'QID24': '3',                           // opportunities_responsibility
      'QID25': '5',                           // secure_with_family
      'QID26': '4',                           // opportunities_abilities
      'QID27': '3',                           // enjoy_cultural_traditions
      'QID28': 'Traffic noise and air pollution', // environmental_challenges
      'QID29': '3',                           // challenges_stress_level
      'QID30': 'Family support and community resources', // coping_help
      'QID31': 'encrypted_location_data_placeholder', // location_data
      'QID32': DateTime.now().toIso8601String(), // submitted_at
    },
    baseUrl,
    apiToken,
  );
  
  await Future.delayed(Duration(seconds: 2));
  
  // Test 3: Consent Survey
  await testSurvey(
    'Consent Survey',
    'SV_eu4OVw6dpbWY5hQ',
    {
      'QID1': 'TEST123',                      // participant_code
      'QID2': 'test-participant-uuid-12345',  // participant_uuid
      'QID3': '1',                            // informed_consent
      'QID4': '1',                            // data_processing_consent
      'QID5': '1',                            // race_ethnicity_consent
      'QID6': '1',                            // health_consent
      'QID7': '1',                            // sexual_orientation_consent
      'QID8': '1',                            // location_mobility_consent
      'QID9': 'Test Participant',             // participant_signature
      'QID10': DateTime.now().toIso8601String(), // consented_at
    },
    baseUrl,
    apiToken,
  );
  
  print('\n✅ All tests completed! Check Qualtrics dashboard for responses.');
}

Future<void> testSurvey(String surveyName, String surveyId, Map<String, String> testData, String baseUrl, String apiToken) async {
  try {
    print('\n📋 Testing $surveyName ($surveyId)...');
    print('   Data points: ${testData.length}');
    
    final response = await http.post(
      Uri.parse('$baseUrl/surveys/$surveyId/responses'),
      headers: {
        'X-API-TOKEN': apiToken,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'values': testData,
      }),
    );
    
    print('   Response status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final responseId = responseData['result']['id'];
      print('   ✅ SUCCESS: Response created with ID: $responseId');
      print('   📊 URL: https://pretoria.eu.qualtrics.com/jfe/form/$surveyId');
    } else {
      print('   ❌ FAILED: ${response.body}');
    }
  } catch (e) {
    print('   ❌ ERROR: $e');
  }
}
