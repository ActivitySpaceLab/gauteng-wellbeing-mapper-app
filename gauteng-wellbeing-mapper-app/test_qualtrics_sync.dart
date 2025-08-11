#!/usr/bin/env dart

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Test script to verify Qualtrics API mapping fixes
void main() async {
  print('🧪 Testing Qualtrics API mapping...');
  
  // Sample survey data structure (mimicking what's in the database)
  final sampleSurveyData = {
    'id': 999,
    'age': 25,
    'ethnicity': '["African"]',
    'gender': 'Female',
    'sexuality': 'Heterosexual',
    'birth_place': 'Gauteng',
    'suburb': 'Johannesburg',
    'building_type': 'Apartment/Flat',
    'household_items': '["Electricity", "Running water", "Flush toilet"]',
    'education': 'University degree',
    'climate_activism': 'Moderately involved',
    'general_health': 'Good',
    'activities': '["Work", "Exercise", "Socializing"]',
    'living_arrangement': 'With family',
    'relationship_status': 'Single',
    'cheerful_spirits': 3,
    'calm_relaxed': 4,
    'active_vigorous': 3,
    'woke_up_fresh': 2,
    'daily_life_interesting': 4,
    'cooperate_with_people': 4,
    'improving_skills': 3,
    'social_situations': 3,
    'family_support': 5,
    'family_knows_me': 4,
    'access_to_food': 5,
    'people_enjoy_time': 4,
    'talk_to_family': 4,
    'friends_support': 4,
    'belong_in_community': 3,
    'family_stands_by_me': 4,
    'friends_stand_by_me': 3,
    'treated_fairly': 3,
    'opportunities_responsibility': 3,
    'secure_with_family': 4,
    'opportunities_abilities': 3,
    'enjoy_cultural_traditions': 4,
    'environmental_challenges': 'Traffic pollution',
    'challenges_stress_level': 'Moderate',
    'coping_help': 'Talk to friends',
    'voice_note_urls': '[]',
    'image_urls': '[]',
    'research_site': 'gauteng',
    'submitted_at': '2025-08-11T06:00:00.000Z',
  };
  
  print('📊 Mapping survey data to Qualtrics format...');
  final mappedData = mapInitialSurveyToQualtrics(sampleSurveyData);
  
  print('📋 Mapped data:');
  mappedData.forEach((key, value) {
    print('  $key: $value');
  });
  
  print('\n📤 Testing Qualtrics API call...');
  await testQualtricsApiCall(mappedData);
  
  print('\n🔍 Testing minimal data to identify required fields...');
  await testMinimalData();
}

/// Test with minimal data to identify required fields
Future<void> testMinimalData() async {
  print('Testing with just QID1 (participant UUID)...');
  await testQualtricsApiCall({'QID1': 'test-uuid-123'});
  
  print('\nTesting with participant UUID + age...');
  await testQualtricsApiCall({'QID1': 'test-uuid-123', 'QID2': '25'});
  
  print('\nTesting different QID formats...');
  await testQualtricsApiCall({'QID_1': 'test-uuid-123'});
  
  print('\nTesting standard Qualtrics format...');
  await testQualtricsApiCall({'Q1': 'test-uuid-123'});
  
  print('\nTesting embedded data format...');
  await testQualtricsApiCall({'participant_uuid': 'test-uuid-123'});
}

/// Map survey data to Qualtrics format (matching the updated service)
Map<String, dynamic> mapInitialSurveyToQualtrics(Map<String, dynamic> survey) {
  final data = <String, dynamic>{};
  
  // Add participant UUID (using test UUID)
  data['QID1'] = 'test-uuid-123';
  
  // Use simple QID numbering that matches the published survey
  if (survey['age'] != null) data['QID2'] = survey['age'].toString();
  if (survey['ethnicity'] != null) {
    final ethnicity = jsonDecode(survey['ethnicity'] as String) as List;
    data['QID3'] = ethnicity.join(',');
  }
  if (survey['gender'] != null) data['QID4'] = survey['gender'];
  if (survey['sexuality'] != null) data['QID5'] = survey['sexuality'];
  if (survey['birth_place'] != null) data['QID6'] = survey['birth_place'];
  if (survey['suburb'] != null) data['QID7'] = survey['suburb'];
  if (survey['building_type'] != null) data['QID8'] = survey['building_type'];
  if (survey['household_items'] != null) {
    final items = jsonDecode(survey['household_items'] as String) as List;
    data['QID9'] = items.join(',');
  }
  if (survey['education'] != null) data['QID10'] = survey['education'];
  if (survey['climate_activism'] != null) data['QID11'] = survey['climate_activism'];
  if (survey['general_health'] != null) data['QID12'] = survey['general_health'];
  
  // Activities and living situation (continue numbering)
  if (survey['activities'] != null) {
    final activities = jsonDecode(survey['activities'] as String) as List;
    data['QID13'] = activities.join(',');
  }
  if (survey['living_arrangement'] != null) data['QID14'] = survey['living_arrangement'];
  if (survey['relationship_status'] != null) data['QID15'] = survey['relationship_status'];
  
  // Wellbeing questions (0-5 scale)
  if (survey['cheerful_spirits'] != null) data['QID16'] = survey['cheerful_spirits'].toString();
  if (survey['calm_relaxed'] != null) data['QID17'] = survey['calm_relaxed'].toString();
  if (survey['active_vigorous'] != null) data['QID18'] = survey['active_vigorous'].toString();
  if (survey['woke_up_fresh'] != null) data['QID19'] = survey['woke_up_fresh'].toString();
  if (survey['daily_life_interesting'] != null) data['QID20'] = survey['daily_life_interesting'].toString();
  
  // Personal characteristics (1-5 scale)
  if (survey['cooperate_with_people'] != null) data['QID21'] = survey['cooperate_with_people'].toString();
  if (survey['improving_skills'] != null) data['QID22'] = survey['improving_skills'].toString();
  if (survey['social_situations'] != null) data['QID23'] = survey['social_situations'].toString();
  if (survey['family_support'] != null) data['QID24'] = survey['family_support'].toString();
  if (survey['family_knows_me'] != null) data['QID25'] = survey['family_knows_me'].toString();
  if (survey['access_to_food'] != null) data['QID26'] = survey['access_to_food'].toString();
  if (survey['people_enjoy_time'] != null) data['QID27'] = survey['people_enjoy_time'].toString();
  if (survey['talk_to_family'] != null) data['QID28'] = survey['talk_to_family'].toString();
  if (survey['friends_support'] != null) data['QID29'] = survey['friends_support'].toString();
  if (survey['belong_in_community'] != null) data['QID30'] = survey['belong_in_community'].toString();
  if (survey['family_stands_by_me'] != null) data['QID31'] = survey['family_stands_by_me'].toString();
  if (survey['friends_stand_by_me'] != null) data['QID32'] = survey['friends_stand_by_me'].toString();
  if (survey['treated_fairly'] != null) data['QID33'] = survey['treated_fairly'].toString();
  if (survey['opportunities_responsibility'] != null) data['QID34'] = survey['opportunities_responsibility'].toString();
  if (survey['secure_with_family'] != null) data['QID35'] = survey['secure_with_family'].toString();
  if (survey['opportunities_abilities'] != null) data['QID36'] = survey['opportunities_abilities'].toString();
  if (survey['enjoy_cultural_traditions'] != null) data['QID37'] = survey['enjoy_cultural_traditions'].toString();
  
  // Digital diary
  if (survey['environmental_challenges'] != null) data['QID38'] = survey['environmental_challenges'];
  if (survey['challenges_stress_level'] != null) data['QID39'] = survey['challenges_stress_level'];
  if (survey['coping_help'] != null) data['QID40'] = survey['coping_help'];
  
  // Media files (store as comma-separated URLs)
  if (survey['voice_note_urls'] != null) {
    final voiceUrls = jsonDecode(survey['voice_note_urls'] as String) as List;
    if (voiceUrls.isNotEmpty) {
      data['QID41'] = voiceUrls.join(',');
    }
  }
  if (survey['image_urls'] != null) {
    final imageUrls = jsonDecode(survey['image_urls'] as String) as List;
    if (imageUrls.isNotEmpty) {
      data['QID42'] = imageUrls.join(',');
    }
  }
  
  // Metadata
  if (survey['research_site'] != null) data['QID43'] = survey['research_site'];
  if (survey['submitted_at'] != null) data['QID44'] = survey['submitted_at'];
  
  return data;
}

/// Test the Qualtrics API call with mapped data
Future<void> testQualtricsApiCall(Map<String, dynamic> responseData) async {
  const baseUrl = 'https://pretoria.eu.qualtrics.com/API/v3';
  const apiToken = 'WxyQMBmQvkPrL3H9YuKPCGhpCtccT7Z28KKwkMVt';
  const surveyId = 'SV_02r8X8ePu0b2WNw'; // Initial Survey ID
  
  final payload = {
    'responses': [
      {
        'responseId': DateTime.now().millisecondsSinceEpoch.toString(),
        'values': responseData,
        'recordedDate': DateTime.now().toIso8601String(),
      }
    ]
  };

  print('📤 Sending payload to Qualtrics:');
  print('   Survey ID: $surveyId');
  print('   Payload: ${jsonEncode(payload)}');

  try {
    final response = await http.post(
      Uri.parse('$baseUrl/surveys/$surveyId/responses'),
      headers: {
        'X-API-TOKEN': apiToken,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(payload),
    );

    print('\n📥 Qualtrics response:');
    print('   Status: ${response.statusCode}');
    print('   Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseJson = jsonDecode(response.body);
      final responseId = responseJson['result']['id'];
      print('✅ Survey response created with ID: $responseId');
    } else {
      print('❌ Qualtrics API error: ${response.statusCode} - ${response.body}');
      
      // Try to parse the error for more details
      try {
        final errorData = jsonDecode(response.body);
        print('📋 Error details: $errorData');
      } catch (e) {
        print('📋 Could not parse error response');
      }
    }
  } catch (e) {
    print('❌ Network error: $e');
  }
}
