import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('=== Comprehensive Qualtrics Survey Structure Test ===\n');
  
  const String qualtricsToken = 'WxyQMBmQvkPrL3H9YuKPCGhpCtccT7Z28KKwkMVt';
  const String qualtricsUrl = 'https://pretoria.eu.qualtrics.com';
  
  // Test all three survey IDs
  const surveys = {
    'Initial Survey': 'SV_8pudN8qTI6iQKY6',
    'Biweekly Survey': 'SV_aXmfOtAIRmIVdfU', 
    'Consent Survey': 'SV_eu4OVw6dpbWY5hQ',
  };
  
  for (var entry in surveys.entries) {
    print('--- Testing ${entry.key} (${entry.value}) ---');
    
    // 1. First check if we can get survey structure
    await checkSurveyStructure(qualtricsUrl, qualtricsToken, entry.value);
    
    // 2. Submit test data with clear field names
    await submitTestData(qualtricsUrl, qualtricsToken, entry.value, entry.key);
    
    print('');
  }
  
  print('=== Test Complete ===');
}

Future<void> checkSurveyStructure(String baseUrl, String token, String surveyId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/API/v3/surveys/$surveyId'),
      headers: {
        'X-API-TOKEN': token,
        'Content-Type': 'application/json',
      },
    );
    
    print('Survey Structure Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final result = data['result'];
      print('Survey Name: ${result['name']}');
      print('Survey Status: ${result['isActive']}');
      
      // Check if we have questions
      if (result['questions'] != null) {
        final questions = result['questions'] as Map;
        print('Questions found: ${questions.length}');
        
        // Print first few question IDs
        var count = 0;
        for (var qid in questions.keys) {
          if (count < 5) {
            final q = questions[qid];
            print('  $qid: ${q['questionText'] ?? 'No text'}');
            count++;
          }
        }
        if (questions.length > 5) print('  ... and ${questions.length - 5} more');
      } else {
        print('❌ No questions found in survey structure!');
      }
    } else {
      print('❌ Failed to get survey structure: ${response.body}');
    }
  } catch (e) {
    print('❌ Error checking survey structure: $e');
  }
}

Future<void> submitTestData(String baseUrl, String token, String surveyId, String surveyType) async {
  // Create different test data for each survey type
  Map<String, dynamic> testData;
  
  switch (surveyType) {
    case 'Initial Survey':
      testData = {
        'QID1': 'TEST-UUID-INITIAL-${DateTime.now().millisecondsSinceEpoch}',
        'QID2': '25',
        'QID3': 'Johannesburg',
        'QID4': 'African',
        'QID5': 'Female',
        'QID6': '4', // Very happy
        'QID7': '5', // Strongly agree
      };
      break;
    case 'Biweekly Survey':
      testData = {
        'QID1': 'TEST-UUID-BIWEEKLY-${DateTime.now().millisecondsSinceEpoch}',
        'QID2': '30',
        'QID3': 'Cape Town', 
        'QID4': 'Coloured',
        'QID5': 'Male',
        'QID6': '3', // Somewhat happy
        'QID7': '4', // Agree
      };
      break;
    case 'Consent Survey':
      testData = {
        'QID1': 'TEST-CODE-${DateTime.now().millisecondsSinceEpoch}',
        'QID2': 'TEST-UUID-CONSENT-${DateTime.now().millisecondsSinceEpoch}',
        'QID3': '1', // Informed consent
        'QID4': '1', // Data processing consent
        'QID5': '1', // Race/ethnicity consent
        'QID6': '1', // Health consent
        'QID7': '0', // Sexual orientation consent (declined)
        'QID8': '1', // Location/mobility consent
        'QID9': '1', // Data transfer consent
        'QID10': '1', // Public reporting consent
        'QID11': '1', // Data sharing consent
        'QID12': '1', // Further research consent
        'QID13': '0', // Public repository consent (declined)
        'QID14': '1', // Follow-up contact consent
        'QID15': 'Test Participant Signature',
        'QID16': DateTime.now().toIso8601String(),
      };
      break;
    default:
      testData = {'QID1': 'Unknown survey type'};
  }
  
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/API/v3/surveys/$surveyId/responses'),
      headers: {
        'X-API-TOKEN': token,
        'Content-Type': 'application/json',
      },
      body: json.encode(testData),
    );
    
    print('Data Submission Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final responseId = responseData['result']?['responseId'];
      print('✅ Response ID: $responseId');
      print('Submitted Data Fields: ${testData.keys.length}');
      print('Sample Field: QID1 = "${testData['QID1']}"');
      
      // Try to retrieve the response we just created
      await Future.delayed(Duration(seconds: 2)); // Wait for processing
      await checkResponseData(baseUrl, token, surveyId, responseId);
      
    } else {
      print('❌ Submission failed: ${response.body}');
    }
  } catch (e) {
    print('❌ Error submitting data: $e');
  }
}

Future<void> checkResponseData(String baseUrl, String token, String surveyId, String? responseId) async {
  if (responseId == null) return;
  
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/API/v3/surveys/$surveyId/responses/$responseId'),
      headers: {
        'X-API-TOKEN': token,
        'Content-Type': 'application/json',
      },
    );
    
    print('Response Retrieval Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final result = data['result'];
      final values = result['values'] as Map?;
      
      if (values != null && values.isNotEmpty) {
        print('✅ Response data retrieved successfully');
        print('Fields with data: ${values.keys.length}');
        
        // Show first few fields with actual values
        var count = 0;
        for (var key in values.keys) {
          if (count < 3 && values[key] != null && values[key].toString().isNotEmpty) {
            print('  $key: "${values[key]}"');
            count++;
          }
        }
      } else {
        print('❌ Response exists but has no field values!');
        print('Full response structure: ${json.encode(result)}');
      }
    } else {
      print('❌ Failed to retrieve response: ${response.body}');
    }
  } catch (e) {
    print('❌ Error retrieving response: $e');
  }
}
