/// Quick test with corrected Question IDs
import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseUrl = 'https://pretoria.eu.qualtrics.com/API/v3';
const String apiToken = 'WxyQMBmQvkPrL3H9YuKPCGhpCtccT7Z28KKwkMVt';
const String testSurveyId = 'SV_bsb8iq0UiATXRJQ'; // Initial Survey

Future<void> main() async {
  print('🧪 Testing with Corrected Question IDs...');
  print('=========================================\n');
  
  // Test with the corrected Question IDs
  final payload = {
    'responses': [
      {
        'responseId': 'CORRECTED_TEST_${DateTime.now().millisecondsSinceEpoch}',
        'values': {
          'QID1': 'TEST_UUID_789',  // participant UUID
          'QID2': '28',             // age
          'QID3': 'Sandton',        // suburb
          'QID5': 'Woman',          // gender
        },
        'recordedDate': DateTime.now().toIso8601String(),
      }
    ]
  };
  
  print('📤 Testing with corrected QIDs: ${jsonEncode(payload)}');
  
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
  
  if (response.statusCode == 200 || response.statusCode == 201) {
    print('🎉 SUCCESS! Corrected Question IDs work!');
    final responseData = jsonDecode(response.body);
    if (responseData['result'] != null && responseData['result']['id'] != null) {
      print('✅ Response ID: ${responseData["result"]["id"]}');
      print('✅ Data successfully submitted to Qualtrics!');
    }
  } else {
    print('❌ Still failing with corrected QIDs');
    try {
      final errorData = jsonDecode(response.body);
      if (errorData['meta'] != null && errorData['meta']['error'] != null) {
        print('🚨 Error: ${errorData["meta"]["error"]}');
      }
    } catch (e) {
      print('🚨 Could not parse error response');
    }
  }
}
