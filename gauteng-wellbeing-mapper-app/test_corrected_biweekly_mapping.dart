import 'dart:convert';
import 'package:http/http.dart' as http;

/// Test script to validate the corrected Qualtrics biweekly survey mapping
void main() async {
  const apiToken = 'WxyQMBmQvkPrL3H9YuKPCGhpCtccT7Z28KKwkMVt';
  const surveyId = 'SV_eUJstaSWQeKykBM'; // Biweekly Survey (Proper)
  const baseUrl = 'https://pretoria.eu.qualtrics.com/API/v3';
  
  // Test with corrected mapping based on QSF file
  final testData = <String, String>{
    'QID1': 'test-participant-uuid-12345',      // participant_uuid
    'QID2': 'Work,Exercise/sport,Socializing',  // activities
    'QID3': 'Living with family',               // living_arrangement  
    'QID4': 'In a relationship',                // relationship_status
    'QID5': 'Good',                            // general_health
    'QID6': '4',                               // cheerful_spirits
    'QID7': '4',                               // calm_relaxed
    'QID8': '3',                               // active_vigorous
    'QID9': '4',                               // woke_up_fresh
    'QID10': '3',                              // daily_life_interesting
    'QID11': '4',                              // cooperate_with_people
    'QID12': '3',                              // improving_skills
    'QID13': '4',                              // social_situations
    'QID14': '5',                              // family_support
    'QID15': '4',                              // family_knows_me
    'QID16': '5',                              // access_to_food
    'QID17': '4',                              // people_enjoy_time
    'QID18': '4',                              // talk_to_family
    'QID19': '3',                              // friends_support
    'QID20': '4',                              // belong_in_community
    'QID21': '5',                              // family_stands_by_me
    'QID22': '3',                              // friends_stand_by_me
    'QID23': '4',                              // treated_fairly
    'QID24': '3',                              // opportunities_responsibility
    'QID25': '5',                              // secure_with_family
    'QID26': '4',                              // opportunities_abilities
    'QID27': '3',                              // enjoy_cultural_traditions
    'QID28': 'Traffic noise and air pollution', // environmental_challenges
    'QID29': '3',                              // challenges_stress_level
    'QID30': 'Family support and community resources', // coping_help
    'QID31': 'encrypted_location_data_placeholder', // location_data
    'QID32': DateTime.now().toIso8601String(),  // submitted_at
  };
  
  try {
    print('🧪 Testing corrected Qualtrics biweekly survey mapping...');
    print('Survey ID: $surveyId');
    print('Data points: ${testData.length}');
    
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
    
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print('✅ SUCCESS: Survey response created with ID: ${responseData['result']['id']}');
    } else {
      print('❌ FAILED: ${response.body}');
    }
  } catch (e) {
    print('❌ ERROR: $e');
  }
}
