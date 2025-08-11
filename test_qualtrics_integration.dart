import 'dart:convert';
import 'dart:io';

// Test the current Qualtrics API integration
void main() async {
  print('=== Testing Current Qualtrics Integration ===\n');
  
  // Simulate the exact data format your app would send
  await testInitialSurvey();
  await testBiweeklySurvey();  
  await testConsentSurvey();
  
  print('\n=== Test Complete ===');
}

Future<void> testInitialSurvey() async {
  print('📋 Testing Initial Survey (SV_8pudN8qTI6iQKY6)...');
  
  final testData = {
    'QID1': 'test-uuid-${DateTime.now().millisecondsSinceEpoch}', // Participant UUID
    'QID2': 'test-code-${DateTime.now().millisecondsSinceEpoch}', // Participant Code  
    'QID3': '28', // Age
    'QID4': 'Pretoria', // Suburb/community in Gauteng
    'QID5': 'Black', // Race/ethnicity
    'QID6': 'Female', // Gender identity
    'QID7': 'Heterosexual', // Sexual orientation
    'QID8': 'South Africa', // Place of birth
    'QID9': 'House', // Building type
    'QID10': 'Car,Computer,TV', // Household items
    'QID11': 'University degree', // Education level
    'QID12': 'Moderately involved', // Climate activism
    'QID13': 'Work,Exercise,Socialize', // Activities
    'QID14': 'With others', // Living arrangement
    'QID15': 'In a relationship', // Relationship status
    'QID16': '4', // General health (1-5)
    'QID17': '4', // Cheerful spirits (0-5)
    'QID18': '3', // Calm and relaxed (0-5)
    'QID19': '4', // Active and vigorous (0-5)
    'QID20': '3', // Woke up fresh (0-5)
    'QID21': '4', // Daily life interesting (0-5)
    'QID22': '4', // Cooperate with people (1-5)
    'QID23': '5', // Improving qualifications important (1-5)
    'QID24': '4', // Know social behavior (1-5)
    'QID25': '4', // Family support (1-5)
    'QID26': 'encrypted_location_data_placeholder', // Encrypted location
    'QID27': DateTime.now().toIso8601String(), // Submission timestamp
  };
  
  await submitAndVerifyData('SV_8pudN8qTI6iQKY6', testData, 'Initial Survey');
}

Future<void> testBiweeklySurvey() async {
  print('\n📋 Testing Biweekly Survey (SV_aXmfOtAIRmIVdfU)...');
  
  final testData = {
    'QID1': 'test-uuid-biweekly-${DateTime.now().millisecondsSinceEpoch}', // Participant UUID
    'QID2': '30', // Age
    'QID3': 'Johannesburg', // Suburb/community
    'QID4': 'Coloured', // Race/ethnicity
    'QID5': 'Male', // Gender identity
    'QID6': '3', // General health (1-5)
    'QID7': '3', // Cheerful spirits (0-5)
    'QID8': '2', // Calm and relaxed (0-5)
    'QID9': '3', // Active and vigorous (0-5)
    'QID10': '2', // Woke up fresh (0-5)
    'QID11': '3', // Daily life interesting (0-5)
    'QID12': '3', // Cooperate with people (1-5)
    'QID13': '4', // Improving qualifications important (1-5)
    'QID14': '3', // Know social behavior (1-5)
    'QID15': '3', // Family support (1-5)
    'QID16': 'Work,Shopping', // Activities in last two weeks
    'QID17': 'Some challenges', // General wellbeing description
    'QID18': 'Moderately happy', // Happiness level
    'QID19': '7', // Life satisfaction (1-10)
    'QID20': 'Sometimes', // Feel in control
    'QID21': 'Good', // Sleep quality
    'QID22': '6', // Energy level (1-10)
    'QID23': 'Moderate', // Stress level
    'QID24': 'Good', // Social connections
    'QID25': '8', // Optimism about future (1-10)
    'QID26': 'Some concerns', // Environmental concerns
    'QID27': 'Somewhat satisfied', // Neighbourhood satisfaction
    'QID28': 'Good', // Access to services
    'QID29': 'Some challenges', // Transportation access
    'QID30': 'encrypted_location_data_biweekly', // Encrypted location
    'QID31': DateTime.now().toIso8601String(), // Submission timestamp
    'QID32': 'Additional notes here', // Any additional comments
  };
  
  await submitAndVerifyData('SV_aXmfOtAIRmIVdfU', testData, 'Biweekly Survey');
}

Future<void> testConsentSurvey() async {
  print('\n📋 Testing Consent Survey (SV_eu4OVw6dpbWY5hQ)...');
  
  final testData = {
    'QID1': 'test-code-consent-${DateTime.now().millisecondsSinceEpoch}', // Participant code
    'QID2': 'test-uuid-consent-${DateTime.now().millisecondsSinceEpoch}', // Participant UUID
    'QID3': '1', // Informed consent
    'QID4': '1', // Data processing consent
    'QID5': '1', // Race/ethnicity consent
    'QID6': '1', // Health consent
    'QID7': '0', // Sexual orientation consent (declined)
    'QID8': '1', // Location/mobility consent
    'QID9': '1', // Data transfer consent
    'QID10': '1', // Public reporting consent
    'QID11': '1', // Data sharing researchers consent
    'QID12': '1', // Further research consent
    'QID13': '0', // Public repository consent (declined)
    'QID14': '1', // Follow-up contact consent
    'QID15': 'Test Participant Signature', // Participant signature
    'QID16': DateTime.now().toIso8601String(), // Consent timestamp
  };
  
  await submitAndVerifyData('SV_eu4OVw6dpbWY5hQ', testData, 'Consent Survey');
}

Future<void> submitAndVerifyData(String surveyId, Map<String, dynamic> testData, String surveyName) async {
  const String qualtricsToken = 'WxyQMBmQvkPrL3H9YuKPCGhpCtccT7Z28KKwkMVt';
  const String qualtricsUrl = 'https://pretoria.eu.qualtrics.com';
  
  try {
    // Submit with the corrected format including finished flag
    final payload = {
      'values': testData,
      'finished': true,
      'recordedDate': DateTime.now().toIso8601String(),
    };
    
    print('  📤 Submitting $surveyName data...');
    
    final client = HttpClient();
    final request = await client.postUrl(Uri.parse('$qualtricsUrl/API/v3/surveys/$surveyId/responses'));
    request.headers.set('X-API-TOKEN', qualtricsToken);
    request.headers.set('Content-Type', 'application/json');
    
    request.write(jsonEncode(payload));
    final response = await request.close();
    
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 200) {
      final responseData = jsonDecode(responseBody);
      final responseId = responseData['result']['responseId'];
      print('  ✅ Submission successful: $responseId');
      
      // Wait and verify data
      await Future.delayed(Duration(seconds: 3));
      await verifyStoredData(client, qualtricsUrl, qualtricsToken, surveyId, responseId, testData, surveyName);
      
    } else {
      print('  ❌ Submission failed: ${response.statusCode}');
      print('  Response: $responseBody');
    }
    
    client.close();
  } catch (e) {
    print('  ❌ Error: $e');
  }
}

Future<void> verifyStoredData(HttpClient client, String baseUrl, String token, String surveyId, String responseId, Map<String, dynamic> originalData, String surveyName) async {
  try {
    print('  🔍 Verifying stored data...');
    
    final request = await client.getUrl(Uri.parse('$baseUrl/API/v3/surveys/$surveyId/responses/$responseId'));
    request.headers.set('X-API-TOKEN', token);
    request.headers.set('Content-Type', 'application/json');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 200) {
      final responseData = jsonDecode(responseBody);
      final storedValues = responseData['result']['values'] as Map<String, dynamic>;
      
      int matchedFields = 0;
      int totalFields = originalData.length;
      
      for (var key in originalData.keys) {
        if (storedValues.containsKey(key) && storedValues[key] != null && storedValues[key].toString().trim().isNotEmpty) {
          matchedFields++;
        }
      }
      
      if (matchedFields == 0) {
        print('  ❌ CRITICAL: No data found in Qualtrics!');
        print('  📊 Survey may not be properly configured for API submissions');
        print('  🔧 Survey needs to be recreated via API');
      } else if (matchedFields < totalFields) {
        print('  ⚠️  Partial data stored: $matchedFields/$totalFields fields');
        print('  📊 Some fields may have validation issues');
      } else {
        print('  ✅ All data stored correctly: $matchedFields/$totalFields fields');
      }
    } else {
      print('  ❌ Could not verify data: ${response.statusCode}');
    }
  } catch (e) {
    print('  ❌ Verification error: $e');
  }
}
