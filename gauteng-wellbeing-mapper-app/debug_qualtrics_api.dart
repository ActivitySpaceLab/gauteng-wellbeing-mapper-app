/// Debug script to test Qualtrics API response creation
/// This will help identify exactly what's wrong with the API calls

import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseUrl = 'https://pretoria.eu.qualtrics.com/API/v3';
const String apiToken = 'WxyQMBmQvkPrL3H9YuKPCGhpCtccT7Z28KKwkMVt';
const String testSurveyId = 'SV_bsb8iq0UiATXRJQ'; // Initial Survey

Future<void> main() async {
  print('🔍 Testing Qualtrics API Response Creation...');
  print('===============================================\n');
  
  // Test 1: Simple minimal payload
  await testMinimalPayload();
  
  // Test 2: Check survey details
  await checkSurveyDetails();
  
  // Test 3: Test with detailed payload matching our app
  await testDetailedPayload();
}

Future<void> testMinimalPayload() async {
  print('🧪 Test 1: Minimal Payload');
  print('---------------------------');
  
  final payload = {
    'responses': [
      {
        'responseId': 'TEST_${DateTime.now().millisecondsSinceEpoch}',
        'values': {
          'QID_PARTICIPANT_UUID': 'TEST_UUID_123',
          'QID_AGE': '25'
        },
        'recordedDate': DateTime.now().toIso8601String(),
      }
    ]
  };
  
  print('📤 Payload: ${jsonEncode(payload)}');
  
  final response = await http.post(
    Uri.parse('$baseUrl/surveys/$testSurveyId/responses'),
    headers: {
      'X-API-TOKEN': apiToken,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: jsonEncode(payload),
  );
  
  print('📥 Response Status: ${response.statusCode}');
  print('📥 Response Body: ${response.body}');
  print('');
}

Future<void> checkSurveyDetails() async {
  print('🧪 Test 2: Survey Details Check');
  print('--------------------------------');
  
  final response = await http.get(
    Uri.parse('$baseUrl/surveys/$testSurveyId'),
    headers: {
      'X-API-TOKEN': apiToken,
      'Content-Type': 'application/json',
    },
  );
  
  print('📥 Survey Details Status: ${response.statusCode}');
  
  if (response.statusCode == 200) {
    final surveyData = jsonDecode(response.body);
    final surveyName = surveyData['result']['name'];
    final isActive = surveyData['result']['isActive'];
    
    print('📋 Survey Name: $surveyName');
    print('📋 Is Active: $isActive');
    
    // Check if survey accepts responses
    if (surveyData['result']['responsesCounts'] != null) {
      final responseCounts = surveyData['result']['responsesCounts'];
      print('📊 Current Response Count: ${responseCounts['auditable']}');
    }
  } else {
    print('❌ Error getting survey details: ${response.body}');
  }
  print('');
}

Future<void> testDetailedPayload() async {
  print('🧪 Test 3: Detailed Payload (App Format)');
  print('------------------------------------------');
  
  final payload = {
    'responses': [
      {
        'responseId': 'APP_TEST_${DateTime.now().millisecondsSinceEpoch}',
        'values': {
          'QID_PARTICIPANT_UUID': 'TEST_UUID_456',
          'QID_AGE': '30',
          'QID_GENDER': 'Female',
          'QID_SUBURB': 'Sandton',
          'QID_CHEERFUL_SPIRITS': '4',
          'QID_CALM_RELAXED': '3',
        },
        'recordedDate': DateTime.now().toIso8601String(),
      }
    ]
  };
  
  print('📤 Detailed Payload: ${jsonEncode(payload)}');
  
  final response = await http.post(
    Uri.parse('$baseUrl/surveys/$testSurveyId/responses'),
    headers: {
      'X-API-TOKEN': apiToken,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: jsonEncode(payload),
  );
  
  print('📥 Detailed Response Status: ${response.statusCode}');
  print('📥 Detailed Response Body: ${response.body}');
  
  if (response.statusCode == 200 || response.statusCode == 201) {
    print('✅ Success! Response created in Qualtrics.');
    final responseData = jsonDecode(response.body);
    if (responseData['result'] != null && responseData['result']['id'] != null) {
      print('🎯 Response ID: ${responseData["result"]["id"]}');
    }
  } else {
    print('❌ Failed to create response');
    try {
      final errorData = jsonDecode(response.body);
      if (errorData['meta'] != null && errorData['meta']['error'] != null) {
        print('🚨 Error Details: ${errorData["meta"]["error"]}');
      }
    } catch (e) {
      print('🚨 Could not parse error response');
    }
  }
}
